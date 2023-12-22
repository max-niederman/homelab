{
  address = "192.168.0.11";
  roles = [ "worker" "manager" "leader" ];

  nixosConfig =
    ({ config, pkgs, lib, ... }: {
      imports = [
        ./hardware-configuration.nix
      ];

      networking = {
        interfaces.enp5s0 = {
          ipv4 = {
            addresses = [{ address = config.homelab.host.address; prefixLength = 24; }];
            routes = [{ address = "0.0.0.0"; prefixLength = 0; via = "192.168.0.1"; }];
          };
        };
      };

      hardware = {
        cpu.amd.updateMicrocode = true;
      };

      # services = {
      #   wings = {
      #     enable = true;
      #     configFile = ./wings.yml;
      #   };
      # };
    });
}
