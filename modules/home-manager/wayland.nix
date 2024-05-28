{
  host,
  lib,
  isLaptop,
  isNixOS,
  pkgs,
  ...
}:
{
  options.custom = {
    monitors = lib.mkOption {
      type =
        with lib.types;
        listOf (submodule {
          options = {
            name = lib.mkOption {
              type = str;
              description = "The name of the display, e.g. eDP-1";
            };
            width = lib.mkOption {
              type = int;
              description = "Pixel width of the display";
            };
            height = lib.mkOption {
              type = int;
              description = "Pixel width of the display";
            };
            refreshRate = lib.mkOption {
              type = int;
              default = 60;
              description = "Refresh rate of the display";
            };
            position = lib.mkOption {
              type = str;
              default = "0x0";
              description = "Position of the display, e.g. 0x0";
            };
            vertical = lib.mkOption {
              type = bool;
              description = "Is the display vertical?";
              default = false;
            };
            workspaces = lib.mkOption {
              type = listOf int;
              description = "List of workspace numbers";
            };
          };
        });
      default = [ ];
      description = "Config for monitors";
    };

    hyprland = {
      enable = lib.mkEnableOption "hyprland" // {
        default = true;
      };
      lock = lib.mkEnableOption "locking of host" // {
        default = isLaptop && isNixOS;
      };
      qtile = lib.mkEnableOption "qtile like behavior for workspaces";
      plugin = lib.mkOption {
        type = with lib.types; nullOr (enum [ "hyprnstack" ]);
        description = "Plugin to enable for hyprland";
        default = null;
      };
    };

    waybar = {
      config = lib.mkOption {
        type = lib.types.submodule { freeformType = (pkgs.formats.json { }).type; };
        default = { };
        description = "Additional waybar config (wallust templating can be used)";
      };
      idle-inhibitor = lib.mkEnableOption "Idle inhibitor" // {
        default = host == "desktop";
      };
      persistent-workspaces = lib.mkEnableOption "Persistent workspaces";
      hidden = lib.mkEnableOption "Hidden waybar by default";
    };
  };
}
