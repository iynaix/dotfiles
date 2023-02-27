{ config, pkgs, user, lib, host, ... }:
let displayCfg = config.iynaix.displays; in
{
  imports = [ ./hardware.nix ];

  config = {
    iynaix = {
      displays.monitor1 = "eDP-1";
      persist.root.directories = [ "/etc/NetworkManager" ];
    };

    networking.hostId = "abb4d116"; # required for zfs

    environment.systemPackages = with pkgs; [
      wirelesstools
      xorg.xbacklight
      xorg.xmodmap
    ];

    # touchpad support
    services.xserver.libinput.enable = true;

    # do not autologin on laptop!
    services.xserver.displayManager.autoLogin.enable = lib.mkForce false;
    security.pam.services.gdm.enableGnomeKeyring = true;

    home-manager.users.${user} = {
      xsession.windowManager.bspwm = lib.mkIf config.iynaix.bspwm.enable {
        monitors = {
          "${displayCfg.monitor1}" = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" ];
        };
        extraConfigEarly = "xrandr --output '${displayCfg.monitor1}' --mode 1920x1080 --pos 0x0 --rotate normal";
        extraConfig = "xwallpaper --output '${displayCfg.monitor1}' --zoom ${../../modules/desktop/wallpapers/gits-catppuccin-1920.png}";
      };

      services.polybar = lib.mkIf config.iynaix.bspwm.enable {
        package = (pkgs.polybar.override {
          iwSupport = true;
          pulseSupport = true;
        });
        script = "polybar ${host} &";
      };

      # for remapping capslock to super
      home = {
        file.".xmodmap".text = ''
          remove Lock = Caps_Lock
          keysym Caps_Lock = Super_R
          add Lock = Caps_Lock
        '';

        # packages = with pkgs; [ xorg.xmodmap ];
      };

      programs.alacritty.settings.font.size = 7;

      services.xcape = {
        enable = true;
        mapExpression = { Super_R = "Escape"; };
        timeout = 200;
      };
    };
  };
}
