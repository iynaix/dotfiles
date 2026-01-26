{ lib, ... }:
{
  flake.nixosModules.core = {
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
                positionX = lib.mkOption {
                  type = lib.types.int;
                  default = 0;
                  description = "Position x coordinate of the display";
                };
                positionY = lib.mkOption {
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
                workspaces = lib.mkOption {
                  type = lib.types.nonEmptyListOf lib.types.int;
                  description = "List of workspace numbers";
                };
                defaultWorkspace = lib.mkOption {
                  type = lib.types.enum config.workspaces;
                  default = lib.elemAt config.workspaces 0;
                  description = "Default workspace for this monitor";
                };
                extraHyprlandConfig = lib.mkOption {
                  type = lib.types.attrs;
                  default = { };
                  description = "Extra monitor config for hyprland";
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

      startup = lib.mkOption {
        description = "Programs to run on startup";
        type = lib.types.listOf (
          lib.types.oneOf [
            lib.types.str
            (lib.types.submodule {
              options = {
                app-id = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  description = "The app-id (class) of the program to start";
                  default = null;
                };
                enable = lib.mkEnableOption "Rule" // {
                  default = true;
                };
                title = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  description = "The window title of the program to start, for differentiating between multiple instances";
                  default = null;
                };
                spawn = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  description = "Command to execute";
                  default = null;
                };
                workspace = lib.mkOption {
                  type = lib.types.nullOr lib.types.int;
                  description = "lib.Optional workspace to start program on";
                  default = null;
                };
                niriArgs = lib.mkOption {
                  type = lib.types.lines;
                  description = "Extra arguments for niri window rules";
                  default = "";
                };
              };
            })
          ]
        );
        default = [ ];
      };

      startupServices = lib.mkOption {
        description = "Services to start after the WM is initialized";
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
    };

  };

  flake.nixosModules.wm =
    # generic functionality for all WMs
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) host;
      # ensure setting terminal title using --title or exec with -e works
      termExe =
        assert config.custom.programs.terminal.package.pname == "ghostty";
        "ghostty";
    in
    {
      custom = {
        startup = [
          {
            app-id = "helium";
            spawn = [
              (lib.getExe (
                pkgs.writeShellApplication {
                  name = "init-helium";
                  runtimeInputs = [
                    pkgs.custom.helium
                    config.custom.programs.dotfiles-rs
                  ];
                  text = ''
                    helium --profile-directory=Default &
                    sleep 1; helium --incognito &
                    # no-op if not niri
                    sleep 5; niri-resize-workspace 1
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
            niriArgs = /* kdl */ ''
              open-maximized true
            '';
          }

          # librewolf for discord
          {
            app-id = "librewolf";
            spawn = [ "librewolf" ];
            workspace = 9;
            niriArgs = /* kdl */ ''
              open-maximized true
            '';
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
                (lib.getExe pkgs.xorg.xhost)
                "+local:${user}"
              ];
            }

            # fix Authorization required, but no authorization protocol specified error
            {
              spawn = [
                (lib.getExe pkgs.xorg.xhost)
                "si:localuser:root"
              ];
            }
          */
        ];
      };
    };
}
