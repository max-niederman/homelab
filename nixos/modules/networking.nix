{ config, pkgs, lib, ... }:

let
  secrets = import ../../secrets.nix;
in
{
  config = {
    networking = {
      hostName = config.homelab.host.name;

      firewall.enable = false;

      useDHCP = false;
      nameservers = [ "192.168.0.2" ];
    };

    # mDNS
    services.avahi = {
      enable = true;
      nssmdns = true;
      publish.enable = true;
    };

    # remote access with ZeroTier
    services.zerotierone = {
      enable = true;
      joinNetworks = [ secrets.zerotierNetwork ];
    };
  };
}
