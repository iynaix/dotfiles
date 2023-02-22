{ config, pkgs, user, lib, host, ... }:
let displayCfg = config.iynaix.displays; in
{
  imports = [
    ./hardware.nix
    ../../modules/media/download.nix # torrenting stuff
  ];

  config = {
    iynaix.bspwm = {
      windowGap = 8;
      padding = 8;
    };

    iynaix.displays = {
      monitor1 = "DP-2";
      monitor2 = "DP-0.8";
      monitor3 = "HDMI-0";
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    # environment.systemPackages = with pkgs; [ ];

    home-manager.users.${user} = {
      xsession.windowManager.bspwm = lib.mkIf config.iynaix.bspwm.enable {
        monitors = {
          "${displayCfg.monitor1}" = [ "1" "2" "3" "4" "5" ];
          "${displayCfg.monitor2}" = [ "6" "7" "8" ];
          "${displayCfg.monitor3}" = [ "9" "10" ];
        };
        extraConfigEarly = "xrandr --output '${displayCfg.monitor1}' --primary --mode 3440x1440 --rate 144 --pos 1440x1080 --rotate normal"
          + " --output '${displayCfg.monitor2}' --mode 2560x1440 --pos 0x728 --rotate left"
          + " --output '${displayCfg.monitor3}' --mode 1920x1080 --pos 1754x0";
        extraConfig = "xwallpaper --output '${displayCfg.monitor1}' --zoom ~/Pictures/Wallpapers/gits-catppuccin-3440.png"
          + " --output '${displayCfg.monitor2}' --zoom ~/Pictures/Wallpapers/gits-catppuccin-2560.png"
          + " --output '${displayCfg.monitor3}' --zoom ~/Pictures/Wallpapers/gits-catppuccin-1920.png";
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
        script = "polybar primary &; polybar secondary &; polybar tertiary &;";
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
