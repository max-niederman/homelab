{ ... }: {
  config = {
    services.prometheus.exporters = {
      node.enable = true;
      zfs.enable = true;
    };

    services.promtail = {
      enable = true;
      configuration = {
        server = { http_listen_port = 9080; };

        clients =
          [{ url = "https://loki.maximal.enterprises/loki/api/v1/push"; }];

        scrape_configs = [{
          job_name = "journal";
          journal = {
            json = false;
            max_age = "12h";
            path = "/var/log/journal";
            labels = { job = "systemd-journal"; };
          };
          relabel_configs = [{
            source_labels = [ "__journal__systemd_unit" ];
            target_label = "unit";
          }];
        }];
      };
    };
  };
}
