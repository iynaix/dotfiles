# generic functionality for all WMs
{
  config,
  isLaptop,
  isNixOS,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) elemAt mkEnableOption mkOption;
  inherit (lib.types)
    bool
    enum
    float
    int
    nonEmptyListOf
    oneOf
    str
    submodule
    ;
in
{
  imports = [
    ./dunst.nix
    ./hypridle.nix
    ./hyprlock.nix
    ./screenshot.nix
    ./wallpaper.nix
    ./wallust.nix
    ./waybar.nix
  ];

  options.custom = {
    wm = mkOption {
      description = "The WM to use, either hyprland, plasma or tty";
      type = enum [
        "hyprland"
        "niri"
        "plasma"
        "tty"
      ];
      default = "hyprland";
    };

    isWm = mkOption {
      description = "Readonly option to check if the WM is hyprland or niri";
      type = bool;
      default = config.custom.wm == "hyprland" || config.custom.wm == "niri";
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
              position-x = mkOption {
                type = int;
                default = 0;
                description = "Position x coordinate of the display";
              };
              position-y = mkOption {
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
            };
          }
        )
      );
      default = [ ];
    };
  };

  config = {
    custom.shell.packages = {
      rofi-clipboard-history = {
        runtimeInputs = [
          config.programs.rofi.package
          config.services.cliphist.package
          pkgs.wl-clipboard
        ];
        text = # sh
          ''
            cliphist list | \
            rofi  -dmenu -theme \"${config.xdg.cacheHome}/wallust/rofi-menu.rasi\" | \
            cliphist decode | \
            wl-copy'';
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
