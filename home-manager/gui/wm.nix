# generic functionality for all WMs
{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  inherit (lib) elemAt mkEnableOption mkOption;
  inherit (lib.types)
    enum
    float
    int
    listOf
    nonEmptyListOf
    nullOr
    oneOf
    package
    str
    submodule
    ;
in
{
  options.custom = {
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
                type = int;
                default = 60;
                description = "Refresh rate of the display";
              };
              position = mkOption {
                type = str;
                default = "0x0";
                description = "Position of the display, e.g. 0x0";
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
            exec = mkOption {
              type = nullOr str;
              description = "Command to execute";
              default = null;
            };
            packages = mkOption {
              type = listOf package;
              default = [ ];
              description = "Packages / dependencies required for exec";
            };
            workspace = mkOption {
              type = nullOr int;
              description = "Optional workspace to start program on";
              default = null;
            };
          };
        })
      ]);
      default = [ ];
    };
  };

  config = {
    custom.startup = [
      # browsers
      {
        exec = "brave --incognito";
        packages = [ config.programs.chromium.package ];
        workspace = 1;
      }
      {
        exec = "brave --profile-directory=Default";
        packages = [ config.programs.chromium.package ];
        workspace = 1;
      }

      # file manager
      {
        packages = [ pkgs.nemo-with-extensions ];
        workspace = 4;
      }

      # terminal
      {
        packages = [ config.custom.terminal.package ];
        workspace = 7;
      }

      # librewolf for discord
      {
        packages = [ config.programs.librewolf.package ];
        workspace = 9;
      }

      # download related
      {
        exec = "${config.custom.terminal.exec} nvim ${config.xdg.userDirs.desktop}/yt.txt";
        packages = [ config.custom.terminal.package ];
        workspace = 10;
      }
      {
        packages = [ config.custom.terminal.package ];
        workspace = 10;
      }

      # misc
      # fix gparted "cannot open display: :0" error
      {
        packages = [ pkgs.xorg.xhost ];
        exec = "xhost +local:${user}";
      }

      # fix Authorization required, but no authorization protocol specified error
      # {
      #   packages = [ pkgs.xorg.xhost ];
      #   exec = "xhost si:localuser:root";
      # }

      # clipboard manager
      {
        packages = with pkgs; [
          cliphist
          wl-clipboard
        ];
        exec = "wl-paste --watch cliphist store";
      }
    ];

    home = {
      sessionVariables = {
        QT_QPA_PLATFORM = "wayland;xcb";
        # GDK_BACKEND = "wayland,x11,*";
      };

      packages = with pkgs; [
        swww
        # clipboard history
        cliphist
        wl-clipboard
      ];
    };
  };
}
