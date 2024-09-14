{
  config,
  isVm,
  lib,
  pkgs,
  ...
}:
# NOTE: zfs datasets are created via install.sh
{
  options.custom = with lib; {
    zfs = {
      encryption = mkEnableOption "zfs encryption" // {
        default = true;
      };
    };
  };

  config = {
    boot = {
      # booting with zfs
      supportedFilesystems.zfs = true;
      kernelPackages = pkgs.linuxPackages_xanmod_latest;
      zfs = {
        devNodes =
          if isVm then
            "/dev/disk/by-partuuid"
          # use by-id for intel mobo when not in a vm
          else if config.hardware.cpu.intel.updateMicrocode then
            "/dev/disk/by-id"
          else
            "/dev/disk/by-partuuid";

        package = pkgs.zfs_unstable;
        requestEncryptionCredentials = config.custom.zfs.encryption;
      };
    };

    services.zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };

    # 16GB swap
    swapDevices = [ { device = "/dev/disk/by-label/SWAP"; } ];

    # standardized filesystem layout
    fileSystems = {
      # NOTE: root and home are on tmpfs
      # root partition, exists only as a fallback, actual root is a tmpfs
      "/" = {
        device = "zroot/root";
        fsType = "zfs";
        neededForBoot = true;
      };

      # boot partition
      "/boot" = {
        device = "/dev/disk/by-label/NIXBOOT";
        fsType = "vfat";
      };

      "/nix" = {
        device = "zroot/nix";
        fsType = "zfs";
      };

      "/tmp" = {
        device = "zroot/tmp";
        fsType = "zfs";
      };

      "/persist" = {
        device = "zroot/persist";
        fsType = "zfs";
        neededForBoot = true;
      };

      "/persist/cache" = {
        device = "zroot/cache";
        fsType = "zfs";
        neededForBoot = true;
      };
    };

    systemd.services = {
      # https://github.com/openzfs/zfs/issues/10891
      systemd-udev-settle.enable = false;
      # snapshot dirs sometimes not accessible
      # https://github.com/NixOS/nixpkgs/issues/257505#issuecomment-2348313665
      zfs-mount = {
        serviceConfig = {
          ExecStart = [ "${lib.getExe' pkgs.util-linux "mount"} -t zfs zroot/persist -o remount" ];
        };
      };
    };

    # https://github.com/NixOS/nixpkgs/issues/257505
    custom.shell.packages.remount-persist = ''
      sudo mount -t zfs zroot/persist -o remount
    '';

    services.sanoid = {
      enable = true;

      datasets = {
        "zroot/persist" = {
          hourly = 50;
          daily = 15;
          weekly = 3;
          monthly = 1;
        };
      };
    };
  };
}
