# generic functionality for all WMs
{
  config,
  host,
  isLaptop,
  isNixOS,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    elemAt
    getExe
    getExe'
    mkEnableOption
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
      default = "niri";
    };

    isWm = mkOption {
      description = "Readonly option to check if the WM is hyprland / niri / mango";
      type = bool;
      default =
        config.custom.wm == "hyprland" || config.custom.wm == "niri" || config.custom.wm == "mango";
      readOnly = true;
    };

    lock.enable = mkEnableOption "screen locking of host" // {
      default = config.custom.isWm && isLaptop && isNixOS;
    };

    monitors = mkOption {
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

  config = {
    custom = {
      startup =
        # ensure setting terminal title using --title or exec with -e works
        assert config.custom.terminal.package.pname == "ghostty";
        [
          {
            app-id = "brave-browser";
            spawn = [
              (getExe (
                pkgs.writeShellApplication {
                  name = "init-brave";
                  runtimeInputs = [
                    config.programs.chromium.package
                    config.custom.dotfiles.package
                  ];
                  text = ''
                    brave --profile-directory=Default &
                    sleep 1; brave --incognito &
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
            spawn = [ (getExe pkgs.nemo-with-extensions) ];
            workspace = 4;
          }

          # terminal
          rec {
            title = "${config.custom.terminal.app-id}-vertical";
            spawn = [
              (getExe config.custom.terminal.package)
              "--title=${title}"
            ];
            workspace = 7;
            niriArgs = {
              open-maximized = true;
            };
          }

          # librewolf for discord
          {
            app-id = "librewolf";
            spawn = [
              (getExe config.programs.librewolf.package)
            ];
            workspace = 9;
            niriArgs = {
              open-maximized = true;
            };
          }

          # download related
          rec {
            enable = host == "desktop";
            title = "${config.custom.terminal.app-id}-dl";
            spawn = [
              (getExe config.custom.terminal.package)
              "--title=${title}"
            ];
            workspace = 10;
          }
          rec {
            enable = host == "desktop";
            title = "${config.custom.terminal.app-id}-yt.txt";
            spawn = [
              (getExe config.custom.terminal.package)
              "--title=${title}"
              "-e"
              "nvim"
              "${config.xdg.userDirs.desktop}/yt.txt"
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

      shell.packages = {
        rofi-clipboard-history = {
          runtimeInputs = [
            config.programs.rofi.package
          ];
          text = # sh
            ''
              rofi \
                -modi clipboard:${getExe' config.services.cliphist.package "cliphist-rofi-img"} \
                -theme "${config.xdg.cacheHome}/wallust/rofi-menu.rasi" \
                -show clipboard -show-icons
            '';
        };
      };
    };

    home = {
      sessionVariables = {
        QT_QPA_PLATFORM = "wayland;xcb";
        # GDK_BACKEND = "wayland,x11,*";
      };

      packages = with pkgs; [
        # clipboard history
        cliphist
        wl-clipboard
      ];
    };

    # WM agnostic polkit authentication agent
    services = {
      cliphist = {
        enable = true;
        allowImages = true;
      };

      polkit-gnome.enable = true;
    };
  };
}
