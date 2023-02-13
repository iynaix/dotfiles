{ config, pkgs, host, ... }:

{
  xsession.windowManager.bspwm = {
    monitors = {
      "${host.monitor1}" = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" ];
    };
    extraConfigEarly =
      "xrandr --output '${host.monitor1}' --mode 1920x1080 --pos 0x0 --rotate normal";
    extraConfig =
      "xwallpaper --output '${host.monitor1}' --zoom ~/Pictures/Wallpapers/gits-catppuccin-3440.png;"
      + "systemctl --user restart polybar";
    # just edit nix config on startup
    startupPrograms = pkgs.lib.mkOverride 0 [
      # vscode on desktop 1
      ''bspc rule -a Code -o desktop="^1"''
      "code"
      # terminal on desktop 2
      ''bspc rule -a Alacritty -o desktop="^2"''
      "alacritty"
    ];
  };

  services.polybar = { script = "polybar vm &"; };
}
