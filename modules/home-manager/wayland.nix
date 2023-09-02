{
  config,
  lib,
  pkgs,
  ...
}: let
  hyprlandCfg = config.wayland.windowManager.hyprland;
in {
  options.iynaix = {
    displays = lib.mkOption {
      type = with lib.types;
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
      default = [];
      description = "Config for new displays";
    };

    waybar = {
      enable = lib.mkEnableOption "waybar" // {default = hyprlandCfg.enable;};
      config = lib.mkOption {
        type = lib.types.submodule {
          freeformType = (pkgs.formats.json {}).type;
        };
        default = {};
        description = "Additional waybar config (wallust templating can be used)";
      };
      css = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Additional waybar css (wallust templating can be used)";
      };
      border-radius = lib.mkOption {
        type = lib.types.str;
        default = "12px";
        description = "Border-radius for waybar";
      };
    };
  };
}
