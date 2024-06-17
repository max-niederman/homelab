{...}: {
  imports = [
    ./hardware-configuration.nix
    ./services/monitoring.nix
    ./services/media.nix
  ];

  config = {
    boot.loader.systemd-boot.enable = true;

    # disable I/O scheduler since we're booting from NVMe
    boot.kernelParams = ["elevator=none"];

    services.zfs.autoScrub = {
      enable = true;
      interval = "1w";
    };

    services.sanoid = {
      enable = true;

      datasets = {
        "rpool/safe" = {
          recursive = true;

          autosnap = true;
          autoprune = true;

          hourly = 24;
          daily = 30;
          monthly = 3;
        };

        "mpool/safe" = {
          recursive = true;

          autosnap = true;
          autoprune = true;

          hourly = 24;
          daily = 7;
        };
      };
    };

    networking = {
      hostName = "beleg";
      hostId = "9f5b4e97";
    };
    systemd.network.networks."10-lan" = {
      matchConfig.Name = "enp5s0";
      address = ["192.168.0.11/24"];
    };

    services.caddy.enable = true;

    system.stateVersion = "24.05";
  };
}
