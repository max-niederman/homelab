{
  config,
  lib,
  ...
}: let
  mkAddress = name: let
    inherit (builtins) hashString substring concatStringsSep;
    hash = hashString "sha256" name;
    hextets = map (i: substring (i * 4) 4 hash) [12 13 14 15]; # take the least significant 64 bits, or 4 hextets
  in
    "fc00::" + concatStringsSep ":" hextets;
in {
  options = {
    hcontainers = lib.mkOption {
      default = {};
      type = lib.types.attrsOf (lib.types.submodule (
        {
          config,
          options,
          name,
          ...
        }: {
          options = {
            config = lib.mkOption {
              description = ''
                A specification of the desired configuration of this
                container, as a NixOS module.
              '';
            };
          };
        }
      ));
    };
  };

  config = {
    # add some useful library functions to the Nixpkgs lib
    nixpkgs.overlays = [
      (self: super: {
        lib =
          super.lib
          // {
            hcontainers = {
              inherit mkAddress;
            };
          };
      })
    ];

    # set up the bridge network shared by all containers
    systemd.network = {
      netdevs."20-hcbridge" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "hcbridge";
        };
      };

      networks."20-hcbridge" = {
        matchConfig.Name = "hcbridge";
        bridgeConfig = {};

        address = ["${mkAddress config.networking.hostName}/64"];
        routes = [{routeConfig.Gateway = "${mkAddress "gateway"}";}];

        networkConfig.ConfigureWithoutCarrier = "yes";
        linkConfig.RequiredForOnline = "routable";
      };
    };

    containers =
      lib.attrsets.mapAttrs
      (
        name: options:
          lib.mkMerge [
            {inherit (options) config;}
            {
              autoStart = true;

              ephemeral = true;

              privateNetwork = true;
              hostBridge = "hcbridge";
              localAddress6 = "${mkAddress name}/64";

              config = {...}: {
              };
            }
          ]
      )
      config.hcontainers;
  };
}
