{ config, pkgs, lib, ... }:

{
  # TODO: Switch to Ceph using Docker RBD for persistent volumes
  config = {
    services.glusterfs.enable = true;

    # while migrating the cluster, we're temporarily connecting to the old cluster's storage
    fileSystems."/data" = {
      device = "192.168.0.10:/data";
      fsType = "glusterfs";
    };
  };
}
