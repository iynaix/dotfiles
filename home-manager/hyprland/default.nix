{
  config,
  host,
  isLaptop,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.custom) monitors;
  isVm = host == "vm" || host == "vm-amd";
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
    ./waybar.nix
  ];

  config = lib.mkIf config.custom.hyprland.enable {
    home = {
      packages = with pkgs; [
        # clipboard history
        cliphist
        wl-clipboard
      ];
    };

    custom.shell.packages = {
      hypr-log = {
        runtimeInputs = [ pkgs.bat ];
        text = ''
          instanceDir=$(find "$XDG_RUNTIME_DIR/hypr" -maxdepth 1 -mindepth 1 -type d | sort | head -n 1)
          bat "$instanceDir/hyprland.log"
        '';
      };
    };

    wayland.windowManager.hyprland = {
      enable = true;
      # package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      package = pkgs.hyprland;

      settings = {
        monitor =
          (lib.forEach monitors (
            d:
            lib.concatStringsSep "," (
              [
                d.name
                "${toString d.width}x${toString d.height}@${toString d.refreshRate}"
                d.position
                "1" # scale
              ]
              ++ lib.optionals d.vertical [ "transform,1" ]
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
          drop_shadow = !isVm;
          shadow_range = 4;
          shadow_render_power = 3;
          "col.shadow" = "rgba(1a1a1aee)";

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

        # bind workspaces to monitors
        workspace = pkgs.custom.lib.mapWorkspaces (
          { workspace, monitor, ... }: "${workspace},monitor:${monitor.name}"
        ) monitors;

        windowrulev2 = [
          # "dimaround,floating:1"
          "bordersize 5,fullscreen:1" # monocle mode
          "float,class:(wlroots)" # hyprland debug session
        ];

        windowrule = [
          # do not idle while watching videos
          "idleinhibit focus,YouTube"
        ];

        exec-once = [
          # clipboard manager
          "wl-paste --watch cliphist store"
        ];

        # handle trackpad settings
        gestures = lib.mkIf isLaptop { workspace_swipe = true; };
      };
    };

    # hyprland crash reports
    custom.persist = {
      home.directories = [ ".cache/hyprland" ];
    };
  };
}
