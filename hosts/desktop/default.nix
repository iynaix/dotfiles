{ config, pkgs, user, lib, host, ... }:
let displayCfg = config.iynaix.displays; in
{
  imports = [
    ./hardware.nix
    ../../modules/media/download.nix # torrenting stuff
  ];

  config = {
    iynaix.displays = {
      monitor1 = "DP-2";
      monitor2 = "DP-0.8";
      monitor3 = "HDMI-0";
    };

    iynaix.bspwm = {
      windowGap = 8;
      padding = 8;
    };

    boot.loader.grub = {
      # useOSProber = true; # os prober is very slow

      # menuentry 'Arch Linux (on /dev/nvme1n1p1)' --class arch --class gnu-linux --class gnu --class os $menuentry_id_option 'osprober-gnulinux-simple-696be7fa-e1d2-4373-ad54-360a93b7c9e2' {
      # 	insmod part_msdos
      # 	insmod ext2
      # 	search --no-floppy --fs-uuid --set=root 696be7fa-e1d2-4373-ad54-360a93b7c9e2
      # 	linux /boot/vmlinuz-linux root=UUID=696be7fa-e1d2-4373-ad54-360a93b7c9e2 rw quiet
      # 	initrd /boot/intel-ucode.img /boot/initramfs-linux.img
      # }

      # set $FS_UUID to the UUID of the EFI partition
      # extraEntries = ''
      #   menuentry "Windows" {
      #     insmod part_gpt
      #     insmod fat
      #     insmod search_fs_uuid
      #     insmod chain
      #     search --fs-uuid --set=root $FS_UUID
      #     chainloader /EFI/Microsoft/Boot/bootmgfw.efi
      #   }
      # '';
    };
    networking.hostId = "89eaa833"; # required for zfs

    # enable nvidia support
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.opengl.enable = true;

    # environment.systemPackages = with pkgs; [ ];

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
            # modules-right = "battery volume mpd date";
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
        packages = with pkgs; [
          # additional media players
          smplayer
          vlc
        ];
      };
    };
  };
}
