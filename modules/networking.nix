{ ... }:

{
  config = {
    networking = {
      firewall.enable = false;

      useDHCP = false;
      nameservers = [ "192.168.0.2" ];
    };

    systemd.network = {
      enable = true;

      networks."10-lan" = {
        routes = [
          { routeConfig.Gateway = "192.168.0.1"; }
        ];
        linkConfig.RequiredForOnline = "routable";
      };
    };
  };
}
