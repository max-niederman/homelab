{ config, pkgs, lib, ... }:

{
  # TODO: Switch to Ceph using Docker RBD for persistent volumes
  config = {
    fileSystems."/data" = {
      device = "192.168.0.10:/data";
      fsType = "nfs";
    };
  };
}
