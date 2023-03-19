{ config, pkgs, user, lib, host, ... }:
let
  displayCfg = config.iynaix.displays;
  bspwmCfg = config.iynaix.bspwm;
in
{
  imports = [ ./hardware.nix ];

  config = {
    iynaix = {
      displays.monitor1 = "eDP-1";
      backlight.enable = true;
      kmonad.enable = true;
      pathofbuilding.enable = true;

      hyprland = {
        enable = true;
        monitors = {
          "${displayCfg.monitor1}" = "1920x1080,0x0,1";
        };
        wallpapers = {
          "${displayCfg.monitor1}" = "${../../modules/desktop/wallpapers/gits-catppuccin-1920.png}";
        };
        extraVariables = {
          gestures = {
            workspace_swipe = true;
          };
        };
        extraBinds = {
          # handle laptop lid
          bindl = {
            # ",switch:on:Lid Switch" = ''exec, hyprctl keyword monitor "${displayCfg.monitor1}, 1920x1080, 0x0, 1"'';
            # ",switch:off:Lid Switch" = ''exec, hyprctl monitor "${displayCfg.monitor1}, disable"'';
            ",switch:Lid Switch" = "exec, hypr-lock";
          };
        };
      };

      waybar = {
        settings = {
          modules-right = [ "network" "pulseaudio" "backlight" "battery" "clock" ];
          network = {
            format = "  {essid}";
            format-disconnected = "睊  Offline";
            on-click = "~/.config/rofi/rofi-wifi-menu";
            on-click-right = "kitty nmtui";
            tooltip = false;
          };
        };
        # add rounded corners for leftmost modules-right
        style = lib.mkAfter ''
          #network {
            border-radius: 12px 0 0 12px;
          }
        '';
      };

      persist.root.directories = [
        "/etc/NetworkManager" # for wifi
      ];
    };

    networking.hostId = "abb4d116"; # required for zfs

    environment.systemPackages = with pkgs; [
      bc # needed for rofi-wifi-menu
      wirelesstools
    ];

    # touchpad support
    services.xserver.libinput.enable = true;

    # do not autologin on laptop!
    services.xserver.displayManager.autoLogin.enable = lib.mkForce false;
    security.pam.services.gdm.enableGnomeKeyring = true;

    home-manager.users.${user} = {
      # bspwm settings
      xsession.windowManager.bspwm = lib.mkIf bspwmCfg.enable {
        monitors = {
          "${displayCfg.monitor1}" = [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" ];
        };
        extraConfigEarly = "xrandr --output '${displayCfg.monitor1}' --mode 1920x1080 --pos 0x0 --rotate normal";
        extraConfig = "xwallpaper --output '${displayCfg.monitor1}' --zoom ${../../modules/desktop/wallpapers/gits-catppuccin-1920.png}";
      };

      services.polybar = lib.mkIf bspwmCfg.enable {
        package = (pkgs.polybar.override {
          iwSupport = true;
          pulseSupport = true;
        });
        script = "polybar ${host} &";
      };

      programs.alacritty.settings.font.size = 10;
      programs.kitty.font.size = 10;
    };
  };
}
