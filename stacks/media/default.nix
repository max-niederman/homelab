{ pkgs, lib }:

with lib;
let
  secrets = import ./secrets.nix;

  binds =
    let
      gen = stacks.getBindTarget "media";
    in
    {
      shared = gen "/shared";

      jellyfin = gen "/jellyfin";

      sonarr = gen "/sonarr";
      radarr = gen "/radarr";

      jackett = gen "/jackett";
      qbittorrent = gen "/qbittorrent";
    };

  servarrService = name: { port }: {
    image = "linuxserver/${name}";
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "${binds.${name}}:/config"
      "${binds.shared}:/data"
    ];
    networks = [
      "internal"
      "public"
    ];
    deploy.labels = stacks.traefik.genSimpleLabels { inherit name port; };
  };
in
rec {
  inherit binds;

  compose = {
    version = "3";

    networks = {
      public.external = true;
      internal.driver = "overlay";
    };

    services = {
      jellyfin = {
        image = "jellyfin/jellyfin";
        user = "1000:1000";
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${binds.jellyfin}/cache:/cache"
          "${binds.jellyfin}/config:/config"
          "${binds.shared}:/data"
        ];
        networks = [
          "internal"
          "public"
        ];
        environment = {
          JELLYFIN_PublishedServerUrl = "http://jellyfin.home.maxniederman.com";
        };
        deploy.labels = stacks.traefik.genSimpleLabels {
          name = "jellyfin";
          port = 8096;
        };
      };

      jellyfin_vue = {
        image = "jellyfin/jellyfin-vue:unstable";
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
        ];
        networks = [ "public" ];
        deploy.labels = stacks.traefik.genSimpleLabels {
          name = "jellyfin-vue";
          port = 80;
        };
      };

      sonarr = servarrService "sonarr" { port = 8989; };
      radarr = servarrService "radarr" { port = 7878; };

      jackett = {
        image = "linuxserver/jackett";
        volumes = [ "${binds.jackett}:/config" ];
        networks = [
          "internal"
          "public"
        ];
        deploy.labels = stacks.traefik.genSimpleLabels {
          name = "jackett";
          port = 9117;
        };
      };

      qbittorrent = {
        image = "binhex/arch-qbittorrentvpn";
        privileged = true;
        sysctls = {
          "net.ipv4.conf.all.src_valid_mark" = "1";
        };
        volumes = [
          # "${./qbittorrent/iptable.sh}:/root/iptable.sh:ro"

          "${./qbittorrent/wireguard}:/config/wireguard"

          "/etc/localtime:/etc/localtime:ro"

          "${binds.qbittorrent}:/config"
          "${binds.shared}/downloads:/data/downloads"
        ];
        networks = [
          "internal"
          "public"
        ];
        environment = {
          VPN_ENABLED = "yes";
          VPN_CLIENT = "wireguard";
          ENABLE_PRIVOXY = "yes";
          LAN_NETWORK = "192.168.0.0/24";
          DOCKER_NETWORK = "10.0.0.0/16";
          NAME_SERVERS = strings.concatStringsSep "," [ "1.1.1.1" "1.0.0.1" ];
        };
        deploy.labels = lists.unique (builtins.concatLists [
          (stacks.traefik.genSimpleLabels {
            name = "qbittorrent";
            port = 8080;
          })
          (stacks.traefik.genSimpleLabels {
            name = "privoxy";
            port = 8118;
          })
        ]);
      };
    };
  };
}
