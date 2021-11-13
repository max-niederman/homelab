{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.services.socat;

  instanceOpt = with types; submodule {
    options = {
      addresses = mkOption {
        type = addCheck (listOf str) (xs: builtins.length xs == 2);
        description = "2-tuple of addresses to transfer data between.";
      };
      unidirectional = mkOption {
        type = bool;
        default = false;
        description = "Whether the transfer should be unidirectional. See man(5) socat `-u` flag.";
      };
      blockSize = mkOption {
        type = ints.u32;
        default = 8192;
        description = "Data transfer block size. See man(5) socat `-b<size>` option.";
      };
      ipVersion = mkOption {
        type = enum [ 4 6 ];
        default = 4;
        description = "Explicity specify IP version in the case that the addresses do not.";
      };
      verbosity = mkOption {
        type = ints.between 0 4;
        default = 0;
        description = "Verbosity level. See man(5) socat `-d` flag.";
      };
    };
  };

  genCommand =
    let
      raw = args: "${cfg.package}/bin/socat ${builtins.concatStringsSep " " args}";
    in
    { addresses, unidirectional, verbosity, blockSize, ipVersion }:
    raw (concatLists [
      (if unidirectional then [ "-u" ] else [ ])
      [ "-b${builtins.toString blockSize}" ]
      [ "-${builtins.toString ipVersion}" ]
      (builtins.genList (_: "-d") verbosity)
      addresses
    ]);
in
{
  options.services.socat = {
    enable = mkEnableOption "socat";

    package = mkOption {
      type = types.package;
      default = pkgs.socat;
    };

    instances = mkOption {
      type = types.attrsOf instanceOpt;
      description = "Attribute set of socat instances to start. Attribute names correspond to systemd service names.";
    };
  };

  config = {
    systemd.services = attrsets.mapAttrs
      (name: instance: {
        description = "Daemonized socat instance";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = genCommand instance;
          Restart = "always";
        };
      })
      cfg.instances;
  };
}
