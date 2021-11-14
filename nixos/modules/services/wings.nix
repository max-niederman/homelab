{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.services.wings;
in
{
  options.services.wings = {
    enable = mkEnableOption "Pterodactyl Wings";

    package = mkOption {
      type = types.package;
      default = pkgs.pterodactyl-wings;
      description = "Wings package to use.";
    };

    configFile = mkOption {
      type = types.path;
      description = "Path to contents of /etc/pterodactyl/config.yml. Can also be generated using `pkgs.formats.yaml`.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.docker.enable = true;

    environment.etc."pterodactyl/config.yml" = {
      source = cfg.configFile;
      mode = "0644";
    };

    systemd.services.wings = {
      description = "Wings, The server control plane for Pterodactyl Panel.";

      wantedBy = [ "multi-user.target" ];
      partOf = [ "docker.service" ];
      requires = [ "docker.service" ];
      after = [ "docker.service" ];

      serviceConfig = {
        User = "root";
        WorkingDirectory = "/etc/pterodactyl";
        LimitNOFILE = 4096;
        PIDFile = "/var/run/wings/daemon.pid";
        ExecStart = "${cfg.package}/bin/wings";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
