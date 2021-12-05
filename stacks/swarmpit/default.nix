{ pkgs, lib }:

with lib;
rec {
  binds =
    let
      gen = stacks.getBindTarget "swarmpit"; in
    {
      couchdb = gen "/couchdb";
      influxdb = gen "/influxdb";
    };

  compose = {
    version = "3";

    networks = {
      internal.driver = "overlay";
      public.external = true;
    };

    services = {

      app = {
        image = "swarmpit/swarmpit:latest";
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ];
        networks = [ "internal" "public" ];
        environment = {
          SWARMPIT_DB = "http://db:5984";
          SWARMPIT_INFLUXDB = "http://influxdb:8086";
        };
        depends_on = [ "db" "influxdb" ];
        deploy = {
          placement.constraints = [ "node.role == manager" ];
          resources = {
            limits = {
              cpus = "0.50";
              memory = "1024M";
            };
            reservations = {
              cpus = "0.25";
              memory = "512M";
            };
          };
          labels = stacks.traefik.genSimpleLabels {
            name = "swarmpit";
            port = 8080;
          };
        };
      };

      db = {
        image = "couchdb:2.3.0";
        volumes = [
          "${binds.couchdb}:/opt/couchdb/data"
        ];
        networks = [ "internal" ];
        deploy.resources = {
          limits = {
            cpus = "0.50";
            memory = "1024M";
          };
          reservations = {
            cpus = "0.25";
            memory = "512M";
          };
        };
      };

      influxdb = {
        image = "influxdb:1.7";
        volumes = [
          "${binds.influxdb}:/var/lib/influxdb"
        ];
        networks = [ "internal" ];
        deploy.resources = {
          limits = {
            cpus = "0.60";
            memory = "512M";
          };
          reservations = {
            cpus = "0.30";
            memory = "128M";
          };
        };
      };

      agent = {
        image = "swarmpit/agent:latest";
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ];
        networks = [ "internal" ];
        deploy = {
          mode = "global";
          labels = stacks.genKVLabels { swarmpit.agent = true; };
          resources = {
            limits = {
              cpus = "0.10";
              memory = "64M";
            };
            reservations = {
              cpus = "0.05";
              memory = "32M";
            };
          };
        };
      };

    };
  };
}
