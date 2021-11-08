{ config, pkgs, lib, ... }:

{
  config = {
    networking = {
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
  };
}
