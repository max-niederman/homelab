{ pkgs, lib }:

with lib;
let
  secrets = import ./secrets.nix;
in
rec {
  binds =
    let
      gen = stacks.getBindTarget "adma"; in
    {
      questdb = gen "/questdb";
    };

  compose = {
    version = "3";

    networks = {
      internal.driver = "overlay";
      public.external = true;
      monitoring.external = true;
    };

    services = {
      bot = {
        image = "ghcr.io/max-niederman/adma-bot:sha-243bd3d";
        networks = [ "internal" ];
        environment = {
          DISCORD_TOKEN = secrets.discord.token;
          QUESTDB_HOST = "questdb";
          QUESTDB_ILP_PORT = 9009;
          QUESTDB_REST_PORT = 9000;
        };
        depends_on = [ "questdb" ];
      };

      questdb = {
        image = "questdb/questdb";
        volumes = [
          "${binds.questdb}:/var/lib/questdb"
        ];
        networks = [ "internal" "monitoring" "public" ];
        environment = {
          # enable strict config validation
          QDB_CONFIG_VALIDATION_STRICT = "true";

          # enable prometheus metrics
          QDB_METRICS_ENABLED = "true";

          # improve Grafana query memory usage
          QDB_PG_SELECT_CACHE_ENABLED = "false";
        };
        deploy.labels = stacks.traefik.genSimpleLabels {
          name = "adma-questdb";
          port = 9000;
        };
      };
    };
  };
}
