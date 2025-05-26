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
  inherit (lib)
    concatStringsSep
    forEach
    getExe
    length
    mkDefault
    mkEnableOption
    mkIf
    optionalAttrs
    optionalString
    optionals
    ;
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

  options.custom = {
    hyprland = {
      enable = mkEnableOption "hyprland" // {
        default = !config.custom.headless;
      };
      hyprnstack = mkEnableOption "hyprnstack";
      hypr-darkwindow = mkEnableOption "hypr-darkwindow" // {
        default = true;
      };
    };
  };

  config = mkIf config.custom.hyprland.enable {
    home = {
      shellAliases = {
        hyprland = "Hyprland";
        hypr-log = "hyprctl rollinglog --follow";
      };
    };

    wayland.windowManager.hyprland = {
      enable = true;
      # package = pkgs.hyprland;
      # package =
      #   assert (assertMsg (versionOlder config.programs.hyprland.package.version "0.42") "hyprland: use version from nixpkgs?");
      #   inputs.hyprland.packages.${pkgs.system}.hyprland;

      # https://wiki.hyprland.org/Useful-Utilities/Systemd-start/#installation
      # conflicts with programs.hyprland.withUWSM in nixos
      systemd.enable = false;

      plugins = optionals config.custom.hyprland.hypr-darkwindow [
        # always build with actual hyprland to keep versions in sync
        (pkgs.custom.hypr-darkwindow.override {
          hyprland = config.wayland.windowManager.hyprland.package;
        })
      ];

      settings =
        {
          monitor =
            (forEach monitors (
              d:
              concatStringsSep "," (
                [
                  d.name
                  "${toString d.width}x${toString d.height}@${toString d.refreshRate}"
                  d.position
                  (toString d.scale)
                ]
                ++ optionals (d.transform != 0) [ "transform,${toString d.transform}" ]
                ++ optionals d.vrr [ "vrr,1" ]
              )
            ))
            ++ [ ",preferred,auto,auto" ];

          input = {
            kb_layout = "us";
            follow_mouse = 1;

            touchpad = mkIf isLaptop {
              natural_scroll = false;
              disable_while_typing = true;
              clickfinger_behavior = true;
            };
          };

          "$mod" = if isVm then "ALT" else "SUPER";

          "$term" = "${getExe config.custom.terminal.package}";
          "$termexec" = "${config.custom.terminal.exec}";

          general =
            let
              gap = if host == "desktop" then 8 else 4;
            in
            {
              gaps_in = gap;
              gaps_out = gap;
              border_size = 2;
              layout = mkDefault "master";
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

          ecosystem = {
            no_update_news = true;
            no_donation_nag = true;
          };

          debug = {
            disable_logs = false;
          };

          windowrule = [
            # "dimaround,floating:1"
            "bordersize 5,fullscreen:1" # monocle mode
            "float,class:(wlroots)" # hyprland debug session
            # save dialog
            "float,class:(xdg-desktop-portal-gtk)"
            "size <50% <50%,class:(xdg-desktop-portal-gtk)"
          ];

          # handle trackpad settings
          gestures = mkIf isLaptop { workspace_swipe = true; };
        }
        //
          # bind workspaces to monitors, don't bother if there is only one monitor
          optionalAttrs (length monitors > 1) {
            workspace = lib.custom.mapWorkspaces (
              {
                workspace,
                monitor,
                ...
              }:
              "${workspace},monitor:${monitor.name}"
              + optionalString (workspace == toString monitor.defaultWorkspace) ",default:true"
            ) monitors;
          }
        //
          # nvidia specific settings
          optionalAttrs config.custom.nvidia.enable {
            cursor = {
              # no_hardware_cursors = true;
              use_cpu_buffer = 1;
            };

            render = {
              explicit_sync = 1;
              # allow_early_buffer_release = true;
            };
          };
    };

    # hyprland crash reports
    custom.persist = {
      home.cache.directories = [ ".cache/hyprland" ];
    };
  };
}
