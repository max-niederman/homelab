{pkgs, ...}: {
  config = {
    systemd.services.safe-harbor-vpn = let
      netns = "harbor";

      # adapted from http://www.naju.se/articles/openvpn-netns
      netns-script = pkgs.writeShellApplication {
        name = "harbor-netns-script";

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

      netns-script-bin = "${netns-script}/bin/harbor-netns-script";
    in {
      description = "Safe harbor VPN";

      after = ["netns@${netns}.service"];
      requires = ["netns@${netns}.service"];

      serviceConfig = {
        Type = "simple";
        # Restart = "always";
        ExecStart = "${pkgs.openvpn}/bin/openvpn --errors-to-stderr --ifconfig-noexec --route-noexec --dev tun --script-security 2 --up ${netns-script-bin} --route-up ${netns-script-bin} --config ${./Mercury-01.ovpn}";
      };
    };
  };
}
