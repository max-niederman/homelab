{ config, pkgs, lib, ... }:
let
  cfg = config.services.caddy;

  # vendored from https://github.com/NixOS/nixpkgs/pull/259275
  caddy-with-plugins = pkgs.caddy.override {
    buildGoModule = args:
      pkgs.buildGoModule (args // {
        src = pkgs.stdenv.mkDerivation (finalAttrs: rec {
          pname = "caddy-using-xcaddy-${pkgs.xcaddy.version}";
          inherit (pkgs.caddy) version;

          isUpToDate = lib.asserts.assertMsg (version == "2.8.4")
            "output hash is not up-to-date, update the version in the isUpToDate assertion the outputHash";

          dontUnpack = true;
          dontFixup = true;

          nativeBuildInputs = with pkgs; [ cacert go ];

          plugins = [
            "github.com/caddy-dns/cloudflare@89f16b99c18ef49c8bb470a82f895bce01cbaece"
          ];

          configurePhase = ''
            export GOCACHE=$TMPDIR/go-cache
            export GOPATH="$TMPDIR/go"
            export XCADDY_SKIP_BUILD=1
          '';

          buildPhase = ''
            ${pkgs.xcaddy}/bin/xcaddy build "v${version}" ${
              lib.concatMapStringsSep " " (plugin: "--with ${plugin}")
              finalAttrs.plugins
            }
            cd buildenv*
            go mod vendor
          '';

          installPhase = ''
            cp -a . $out
          '';

          outputHash = "sha256-sHfcEXF39s2PTyOl6HX8lqHb/wv3k+VuEq61Wo8xtF4=";
          outputHashMode = "recursive";
        });

        subPackages = [ "." ];
        ldflags = [ "-s" "-w" ];
        vendorHash = null;
      });
  };

  caddy-with-plugins-and-secrets = pkgs.stdenv.mkDerivation {
    pname = "caddy-with-plugins-and-secrets";
    inherit (caddy-with-plugins) version;

    src = caddy-with-plugins;

    nativeBuildInputs = with pkgs; [ makeWrapper ];

    installPhase = ''
      makeWrapper $src/bin/caddy $out/bin/caddy \
        --run "export CF_ZONE_TOKEN=\$(cat /run/secrets/caddy/cf_zone_token)" \
        --run "export CF_API_TOKEN=\$(cat /run/secrets/caddy/cf_api_token)"
    '';
  };
in {
  options.services.caddy = {
    maximalHosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ config, lib, ... }: {
        options = {
          proxyTo = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
          };

          extraConfig = lib.mkOption {
            type = lib.types.str;
            default = lib.strings.optionalString (config.proxyTo != null) ''
              reverse_proxy ${config.proxyTo}
            '';
          };
        };
      }));
    };
  };

  config = {
    services.caddy = {
      package = caddy-with-plugins-and-secrets;

      globalConfig = ''
        servers { metrics }

        admin 0.0.0.0:2019 {
          origins localhost:2019 [::1]:2019 127.0.0.1:2019 ${config.networking.hostName}:2019 ${config.networking.hostName}.banded-scala.ts.net:2019
        }
      '';

      virtualHosts = lib.attrsets.mapAttrs' (name: cfg: {
        name = "${name}.maximal.enterprises";
        value = {
          extraConfig = ''
            tls max@maxniederman.com {
              dns cloudflare {
                zone_token {env.CF_ZONE_TOKEN}
                api_token {env.CF_API_TOKEN}
              }
              resolvers 1.1.1.1 1.0.0.1
            }

            ${cfg.extraConfig or ""}
          '';
        };
      }) cfg.maximalHosts;
    };

    # allow caddy to bind to privileged ports
    systemd.services.caddy.serviceConfig = {
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
    };

    systemd.tmpfiles.rules = [ "L /var/lib/caddy - - - - /persist/caddy" ];

    sops.secrets = {
      "caddy/cf_zone_token".owner = config.users.users.caddy.name;
      "caddy/cf_api_token".owner = config.users.users.caddy.name;
    };
  };
}
