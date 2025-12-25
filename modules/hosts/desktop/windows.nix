{
  flake.nixosModules.host-desktop = {
    # dual boot
    boot = {
      loader.grub = {
        extraEntries = ''
          menuentry "Windows 11" {
            insmod part_gpt
            insmod fat
            insmod search_fs_uuid
            insmod chain
            search --fs-uuid --set=root FA1C-F224
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          }
        '';
      };
    };

    # hide disks
    fileSystems = {
      "/media/windows" = {
        device = "/dev/disk/by-uuid/94F422A4F4228916";
        fsType = "ntfs-3g";
        options = [
          "nofail"
          "x-gvfs-hide"
        ];
      };

      "/media/windowsgames" = {
        device = "/dev/disk/by-label/GAMES";
        fsType = "ntfs-3g";
        options = [
          "nofail"
          "x-gvfs-hide"
        ];
      };
    };
  };
}
