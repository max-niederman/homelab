{ config, pkgs, lib, ... }:

{
  imports = [
    ./networking.nix
    ./administration.nix
    ./cluster.nix
  ];

  config = {
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    time.timeZone = "America/Los_Angeles";
  };
}
