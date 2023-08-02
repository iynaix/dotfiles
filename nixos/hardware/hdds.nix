{
  lib,
  config,
  user,
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
      (lib.optional cfg.ironwolf22 "zfs-ironwolf22-1")
      ++ (lib.optional cfg.wdred6 "zfs-wdred6-1");

    fileSystems.${ironwolf} = lib.mkIf cfg.ironwolf22 {
      device = ironwolf-dataset;
      fsType = "zfs";
    };

    fileSystems.${wdred} = lib.mkIf cfg.wdred6 {
      device = wdred-dataset;
      fsType = "zfs";
    };

    services.sanoid = lib.mkIf config.iynaix-nixos.zfs.snapshots {
      enable = true;

      datasets = {
        ${ironwolf-dataset} = lib.mkIf cfg.ironwolf22 {
          hourly = 0;
          daily = 10;
          weekly = 2;
          monthly = 0;
        };
        ${wdred-dataset} = lib.mkIf cfg.wdred6 {
          hourly = 0;
          daily = 10;
          weekly = 2;
          monthly = 0;
        };
      };
    };

    # symlinks from hdds
    # dest src
    systemd.tmpfiles.rules =
      (lib.optionals cfg.ironwolf22 [
        "L+ /home/${user}/Downloads   - - - - ${ironwolf}/Downloads"
      ])
      ++ (lib.optionals (cfg.ironwolf22 && cfg.wdred6) [
        "L+ ${wdred}/Anime            - - - - ${ironwolf}/Anime"
        "L+ ${wdred}/Movies           - - - - ${ironwolf}/Movies"
        "L+ ${wdred}/TV               - - - - ${ironwolf}/TV"
      ])
      ++ (lib.optionals cfg.wdred6 [
        "L+ /home/${user}/Videos      - - - - ${wdred}"
      ]);

    # dual boot windows
    boot.loader.grub = {
      extraEntries = lib.concatStringsSep "\n" ((lib.optional cfg.windows ''
          menuentry "Windows 11" {
            insmod part_gpt
            insmod fat
            insmod search_fs_uuid
            insmod chain
            search --fs-uuid --set=root FA1C-F224
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          }
        '')
        ++ (lib.optional cfg.archlinux ''
          menuentry "Arch Linux" {
            insmod part_msdos
            insmod ext2
            search --no-floppy --fs-uuid --set=root e630c4b1-075e-42a9-bd4e-894273e99ac7
            linux /boot/vmlinuz-linux root=UUID=e630c4b1-075e-42a9-bd4e-894273e99ac7 rw quiet
            initrd /boot/intel-ucode.img /boot/initramfs-linux.img
          }
        ''));
    };
  };
}
