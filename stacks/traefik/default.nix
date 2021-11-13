{ pkgs, lib }:

let
  staticConfig = (pkgs.formats.yaml { }).generate "traefik.yml" {
    entrypoints = {
      web.address = ":80";
      # websecure.address = ":443";
    };

    api.dashboard = true;
    metrics.prometheus = true;

    providers.docker = {
      swarmMode = true;
      exposedByDefault = true;
      network = "public";
    };
  };
in
{
  compose = {
    version = "3";

    networks = {
      public.external = true;
      monitoring.external = true;
    };

    services.traefik = {
      image = "traefik:v2.5";
      volumes = [
        "${staticConfig}:/etc/traefik/traefik.yml:ro"
        "/var/run/docker.sock:/var/run/docker.sock:ro"
      ];
      networks = [ "public" "monitoring" ];
      ports = [ "80:80" "443:443" ];
      deploy = {
        placement.constraints = [ "node.role == manager" ];
        labels = lib.stacks.genKVLabels {
          traefik = {
            enable = true;
            docker.network = "public";
            http = {
              routers.traefik-api = {
                rule = "HostRegexp(`traefik{tld:(\\.\\S+)*\\.?}`)";
                service = "api@internal";
              };
              # necessary for Swarm port detection
              services.dummy-svc.loadbalancer.server.port = 1337;
            };
          };
        };
      };
    };
  };
}
