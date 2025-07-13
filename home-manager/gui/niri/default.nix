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
    forEach
    listToAttrs
    mkIf
    mkMerge
    mod
    ;
in
{
  imports = [
    ./keybinds.nix
    ./startup.nix
  ];

  config = mkIf (config.custom.wm == "niri") {
    programs.niri = {
      enable = true;
      package = pkgs.niri;

      settings = mkMerge [
        {
          environment = {
            DISPLAY = ":0";
            NIXOS_OZONE_WL = "1";
          };

          input = {
            keyboard = {
              xkb = {
                layout = "us";
              };

              numlock = true;
            };

            touchpad = {
              enable = isLaptop;
              tap = true;
              dwt = true; # disable while typing
              # drag = false;
              natural-scroll = false;
            };

            mouse = {
              natural-scroll = false;
            };

            # setting max-scroll-amount="0%" makes it work only on windows already fully on screen.
            focus-follows-mouse = {
              enable = true;
              max-scroll-amount = "95%";
            };
          };

          # Settings that influence how windows are positioned and sized.
          layout =
            let
              gap = if host == "desktop" then 8 else 4;
            in
            {
              gaps = gap;

              # When to center a column when changing focus, options are:
              # - "never", default behavior, focusing an off-screen column will keep at the left
              #   or right edge of the screen.
              # - "always", the focused column will always be centered.
              # - "on-overflow", focusing a column will center it if it doesn't fit
              #   together with the previously focused column.
              center-focused-column = "never";
              always-center-single-column = true;

              # widths that "switch-preset-column-width" (Mod+R) toggles between.
              preset-column-widths = [
                { proportion = 0.33333; }
                { proportion = 0.5; }
                { proportion = 0.66667; }
              ];

              # heights that "switch-preset-window-height" (Mod+Shift+R) toggles between.
              preset-window-heights = [
                { proportion = 0.33333; }
                { proportion = 0.5; }
                { proportion = 0.66667; }
              ];

              # default width of the new windows, empty for deciding initial width
              default-column-width = {
                proportion = 0.5;
              };

              focus-ring = {
                width = 2;

                # ring on active / inactive monitor
                active = {
                  color = "#7fc8ff";
                };
                inactive = {
                  color = "#505050";
                };

                # TODO: gradients?
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

              # redundant, use focus-ring instead
              border.enable = false;

              # TODO: update shadow settings
              shadow = {
                enable = !isVm;

                # By default, the shadow draws only around its window, and not behind it.
                # draw-behind-window = true;

                # You can change how shadows look. The values below are in logical
                # pixels and match the CSS box-shadow properties.

                # Softness controls the shadow blur radius.
                softness = 30;
                spread = 4;

                # offset = { x = 0; y = 5; };

                color = "#1a1a1aee";
              };

              # outer gaps
              struts = {
                left = gap;
                right = gap;
                top = gap;
                bottom = gap;
              };
            };

          # no client-side decorations
          prefer-no-csd = true;

          animations = { };

          cursor = {
            theme = config.home.pointerCursor.name;
            inherit (config.home.pointerCursor) size;
          };

          # match focal format
          screenshot-path = "${config.xdg.userDirs.pictures}/Screenshots/%Y-%m-%dT%H:%M:%S%z.png";

          window-rules = [
            # rounded corners for all windows
            {
              geometry-corner-radius =
                let
                  radius = 4.0;
                in
                {
                  top-left = radius;
                  top-right = radius;
                  bottom-left = radius;
                  bottom-right = radius;
                };
              clip-to-geometry = true;
              draw-border-with-background = false;
            }
          ];

          # set blurred wallpaper backdrop for overview
          layer-rules = [
            {
              # namespaced swww-daemon layer is named "swww-daemonbackdrop"
              matches = [ { namespace = "^swww-daemonbackdrop$"; } ];
              place-within-backdrop = true;
            }
          ];

          hotkey-overlay = {
            skip-at-startup = true;
          };
        }

        # create monitors config
        {
          outputs = listToAttrs (
            forEach config.custom.monitors (d: {
              inherit (d) name;
              value = {
                mode = {
                  inherit (d) width height;
                  # just use highest refresh rate by not setting it
                  # refresh = d.refreshRate * 1.0;
                };
                position = {
                  x = d.position-x;
                  y = d.position-y;
                };
                variable-refresh-rate = d.vrr;
                transform = {
                  rotation = mod (d.transform * 90) 360;
                  flipped = d.transform > 3;
                };
                inherit (d) scale;
              };
            })
          );
        }
      ];
    };
  };
}
