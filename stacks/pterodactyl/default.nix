{ pkgs, lib }:

with lib;
let
  secrets = import ./secrets.nix;
in
rec {
  binds =
    let
      gen = stacks.getBindTarget "pterodactyl"; in
    {
      var = gen "/var";
      nginx = gen "/nginx";
      certs = gen "/certs";
      logs = gen "/logs";
      db = gen "/database";
    };

  compose = {
    version = "3";

    networks = {
      public.external = true;
      internal.driver = "overlay";
    };

    services = {
      panel = {
        image = "ghcr.io/pterodactyl/panel:latest";
        volumes = [
          "${binds.var}:/app/var"
          "${binds.nginx}:/etc/nginx/conf.d"
          "${binds.certs}:/etc/letsencrypt"
          "${binds.logs}:/app/storage/logs"
        ];
        networks = [ "internal" "public" ];
        environment = {
          APP_URL = "http://pterodactyl.home.maxniederman.com";
          APP_TIMEZOME = "PST";
          APP_SERVICE_AUTHOR = "max@maxniederman.com";

          APP_ENV = "production";
          APP_ENVIRONMENT_ONLY = "false";

          CACHE_DRIVER = "redis";
          SESSION_DRIVER = "redis";
          QUEUE_DRIVER = "redis";
          REDIS_HOST = "cache";

          DB_HOST = "db";
          DB_PASSWORD = secrets.mysql.password;
        };
        depends_on = [ "db" "cache" ];
        deploy = {
          labels = stacks.traefik.genSimpleLabels {
            name = "pterodactyl";
            port = 80;
          };
        };
      };

      db = {
        image = "library/mysql:8.0";
        volumes = [
          "${binds.db}:/var/lib/mysql"
        ];
        networks = [ "internal" ];
        user = "1000:1000";
        environment = {
          MYSQL_DATABASE = "panel";
          MYSQL_USER = "pterodactyl";
          MYSQL_PASSWORD = secrets.mysql.password;
          MYSQL_ROOT_PASSWORD = secrets.mysql.rootPassword;
        };
      };

      cache = {
        image = "redis:alpine";
        networks = [ "internal" ];
      };
    };
  };
}
