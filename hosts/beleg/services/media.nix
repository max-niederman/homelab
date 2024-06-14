{pkgs, ...}: let
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
      after = ["safe-harbor-lan.service" "safe-harbor-internet.service"];
      requires = ["safe-harbor-lan.service" "safe-harbor-internet.service"];

      serviceConfig = {
        NetworkNamespacePath = "/run/netns/${netns}";
        BindReadOnlyPaths = ["/etc/netns/${netns}/resolv.conf:/etc/resolv.conf"];
      };
    };

    services.sonarr = {
      enable = true;
    };

    services.caddy.maximalHosts = {
      transmission.proxyTo = "[${lanPrefix}::2]:9091";
      sonarr.proxyTo = "beleg:8989";
    };

    systemd.tmpfiles.rules = [
      "L /var/lib/sonarr - sonarr sonarr - /persist/sonarr"
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

      after = ["netns@${netns}.service"];
      requires = ["netns@${netns}.service"];

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

    systemd.services.safe-harbor-internet = let
      # adapted from http://www.naju.se/articles/openvpn-netns
      netns-script = pkgs.writeShellApplication {
        name = "netns-script-${netns}";

        runtimeInputs = with pkgs; [iproute2];

        text = ''
          case $script_type in
            up)
              ip link set dev "$1" up netns ${netns} mtu "$2"
              ip netns exec ${netns} ip addr add dev "$1" \
                      "$4/''${ifconfig_netmask:-30}" \
                      ''${ifconfig_broadcast:+broadcast "$ifconfig_broadcast"}
              if [ -n "$ifconfig_ipv6_local" ]; then
                ip netns exec ${netns} ip addr add dev "$1" \
                        "$ifconfig_ipv6_local"/112
              fi
              ;;
            route-up)
              ip netns exec ${netns} ip route add default via "$route_vpn_gateway"
              if [ -n "$ifconfig_ipv6_remote" ]; then
                ip netns exec ${netns} ip route add default via \
                        "$ifconfig_ipv6_remote"
              fi
              ;;
          esac
        '';

        # openvpn sets some variables that shellcheck doesn't know about
        excludeShellChecks = ["SC2154"];
      };

      netns-script-bin = "${netns-script}/bin/netns-script-${netns}";
    in {
      description = "Safe harbor VPN Internet Access";

      after = ["netns@${netns}.service"];
      requires = ["netns@${netns}.service"];

      serviceConfig = {
        Type = "exec";
        Restart = "always";
        ExecStart = "${pkgs.openvpn}/bin/openvpn --errors-to-stderr --ifconfig-noexec --route-noexec --dev tun --script-security 2 --up ${netns-script-bin} --route-up ${netns-script-bin} --config ${./Mercury-01.ovpn}";
      };
    };
  };
}
