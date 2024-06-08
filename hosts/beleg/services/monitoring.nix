{config,...}: {
  config = {
    services.prometheus = {
      enable = true;

      globalConfig = {
        scrape_interval = "10s";
      };

      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {targets = ["beleg:9100"];}
          ];
        }
        {
          job_name = "zfs";
          static_configs = [
            {targets = ["beleg:9134"];}
          ];
        }
        {
          job_name = "caddy";
          static_configs = [
            {targets = ["beleg:2019"];}
          ];
        }
      ];
    };

    services.loki = {
      enable = true;
      configuration = {
        auth_enabled = false;

        analytics.reporting_enabled = false;

        server = {
          http_listen_port = 3100;
          grpc_listen_port = 0;
        };

        common = {
          instance_addr = "127.0.0.1";
          replication_factor = 1;

          ring.kvstore.store = "inmemory";

          path_prefix = config.services.loki.dataDir;
          storage.filesystem = {
            chunks_directory = "${config.services.loki.dataDir}/chunks";
            rules_directory = "${config.services.loki.dataDir}/rules";
          };
        };

        schema_config.configs = [
          {
            from = "2024-06-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };
    };

    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_port = 3000;
          root_url = "https://grafana.maximal.enterprises";
        };
        analytics.reporting_enabled = false;
      };
    };

    systemd.tmpfiles.rules = [
      "L /var/lib/prometheus2 - prometheus - - /persist/var/lib/prometheus2"
      "L /var/lib/loki        - loki       - - /persist/var/lib/loki"
      "L /var/lib/grafana     - grafana    - - /persist/var/lib/grafana"
    ];

    services.caddy.virtualHosts = {
      "prometheus.maximal.enterprises".extraConfig = ''
        reverse_proxy beleg:9090
      '';
      "loki.maximal.enterprises".extraConfig = ''
        reverse_proxy beleg:3100
      '';
      "grafana.maximal.enterprises".extraConfig = ''
        reverse_proxy beleg:3000
      '';
    };
  };
}
