{
  config,
  lib,
  user,
  ...
}: let
  cfg = config.iynaix-nixos.zfs;
  persistCfg = config.iynaix-nixos.persist;
in {
  config = lib.mkIf cfg.enable {
    # booting with zfs
    boot.supportedFilesystems = ["zfs"];
    boot.zfs.devNodes = lib.mkDefault "/dev/disk/by-id";
    boot.zfs.enableUnstable = true;
    boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

    services.zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };

    # 16GB swap created by zfs.sh
    swapDevices = [
      {device = "/dev/disk/by-label/SWAP";}
    ];

    # standardized filesystem layout
    fileSystems = let
      homeMountPoint =
        if persistCfg.erase.home
        then "/home/${user}"
        else "/home";
    in {
      # boot partition
      "/boot" = {
        device = "/dev/disk/by-label/NIXBOOT";
        fsType = "vfat";
      };

      # zfs datasets
      "/" = {
        device = "zroot/local/root";
        fsType = "zfs";
      };

      "/nix" = {
        device = "zroot/local/nix";
        fsType = "zfs";
      };

      "/tmp" = {
        device = "zroot/local/tmp";
        fsType = "zfs";
      };

      "${homeMountPoint}" = {
        device = "zroot/safe/home";
        fsType = "zfs";
      };

      "/persist" = {
        device = "zroot/safe/persist";
        fsType = "zfs";
      };
    };

    services.sanoid = lib.mkIf cfg.snapshots {
      enable = true;

      datasets = {
        "zroot/safe/home" = lib.mkIf (!persistCfg.erase.home) {
          hourly = 50;
          daily = 20;
          weekly = 6;
          monthly = 3;
        };

        "zroot/safe/persist" = {
          hourly = 50;
          daily = 20;
          weekly = 6;
          monthly = 3;
        };
      };
    };
  };
}
