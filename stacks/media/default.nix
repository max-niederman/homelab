{ pkgs, lib }:

with lib;
let
  secrets = import ./secrets.nix;

  binds =
    let
      gen = stacks.getBindTarget "media"; in
    {
      shared = gen "/shared";

      jellyfin = gen "/jellyfin";

      sonarr = gen "/sonarr";
      radarr = gen "/radarr";

      jackett = gen "/jackett";
      deluge = gen "/deluge";
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
    environment = {
      PUID = 1000;
      PGID = 1000;
    };
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

      deluge = {
        image = "binhex/arch-delugevpn";
        cap_add = [ "NET_ADMIN" ];
        volumes = [
          "${./deluge/iptable.sh}:/root/iptable.sh:ro"
          "/etc/localtime:/etc/localtime:ro"
          "${binds.deluge}:/config"
          "${binds.shared}/downloads:/data/downloads"
        ];
        networks = [
          "internal"
          "public"
        ];
        environment = {
          PUID = 1000;
          PGID = 1000;
          VPN_ENABLED = "yes";
          VPN_CLIENT = "openvpn";
          VPN_PROV = "pia";
          VPN_USER = secrets.pia.user;
          VPN_PASS = secrets.pia.password;
          ENABLE_PRIVOXY = "yes";
          LAN_NETWORK = "192.168.0.0/24";
          DOCKER_NETWORK = "10.0.0.0/16";
          NAME_SERVERS = strings.concatStringsSep "," [ "1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4" ];
        };
        deploy.labels = stacks.traefik.genSimpleLabels {
          name = "deluge";
          port = 8112;
        };
      };
    };
  };
}
