{ lib, self, ... }:
{
  flake.nixosModules.wm =
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) host;
    in
    {
      custom.programs = {
        niri.settings.config = lib.mkMerge [
          /* kdl */ ''
            input {
                keyboard {
                    xkb {
                        layout "us"
                        model ""
                        rules ""
                        variant ""
                    }
                    repeat-delay 600
                    repeat-rate 25
                    track-layout "global"
                    numlock
                }
                touchpad {
                    tap
                    dwt
                }
                focus-follows-mouse max-scroll-amount="95%"
                workspace-auto-back-and-forth
                disable-power-key-handling
            }

            layout {
                gaps ${toString (if host == "desktop" then 8 else 4)}

                struts {
                    left 20
                    right 20
                    top 8
                    bottom 8
                }
                focus-ring {
                    width 2
                    // overwritten by wallpaper script later
                    active-gradient angle=45 from="#89B4FA" relative-to="workspace-view" to="#94E2D5"
                    inactive-color "#1e1e2e"
                }
                border { off; }
                shadow {
                    on
                    offset x=0.000000 y=5.000000
                    softness 30
                    spread 4
                    draw-behind-window false
                    color "#1a1a1aee"
                }
                tab-indicator {
                    hide-when-single-tab
                    gap 0
                    width 12
                    length total-proportion=1.000000
                    position "top"
                    gaps-between-tabs 0.000000
                    corner-radius 0.000000
                }
                default-column-width { proportion 0.500000; }
                preset-column-widths {
                    proportion 0.333330
                    proportion 0.500000
                    proportion 0.666670
                    proportion 1.000000
                }
                preset-window-heights {
                    proportion 0.333330
                    proportion 0.500000
                    proportion 0.666670
                    proportion 1.000000
                }
                center-focused-column "never"
                always-center-single-column
            }

            // no client-side decorations
            prefer-no-csd

            gestures {
                hot-corners {
                    off
                }
            }

            cursor {
                xcursor-theme "${config.custom.gtk.cursor.name}"
                xcursor-size ${toString config.custom.gtk.cursor.size}
            }

            recent-windows {
                binds {
                    Alt+Tab         { next-window     scope="output"; }
                    Alt+Shift+Tab   { previous-window scope="output"; }
                    // switches to the next / prev window of the same class
                    Ctrl+Alt+Tab       { next-window     scope="all" filter="app-id"; }
                    Ctrl+Alt+Shift+Tab { previous-window scope="all" filter="app-id"; }
                }
            }

            // match focal format
            screenshot-path "${config.hj.directory}/Pictures/Screenshots/%Y-%m-%dT%H:%M:%S%z.png";

            // allows jumping to a window when clicking on notifications
            debug {
                honor-xdg-activation-with-invalid-serial
            }

            hotkey-overlay {
                skip-at-startup
            }

            clipboard {
                disable-primary
            }

            overview {
                zoom 0.4
            }

            xwayland-satellite {
                path "${lib.getExe pkgs.xwayland-satellite}"
            }

            window-rule {
                draw-border-with-background false
                // rounded corners for all windows
                geometry-corner-radius 4
                clip-to-geometry true
                open-maximized-to-edges false
            }

            // use blurred overview from noctalia
            layer-rule {
                match namespace="^noctalia-overview*"
                place-within-backdrop true
            }
          ''

          # create workspaces config
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

          # create monitors config
          (lib.concatImapStringsSep "\n" (
            i: d:
            let
              rotation = toString (lib.mod (d.transform * 90) 360);
              flipped = d.transform > 3;
              isVertical = d.transform == 1 || d.transform == 3;
            in
            ''
              output "${d.name}" {
                ${lib.optionalString (i == 1) "focus-at-startup"}
                scale ${toString d.scale};
                transform "${lib.optionalString flipped "flipped-"}${
                  if rotation == "0" then "normal" else rotation
                }";
                mode "${toString d.width}x${toString d.height}"
                position x=${toString d.positionX} y=${toString d.positionY}
                ${lib.optionalString d.vrr "variable-refresh-rate"}

                ${lib.optionalString isVertical ''
                  layout {
                      default-column-width { proportion 1.0; }
                  }
                ''}
              }
            ''
          ) config.custom.hardware.monitors)

          # final include right at the end of the file
          (lib.mkAfter ''
            include optional=true "${config.hj.xdg.config.directory}/niri/config.kdl";
          '')
        ];
      };
    };
}
