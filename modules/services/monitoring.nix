{config, ...}: {
  config = {
    services.prometheus.exporters = {
      node.enable = true;
      zfs.enable = true;
    };
  };
}
