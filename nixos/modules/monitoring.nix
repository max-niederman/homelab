{ config, pkgs, lib, ... }:

{
  config = {
    services.prometheus.exporters = {
      node = {
        enable = true;
        port = 9100;
      };
    };
  };
}
