{
  config,
  host,
  isLaptop,
  lib,
  pkgs,
  ...
}: let
  displays = config.iynaix.displays;
  isVm = host == "vm" || host == "vm-amd";
in {
  imports = [
    ./hyprnstack.nix
    ./keybinds.nix
    ./lock.nix
    ./screenshot.nix
    ./startup.nix
    ./wallpaper.nix
    ./waybar.nix
  ];

  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    home = {
      sessionVariables = {
        XCURSOR_SIZE = "${toString config.home.pointerCursor.size}";
        HYPR_LOG = "/tmp/hypr/$(command ls -t /tmp/hypr/ | grep -v lock | head -n 1)/hyprland.log";
      };

      shellAliases = {
        hypr-log = "less /tmp/hypr/$(command ls -t /tmp/hypr/ | grep -v lock | head -n 1)/hyprland.log";
      };

      packages = with pkgs; [
        # clipboard history
        cliphist
        wl-clipboard
      ];
    };

    wayland.windowManager.hyprland.settings = lib.mkMerge [
      {
        monitor =
          (lib.forEach displays ({
            name,
            hyprland,
            ...
          }: "${name}, ${hyprland}"))
          ++ (lib.optional (host != "desktop") ",preferred,auto,auto");

        input = {
          kb_layout = "us";
          follow_mouse = 1;

          touchpad = {
            natural_scroll = false;
            disable_while_typing = true;
          };
        };

        "$mod" =
          if isVm
          then "ALT"
          else "SUPER";

        "$term" = "${config.iynaix.terminal.exec}";

        general = let
          gap =
            if host == "desktop"
            then 8
            else 4;
        in {
          gaps_in = gap;
          gaps_out = gap;
          border_size = 2;
          layout = "master";
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

          animation = [
            "windows, 1, 5, overshot, slide"
            "windowsOut, 1, 4, smoothOut, slide"
            "windowsMove, 1, 4, smoothIn, slide"
            "border, 1, 5, default"
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
          new_is_master = false;
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
          mouse_move_enables_dpms = true;
          # animate_manual_resizes = true;
          # animate_mouse_windowdragging = true;
          # key_press_enables_dpms = true;
          enable_swallow = false;
          swallow_regex = "^([Kk]itty|[Ww]ezterm)$";
        };

        debug.disable_logs = false;

        # bind workspaces to monitors
        workspace = lib.concatMap ({
          name,
          workspaces,
          ...
        }:
          lib.forEach workspaces (ws: "${toString ws}, monitor:${name}"))
        displays;

        windowrulev2 = [
          # "dimaround,floating:1"
          "bordersize 5,fullscreen:1" # monocle mode
          "float,class:(wlroots)" # hyprland debug session
        ];

        windowrule = [
          # do not idle while watching videos
          "idleinhibit fullscreen,Brave-browser"
          "idleinhibit fullscreen,firefox-aurora"
          "idleinhibit focus,YouTube"
          "idleinhibit focus,mpv"
        ];

        exec-once = [
          # clipboard manager
          "wl-paste --watch cliphist store"
        ];

        # source = "~/.config/hypr/hyprland-test.conf";
      }
      # handle trackpad settings
      (lib.optionalAttrs isLaptop {
        gestures = {
          workspace_swipe = true;
        };

        # handle laptop lid
        bindl = [
          # ",switch:on:Lid Switch, exec, hyprctl keyword monitor ${displayCfg.monitor1}, 1920x1080, 0x0, 1"
          # ",switch:off:Lid Switch, exec, hyprctl monitor ${displayCfg.monitor1}, disable"
          ",switch:Lid Switch, exec, hypr-lock"
        ];
      })
    ];

    # hyprland crash reports
    iynaix.persist = {
      home.directories = [
        ".hyprland"
      ];
    };
  };
}
