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
            { targets = [ "192.168.0.11:9100" ]; }
          ];
        }
      ];
    };

    services.caddy.virtualHosts = {
      "http://prometheus.maximal.enterprises".extraConfig = ''
        reverse_proxy 192.168.0.11:9090
      '';
    };
  };
}
