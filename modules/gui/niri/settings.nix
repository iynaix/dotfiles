{ lib, ... }:
let
  inherit (lib)
    concatImapStringsSep
    concatLines
    getExe
    mkAfter
    mkMerge
    mod
    optionalString
    ;
in
{
  flake.nixosModules.wm =
    {
      config,
      host,
      pkgs,
      self,
      ...
    }:
    {
      custom.programs = {

        niri.settings.config = mkMerge [
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
                path "${getExe pkgs.xwayland-satellite}"
            }

            // set blurred wallpaper backdrop for overview
            layer-rule {
                // namespaced swww-daemon layer is named "swww-daemonbackdrop"
                match namespace="^swww-daemonbackdrop$"
                place-within-backdrop true
            }

            window-rule {
                draw-border-with-background false
                // rounded corners for all windows
                geometry-corner-radius 4
                clip-to-geometry true
                open-maximized-to-edges false
            }
          ''

          # create workspaces config
          (
            config.custom.hardware.monitors
            |> self.lib.mapWorkspaces (
              {
                workspace,
                monitor,
                ...
              }:
              ''
                workspace "W${toString workspace}" {
                    open-on-output "${monitor.name}"
                }
              ''
            )
            |> concatLines
          )

          # create monitors config
          (concatImapStringsSep "\n" (
            i: d:
            let
              rotation = toString (mod (d.transform * 90) 360);
              flipped = d.transform > 3;
            in
            ''
              output "${d.name}" {
                ${optionalString (i == 1) "focus-at-startup"}
                scale ${toString d.scale};
                transform "${optionalString flipped "flipped-"}${if rotation == "0" then "normal" else rotation}";
                mode "${toString d.width}x${toString d.height}"
                position x=${toString d.positionX} y=${toString d.positionY}
                ${optionalString d.vrr "variable-refresh-rate"}
              }
            ''
          ) config.custom.hardware.monitors)

          # final include right at the end of the file
          (mkAfter ''
            include optional=true "${config.hj.xdg.config.directory}/niri/config.kdl";
          '')
        ];
      };
    };
}
