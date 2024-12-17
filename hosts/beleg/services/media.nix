{ config, lib, pkgs, ... }:
let
  netns = "harbor";
  lanPrefix = "fc42:1651:0:0";
in {
  config = {
    services.transmission = {
      enable = true;

      settings = {
        download-dir = "/persist/media/downloads";
        incomplete-dir = "/persist/media/downloads/.incomplete";
        incomplete-dir-enabled = true;

        rpc-bind-address = "${lanPrefix}::2";
        rpc-port = 9091;
        rpc-whitelist-enabled = false;
        rpc-host-whitelist-enabled = false;
      };

      webHome = pkgs.flood-for-transmission;
    };
    systemd.services.transmission = {
      after = [ "safe-harbor-lan.service" "safe-harbor-internet.service" ];
      requires = [ "safe-harbor-lan.service" "safe-harbor-internet.service" ];

      serviceConfig = {
        NetworkNamespacePath = "/run/netns/${netns}";
        BindReadOnlyPaths =
          [ "/etc/netns/${netns}/resolv.conf:/etc/resolv.conf" ];
      };
    };

    # we can't use NixOS's built-in Prowlarr service because it uses systemd dynamic users, which interferes with the impermanence setup
    systemd.services.prowlarr = {
      description = "Prowlarr";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "prowlarr";
        Group = "prowlarr";
        ExecStart =
          "${lib.getExe pkgs.prowlarr} -nobrowser -data=/var/lib/prowlarr";
        Restart = "on-failure";
      };
    };
    ids = {
      uids.prowlarr = 801;
      gids.prowlarr = 801;
    };
    users.users.prowlarr = {
      group = "prowlarr";
      home = "/var/lib/prowlarr";
      uid = config.ids.uids.prowlarr;
    };
    users.groups.prowlarr.gid = config.ids.gids.prowlarr;
    # TODO: set up exportarr-prowlarr

    environment.systemPackages = with pkgs; [ recyclarr ];
    environment.variables.RECYCLARR_APP_DATA = "/persist/recyclarr";

    services.sonarr = { enable = true; };

    services.radarr = { enable = true; };

    services.jellyfin = { enable = true; };

    services.caddy.maximalHosts = {
      transmission.proxyTo = "[${lanPrefix}::2]:9091";
      prowlarr.proxyTo = "beleg:9696";
      sonarr.proxyTo = "beleg:8989";
      radarr.proxyTo = "beleg:7878";
      jellyfin.proxyTo = "beleg:8096";
    };

    systemd.tmpfiles.rules = [
      "L /var/lib/prowlarr - - - - /persist/prowlarr"
      "L /var/lib/sonarr   - - - - /persist/sonarr"
      "L /var/lib/radarr   - - - - /persist/radarr"
      "L /var/lib/jellyfin - - - - /persist/jellyfin"
    ];

    environment.etc."netns/${netns}/resolv.conf".text = ''
      nameserver 2606:4700:4700::1111
      nameserver 2606:4700:4700::1001
      nameserver 1.1.1.1
      nameserver 1.0.0.1
      options edns0
    '';

    systemd.services.safe-harbor-lan = {
      description = "Safe harbor LAN Access";

      after = [ "netns@${netns}.service" ];
      requires = [ "netns@${netns}.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = [
          "${pkgs.iproute2}/bin/ip link add vethharbor type veth peer name vethlan netns ${netns}"
          "${pkgs.iproute2}/bin/ip addr add ${lanPrefix}::1/64 dev vethharbor"
          "${pkgs.iproute2}/bin/ip link set dev vethharbor up"
          "${pkgs.iproute2}/bin/ip -n ${netns} addr add ${lanPrefix}::2/64 dev vethlan"
          "${pkgs.iproute2}/bin/ip -n ${netns} link set dev vethlan up"
        ];
        ExecStop = "${pkgs.iproute2}/bin/ip link del vethharbor";
      };
    };

    systemd.services.safe-harbor-internet = {
      description = "Safe harbor VPN Internet Access";

      after = [ "netns@${netns}.service" ];
      requires = [ "netns@${netns}.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = [
          "${pkgs.iproute2}/bin/ip link add vethinternet type wireguard"
          "${pkgs.wireguard-tools}/bin/wg set vethinternet private-key /run/secrets/networking/mullvad_wg_pk peer Xt80FGN9eLy1vX3F29huj6oW2MnQt7ne3DMBpo525Qw= allowed-ips 0.0.0.0/0,::0/0 endpoint 138.199.43.78:51820"
          "${pkgs.iproute2}/bin/ip link set dev vethinternet netns ${netns}"
          "${pkgs.iproute2}/bin/ip -n ${netns} address add dev vethinternet 10.69.233.140/32"
          "${pkgs.iproute2}/bin/ip -n ${netns} address add dev vethinternet fc00:bbbb:bbbb:bb01::6:e98b/128"
          "${pkgs.iproute2}/bin/ip -n ${netns} link set up dev vethinternet"
          "${pkgs.iproute2}/bin/ip -n ${netns} route add default dev vethinternet"
          "${pkgs.iproute2}/bin/ip -n ${netns} -6 route add default dev vethinternet"
        ];
        ExecStop = "${pkgs.iproute2}/bin/ip -n ${netns} link del vethinternet";
      };
    };

    sops.secrets = { "networking/mullvad_wg_pk".owner = "root"; };
  };
}
