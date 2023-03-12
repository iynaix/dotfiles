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
      pathofbuilding.enable = true;

      hyprland = {
        monitors = lib.concatStringsSep "\n" [
          "monitor=${displayCfg.monitor1},1920x1080,0x0,1"
        ];
        wallpapers = {
          "${displayCfg.monitor1}" = "${../../modules/desktop/wallpapers/gits-catppuccin-1920.png}";
        };
      };

      waybar = {
        settings = {
          modules-right = [ "network" "pulseaudio" "backlight" "battery" "clock" ];
          network = {
            format = "  {essid}";
            on-click = "~/.config/rofi/scripts/rofi-wifi-menu";
          };
        };
        # add rounded corners for leftmost modules-right
        style = lib.mkAfter ''
          #network {
            border-radius: 12px 0 0 12px;
          }
        '';
      };

      # toggle WMs
      bspwm.enable = false;
      hyprland.enable = true;

      persist.root.directories = [
        "/etc/NetworkManager" # for wifi
      ];
    };

    networking.hostId = "abb4d116"; # required for zfs

    environment.systemPackages = with pkgs; [
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

      # for remapping capslock to super
      home = {
        file.".xmodmap".text = ''
          remove Lock = Caps_Lock
          keysym Caps_Lock = Super_R
          add Lock = Caps_Lock
        '';
      };

      programs.alacritty.settings.font.size = 10;
      programs.kitty.font.size = 10;

      services.xcape = {
        enable = true;
        mapExpression = { Super_R = "Escape"; };
        timeout = 200;
      };
    };

    # run xmodmap, see:
    # https://nixos.wiki/wiki/Keyboard_Layout_Customization
    services.xserver.displayManager.sessionCommands = ''
      sleep 5 && ${pkgs.xorg.xmodmap}/bin/xmodmap ~/.xmodmap &
    '';
  };
}
