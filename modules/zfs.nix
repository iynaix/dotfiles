{ lib, ... }:
{
  flake.modules.nixos.core =
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) isVm;
    in
    # NOTE: zfs datasets are created via install.sh
    {
      boot = {
        kernelPackages =
          assert lib.assertMsg (lib.versionOlder pkgs.zfs_unstable.version "2.4.2")
            "zfs 2.4.2 supports kernel 7.0 or greater";
          pkgs.linuxPackages_xanmod;
        # lock xanmod version
        # kernelPackages =
        # assert lib.assertMsg (lib.versionOlder pkgs.zfs_unstable.version "2.4.2")
        #   "zfs 2.4.2 supports kernel 7.0 or greater";
        #   pkgs.linuxPackagesFor (
        #     pkgs.linux_xanmod_latest.override {
        #       argsOverride = rec {
        #         version = "6.10.11";
        #         modDirVersion = lib.versions.pad 3 "${version}-xanmod1";
        #         src = pkgs.fetchFromGitHub {
        #           owner = "xanmod";
        #           repo = "linux";
        #           rev = modDirVersion;
        #           hash = "sha256-FDWFpiN0VvzdXcS3nZHm1HFgASazNX5+pL/8UJ3hkI8=";
        #         };
        #       };
        #     }
        #   );
        zfs = {
          devNodes =
            if isVm then
              "/dev/disk/by-partuuid"
            # use by-id for intel mobo when not in a vm
            else if config.hardware.cpu.intel.updateMicrocode then
              "/dev/disk/by-id"
            else
              "/dev/disk/by-partuuid";
          forceImportRoot = false; # new default in 26.11

          package = pkgs.zfs_unstable;
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
        };

        # uncomment to use separate home dataset
        # "/home" = {
        #   device = "zroot/home";
        #   fsType = "zfs";
        #   neededForBoot = true;
        # };

        # boot partition
        "/boot" = {
          device = "/dev/disk/by-label/NIXBOOT";
          fsType = "vfat";
        };

        "/nix" = {
          device = "zroot/nix";
          fsType = "zfs";
        };

        # by default, /tmp is not a tmpfs on nixos as some build artifacts can be stored there
        # when using / as a small tmpfs for impermanence, /tmp can then easily run out of space,
        # so create a dataset for /tmp to prevent this
        # /tmp is cleared on boot via `boot.tmp.cleanOnBoot = true;`
        "/tmp" = {
          device = "zroot/tmp";
          fsType = "zfs";
        };

        "/persist" = {
          device = "zroot/persist";
          fsType = "zfs";
          neededForBoot = true;
        };

        # cache are files that should be persisted, but not to snapshot
        # e.g. npm, cargo cache etc, that could always be redownloaded
        "/cache" = {
          device = "zroot/cache";
          fsType = "zfs";
          neededForBoot = true;
        };
      };

      systemd.services = {
        # https://github.com/openzfs/zfs/issues/10891
        systemd-udev-settle.enable = false;
      };

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

      # show compress ratio in zfs list output
      environment.shellAliases = {
        zls = "zfs list -o name,used,avail,compressratio";
      };
    };

  # setup zfs event daemon for email notifications
  flake.modules.nixos.zfs-zed =
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) user;
    in
    {
      sops.secrets.zfs-zed.owner = user;

      # setup email for zfs event daemon to use
      programs.msmtp = {
        enable = true;
        setSendmail = true;
        accounts = {
          default = {
            host = "smtp.gmail.com";
            tls = true;
            auth = true;
            port = 587;
            inherit user;
            from = "${user}@gmail.com";
            # app specific password needed for 2fa
            passwordeval = "cat ${config.sops.secrets.zfs-zed.path}";
          };
        };
      };

      services.zfs.zed = {
        enableMail = true;
        settings = {
          ZED_DEBUG_LOG = "/tmp/zed.debug.log";
          ZED_EMAIL_ADDR = [ "${user}@gmail.com" ];
          ZED_EMAIL_PROG = lib.getExe pkgs.msmtp;
          ZED_EMAIL_OPTS = "@ADDRESS@";

          ZED_NOTIFY_INTERVAL_SECS = 3600;
          ZED_NOTIFY_DATA = true;
          ZED_NOTIFY_VERBOSE = true;

          ZED_USE_ENCLOSURE_LEDS = false;
          ZED_SCRUB_AFTER_RESILVER = true;
        };

        # example of testing in a VM
        /*
            sudo zpool create -f \
                -o ashift=12 \
                -o autotrim=on \
                -O compression=zstd \
                -O acltype=posixacl \
                -O atime=off \
                -O xattr=sa \
                -O normalization=formD \
                -O mountpoint=none \
                nas raidz1 /dev/vdb /dev/vdc /dev/vdd /dev/vde

          nix filesystem config for new zpool
          fileSystems."/nas" = {
              device = "nas/root";
              fsType = "zfs";
          };

          see pool status:
          zpool status -v nas

          simulating a failed disk:
          sudo zpool offline -f nas /dev/disk/by-partuuid/DISK_UUID

          NOTE: -f faults the disk, which causes zed to send an email

          https://forum.proxmox.com/threads/no-email-notification-for-zfs-status-degraded.87629/#post-520096

          manually offing a disk without -f *does not* send an email!
        */
      };
    };
}
