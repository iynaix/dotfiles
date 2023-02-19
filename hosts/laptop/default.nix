{ config, pkgs, user, lib, host, ... }:
let displayCfg = config.iynaix.displays; in
{
  imports = [ ./hardware.nix ];

  config = {
    iynaix.displays.monitor1 = "eDP-1";

    environment.systemPackages = with pkgs; [ ];

    # do not autologin on laptop!
    services.xserver.displayManager.autoLogin.enable = false;

    home-manager.users.${user} = {
      xsession.windowManager.bspwm = lib.mkIf config.iynaix.bspwm {
        monitors = {
          "${displayCfg.monitor1}" = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" ];
        };
        extraConfigEarly = lib.concatStringsSep "\n" [
          "xrandr --output '${displayCfg.monitor1}' --mode 1920x1080 --pos 0x0 --rotate normal"
        ];
        extraConfig = "xwallpaper --output '${displayCfg.monitor1}' --zoom ~/Pictures/Wallpapers/gits-catppuccin-1920.png";
      };

      services.polybar = lib.mkIf config.iynaix.bspwm {
        script = "polybar ${host} &";
      };

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
    };
  };
}
