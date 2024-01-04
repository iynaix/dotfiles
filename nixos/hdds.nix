{
  lib,
  config,
  ...
}: let
  cfg = config.iynaix-nixos.hdds;
  wdred = "/media/6TBRED";
  wdred-dataset = "zfs-wdred6-1/media";
  ironwolf = "/media/IRONWOLF22";
  ironwolf-dataset = "zfs-ironwolf22-1/media";
in {
  config = lib.mkIf cfg.enable {
    # non os zfs disks
    boot.zfs.extraPools =
      lib.optional cfg.ironwolf22 "zfs-ironwolf22-1"
      ++ (lib.optional cfg.wdred6 "zfs-wdred6-1");

    services.sanoid = lib.mkIf config.iynaix-nixos.zfs.snapshots {
      enable = true;

      datasets = {
        ${ironwolf-dataset} = lib.mkIf cfg.ironwolf22 {
          hourly = 3;
          daily = 10;
          weekly = 2;
          monthly = 0;
        };
        ${wdred-dataset} = lib.mkIf cfg.wdred6 {
          hourly = 3;
          daily = 10;
          weekly = 2;
          monthly = 0;
        };
      };
    };

    # symlinks from hdds
    # dest src
    systemd.tmpfiles.rules = lib.optionals (cfg.ironwolf22 && cfg.wdred6) [
      "L+ ${wdred}/Anime            - - - - ${ironwolf}/Anime"
      "L+ ${wdred}/Movies           - - - - ${ironwolf}/Movies"
      "L+ ${wdred}/TV               - - - - ${ironwolf}/TV"
    ];

    # add bookmarks for gtk
    hm = hmCfg: {
      gtk.gtk3.bookmarks = lib.mkIf cfg.ironwolf22 [
        "file://${ironwolf}/Anime/Current Anime Current"
        "file://${ironwolf}/TV/Current TV Current"
        "file://${ironwolf}/Anime Anime"
        "file://${ironwolf}/TV TV"
        "file://${ironwolf}/Movies"
      ];

      # create symlinks for locations with ~
      home.file = let
        inherit (hmCfg.config.lib.file) mkOutOfStoreSymlink;
      in {
        Downloads.source = lib.mkIf cfg.ironwolf22 (mkOutOfStoreSymlink "${ironwolf}/Downloads");
        Videos.source = lib.mkIf cfg.wdred6 (mkOutOfStoreSymlink "${wdred}");
      };
    };

    # dual boot windows
    boot = {
      loader.grub = {
        extraEntries = lib.concatStringsSep "\n" (lib.optional cfg.windows ''
          menuentry "Windows 11" {
            insmod part_gpt
            insmod fat
            insmod search_fs_uuid
            insmod chain
            search --fs-uuid --set=root FA1C-F224
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          }
        '');
        # ++ (lib.optional cfg.archlinux ''
        #   menuentry "Arch Linux" {
        #     insmod gzio
        #     insmod part_gpt
        #     insmod fat
        #     search --no-floppy --fs-uuid --set=root 35EE-1411
        #     linux /vmlinuz-linux root=UUID=e630c4b1-075e-42a9-bd4e-894273e99ac7 rw rootflags=subvol=@ loglevel=3 quiet
        #     initrd /amd-ucode.img /initramfs-linux.img
        #   }
        # ''));
      };

      supportedFilesystems = lib.mkIf cfg.windows ["ntfs"];
    };

    # hide disks
    fileSystems = {
      # "/media/archlinux" = lib.mkIf cfg.archlinux {
      #   device = "/dev/disk/by-uuid/e630c4b1-075e-42a9-bd4e-894273e99ac7";
      #   fsType = "btrfs";
      #   options = ["nofail" "x-gvfs-hide" "subvol=/@"];
      # };

      "/media/windows" = lib.mkIf cfg.windows {
        device = "/dev/disk/by-uuid/94F422A4F4228916";
        fsType = "ntfs-3g";
        options = ["nofail" "x-gvfs-hide"];
      };

      "/media/windowsgames" = lib.mkIf cfg.windows {
        device = "/dev/disk/by-label/GAMES";
        fsType = "ntfs-3g";
        options = ["nofail" "x-gvfs-hide"];
      };
    };
  };
}
