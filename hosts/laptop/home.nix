{ config, pkgs, host, ... }:

{
  xsession.windowManager.bspwm = {
    monitors = {
      "${host.monitor1}" = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" ];
    };
    extraConfigEarly = lib.concatStringsSep "\n" [
      "xrandr --output '${host.monitor1}' --mode 1920x1080 --pos 0x0 --rotate normal"
    ];
    extraConfig = lib.concatStringsSep "\n" [
      "xwallpaper --output '${host.monitor1}' --zoom ~/Pictures/Wallpapers/gits-catppuccin-1920.png"
      "systemctl --user restart polybar"
    ];
  };

  services.polybar = { script = "polybar laptop &"; };

  # for remapping capslock to super
  home = {
    file.".xmodmap".text = ''
      remove Lock = Caps_Lock
      keysym Caps_Lock = Super_R
      add Lock = Caps_Lock
    '';

    packages = with pkgs; [ xorg.xmodmap ];
  };

  services.xcape = {
    enable = true;
    mapExpression = { Super_R = "Escape"; };
    timeout = 200;
  };
}
