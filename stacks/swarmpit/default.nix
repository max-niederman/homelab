{ pkgs, lib }:


rec {
  binds = let gen = lib.stacks.getBindTarget "swarmpit"; in
    {
      couchdbData = gen "/opt/couchdb/data";
      influxdbData = gen "/var/lib/influxdb";
    };

  compose = {
    version = "3";

    networks = {
      net.driver = "overlay";
      public.external = true;
    };

    services = {

      app = {
        image = "swarmpit/swarmpit:latest";
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ];
        networks = [ "net" "public" ];
        environment = {
          SWARMPIT_DB = "http://db:5984";
          SWARMPIT_INFLUXDB = "http://influxdb:8086";
        };
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
          labels = lib.stacks.traefik.genSimpleLabels {
            name = "swarmpit";
            port = 8080;
          };
        };
      };

      db = {
        image = "couchdb:2.3.0";
        volumes = [
          "${binds.couchdbData}:/opt/couchdb/data"
        ];
        networks = [ "net" ];
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
          "${binds.influxdbData}:/var/lib/influxdb"
        ];
        networks = [ "net" ];
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
        networks = [ "net" ];
        deploy = {
          mode = "global";
          labels = lib.stacks.genKVLabels { swarmpit.agent = true; };
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
