{ lib, ... }:
{
  flake.modules.nixos.core = {
    options.custom = {
      hardware.monitors = lib.mkOption {
        description = "Config for monitors";
        type = lib.types.nonEmptyListOf (
          lib.types.submodule (
            { config, ... }:
            {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "The name of the display, e.g. eDP-1";
                };
                width = lib.mkOption {
                  type = lib.types.int;
                  description = "Pixel width of the display";
                };
                height = lib.mkOption {
                  type = lib.types.int;
                  description = "Pixel width of the display";
                };
                refreshRate = lib.mkOption {
                  type = lib.types.oneOf [
                    lib.types.int
                    lib.types.str
                  ];
                  default = 60;
                  description = "Refresh rate of the display";
                };
                x = lib.mkOption {
                  type = lib.types.int;
                  default = 0;
                  description = "Position x coordinate of the display";
                };
                y = lib.mkOption {
                  type = lib.types.int;
                  default = 0;
                  description = "Position y coordinate of the display";
                };
                scale = lib.mkOption {
                  type = lib.types.float;
                  default = 1.0;
                };
                vrr = lib.mkEnableOption "Variable Refresh Rate";
                transform = lib.mkOption {
                  type = lib.types.int;
                  description = "Transform for rotation";
                  default = 0;
                };
                hdr = lib.mkEnableOption "HDR";
                workspaces = lib.mkOption {
                  type = lib.types.nonEmptyListOf lib.types.int;
                  description = "List of workspace numbers";
                };
                defaultWorkspace = lib.mkOption {
                  type = lib.types.enum config.workspaces;
                  default = lib.elemAt config.workspaces 0;
                  description = "Default workspace for this monitor";
                };
                isVertical = lib.mkOption {
                  type = lib.types.bool;
                  default = lib.mod config.transform 2 == 1;
                  description = "Whether the monitor is vertical";
                  readOnly = true;
                };
              };
            }
          )
        );
        default = [ ];
      };
    };
  };
}
