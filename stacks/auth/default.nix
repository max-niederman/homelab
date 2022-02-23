{ pkgs, lib }:

with lib;
let
  secrets = import ./secrets.nix;
in
rec {
  binds =
    let
      gen = stacks.getBindTarget "auth"; in
    {
      keycloak = gen "/keycloak/database";
      keycloackDump = gen "/keycloak/database-dump";
    };

  compose = {
    version = "3";

    networks = {
      internal.driver = "overlay";
      public.external = true;
    };

    services = {

      keycloak = {
        image = "jboss/keycloak";
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
        ];
        networks = [ "internal" "public" ];
        environment = {
          DB_VENDOR = "postgres";
          DB_DATABASE = "keycloak";
          DB_ADDR = "keycloak_db";
          DB_USER = secrets.keycloak.db.user;
          DB_PASSWORD = secrets.keycloak.db.password;
          PROXY_ADDRESS_FORWARDING = "true";
        };
        deploy.labels = stacks.traefik.genSimpleLabels {
          name = "keycloak";
          port = 8080;
        };
      };

      keycloak_db = {
        image = "postgres:10";
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${binds.keycloak}:/var/lib/postgresql/data"
        ];
        networks = [ "internal" ];
        environment = {
          POSTGRES_USER = secrets.keycloak.db.user;
          POSTGRES_PASSWORD = secrets.keycloak.db.password;
        };
      };
      keycloak_db_dump = {
        image = "postgres:10";
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${binds.keycloackDump}:/dump"
        ];
        networks = [ "internal" ];
        environment = {
          PGHOST = "keycloak_db";
          PGUSER = secrets.keycloak.db.user;
          PGPASSWORD = secrets.keycloak.db.password;
          BACKUP_NUM_KEEP = 7;
          BACKUP_FREQUENCY = "1d";
        };
        entrypoint = ''
          bash -c 'bash -s <<EOF

          trap "break;exit" SIGHUP SIGINT SIGTERM
          sleep 2m
          while /bin/true; do
            pg_dump -Fc > /dump/dump_\`date +%d-%m-%Y"_"%H_%M_%S\`.psql
            (ls -t /dump/dump*.psql|head -n $$BACKUP_NUM_KEEP;ls /dump/dump*.psql)|sort|uniq -u|xargs rm -- {}
            sleep $$BACKUP_FREQUENCY
          done

          EOF'
        '';
      };

    };
  };
}
