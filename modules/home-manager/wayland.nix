{
  config,
  lib,
  isLaptop,
  pkgs,
  ...
}:
let
  hyprlandCfg = config.wayland.windowManager.hyprland;
in
{
  options.custom = {
    displays = lib.mkOption {
      type =
        with lib.types;
        listOf (
          submodule {
            options = {
              name = lib.mkOption {
                type = str;
                description = "The name of the display, e.g. eDP-1";
              };
              hyprland = lib.mkOption {
                type = str;
                description = ''
                  Hyprland config for the monitor, see
                  https://wiki.hyprland.org/Configuring/Monitors/

                  e.g. 3440x1440@160,1440x1080,1
                '';
              };
              workspaces = lib.mkOption {
                type = listOf int;
                description = "List of workspace strings";
              };
            };
          }
        );
      default = [ ];
      description = "Config for new displays";
    };

    hyprland = {
      autostart = lib.mkEnableOption "Autostart hyprland from tty" // {
        default = true;
      };
      lock = lib.mkEnableOption "locking of host" // {
        default = isLaptop;
      };
      qtile = lib.mkEnableOption "qtile like behavior for workspaces";
      plugin = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum [ "hyprnstack" ]);
        description = "Plugin to enable for hyprland";
        default = null;
      };
    };

    waybar = {
      enable = lib.mkEnableOption "waybar" // {
        default = hyprlandCfg.enable;
      };
      config = lib.mkOption {
        type = lib.types.submodule { freeformType = (pkgs.formats.json { }).type; };
        default = { };
        description = "Additional waybar config (wallust templating can be used)";
      };
      persistent-workspaces = lib.mkEnableOption "Persistent workspaces";
      hidden = lib.mkEnableOption "Hidden waybar by default";
    };
  };
}
