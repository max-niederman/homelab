{...}: {
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
            {targets = ["192.168.0.11:9100"];}
          ];
        }
        {
          job_name = "zfs";
          static_configs = [
            {targets = ["192.168.0.11:9134"];}
          ];
        }
      ];
    };

    systemd.tmpfiles.rules = [
      "L /var/lib/prometheus2 - - - - /persist/var/lib/prometheus2"
    ];

    services.caddy.virtualHosts = {
      "prometheus.maximal.enterprises".extraConfig = ''
        reverse_proxy 192.168.0.11:9090
      '';
    };
  };
}
