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

            plugins = ["github.com/caddy-dns/porkbun@v0.1.4"];

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

            outputHash = "sha256-W1VoZhtGlL4eiC0ttXEpUAk8J9OgvbVrtGIEAmfssbk=";
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
        --run "export PORKBUN_API_KEY=\$(cat /run/secrets/porkbun_dns/api_key)" \
        --run "export PORKBUN_API_SECRET_KEY=\$(cat /run/secrets/porkbun_dns/api_secret_key)"
    '';
  };
in {
  config = {
    services.caddy = {
      enable = true;
      package = caddy-with-plugins-and-secrets;

      globalConfig = ''
        acme_dns porkbun {
          api_key {env.PORKBUN_API_KEY}
          api_secret_key {env.PORKBUN_API_SECRET_KEY}
        }
      '';
    };

    # allow caddy to bind to privileged ports
    systemd.services.caddy.serviceConfig = {
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
    };

    sops.secrets = {
      "porkbun_dns/api_key".owner = config.users.users.caddy.name;
      "porkbun_dns/api_secret_key".owner = config.users.users.caddy.name;
    };
  };
}
