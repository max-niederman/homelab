{ config, pkgs, lib, ... }:

with lib;
let
  members = rec {
    servers = [ "192.168.0.11" ];
    clients = [ "192.168.0.11" ];
    all = lists.unique (servers ++ clients);
  };
  addr = config.deployment.targetHost;
  isIn = builtins.elem addr;
in
{
  config = {
    services = mkIf (isIn members.all) {

      nomad = {
        enable = true;
        enableDocker = true;
        settings =
          let
            server_join = {
              retry_join = members.servers;
              retry_max = 3;
              retry_interval = "30s";
            };
          in
          {
            bind_addr = addr;

            client = mkIf (isIn members.clients) {
              enabled = true;
              server_join = server_join;
            };

            server = mkIf (isIn members.servers) {
              enabled = true;
              bootstrap_expect = builtins.length members.servers;
              server_join = server_join;
            };
          };
      };

      consul = {
        enable = true;
        extraConfig = {
          bind_addr = addr;
          # if server, serve web ui publicly
          addresses.http = mkIf (isIn members.servers) addr; 

          server = isIn members.servers;
          bootstrap_expect = builtins.length members.servers;

          ui_config = {
            enabled = true;
            # TODO: integrate Prometheus
          };
        };
      };
    };
  };
}
