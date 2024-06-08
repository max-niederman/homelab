{
  config,
  pkgs,
  lib,
  ...
}: let
  # vendored from https://github.com/NixOS/nixpkgs/pull/259275
  caddy-with-plugins = pkgs.caddy.override {
    buildGoModule = args:
      pkgs.buildGoModule (
        args
        // {
          src = pkgs.stdenv.mkDerivation (finalAttrs: rec {
            pname = "caddy-using-xcaddy-${pkgs.xcaddy.version}";
            inherit (pkgs.caddy) version;

            isUpToDate = lib.asserts.assertMsg (version == "2.7.6") "output hash is not up-to-date";

            dontUnpack = true;
            dontFixup = true;

            nativeBuildInputs = with pkgs; [
              cacert
              go
            ];

            plugins = ["github.com/caddy-dns/cloudflare@44030f9306f4815aceed3b042c7f3d2c2b110c97"];

            configurePhase = ''
              export GOCACHE=$TMPDIR/go-cache
              export GOPATH="$TMPDIR/go"
              export XCADDY_SKIP_BUILD=1
            '';

            buildPhase = ''
              ${pkgs.xcaddy}/bin/xcaddy build "v${version}" ${
                lib.concatMapStringsSep " " (plugin: "--with ${plugin}") finalAttrs.plugins
              }
              cd buildenv*
              go mod vendor
            '';

            installPhase = ''
              cp -a . $out
            '';

            outputHash = "sha256-KzJUWEF94ac1KHiFrFoo5YgaiQjCcBFYrJHKrd4OXUw=";
            outputHashMode = "recursive";
          });

          subPackages = ["."];
          ldflags = [
            "-s"
            "-w"
          ];
          vendorHash = null;
        }
      );
  };

  caddy-with-plugins-and-secrets = pkgs.stdenv.mkDerivation {
    pname = "caddy-with-plugins-and-secrets";
    inherit (caddy-with-plugins) version;

    src = caddy-with-plugins;

    nativeBuildInputs = with pkgs; [makeWrapper];

    installPhase = ''
      makeWrapper $src/bin/caddy $out/bin/caddy \
        --run "export CF_API_TOKEN=\$(cat /run/secrets/caddy/cf_api_token)" \
    '';
  };
in {
  config = {
    services.caddy = {
      enable = true;
      package = caddy-with-plugins-and-secrets;

      globalConfig = ''
        email max@maxniederman.com

        acme_dns cloudflare {env.CF_API_TOKEN}
      '';
    };

    # allow caddy to bind to privileged ports
    systemd.services.caddy.serviceConfig = {
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
    };

    systemd.tmpfiles.rules = [
      "L /var/lib/caddy - - - - /persist/var/lib/caddy"
    ];

    sops.secrets = {
      "caddy/cf_api_token".owner = config.users.users.caddy.name;
    };
  };
}
