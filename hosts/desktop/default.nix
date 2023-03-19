{ config, pkgs, user, lib, ... }:
let
  displayCfg = config.iynaix.displays;
  hyprlandCfg = config.iynaix.hyprland;
in
{
  imports = [ ./hardware.nix ];

  config = {
    iynaix = {
      displays = {
        monitor1 = "DP-2";
        monitor2 = if hyprlandCfg.enable then "DP-4" else "DP-0.8";
        monitor3 = if hyprlandCfg.enable then "HDMI-A-1" else "HDMI-0";
      };

      # wayland settings
      hyprland = {
        enable = true;
        monitors = {
          "${displayCfg.monitor1}" = "3440x1440@144,1440x1080,1";
          "${displayCfg.monitor2}" = "2560x1440,0x728,1,transform,1";
          "${displayCfg.monitor3}" = "1920x1080,1754x0,1";
        };
        wallpapers = {
          "${displayCfg.monitor1}" = "${../../modules/desktop/wallpapers/gits-catppuccin-3440.png}";
          "${displayCfg.monitor2}" = "${../../modules/desktop/wallpapers/gits-catppuccin-2560.png}";
          "${displayCfg.monitor3}" = "${../../modules/desktop/wallpapers/gits-catppuccin-1920.png}";
        };
      };
      waybar = {
        style = ''
          /* add rounded corners for leftmost modules-right */
          #pulseaudio {
            border-radius: 12px 0 0 12px;
          }
        '';
      };

      smplayer.enable = true;
      torrenters.enable = true;
    };

    boot.loader.grub = {
      extraEntries = lib.concatStringsSep "\n" [
        ''
          menuentry "Arch Linux" {
            insmod part_msdos
            insmod ext2
            search --no-floppy --fs-uuid --set=root 696be7fa-e1d2-4373-ad54-360a93b7c9e2
            linux /boot/vmlinuz-linux root=UUID=696be7fa-e1d2-4373-ad54-360a93b7c9e2 rw quiet
            initrd /boot/intel-ucode.img /boot/initramfs-linux.img
          }
        ''
        ''
          menuentry "Windows 10" {
            insmod part_gpt
            insmod fat
            insmod search_fs_uuid
            insmod chain
            search --fs-uuid --set=root 8651-D10F
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          }
        ''
      ];
    };

    # fix clock to be compatible with windows
    time.hardwareClockInLocalTime = true;

    networking.hostId = "89eaa833"; # required for zfs

    # enable nvidia support
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.opengl = {
      enable = true;
      driSupport = true;
    };

    # environment.systemPackages = with pkgs; [ ];

    # symlinks from other drives
    systemd.tmpfiles.rules = [
      "L+ /home/${user}/Documents   - - - - /media/Files/Documents"
      "L+ /home/${user}/Downloads   - - - - /media/Files/Downloads"
      "L+ /home/${user}/Pictures   - - - - /media/Files/Pictures"
      "L+ /home/${user}/Videos   - - - - /media/6TBRED"
    ];

    home-manager.users.${user} = {
      home = {
        packages = with pkgs; [
          filezilla
          vlc
        ];
      };
    };

    iynaix.persist.home.directories = [
      ".config/smplayer"
    ];
  };
}
