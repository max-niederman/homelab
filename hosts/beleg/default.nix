{...}: {
  imports = [
    ./hardware-configuration.nix
  ];

  config = {
    boot.loader.systemd-boot.enable = true;

    # disable I/O scheduler since we're booting from NVMe
    boot.kernelParams = ["elevator=none"];

    services.zfs.autoScrub = { enable = true; interval = "1w"; };

    networking = {
      hostName = "beleg";
      hostId = "9f5b4e97";
    };
    systemd.network.networks."10-lan" = {
      matchConfig.Name = "enp5s0";
      address = ["192.168.0.11/24"];
    };

    system.stateVersion = "24.05";
  };
}
