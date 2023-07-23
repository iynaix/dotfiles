{
  lib,
  config,
  user,
  ...
}: let
  cfg = config.iynaix-nixos.hdds;
  wdred = "/media/6TBRED";
  ironwolf = "/media/IRONWOLF22";
  ironwolf-dataset = "zfs-ironwolf22-1/media";
in {
  config = lib.mkIf cfg.enable {
    # filesystems
    fileSystems.${wdred} = {
      device = "/dev/disk/by-label/6TBRED";
      fsType = "ext4";
    };

    # non os zfs disks
    boot.zfs.extraPools = ["zfs-ironwolf22-1"];
    fileSystems.${ironwolf} = {
      device = ironwolf-dataset;
      fsType = "zfs";
    };

    services.sanoid = lib.mkIf config.iynaix-nixos.zfs.snapshots {
      enable = true;

      datasets.${ironwolf-dataset} = {
        daily = 10;
      };
    };

    # symlinks from hdds
    systemd.tmpfiles.rules = [
      # dest src
      "L+ /home/${user}/Downloads   - - - - ${ironwolf}/Downloads"
      "L+ ${wdred}/Anime            - - - - ${ironwolf}/Anime"
      "L+ ${wdred}/Movies           - - - - ${ironwolf}/Movies"
      "L+ ${wdred}/TV               - - - - ${ironwolf}/TV"
      "L+ /home/${user}/Videos      - - - - ${wdred}"
    ];

    # dual boot windows
    boot.loader.grub = {
      extraEntries = lib.concatStringsSep "\n" [
        ''
          menuentry "Windows 11" {
            insmod part_gpt
            insmod fat
            insmod search_fs_uuid
            insmod chain
            search --fs-uuid --set=root FA1C-F224
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          }
        ''
      ];
    };
  };
}
