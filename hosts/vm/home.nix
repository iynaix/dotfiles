{ config, pkgs, lib, host, ... }:

{
  xsession.windowManager.bspwm = {
    monitors = {
      "${host.monitor1}" = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" ];
    };
    extraConfigEarly = lib.concatStringsSep "\n" [
      "xrandr --output '${host.monitor1}' --mode 1920x1200 --pos 0x0 --rotate normal"
    ];
    extraConfig = lib.concatStringsSep "\n" [
      "xwallpaper --output '${host.monitor1}' --zoom ~/Pictures/Wallpapers/gits-catppuccin-3440.png"
      "systemctl --user restart polybar"
    ];
    # just edit nix config on startup
    startupPrograms = lib.mkForce [
      # vscode on desktop 1
      ''bspc rule -a Code -o desktop="^1"''
      "code"
      # terminal on desktop 2
      ''bspc rule -a Alacritty -o desktop="^2"''
      "$TERMINAL"
    ];
  };

  services.polybar = { script = "polybar vm &"; };
}
