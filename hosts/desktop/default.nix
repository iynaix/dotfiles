{ config, pkgs, user, lib, host, ... }:
let displayCfg = config.iynaix.displays; in
{
  imports = [
    ./hardware.nix
    ../../modules/media/download.nix # torrenting stuff
  ];

  config = {
    environment.systemPackages = [ (pkgs.callPackage ../../packages/pathofbuilding.nix { }) ];

    iynaix = {
      displays = {
        monitor1 = "DP-2";
        monitor2 = "DP-0.8";
        monitor3 = "HDMI-0";
      };
      bspwm = {
        windowGap = 8;
        padding = 8;
      };
    };

    boot.loader.grub = {
      # useOSProber = true; # os prober is very slow
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

    networking.hostId = "89eaa833"; # required for zfs

    # enable nvidia support
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.opengl.enable = true;

    # environment.systemPackages = with pkgs; [ ];

    # symlinks from other drives
    systemd.tmpfiles.rules = [
      "L+ /home/${user}/Documents   - - - - /media/Files/Documents"
      "L+ /home/${user}/Downloads   - - - - /media/Files/Downloads"
      "L+ /home/${user}/Pictures   - - - - /media/Files/Pictures"
    ];

    home-manager.users.${user} = {
      xsession.windowManager.bspwm = lib.mkIf config.iynaix.bspwm.enable {
        monitors = {
          "${displayCfg.monitor1}" = [ "1" "2" "3" "4" "5" ];
          "%${displayCfg.monitor2}" = [ "6" "7" "8" ]; # escape with % because there is a dot
          "${displayCfg.monitor3}" = [ "9" "10" ];
        };
        extraConfigEarly = "xrandr --output '${displayCfg.monitor1}' --primary --mode 3440x1440 --rate 144 --pos 1440x1080 --rotate normal"
          + " --output '${displayCfg.monitor2}' --mode 2560x1440 --pos 0x728 --rotate left"
          + " --output '${displayCfg.monitor3}' --mode 1920x1080 --pos 1754x0";
        extraConfig = "xwallpaper --output '${displayCfg.monitor1}' --zoom ${../../modules/desktop/wallpapers/gits-catppuccin-3440.png}"
          + " --output '${displayCfg.monitor2}' --zoom ${../../modules/desktop/wallpapers/gits-catppuccin-2560.png}"
          + " --output '${displayCfg.monitor3}' --zoom ${../../modules/desktop/wallpapers/gits-catppuccin-1920.png}";
      };

      services.polybar = lib.mkIf config.iynaix.bspwm.enable {
        # setup bars specific to host
        config = lib.mkAfter {
          "bar/primary" = {
            "inherit" = "bar/base";
            monitor = "${displayCfg.monitor1}";

            modules-left = "bspwm_mode";
            modules-center = "bspwm";
            modules-right = "lan volume date";
          };
          "bar/secondary" = {
            "inherit" = "bar/base";
            monitor = "${displayCfg.monitor2}";

            modules-left = "bspwm_mode";
            modules-center = "bspwm";
            modules-right = "date";
          };
          "bar/tertiary" = {
            "inherit" = "bar/base";
            monitor = "${displayCfg.monitor3}";

            modules-left = "bspwm_mode";
            modules-center = "bspwm";
            modules-right = "date";
          };
        };
        script = ''
          polybar primary &
          polybar secondary &
          polybar tertiary &
        '';
      };

      home = {
        packages = [
          # additional media players
          pkgs.smplayer
          pkgs.vlc
        ];
      };
    };
  };
}
