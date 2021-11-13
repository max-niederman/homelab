{ config, pkgs, lib, ... }:

with builtins;
with lib;
let
  host = config.homelab.host;
  hasRole = r: elem r host.roles;

  hosts = import ../hosts { lib = lib; };
  servers = hosts.withRole "server";
in
{
  config = {
    services = {

      nomad = {
        enable = true;
        enableDocker = true;
        dropPrivileges = false; # needed for Consul Connect
        settings =
          let
            serverJoin = {
              retry_join = map ({ address, ... }: address) servers;
            };
          in
          {
            region = "home";

            bind_addr = host.address;

            client = mkIf (hasRole "client") {
              enabled = true;
            };

            server = mkIf (hasRole "server") {
              enabled = true;
              bootstrap_expect = length servers;
            };

            telemetry = {
              collection_interval = "1s";
              disable_hostname = true;
              prometheus_metrics = true;
              publish_allocation_metrics = true;
              publish_node_metrics = true;
            };
          };
      };

      consul = {
        enable = true;
        extraConfig = {
          server = hasRole "server";
          bootstrap_expect = length servers;

          connect.enabled = true;

          ports = {
            grpc = 8502;
          };

          ui_config = {
            enabled = hasRole "server";
            # TODO: integrate Prometheus
          };
        };
      };

      vault = mkIf (hasRole "server") {
        enable = true;
        storageBackend = "consul";
      };

      # expose the Consul UI
      socat = mkIf (hasRole "server") {
        enable = true;
        instances.proxy-consul-ui = {
          addresses = [ "TCP-LISTEN:8500,fork,bind=${host.address}" "TCP4:127.0.0.1:8500" ];
        };
      };
    };

    # Nomad's Consul Connect integration assumes CNI plugin binaries are in /opt/cni/bin
    # this activation script creates a custom CNI environment from the `cni` and `cni-plugins` packages and links /opt/cni to it
    system.activationScripts.cni =
      let
        env = pkgs.buildEnv
          {
            name = "cni";
            paths = with pkgs; [ cni cni-plugins ];
            pathsToLink = [ "/bin" ];
            extraPrefix = "/opt/cni";
          };
      in
      ''
        ln -sf ${env}/opt/cni /opt/cni
      '';

    # in addition, we install the `cni` package normally, which Nomad will use the normal way
    environment.systemPackages = with pkgs; [ cni ];
  };
}

