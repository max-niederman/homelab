{ config, pkgs, ... }:

{
  services = {
    nomad = { };

    consul = {
      interface.bind = "enp4s0";
    };

    vault = {
      enable = true;
      storageBackend = "consul";
    };
  };
}
