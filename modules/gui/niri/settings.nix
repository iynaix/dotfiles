{ lib, self, ... }:
{
  flake.nixosModules.wm =
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) host;
    in
    {
      custom.programs = {
        niri.settings = {
          layout = {
            gaps = if host == "desktop" then 8 else 4;

            struts = {
              left = 20;
              right = 20;
              top = 8;
              bottom = 8;
            };
            focus-ring = {
              width = 2;
              # overwritten by wallpaper script later
              active-gradient._attrs = {
                angle = 45;
                from = "#89B4FA";
                relative-to = "workspace-view";
                to = "#94E2D5";
              };
              inactive-color = "#1e1e2e";
            };
            border = {
              off = null;
            };
            shadow = {
              on = null;
              offset._attrs = {
                x = 0.0;
                y = 5.0;
              };
              softness = 30;
              spread = 4;
              draw-behind-window = false;
              color = "#1a1a1aee";
            };
            tab-indicator = {
              hide-when-single-tab = null;
              gap = 0;
              width = 12;
              length._attrs = {
                total-proportion = 1.0;
              };
              position = "top";
              gaps-between-tabs = 0.000000;
              corner-radius = 0.000000;
            };
            default-column-width = {
              proportion = 0.500000;
            };
            preset-column-widths = [
              { proportion = 0.33333; }
              { proportion = 0.50000; }
              { proportion = 0.66667; }
              { proportion = 1.00000; }
            ];
            preset-window-heights = [
              { proportion = 0.33333; }
              { proportion = 0.50000; }
              { proportion = 0.66667; }
              { proportion = 1.00000; }
            ];
            center-focused-column = "never";
            always-center-single-column = null;
          };

          # use blurred overview from noctalia
          layer-rules = [
            {
              matches = [ { namespace = "^noctalia-overview*"; } ];
              place-within-backdrop = true;
            }
          ];

          window-rules = [
            {
              draw-border-with-background = false;
              # rounded corners for all windows
              geometry-corner-radius = 4;
              clip-to-geometry = true;
              open-maximized-to-edges = false;
            }
          ];

          # create monitors config
          outputs =
            config.custom.hardware.monitors
            |> lib.imap1 (
              i: d:
              let
                rotation = toString (lib.mod (d.transform * 90) 360);
                flipped = d.transform > 3;
                isVertical = d.transform == 1 || d.transform == 3;
              in
              {
                inherit (d) name;
                value = {
                  inherit (d) scale;
                  mode = "${toString d.width}x${toString d.height}";
                  transform = "${lib.optionalString flipped "flipped-"}${
                    if rotation == "0" then "normal" else rotation
                  }";
                  position._attrs = {
                    inherit (d) x y;
                  };
                }
                // lib.optionalAttrs (i == 1) { focus-at-startup = null; }
                // lib.optionalAttrs d.vrr { variable-refresh-rate = null; }
                // lib.optionalAttrs isVertical {
                  layout = {
                    default-column-width = {
                      proportion = 1.0;
                    };
                  };
                };
              }
            )
            |> lib.listToAttrs;

          input = {
            keyboard = {
              xkb = {
                layout = "us";
                model = "";
                rules = "";
                variant = "";
              };
              repeat-delay = 600;
              repeat-rate = 25;
              track-layout = "global";
              numlock = null;
            };
            touchpad = {
              tap = null;
              dwt = null;
            };
            focus-follows-mouse._attrs = {
              max-scroll-amount = "95%";
            };
            workspace-auto-back-and-forth = null;
            disable-power-key-handling = null;
          };

          prefer-no-csd = null;

          gestures = {
            hot-corners = {
              off = null;
            };
          };

          cursor = {
            xcursor-theme = config.custom.gtk.cursor.name;
            xcursor-size = config.custom.gtk.cursor.size;
          };

          recent-windows.binds = {
            "Alt+Tab" = {
              next-window._attrs = {
                scope = "output";
              };
            };
            "Alt+Shift+Tab" = {
              previous-window._attrs = {
                scope = "output";
              };
            };
            "Ctrl+Alt+Tab" = {
              next-window._attrs = {
                scope = "all";
                filter = "app-id";
              };
            };
            "Ctrl+Alt+Shift+Tab" = {
              previous-window._attrs = {
                scope = "all";
                filter = "app-id";
              };
            };
          };

          screenshot-path = "${config.hj.directory}/Pictures/Screenshots/%Y-%m-%dT%H:%M:%S%z.png";

          debug = {
            honor-xdg-activation-with-invalid-serial = null;
          };

          hotkey-overlay = {
            skip-at-startup = null;
          };

          clipboard = {
            disable-primary = null;
          };

          overview = {
            zoom = 0.4;
          };

          xwayland-satellite = {
            path = lib.getExe pkgs.xwayland-satellite;
          };

          # final include right at the end of the file
          extraConfig = lib.mkMerge [
            # don't use the workspaces key in setting as attrset keys are unordered and it becomes 1, 10, 2, 3...
            (
              config.custom.hardware.monitors
              |> self.libCustom.mapWorkspaces (
                {
                  workspace,
                  monitor,
                  ...
                }:
                ''workspace "${toString workspace}" { open-on-output "${monitor.name}"; }''
              )
              |> lib.concatLines
            )
            # always source original config.kdl at the end
            (lib.mkAfter ''
              include optional=true "${config.hj.xdg.config.directory}/niri/config.kdl";
            '')
          ];
        };
      };
    };
}
