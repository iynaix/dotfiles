{
  ...
}:
{
  imports = [ ./keybinds.nix ];

  config = {
    programs.niri.settings = {
      # Input device configuration
      input = {
        keyboard = {
          xkb = {
            # You can set rules, model, layout, variant and options.
            # For more information, see xkeyboard-config(7).
            # For example:
            # layout = "us,ru";
            # options = "grp:win_space_toggle,compose:ralt,ctrl:nocaps";
          };

          # Enable numlock on startup, omitting this setting disables it.
          numlock = true;
        };

        # Next sections include libinput settings.
        # Omitting settings disables them, or leaves them at their default values.
        # All commented-out settings here are examples, not defaults.
        touchpad = {
          # off = true;
          tap = true;
          # dwt = true;
          # dwtp = true;
          # drag = false;
          # drag-lock = true;
          natural-scroll = true;
          # accel-speed = 0.2;
          # accel-profile = "flat";
          # scroll-method = "two-finger";
          # disabled-on-external-mouse = true;
        };

        mouse = {
          # off = true;
          # natural-scroll = true;
          # accel-speed = 0.2;
          # accel-profile = "flat";
          # scroll-method = "no-scroll";
        };

        trackpoint = {
          # off = true;
          # natural-scroll = true;
          # accel-speed = 0.2;
          # accel-profile = "flat";
          # scroll-method = "on-button-down";
          # scroll-button = 273;
          # scroll-button-lock = true;
          # middle-emulation = true;
        };

        # Uncomment this to make the mouse warp to the center of newly focused windows.
        # warp-mouse-to-focus = true;

        # Focus windows and outputs automatically when moving the mouse into them.
        # Setting max-scroll-amount="0%" makes it work only on windows already fully on screen.
        # focus-follows-mouse = { max-scroll-amount = "0%"; };
      };

      # You can configure outputs by their name, which you can find
      # by running `niri msg outputs` while inside a niri instance.
      # The built-in laptop monitor is usually called "eDP-1".
      # outputs."eDP-1" = {
      #   # Uncomment this line to disable this output.
      #   # off = true;
      #
      #   # Resolution and, optionally, refresh rate of the output.
      #   mode = "1920x1080@120.030";
      #
      #   # You can use integer or fractional scale, for example use 1.5 for 150% scale.
      #   scale = 2;
      #
      #   # Transform allows to rotate the output counter-clockwise, valid values are:
      #   # normal, 90, 180, 270, flipped, flipped-90, flipped-180 and flipped-270.
      #   transform = "normal";
      #
      #   # Position of the output in the global coordinate space.
      #   position = { x = 1280; y = 0; };
      # };

      # Settings that influence how windows are positioned and sized.
      layout = {
        # Set gaps around windows in logical pixels.
        gaps = 16;

        # When to center a column when changing focus, options are:
        # - "never", default behavior, focusing an off-screen column will keep at the left
        #   or right edge of the screen.
        # - "always", the focused column will always be centered.
        # - "on-overflow", focusing a column will center it if it doesn't fit
        #   together with the previously focused column.
        center-focused-column = "never";

        # You can customize the widths that "switch-preset-column-width" (Mod+R) toggles between.
        preset-column-widths = [
          # Proportion sets the width as a fraction of the output width, taking gaps into account.
          # For example, you can perfectly fit four windows sized "proportion 0.25" on an output.
          # The default preset widths are 1/3, 1/2 and 2/3 of the output.
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66667; }

          # Fixed sets the width in logical pixels exactly.
          # { fixed = 1920; }
        ];

        # You can also customize the heights that "switch-preset-window-height" (Mod+Shift+R) toggles between.
        # preset-window-heights = [];

        # You can change the default width of the new windows.
        default-column-width = {
          proportion = 0.5;
        };
        # If you leave the brackets empty, the windows themselves will decide their initial width.
        # default-column-width = {};

        # You can change how the focus ring looks.
        focus-ring = {
          # Uncomment this line to disable the focus ring.
          # off = true;

          # How many logical pixels the ring extends out from the windows.
          width = 4;

          # Color of the ring on the active monitor.
          active = {
            color = "#7fc8ff";
          };

          # Color of the ring on inactive monitors.
          inactive = {
            color = "#505050";
          };

          # You can also use gradients. They take precedence over solid colors.
          # active-gradient = {
          #   from = "#80c8ff";
          #   to = "#c7ff7f";
          #   angle = 45;
          # };

          # inactive-gradient = {
          #   from = "#505050";
          #   to = "#808080";
          #   angle = 45;
          #   relative-to = "workspace-view";
          # };
        };

        # You can also add a border. It's similar to the focus ring, but always visible.
        border = {
          # The settings are the same as for the focus ring.
          # If you enable the border, you probably want to disable the focus ring.
          enable = false;

          width = 4;
          active = {
            color = "#ffc87f";
          };
          inactive = {
            color = "#505050";
          };

          # Color of the border around windows that request your attention.
          urgent = {
            color = "#9b0000";
          };

          # active-gradient = {
          #   from = "#e5989b";
          #   to = "#ffb4a2";
          #   angle = 45;
          #   relative-to = "workspace-view";
          #   in = "oklch longer hue";
          # };

          # inactive-gradient = {
          #   from = "#505050";
          #   to = "#808080";
          #   angle = 45;
          #   relative-to = "workspace-view";
          # };
        };

        # You can enable drop shadows for windows.
        shadow = {
          # Uncomment the next line to enable shadows.
          # on = true;

          # By default, the shadow draws only around its window, and not behind it.
          # draw-behind-window = true;

          # You can change how shadows look. The values below are in logical
          # pixels and match the CSS box-shadow properties.

          # Softness controls the shadow blur radius.
          softness = 30;

          # Spread expands the shadow.
          spread = 5;

          # Offset moves the shadow relative to the window.
          offset = {
            x = 0;
            y = 5;
          };

          # You can also change the shadow color and opacity.
          color = "#0007";
        };

        # Struts shrink the area occupied by windows, similarly to layer-shell panels.
        struts = {
          # left = 64;
          # right = 64;
          # top = 64;
          # bottom = 64;
        };
      };

      # Add lines like this to spawn processes at startup.
      spawn-at-startup = [
      ];
      # Uncomment this line to ask the clients to omit their client-side decorations if possible.
      # prefer-no-csd = true;

      # You can change the path where screenshots are saved.
      # A ~ at the front will be expanded to the home directory.
      # The path is formatted with strftime(3) to give you the screenshot date and time.
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

      # You can also set this to null to disable saving screenshots to disk.
      # screenshot-path = null;

      # Animation settings.
      animations = {
        # Uncomment to turn off all animations.
        # off = true;

        # Slow down all animations by this factor. Values below 1 speed them up instead.
        # slowdown = 3.0;
      };

      # Window rules let you adjust behavior for individual windows.
      window-rules = [
        # Work around WezTerm's initial configure bug
        # by setting an empty default-column-width.
        {
          matches = [
            {
              app-id = "^org\.wezfurlong\.wezterm$";
            }
          ];
          default-column-width = { };
        }

        # Open the Firefox picture-in-picture player as floating by default.
        {
          matches = [
            {
              app-id = "firefox$";
              title = "^Picture-in-Picture$";
            }
          ];
          open-floating = true;
        }

        # Example: block out two password managers from screen capture.
        # {
        #   match = {
        #     app-id = "^org\.keepassxc\.KeePassXC$|^org\.gnome\.World\.Secrets$";
        #   };
        #   block-out-from = "screen-capture";
        #   # Use this instead if you want them visible on third-party screenshot tools.
        #   # block-out-from = "screencast";
        # }

        # Example: enable rounded corners for all windows.
        # {
        #   geometry-corner-radius = 12;
        #   clip-to-geometry = true;
        # }
      ];
    };
  };
}
