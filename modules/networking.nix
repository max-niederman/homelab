{pkgs, ...}: {
  config = {
    networking = {
      firewall.enable = false;

      useDHCP = false;
      nameservers = [
        "192.168.0.2"
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

    systemd.services."netns@" = {
      description = "%I network namespace";
      before = ["network.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = [
          "${pkgs.iproute}/bin/ip netns add %I"
          "${pkgs.iproute}/bin/ip -netns %I link set lo up"
        ];
        ExecStop = "${pkgs.iproute}/bin/ip netns del %I";
      };
    };

    services.tailscale = {
      enable = true;
      authKeyFile = "/run/secrets/networking/ts_auth_key";
    };

    sops.secrets = {
      "networking/ts_auth_key".owner = "root";
    };
  };
}
