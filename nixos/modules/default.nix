{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.homelab;
in
{
  imports = [
    ./networking.nix
    ./administration.nix
    ./cluster.nix
  ];

  options.homelab = {
    host = mkOption {
      type = types.submodule {
        options = {
          name = mkOption { type = types.str; };
          address = mkOption { type = types.str; };
          roles = mkOption { type = types.listOf types.str; };
          nixosConfig = mkOption { type = types.anything; };
        };
      };
      description = "Description of Homelab host.";
    };
  };

  config = {
    deployment.targetHost = cfg.host.address;

    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    time.timeZone = "America/Los_Angeles";
  };
}
