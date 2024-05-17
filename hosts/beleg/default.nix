{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];
  
  config = {
    # disable I/O scheduler since we're booting from NVMe
    boot.kernelParams = [ "elevator=none" ];

    boot.loader.systemd-boot.enable = true;
    
    networking = {
      hostName = "beleg";
      hostId = "3f69adf9";
    };
    systemd.network.networks."10-lan".address = [ "192.168.0.11/24" ];

    system.stateVersion = "24.05";
  };
}