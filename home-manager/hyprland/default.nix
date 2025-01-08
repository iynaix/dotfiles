{
  config,
  host,
  isLaptop,
  isVm,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.custom) monitors;
in
{
  imports = [
    ./hyprnstack.nix
    ./idle.nix
    ./keybinds.nix
    ./lock.nix
    ./screenshot.nix
    ./startup.nix
    ./wallpaper.nix
  ];

  options.custom = with lib; {
    hyprland = {
      enable = mkEnableOption "hyprland" // {
        default = !config.custom.headless;
      };
      plugin = mkOption {
        type = types.nullOr (types.enum [ "hyprnstack" ]);
        description = "Plugin to enable for hyprland";
        default = null;
      };
    };

    monitors = mkOption {
      type =
        with types;
        nonEmptyListOf (
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
                vertical = mkOption {
                  type = bool;
                  description = "Is the display vertical?";
                  default = false;
                };
                workspaces = mkOption {
                  type = nonEmptyListOf int;
                  description = "List of workspace numbers";
                };
                defaultWorkspace = mkOption {
                  type = types.enum config.workspaces;
                  default = lib.elemAt config.workspaces 0;
                  description = "Default workspace for this monitor";
                };
              };
            }
          )
        );
      default = [ ];
      description = "Config for monitors";
    };
  };

  config = lib.mkIf config.custom.hyprland.enable {
    home = {
      packages = with pkgs; [
        swww
        # clipboard history
        cliphist
        wl-clipboard
      ];

      shellAliases = {
        hyprland = "Hyprland";
        hypr-log = "hyprctl rollinglog --follow";
      };
    };

    wayland.windowManager.hyprland = {
      enable = true;
      # package = pkgs.hyprland;
      # package =
      #   assert (lib.assertMsg (lib.versionOlder config.programs.hyprland.package.version "0.42") "hyprland: use version from nixpkgs?");
      #   inputs.hyprland.packages.${pkgs.system}.hyprland;

      # https://wiki.hyprland.org/Useful-Utilities/Systemd-start/#installation
      # conflicts with programs.hyprland.withUWSM in nixos
      systemd.enable = false;

      settings =
        {
          monitor =
            (lib.forEach monitors (
              d:
              lib.concatStringsSep "," (
                [
                  d.name
                  "${toString d.width}x${toString d.height}@${toString d.refreshRate}"
                  d.position
                  (toString d.scale)
                ]
                ++ lib.optionals d.vertical [ "transform,1" ]
                ++ lib.optionals d.vrr [ "vrr,1" ]
              )
            ))
            ++ [ ",preferred,auto,auto" ];

          # https://wiki.hyprland.org/Configuring/Environment-variables/
          env = [
            "QT_QPA_PLATFORM,wayland;xcb"
            # "GDK_BACKEND,wayland,x11,*"
            "HYPRCURSOR_THEME,${config.home.pointerCursor.name}"
            "HYPRCURSOR_SIZE,${toString config.home.pointerCursor.size}"
          ];

          input = {
            kb_layout = "us";
            follow_mouse = 1;

            touchpad = lib.mkIf isLaptop {
              natural_scroll = false;
              disable_while_typing = true;
            };
          };

          "$mod" = if isVm then "ALT" else "SUPER";

          "$term" = "${config.custom.terminal.exec}";

          general =
            let
              gap = if host == "desktop" then 8 else 4;
            in
            {
              gaps_in = gap;
              gaps_out = gap;
              border_size = 2;
              layout = lib.mkDefault "master";
            };

          decoration = {
            rounding = 4;

            shadow = {
              enabled = !isVm;
              range = 4;
              render_power = 3;
              color = "rgba(1a1a1aee)";
            };

            # dim_inactive = true
            # dim_strength = 0.05

            blur = {
              enabled = !isVm;
              size = 2;
              passes = 3;
              new_optimizations = true;
            };
          };

          animations = {
            enabled = !isVm;
            bezier = [
              "overshot, 0.05, 0.9, 0.1, 1.05"
              "smoothOut, 0.36, 0, 0.66, -0.56"
              "smoothIn, 0.25, 1, 0.5, 1"
            ];

            # name, onoff, speed, curve, style
            # speed units is measured in 100ms
            animation = [
              "windows, 1, 5, overshot, slide"
              "windowsOut, 1, 4, smoothOut, slide"
              "windowsMove, 1, 4, smoothIn, slide"
              "layers, 1, 5, default, popin 80%"
              "border, 1, 5, default"
              # 1 loop every 5 minutes
              "borderangle, 1, ${toString (10 * 60 * 5)}, default, loop"
              "fade, 1, 5, smoothIn"
              "fadeDim, 1, 5, smoothIn"
              "workspaces, 1, 6, default"
            ];
          };

          dwindle = {
            pseudotile = true;
            preserve_split = true;
          };

          master = {
            new_on_active = "after";
            mfact = "0.5";
            orientation = "left";
            smart_resizing = true;
          };

          binds = {
            workspace_back_and_forth = true;
          };

          misc = {
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
            initial_workspace_tracking = 0;
            mouse_move_enables_dpms = true;
            # enable_hyprcursor = false;
            # animate_manual_resizes = true;
            # animate_mouse_windowdragging = true;
            # key_press_enables_dpms = true;
            enable_swallow = false;
            swallow_regex = "^([Kk]itty|[Ww]ezterm|[Gg]hostty)$";
          };

          debug.disable_logs = false;

          windowrulev2 = [
            # "dimaround,floating:1"
            "bordersize 5,fullscreen:1" # monocle mode
            "float,class:(wlroots)" # hyprland debug session
            # save dialog
            "float,class:(xdg-desktop-portal-gtk)"
            "size <50% <50%,class:(xdg-desktop-portal-gtk)"
          ];

          exec-once = [
            # clipboard manager
            "wl-paste --watch cliphist store"
          ];

          # handle trackpad settings
          gestures = lib.mkIf isLaptop { workspace_swipe = true; };
        }
        //
        # bind workspaces to monitors, don't bother if there is only one monitor
        lib.optionalAttrs (lib.length monitors > 1) {
          workspace = lib.custom.mapWorkspaces (
            {
              workspace,
              monitor,
              ...
            }:
            "${workspace},monitor:${monitor.name}"
            + lib.optionalString (workspace == toString monitor.defaultWorkspace) ",default:true"
          ) monitors;
        };
    };

    # hyprland crash reports
    custom.persist = {
      home.cache.directories = [ ".cache/hyprland" ];
    };
  };
}
