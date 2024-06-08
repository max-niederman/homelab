{...}: {
  config = {
    networking = {
      firewall.enable = false;

      useDHCP = false;
      nameservers = [
        "1.1.1.1"
        "1.0.0.1"
        "2606:4700:4700::1111"
        "2606:4700:4700::1001"
      ];
    };

    systemd.network = {
      enable = true;

      networks."10-lan" = {
        routes = [
          {routeConfig.Gateway = "192.168.0.1";}
        ];
        linkConfig.RequiredForOnline = "routable";
      };
    };
  };
}
