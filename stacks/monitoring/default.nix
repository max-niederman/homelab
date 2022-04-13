{ pkgs, lib }:

with lib;
rec {
  binds = attrsets.mapAttrs (_name: stacks.getBindTarget "monitoring") {
    prometheus = "/prometheus";
    grafanaProvisioning = "/grafana/provisioning";
    grafanaData = "/grafana/data";
  };

  compose = {
    version = "3";

    networks = {
      public.external = true;
      monitoring.external = true;
    };

    services = {
      prometheus = {
        image = "prom/prometheus";
        user = "root"; # required to access docker socket
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock" # for docker swarm service discovery
          "${./prometheus}:/etc/prometheus"
          "${binds.prometheus}:/data"
        ];
        networks = [
          "monitoring"
          "public"
        ];
        command = [
          "--config.file=/etc/prometheus/prometheus.yml"
          "--storage.tsdb.path=/data"
          "--storage.tsdb.retention.time=28d"
        ];
        deploy = {
          placement.constraints = [
            "node.role==manager"
          ];
          labels = stacks.traefik.genSimpleLabels {
            name = "prometheus";
            port = 9090;
          };
        };
      };

      grafana = {
        image = "grafana/grafana";
        volumes = [
          "${binds.grafanaProvisioning}:/etc/grafana/provisioning"
          "${binds.grafanaData}:/var/lib/grafana"
        ];
        networks = [
          "monitoring"
          "public"
        ];
        deploy.labels = stacks.traefik.genSimpleLabels {
          name = "grafana";
          port = 3000;
        };
      };

      # exporters

      speedtest = {
        image = "ghcr.io/miguelndecarvalho/speedtest-exporter";
        networks = [
          "monitoring"
          "public"
        ];
        deploy.labels = stacks.traefik.genSimpleLabels {
          name = "speedtest-exporter";
          port = 9798;
        };
      };
    };
  };
}
