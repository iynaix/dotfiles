{
  tags = [ "wm" ];

  config =
    {
      config,
      host,
      lib,
      libCustom,
      tags,
      ...
    }:
    {
      custom.programs = {
        umbriel.settings =
          let
            gap = if host == "desktop" then 8 else 4;
            strut = gap + 12;
          in
          {
            output =
              config.custom.hardware.monitors
              |> lib.map (
                d:
                let
                  rotation = toString (lib.mod (d.transform * 90) 360);
                  flipped = d.transform > 3;
                in
                {
                  inherit (d) name;
                  value = {
                    inherit (d) scale;
                    mode = "${toString d.width}x${toString d.height}@${toString d.refreshRate}";
                    position = [
                      d.x
                      d.y
                    ];
                    vrr = if d.vrr then "always" else "disabled";
                    hdr = if d.hdr then "fullscreen" else "off";
                    transform = "${lib.optionalString flipped "flipped-"}${
                      if rotation == "0" then "normal" else rotation
                    }";
                    workspaces = map toString d.workspaces;
                  };
                }
              )
              |> lib.listToAttrs;
          }
          //
            # setup vertical monitors if any
            (
              config.custom.hardware.monitors
              |> lib.concatMap (d: if d.transform == 1 || d.transform == 3 then d.workspaces else [ ])
              |> map (w: {
                workspace = [
                  {
                    name = toString w;
                    # layout.scrolling.direction = "vertical";
                    layout.mode = "dwindle";

                    # struts are unnecessary for dwindle
                    layout.struts = {
                      left = 0;
                      right = 0;
                      top = 0;
                      bottom = 0;
                    };
                  }
                ];
              })
              |> libCustom.recursiveMergeAttrsList
            )
          //
            # general umbriel settings
            {
              general = {
                mod_key = if (builtins.elem "vm" tags) then "Alt" else "Super"; # Mod in keybinds; defaults to Super (Alt when nested)
                xwayland = true; # requires restart to change
                show_cheatsheet = false;
                focus_on_activate = true; # unsolicited requests cannot add focus; trusted launches may still focus
                honor_restored_maximize = false; # let apps restore their saved maximized state
              };

              workspaces = {
                back_and_forth = true;
                empty_above = false;
              };

              animation = {
                enabled = true;
                duration_ms = 250; # 1-10000
                curve = "easeout";

                windows_in = {
                  enabled = true;
                  duration_ms = 150;
                  curve = "easeout";
                  style = "popin"; # popin, zoom, slide, fade, none
                  scale = 0.85; # 0.1-1.0, used by popin
                };

                windows_out = {
                  enabled = true;
                  duration_ms = 150;
                  curve = "easeout";
                  style = "fade"; # fade, slide
                };

                windows_move = {
                  enabled = true; # window move, resize, and floating maximize transitions
                  duration_ms = 250;
                  curve = "snappy";
                };

                workspaces = {
                  enabled = true;
                  duration_ms = 250;
                  curve = "easeout";
                };

                overview = {
                  enabled = true;
                  duration_ms = 250;
                  curve = "easeout";
                };

                scratchpad = {
                  enabled = false;
                  duration_ms = 250;
                  curve = "easeout";
                  dim = 0.5; # 0.0-1.0
                  blur = false;
                  scale = 0.0; # 0 preserves the window geometry
                  maximize = false;
                  fullscreen = false;
                };

                border = {
                  enabled = false;
                  duration_ms = 250;
                  curve = "easeout";
                };

                dim_unfocused = {
                  enabled = false;
                  duration_ms = 250;
                  curve = "easeout";
                  dim = 0.0; # 0.0-1.0
                };

                layers = {
                  enabled = false;
                  duration_ms = 250;
                  curve = "easeout";
                };
              };

              appearance = {
                prefer_no_csd = true; # false lets newly started apps draw their own decorations
                border_width = 2; # 0-100
                outer_border_width = 0; # 0-100
                corner_radius = 10; # 0-100, radius of the final decorated outer edge
                drag_opacity = 0.75;

                blur = {
                  enabled = true;
                  optimized = true;
                  passes = 3; # 0-8
                  radius = 3; # 0-100
                  noise = 0.02; # 0.0-1.0
                  brightness = 0.9; # 0.0-2.0
                  contrast = 0.9; # 0.0-2.0
                  saturation = 1.1; # 0.0-2.0
                };

                shadow = {
                  enabled = true;
                  softness = 10; # 0-200, 0 = hard edge
                  offset_x = 2; # -200 to 200
                  offset_y = 2;
                  color = "#0000007F";
                };
              };

              overview = {
                zoom = 0.5; # 0.1-0.75
                # Pinned windows stay hidden until overview closes; visible scratchpads are dismissed.
                # background_blur = true         # blur the wallpaper while the overview is open
                # background_tint = "#10101430"
                # workspace_background = "#00000044" # set alpha to FF for an opaque background
                # shortcuts = true
                # shortcut_keys = "1234567890" # favorite keys in preference order
                # badge_color = "#7AA3FFFF"   # defaults to colors.accent_primary
              };

              layout = {
                mode = "scrolling"; # "scrolling", "dwindle", or "master"
                # Inspect every workspace's effective mode with `umbriel workspaces --json`.
                inherit gap;
                width_presets = [
                  0.33333
                  0.5
                  0.66667
                  1.0
                ];

                struts = {
                  left = strut;
                  right = strut;
                  top = 0;
                  bottom = 0;
                };

                scrolling = {
                  default_width_fraction = 0.5; # remove to let clients choose their initial width
                  center_underfull_strip = true; # center the strip whenever it is narrower than the viewport
                  center_focused = false; # always center the focused column
                  expand_single_column = true; # fill lone column to viewport width
                };

                dwindle = {
                  # Keep each split direction fixed after it is created.
                  # preserve_split = false
                };

                master = {
                  position = "left"; # "left" or "right"
                  default_width_fraction = 0.5; # 0.1-0.9
                  new_on_top = true; # place new windows at the top of the stack
                };
              };

              # Workspace layout overrides (see docs/user/workspaces.md#workspace-rules)
              # [[workspace]]
              # name = "chat"
              # layout.mode = "dwindle"
              # layout.gap = 4
              # layout.struts.top = 24       # override one edge and inherit the others
              # layout.scrolling.center_underfull_strip = false
              # layout.dwindle.preserve_split = true

              input = {
                middle_click_paste = true; # primary-selection clipboard, applies on reload

                keyboard = {
                  # ASCII keybind fallback uses only layouts listed for this keyboard; a single
                  # non-Latin layout has no implicit Latin fallback.
                  layout = ""; # "us,de" loads both; switch with keyboard-layout-next
                  variant = "";
                  options = ""; # XKB options, e.g. "grp:alt_shift_toggle"
                  repeat_rate = 25; # 0-1000 Hz
                  repeat_delay = 600; # 0-10000 ms
                  numlock_toggle = true; # true enables NumLock when a keyboard connects; false leaves it off
                  track_layout = "global"; # "global", or "window" to track the layout per surface
                };

                touchpad = {
                  tap = true; # enabled by default; false disables tap-to-click
                  # natural_scroll = true
                  # accel_profile = "adaptive"    # "flat", "adaptive", or "custom <step> <points...>"
                  # sensitivity = 0.5             # pointer speed, -1.0 to 1.0
                  # scroll_factor = 1.5           # touchpad scroll speed, 0.1 to 10.0
                  # disable_while_typing = true   # omitted preserves the device's libinput default
                  # disable_on_external_mouse = true  # disable the touchpad while an external mouse is connected
                };

                mouse = {
                  # accel_profile = "flat"       # omitted preserves the device's libinput default
                  sensitivity = 0.0; # pointer speed, -1.0 to 1.0
                  scroll_wheel_step = 60; # 1-1000
                  # Override only the listed settings for an exact, case-sensitive device name.
                  # Applies per device kind: layout, variant, options, repeat_rate, and
                  # repeat_delay to keyboards; tap and disable_while_typing to touchpads;
                  # natural_scroll, accel_profile, and sensitivity to touchpads and mice.
                  # Find names with `libinput list-devices`.
                  # [[input.device]]
                  # name = "Acme Precision Touchpad"
                  # tap = true
                  # natural_scroll = false
                  # accel_profile = "flat"
                  # sensitivity = 0.0
                  # disable_while_typing = false
                };

                cursor = {
                  theme = config.custom.gtk.cursor.name;
                  size = config.custom.gtk.cursor.size;
                  hardware_cursor = true; # false forces software cursor composition
                  follows_focus = false; # warp to windows selected by focus navigation
                  hide_when_typing = false; # hide after typing unless a pointer button is held
                  hide_timeout_ms = 0; # 0-3600000, 0 disables hiding
                };

                focus = {
                  follows_mouse = false;
                  # Refuse hover focus when revealing the window would scroll further than this,
                  # measured in viewport widths (1.0 = one full screen). Omit for no limit.
                  # follows_mouse_max_scroll = 0.5
                };
              };

              # Blur all windows
              window_rule = [
                {
                  blur = true;
                  blur_optimized = true;
                }
                {
                  match.app_id = "^dev.noctalia.UmbrielSharePicker$";
                  default_floating = true;
                  default_size = [
                    800
                    600
                  ];
                }
                # Browsers do not expose a semantic PiP role or control global window position.
                {
                  match.title = "^(Picture-in-Picture|Picture in picture)$";
                  default_floating = true;
                  default_maximize = false;
                  default_position = {
                    x = 20;
                    y = 20;
                    anchor = "bottom_right";
                  };
                }
                # Size a float as fractions of the usable area instead of pixels, so the rule
                # suits any monitor. default_size wins on both axes when it is also set.
                # {
                #   match.app_id = "^org[.]example[.]Utility$";
                #   default_floating = true;
                #   default_width = 0.5;           # initial width as a fraction of the usable area
                #   default_height = 0.6;          # initial height as a fraction of the usable area
                # }
              ];
            };
      };
    };
}
