# generic functionality for all WMs
{
  config,
  host,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    elemAt
    getExe
    mkEnableOption
    mkIf
    mkOption
    mod
    optionalString
    ;
  inherit (lib.types)
    attrs
    bool
    enum
    float
    int
    nonEmptyListOf
    listOf
    nullOr
    oneOf
    str
    submodule
    ;
  # ensure setting terminal title using --title or exec with -e works
  termExe =
    assert config.custom.programs.terminal.package.pname == "ghostty";
    "ghostty";
in
{
  options.custom = {
    wm = mkOption {
      description = "The WM to use, either hyprland / niri / mango / plasma / tty";
      type = enum [
        "hyprland"
        "niri"
        "mango"
        "plasma"
        "tty"
      ];
      default = "hyprland";
    };

    isWm = mkOption {
      description = "Readonly option to check if the WM is hyprland / niri / mango";
      type = bool;
      default =
        config.custom.wm == "hyprland" || config.custom.wm == "niri" || config.custom.wm == "mango";
      readOnly = true;
    };

    hardware.monitors = mkOption {
      description = "Config for monitors";
      type = nonEmptyListOf (
        submodule (
          { config, ... }:
          {
            options = {
              name = mkOption {
                type = str;
                description = "The name of the display, e.g. eDP-1";
              };
              width = mkOption {
                type = int;
                description = "Pixel width of the display";
              };
              height = mkOption {
                type = int;
                description = "Pixel width of the display";
              };
              refreshRate = mkOption {
                type = oneOf [
                  int
                  str
                ];
                default = 60;
                description = "Refresh rate of the display";
              };
              positionX = mkOption {
                type = int;
                default = 0;
                description = "Position x coordinate of the display";
              };
              positionY = mkOption {
                type = int;
                default = 0;
                description = "Position y coordinate of the display";
              };
              scale = mkOption {
                type = float;
                default = 1.0;
              };
              vrr = mkEnableOption "Variable Refresh Rate";
              transform = mkOption {
                type = int;
                description = "Tranform for rotation";
                default = 0;
              };
              workspaces = mkOption {
                type = nonEmptyListOf int;
                description = "List of workspace numbers";
              };
              defaultWorkspace = mkOption {
                type = enum config.workspaces;
                default = elemAt config.workspaces 0;
                description = "Default workspace for this monitor";
              };
              extraHyprlandConfig = mkOption {
                type = attrs;
                default = { };
                description = "Extra monitor config for hyprland";
              };
              isVertical = mkOption {
                type = bool;
                default = mod config.transform 2 == 1;
                description = "Whether the monitor is vertical";
                readOnly = true;
              };
            };
          }
        )
      );
      default = [ ];
    };

    startup = mkOption {
      description = "Programs to run on startup";
      type = listOf (oneOf [
        str
        (submodule {
          options = {
            app-id = mkOption {
              type = nullOr str;
              description = "The app-id (class) of the program to start";
              default = null;
            };
            enable = mkEnableOption "Rule" // {
              default = true;
            };
            title = mkOption {
              type = nullOr str;
              description = "The window title of the program to start, for differentiating between multiple instances";
              default = null;
            };
            spawn = mkOption {
              type = listOf str;
              description = "Command to execute";
              default = null;
            };
            workspace = mkOption {
              type = nullOr int;
              description = "Optional workspace to start program on";
              default = null;
            };
            niriArgs = mkOption {
              type = attrs;
              description = "Extra arguments for niri window rules";
              default = { };
            };
          };
        })
      ]);
      default = [ ];
    };
  };

  config = mkIf config.custom.isWm {
    custom = {
      startup = [
        {
          app-id = "helium";
          spawn = [
            (getExe (
              pkgs.writeShellApplication {
                name = "init-helium";
                runtimeInputs = [
                  pkgs.custom.helium
                  config.custom.programs.dotfiles.package
                ];
                text = ''
                  helium --profile-directory=Default &
                  sleep 1; helium --incognito &
                  ${optionalString (config.custom.wm == "niri") "sleep 5; niri-resize-workspace 1"}
                '';
              }
            ))
          ];
          workspace = 1;
        }

        # file manager
        {
          app-id = "nemo";
          # NOTE: nemo seems ignore --class and --name flags?
          spawn = [ "nemo" ];
          workspace = 4;
        }

        # terminal
        # NOTE: use --class instead of --title to fix ghostty not properly setting initialTitle:
        # https://github.com/ghostty-org/ghostty/discussions/8804
        rec {
          app-id = "${config.custom.programs.terminal.app-id}-vertical";
          spawn = [
            termExe
            "--class=${app-id}"
          ];
          workspace = 7;
          niriArgs = {
            open-maximized = true;
          };
        }

        # librewolf for discord
        {
          app-id = "librewolf";
          spawn = [ "librewolf" ];
          workspace = 9;
          niriArgs = {
            open-maximized = true;
          };
        }

        # download related
        rec {
          enable = host == "desktop";
          app-id = "${config.custom.programs.terminal.app-id}-dl";
          spawn = [
            termExe
            "--class=${app-id}"
          ];
          workspace = 10;
        }
        rec {
          enable = host == "desktop";
          app-id = "${config.custom.programs.terminal.app-id}-yt.txt";
          spawn = [
            termExe
            "--class=${app-id}"
            "-e"
            "nvim"
            "${config.hj.directory}/Desktop/yt.txt"
          ];
          workspace = 10;
        }
        /*
          # fix gparted "cannot open display: :0" error
          {
            spawn = [
              (getExe pkgs.xorg.xhost)
              "+local:${user}"
            ];
          }

          # fix Authorization required, but no authorization protocol specified error
          {
            spawn = [
              (getExe pkgs.xorg.xhost)
              "si:localuser:root"
            ];
          }
        */
      ];
    };

  };
}
