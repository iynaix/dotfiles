{
  config,
  pkgs,
  user,
  lib,
  ...
}: let
  displayCfg = config.iynaix.displays;
in {
  imports = [./hardware.nix];

  config = {
    iynaix = {
      displays.monitor1 = "eDP-1";
      backlight.enable = true;
      kmonad.enable = true;
      pathofbuilding.enable = true;

      hyprland = {
        enable = true;
        monitors = ''
          monitor = ${displayCfg.monitor1}, 1920x1080,0x0,1
        '';
        extraVariables = ''
          gestures {
            workspace_swipe = true
          }
        '';
        extraBinds = {
          # handle laptop lid
          bindl = {
            # ",switch:on:Lid Switch" = ''exec, hyprctl keyword monitor "${displayCfg.monitor1}, 1920x1080, 0x0, 1"'';
            # ",switch:off:Lid Switch" = ''exec, hyprctl monitor "${displayCfg.monitor1}, disable"'';
            ",switch:Lid Switch" = "exec, hypr-lock";
          };
        };
      };

      terminal.size = 10;

      waybar = {
        settings-template = ''
          "modules-right": [ "network", "pulseaudio", "backlight", "battery", "clock" ],
          "network": {
            "format": "  {essid}",
            "format-disconnected": "睊  Offline",
            "on-click": "/home/${user}/.config/rofi/rofi-wifi-menu",
            "on-click-right": "${config.iynaix.terminal.exec} nmtui",
            "tooltip": false
          }
        '';
        # add rounded corners for leftmost modules-right
        style-template = lib.mkAfter ''
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

    home-manager.users.${user} = {};
  };
}
