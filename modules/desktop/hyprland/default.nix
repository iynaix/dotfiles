{ pkgs, host, user, lib, config, inputs, ... }:
let
  cfg = config.iynaix.hyprland;
  displays = config.iynaix.displays;
  mod = if host == "vm" then "ALT" else "SUPER";
  # functions for creating hyprland config
  # https://github.com/hyprwm/Hyprland/pull/870#issuecomment-1319448768
  mkValueString = value: (
    if builtins.isBool value then (if value then "true" else "false")
    else if (builtins.isFloat value || builtins.isInt value) then (builtins.toString value)
    else if builtins.isString value then (value)
    else if (
      (builtins.isList value) &&
      ((builtins.length value) == 2) &&
      ((builtins.isFloat (builtins.elemAt value 0)) || (builtins.isFloat (builtins.elemAt value 0))) &&
      ((builtins.isFloat (builtins.elemAt value 1)) || (builtins.isFloat (builtins.elemAt value 1)))
    ) then (builtins.toString (builtins.elemAt value 0) + " " + builtins.toString (builtins.elemAt value 1))
    else abort "Unhandled value type ${builtins.typeOf value}"
  );
  concatAttrs = arg: func: (
    assert builtins.isAttrs arg;
    builtins.concatStringsSep "\n" (lib.attrsets.mapAttrsToList func arg)
  );
  mkHyprlandVariables = arg: (
    concatAttrs arg (
      name: value: name + (
        if builtins.isAttrs value then (" {\n" + (mkHyprlandVariables value) + "\n}")
        else " = " + mkValueString value
      )
    )
  );
  mkHyprlandBinds = arg: (
    concatAttrs arg (
      name: value: (
        if builtins.isList value then
          (
            builtins.concatStringsSep "\n" (builtins.map (x: name + " = " + x) value)
          )
        else
          concatAttrs value (
            name2: value2: name + " = " + name2 + "," + (assert builtins.isString value2; value2)
          )
      )
    )
  );
in
{
  imports = [
    ./nvidia.nix
    ./screenshot.nix
    ./startup.nix
    ./waybar.nix
    ./wallpaper.nix
  ];

  options.iynaix.hyprland = {
    # mutually exclusive with bspwm
    enable = lib.mkEnableOption "Hyprland" // {
      default = (!config.iynaix.bspwm && !config.iynaix.gnome3);
    };
    keybinds = lib.mkOption {
      type = with lib.types; attrsOf str;
      description = ''
        Keybinds for Hyprland, see
        https://wiki.hyprland.org/Configuring/Binds/
      '';
      example = ''{
        "SUPER, Return" = "exec, kitty";
      }'';
      default = { };
    };
    monitors = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Config for monitors, see
        https://wiki.hyprland.org/Configuring/Monitors/
      '';
    };
    extraVariables = lib.mkOption {
      type = with lib.types; attrsOf unspecified;
      default = { };
      description = "Extra variable config for Hyprland";
    };
    extraBinds = lib.mkOption {
      type = with lib.types; attrsOf unspecified;
      default = { };
      description = "Extra binds for Hyprland";
    };
  };

  config = lib.mkIf cfg.enable {
    services.xserver.desktopManager.gnome.enable = lib.mkForce false;
    services.xserver.displayManager.lightdm.enable = lib.mkForce false;
    # services.xserver.displayManager.sddm.enable = lib.mkForce true;

    services.greetd = {
      enable = true;
      settings = {
        default_session.command = "${pkgs.greetd.greetd}/bin/agreety --cmd Hyprland";

        initial_session = {
          command = "Hyprland";
          inherit user;
        };
      };
    };

    home-manager.users.${user} = {
      imports = [ inputs.hyprland.homeManagerModules.default ];

      programs.rofi = {
        package = pkgs.rofi-wayland;
        extraConfig = {
          modi = "run,drun";
        };
      };

      home = {
        sessionVariables = {
          "XCURSOR_SIZE" = "24";
        };

        packages = with pkgs; [
          pciutils
          socat
          # clipboard history
          cliphist
          wl-clipboard
        ];
      };

      wayland.windowManager.hyprland =
        let
          xrdb = lib.mapAttrs (name: value: (lib.substring 1 50 value)) config.iynaix.xrdb;
        in
        {
          enable = true;
          systemdIntegration = true;
          xwayland.hidpi = false;
          extraConfig = lib.concatStringsSep "\n" [
            # monitors
            cfg.monitors
            # handles displays that are plugged in
            "monitor=,preferred,auto,auto"
            (mkHyprlandVariables {
              input = {
                kb_layout = "us";
                follow_mouse = 1;

                touchpad = {
                  natural_scroll = false;
                  disable_while_typing = true;
                };
              };

              general = {
                gaps_in = if host == "desktop" then 8 else 4;
                gaps_out = if host == "desktop" then 8 else 4;
                border_size = 2;

                # "col.inactive_border" = "rgba(595959aa)";
                # "col.active_border" = "rgba(${xrdb.color4}ee) rgba(${xrdb.color2}55)";
                "col.active_border" = "rgb(${xrdb.color4})";
                "col.inactive_border" = "rgb(${xrdb.color0})";

                layout = "master";
              };

              decoration = {
                rounding = 8;
                blur = true;
                blur_size = 3;
                blur_passes = 1;
                blur_new_optimizations = true;

                drop_shadow = true;
                shadow_range = 4;
                shadow_render_power = 3;
                "col.shadow" = "rgba(1a1a1aee)";

                # dim_inactive = true;
                # dim_strength = 0.05;
              };

              animations = {
                enabled = true;
              };

              dwindle = {
                pseudotile = true; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
                preserve_split = true; # you probably want this
              };

              master = {
                new_is_master = false;
                mfact = 0.5;
              };

              binds = {
                workspace_back_and_forth = true;
              };

              misc = {
                disable_splash_rendering = true;
                mouse_move_enables_dpms = true;
                # key_press_enables_dpms = true;
                enable_swallow = true;
                swallow_regex = "[Kk]itty|[Aa]lacritty";
              };
            })
            (mkHyprlandVariables cfg.extraVariables)
            (mkHyprlandBinds
              {
                bind = {
                  "${mod}, Return" = "exec, kitty";
                  "${mod}_SHIFT, Return" = "exec, rofi -show drun";
                  "${mod}, BackSpace" = "killactive,";
                  "${mod}, e" = "exec, nemo ~/Downloads";
                  "${mod}_SHIFT, e" = "exec, kitty ranger ~/Downloads";
                  "${mod}, w" = "exec, brave";
                  "${mod}_SHIFT, w" = "exec, brave --incognito";
                  "${mod}, v" = "exec, kitty nvim";
                  "${mod}_SHIFT, v" = "exec, code";

                  "CTRL_ALT, Delete" = ''exec, rofi -show power-menu -font "${config.iynaix.font.regular} 14" -modi power-menu:rofi-power-menu'';
                  "${mod}_CTRL, v" = "exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy";

                  # reload
                  "CTRL_SHIFT, Escape" = "forcerendererreload";

                  # bind = ${mod}, P, pseudo, # dwindle
                  # bind = ${mod}, J, togglesplit, # dwindle

                  # Move focus with mainMod + arrow keys
                  # "${mod}, left" = "movefocus, l";
                  # "${mod}, right" = "movefocus, r";
                  # "${mod}, up" = "movefocus, u";
                  # "${mod}, down" = "movefocus, d";

                  "${mod}, h" = "movefocus, l";
                  "${mod}, l" = "movefocus, r";
                  "${mod}, j" = "movefocus, u";
                  "${mod}, k" = "movefocus, d";

                  "${mod}_SHIFT, h" = "movewindow, l";
                  "${mod}_SHIFT, l" = "movewindow, r";
                  "${mod}_SHIFT, j" = "movewindow, u";
                  "${mod}_SHIFT, k" = "movewindow, d";

                  # Switch workspaces with mainMod + [0-9]
                  "${mod}, 1" = "workspace, 1";
                  "${mod}, 2" = "workspace, 2";
                  "${mod}, 3" = "workspace, 3";
                  "${mod}, 4" = "workspace, 4";
                  "${mod}, 5" = "workspace, 5";
                  "${mod}, 6" = "workspace, 6";
                  "${mod}, 7" = "workspace, 7";
                  "${mod}, 8" = "workspace, 8";
                  "${mod}, 9" = "workspace, 9";
                  "${mod}, 0" = "workspace, 10";

                  # Move active window to a workspace with mainMod + SHIFT + [0-9]
                  "${mod}_SHIFT, 1" = "movetoworkspace, 1";
                  "${mod}_SHIFT, 2" = "movetoworkspace, 2";
                  "${mod}_SHIFT, 3" = "movetoworkspace, 3";
                  "${mod}_SHIFT, 4" = "movetoworkspace, 4";
                  "${mod}_SHIFT, 5" = "movetoworkspace, 5";
                  "${mod}_SHIFT, 6" = "movetoworkspace, 6";
                  "${mod}_SHIFT, 7" = "movetoworkspace, 7";
                  "${mod}_SHIFT, 8" = "movetoworkspace, 8";
                  "${mod}_SHIFT, 9" = "movetoworkspace, 9";
                  "${mod}_SHIFT, 0" = "movetoworkspace, 10";

                  "${mod}, b" = "layoutmsg, swapwithmaster";

                  # set master to vertical on every navigation to the workspace
                  # "${mod}, 6" = "layoutmsg, orientationtop";
                  # "${mod}, 7" = "layoutmsg, orientationtop";
                  # "${mod}, 8" = "layoutmsg, orientationtop";

                  # "${mod}_SHIFT, 6" = "layoutmsg, orientationtop";
                  # "${mod}_SHIFT, 7" = "layoutmsg, orientationtop";
                  # "${mod}_SHIFT, 8" = "layoutmsg, orientationtop";

                  # focus the previous / next desktop in the current monitor (DE style)
                  "CTRL_ALT, Left" = "workspace, m-1";
                  "CTRL_ALT, Right" = "workspace, m+1";

                  # monocle mode
                  "${mod}, z" = "fullscreen, 1";

                  # fullscreen
                  "${mod}, f" = "fullscreen, 0";
                  "${mod}_SHIFT, f" = "fakefullscreen";

                  # floating
                  "${mod}, g" = "togglefloating";

                  # sticky
                  "${mod}, s" = "pin";

                  # focus next / previous monitor
                  "${mod}, Left" = "focusmonitor, -1";
                  "${mod}, Right" = "focusmonitor, +1";

                  # move to next / previous monitor
                  "${mod}_SHIFT, Left" = "movewindow, mon:-1";
                  "${mod}_SHIFT, Right" = "movewindow, mon:+1";

                  "ALT, Tab" = "cyclenext";
                  "ALT_SHIFT, Tab" = "cyclenext, prev";

                  # toggle between previous and current window
                  "${mod}, grave" = "focuscurrentorlast";

                  # add / remove master windows
                  "${mod}, m" = "layoutmsg, addmaster";
                  "${mod}_SHIFT, m" = "layoutmsg, removemaster";

                  # rotate via switching master orientation
                  "${mod}, r" = "layoutmsg, orientationnext";
                  "${mod}_SHIFT, r" = "layoutmsg, orientationprev";

                  # Scroll through existing workspaces with mainMod + scroll
                  "${mod}, mouse_down" = "workspace, e+1";
                  "${mod}, mouse_up" = "workspace, e-1";

                  # lock monitors
                  "${mod}_SHIFT_CTRL, l" = "dpms, off";

                  # TODO:
                  # special keys
                  # "XF86AudioPlay" = "mpvctl playpause";

                  # equalize size of windows at parent / root level
                  # "${mod} + {_,ctrl + }equal" = "bspc node {@parent,@/} --balance";

                  # focus the next/previous node of the same class
                  # "${mod} + {_,shift + }Tab" = "bspc node -f {next,prev}.same_class";
                };

                # Move/resize windows with mainMod + LMB/RMB and dragging
                bindm = {
                  "${mod}, mouse:272" = "movewindow";
                  "${mod}, mouse:273" = "resizewindow";
                };

                # bind workspaces to monitors
                wsbind = {
                  "1" = displays.monitor1;
                  "2" = displays.monitor1;
                  "3" = displays.monitor1;
                  "4" = displays.monitor1;
                  "5" = displays.monitor1;
                  "6" = displays.monitor2;
                  "7" = displays.monitor2;
                  "8" = displays.monitor2;
                  "9" = displays.monitor3;
                  "10" = displays.monitor3;
                };

                windowrulev2 = [
                  # pink border for monocle windows
                  "bordercolor rgb(${xrdb.color5}),fullscreen:1"
                  # teal border for floating windows
                  "bordercolor rgb(${xrdb.color6}),floating:1"
                  # yellow border for sticky (must be floating) windows
                  "bordercolor rgb(${xrdb.color3}),pinned:1"
                ];

                exec = [
                  "hyprpaper" # reload wallpaper every time
                ];

                exec-once = [
                  # clipboard manager
                  "wl-paste - -watch cliphist store"
                ];
              })
            (mkHyprlandBinds cfg.extraBinds)
          ];
        };
    };
  };
}
