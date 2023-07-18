{
  lib,
  config,
  user,
  ...
}: let
  cfg = config.iynaix.hdds;
in {
  config = lib.mkIf cfg.enable {
    # filesystems
    fileSystems."/media/Files" = {
      device = "/dev/disk/by-label/Files";
      fsType = "ext4";
    };

    fileSystems."/media/6TBRED" = {
      device = "/dev/disk/by-label/6TBRED";
      fsType = "ext4";
    };

    fileSystems."/media/6TBRED2" = {
      device = "/dev/disk/by-label/6TBRED2";
      fsType = "ext4";
    };

    # symlinks from hdds
    systemd.tmpfiles.rules = [
      "L+ /home/${user}/Documents   - - - - /media/Files/Documents"
      "L+ /home/${user}/Downloads   - - - - /media/Files/Downloads"
      "L+ /home/${user}/Pictures   - - - - /media/Files/Pictures"
      "L+ /home/${user}/Videos   - - - - /media/6TBRED"
    ];

    # extra nemo bookmarks
    home-manager.users.${user} = {
      gtk.gtk3 = {
        bookmarks = lib.mkAfter [
          "file:///media/6TBRED/Anime/Current Anime Current"
          "file:///media/6TBRED/US/Current TV Current"
          "file:///media/6TBRED/Movies"
        ];
      };
    };

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
