{
  config,
  host,
  inputs,
  isVm,
  lib,
  libCustom,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    imap0
    listToAttrs
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mod
    optionals
    toInt
    types
    ;
  # niri-flake does not support generate a config.kdl without home-manager, generate the file manually
  # and write it with hjem, see sodiboo's config for reference
  # https://github.com/sodiboo/system/blob/8ca2b21c61a4f23052c67e52276bb673a574e17c/login.mod.nix#L66
  niri-cfg-modules = lib.evalModules {
    modules = [
      inputs.niri.lib.internal.settings-module
      { programs.niri.settings = config.custom.programs.niri.settings; }
    ];
  };
  niriConf =
    inputs.niri.lib.internal.validated-config-for pkgs config.programs.niri.package
      niri-cfg-modules.config.programs.niri.finalConfig;
in
{
  options.custom = {
    programs.niri = {
      blur.enable = mkEnableOption "blur behind windows using PR";

      settings = mkOption {
        # it's KDL not JSON, but the JSON type gives the wanted recursive merging properties
        type = types.submodule { freeformType = (pkgs.formats.json { }).type; };
        default = { };
        description = "Niri settings, will be passed directly to niri-flake and validated";
      };
    };
  };

  config = mkIf (config.custom.wm == "niri") {
    nixpkgs.overlays = [ inputs.niri.overlays.niri ];

    environment = {
      sessionVariables = {
      };

      shellAliases = {
        niri-log = ''journalctl --user -u niri --no-hostname -o cat | awk '{$1=""; print $0}' | sed 's/^ *//' | sed 's/\x1b[[0-9;]*m//g' '';
      };
    };

    # NOTE: named workspaces are used, because dynamic workspaces are just... urgh
    # the workspaces are name W1, W2, etc as simply naming them as "1", "2", etc
    # causes waybar to just coerce them back into numbers, so workspaces end up being a
    # weird sequence of numbers and indexes on any monitor that isn't the first, e.g.
    # 6 7 3
    programs.niri = {
      enable = true;
      # package = inputs.niri.packages.${pkgs.system}.niri-unstable.overrideAttrs (o: {
      package = pkgs.niri.overrideAttrs (o: {
        patches =
          (o.patches or [ ])
          ++ optionals config.custom.programs.niri.blur.enable [
            (pkgs.fetchpatch {
              url = "https://patch-diff.githubusercontent.com/raw/YaLTeR/niri/pull/1634.diff";
              hash = "sha256-nEyYtMOnZmYJPhu1/5p4H9RWBKHMq0/IYwvkorMgwoo=";
              name = "blur-behind-windows";
            })
            # additional patch to fix blur on vertical monitors, sadly there's still an artifact on the bottom right
            ./fix-vertical-blur.patch
          ]
          # not compatible with blur patch
          ++ optionals (!config.custom.programs.niri.blur.enable) [
            # fix fullscreen windows have a black background
            # https://github.com/YaLTeR/niri/discussions/1399#discussioncomment-12745734
            ./transparent-fullscreen.patch
          ]
          ++ [
            # increase maximum shadow spread to be able to fake dimaround on ultrawide
            # see: https://github.com/YaLTeR/niri/discussions/1806
            ./larger-shadow-spread.patch
          ];

        doCheck = false;
      });
    };

    # write validated niri config with hjem
    hj.xdg.config.files."niri/config.kdl".source = niriConf;

    xdg.portal = {
      enable = true;
      config = {
        common.default = [ "gnome" ];
        niri = {
          default = "gnome";
          "org.freedesktop.impl.portal.FileChooser" = "gtk";
        };
        obs.default = [ "gnome" ];
      };
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    custom = {
      programs = {
        niri.settings = mkMerge [
          {
            input = {
              keyboard = {
                xkb = {
                  layout = "us";
                };

                numlock = true;
              };

              touchpad = {
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

              workspace-auto-back-and-forth = true;

              # let power button turn machine off
              power-key-handling.enable = false;
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
                  { proportion = 1.0; }
                ];

                # heights that "switch-preset-window-height" (Mod+Shift+R) toggles between.
                preset-window-heights = [
                  { proportion = 0.33333; }
                  { proportion = 0.5; }
                  { proportion = 0.66667; }
                  { proportion = 1.0; }
                ];

                # default width of the new windows, empty for deciding initial width
                default-column-width = {
                  proportion = 0.5;
                };

                tab-indicator = {
                  position = "top";
                  hide-when-single-tab = true;
                  gap = 0;
                  length = {
                    total-proportion = 1.0;
                  };
                  width = 12;
                };

                focus-ring = {
                  width = 2;

                  active = {
                    gradient = {
                      from = "#89B4FA";
                      to = "#94E2D5";
                      relative-to = "workspace-view";
                      angle = 45;
                    };
                  };

                  inactive = {
                    color = "#1e1e2e"; # background
                  };
                };

                # redundant, use focus-ring instead
                border.enable = false;

                shadow = {
                  enable = !isVm;

                  # By default, the shadow draws only around its window, and not behind it.
                  # draw-behind-window = true; # breaks ghostty transparency?

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
                  # larger struts to be able to see the other window when maximized
                  left = gap + 12;
                  right = gap + 12;
                  top = gap;
                  bottom = gap;
                };
              };

            # no client-side decorations
            prefer-no-csd = true;

            animations = { };

            gestures = {
              hot-corners.enable = false;
            };

            cursor = {
              theme = config.custom.gtk.cursor.name;
              size = config.custom.gtk.cursor.size;
            };

            # match focal format
            screenshot-path = "${config.hj.directory}/Pictures/Screenshots/%Y-%m-%dT%H:%M:%S%z.png";

            # allows jumping to a window when clicking on notifications
            debug = {
              honor-xdg-activation-with-invalid-serial = { };
            };

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

            clipboard = {
              disable-primary = true;
            };

            overview = {
              zoom = 0.4;
            };

            xwayland-satellite = {
              enable = true;
              path = getExe pkgs.xwayland-satellite;
            };
          }

          # create workspaces config
          {
            workspaces = listToAttrs (
              libCustom.mapWorkspaces (
                {
                  workspace,
                  monitor,
                  ...
                }:
                {
                  # start from 0 instead to prevent "1" and "10" from sorting wrongly in lexigraphical order
                  name = toString ((toInt workspace) - 1);
                  value = {
                    open-on-output = monitor.name;
                    name = "W${toString workspace}";
                  };
                }
              ) config.custom.hardware.monitors
            );
          }

          # create monitors config
          {
            outputs = listToAttrs (
              imap0 (i: d: {
                inherit (d) name;
                value = {
                  focus-at-startup = i == 0;
                  mode = {
                    inherit (d) width height;
                    # use highest refresh rate by not setting it
                    # refresh = d.refreshRate * 1.0;
                  };
                  position = {
                    x = d.positionX;
                    y = d.positionY;
                  };
                  variable-refresh-rate = d.vrr;
                  transform = {
                    rotation = mod (d.transform * 90) 360;
                    flipped = d.transform > 3;
                  };
                  inherit (d) scale;
                };
              }) config.custom.hardware.monitors
            );
          }
        ];

        wallust.nixJson = {
          niriBlur = config.custom.programs.niri.blur.enable;
        };

        # waybar config for niri
        waybar.config = {
          "niri/workspaces" = {
            format = "{icon}";
            format-icons = {
              # named workspaces
              "W1" = "1";
              "W2" = "2";
              "W3" = "3";
              "W4" = "4";
              "W5" = "5";
              "W6" = "6";
              "W7" = "7";
              "W8" = "8";
              "W9" = "9";
              "W10" = "10";
              # non named workspaces
              default = "";
            };
          };
        };
      };
    };
  };
}
