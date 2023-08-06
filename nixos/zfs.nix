{
  config,
  lib,
  ...
}: let
  cfg = config.iynaix-nixos.zfs;
in {
  config = lib.mkIf cfg.enable {
    # booting with zfs
    boot.supportedFilesystems = ["zfs"];
    boot.zfs.devNodes = lib.mkDefault "/dev/disk/by-id";
    boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

    services.zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };

    # standard boot partition
    fileSystems."/boot" = {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
    };

    # mount swap if specified
    swapDevices = lib.mkIf cfg.swap (lib.mkForce [
      {
        device = "/dev/disk/by-label/SWAP";
      }
    ]);

    # standard zfs filesystem layout
    fileSystems = {
      "/" = {
        device = "zroot/local/root";
        fsType = "zfs";
      };

      "/nix" = {
        device = "zroot/local/nix";
        fsType = "zfs";
      };

      "/home" = {
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
        "zroot/safe/home" = {
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
