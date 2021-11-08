{ config, pkgs, ... }:

{
  deployment = {
    targetHost = "192.168.0.11";
  };

  imports = [
    ./hardware-configuration.nix
    ./cluster.nix
  ];

  networking = {
    hostName = "beleg";
    interfaces.enp4s0 = {
      ipv4 = {
        addresses = [{ address = config.deployment.targetHost; prefixLength = 24; }];
        routes = [{ address = "0.0.0.0"; prefixLength = 0; via = "192.168.0.1"; }];
      };
    };
  };

  hardware = {
    cpu.amd.updateMicrocode = true;
  };
}
