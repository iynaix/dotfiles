{ config, pkgs, host, ... }:

{
  xsession.windowManager.bspwm = {
    monitors = {
      "${host.monitor1}" = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" ];
    };
    extraConfigEarly =
      "xrandr --output '${host.monitor1}' --mode 1920x1080 --pos 0x0 --rotate normal";
    extraConfig =
      "xwallpaper --output '${host.monitor1}' --zoom ~/Pictures/Wallpapers/gits-catppuccin-1920.png";
  };

  # TODO: xmodmap and xcape
}
