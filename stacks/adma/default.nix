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
      monitoring.external = true;
    };

    services = {
      bot = {
        image = "ghcr.io/max-niederman/adma-bot:sha-4f65f5e";
        networks = [ "internal" ];
        environment = {
          DISCORD_TOKEN = secrets.discord.token;
          QUESTDB_HOST = "questdb";
          QUESTDB_PORT = 9009;
        };
        depends_on = [ "questdb" ];
      };

      questdb = {
        image = "questdb/questdb";
        volumes = [
          "${binds.questdb}:/var/lib/questdb"
        ];
        networks = [ "internal" "monitoring" ];
        environment = {
          # enable strict config validation
          QDB_CONFIG_VALIDATION_STRICT = "true";

          # enable prometheus metrics
          QDB_METRICS_ENABLED = "true";

          # improve Grafana query memory usage
          QDB_PG_SELECT_CACHE_ENABLED = "false";
        };
      };
    };
  };
}
