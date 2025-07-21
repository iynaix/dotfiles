{
  config,
  host,
  inputs,
  isVm,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    imap0
    listToAttrs
    mkIf
    mkMerge
    mod
    optionals
    ;
in
{
  imports = [
    ./keybinds.nix
    ./startup.nix
  ];

  options.custom = {
    niri = {
      blur.enable = lib.mkEnableOption "blur behind windows using PR";

      # create a copy of niri settings for wallust, loads of nix option black magic, that is
      # waayyyyyyyyyyyyyyyy over my head, see:
      # https://github.com/sodiboo/niri-flake/issues/1199
      # settings = lib.mkOption {
      #   default = lib.modules.mkAliasAndWrapDefsWithPriority id options.programs.niri.settings;
      #   description = "Niri settings to be override for wallust";
      #   readOnly = true;
      # };
    };
  };

  config = mkIf (config.custom.wm == "niri") {
    # NOTE: named workspaces are used, because dynamic workspaces are just... urgh
    # the workspaces are name W1, W2, etc as simply naming them as "1", "2", etc
    # causes waybar to just coerce them back into numbers, so workspaces end up being a
    # weird sequence of numbers and indexes on any monitor that isn't the first, e.g.
    # 6 7 3
    programs.niri = {
      enable = true;
      package = inputs.niri.packages.${pkgs.system}.niri-unstable.overrideAttrs (o: {
        patches =
          (o.patches or [ ])
          # increase maximum shadow spread to be able to fake dimaround on ultrawide
          # see: https://github.com/YaLTeR/niri/discussions/1806
          ++ [ ./larger-shadow-spread.patch ]
          ++ optionals config.custom.niri.blur.enable [
            (pkgs.fetchpatch {
              url = "https://patch-diff.githubusercontent.com/raw/YaLTeR/niri/pull/1634.diff";
              hash = "sha256-ucIBkohHGoALm8dyYxNDd90tyjR1Vr/F/rUWh1+6bRs=";
              name = "blur-behind-windows";
            })
            # additional patch to fix blur on vertical monitors, sadly there's still an artifact on the bottom right
            ./fix-vertical-blur.patch
          ];

        doCheck = false;
      });

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

          overview = {
            zoom = 0.4;
          };

          xwayland-satellite = {
            enable = true;
            path = lib.getExe inputs.niri.packages.${pkgs.system}.xwayland-satellite-unstable;
          };
        }

        # create workspaces config
        {
          workspaces = listToAttrs (
            lib.custom.mapWorkspaces (
              {
                workspace,
                monitor,
                ...
              }:
              {
                # start from 0 instead to prevent "1" and "10" from sorting wrongly in lexigraphical order
                name = toString ((lib.toInt workspace) - 1);
                value = {
                  open-on-output = monitor.name;
                  name = "W${toString workspace}";
                };
              }
            ) config.custom.monitors
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
            }) config.custom.monitors
          );
        }
      ];
    };

    home.shellAliases = {
      niri-log = ''journalctl --user -u niri --no-hostname -o cat | awk '{$1=""; print $0}' | sed 's/^ *//' | sed 's/\x1b[[0-9;]*m//g' '';
    };

    # allow override of modified file by the wallpaper theme changer
    xdg.configFile.niri-config.force = true;

    custom = {
      # override niri settings with placeholders for wallust
      /*
        wallust.templates = {
          "niri-config.kdl" = {
            text =
              # override niri settings with placeholders for wallust, referenced from
              # sodiboo's own config:
              # https://github.com/sodiboo/system/blob/main/personal/login.mod.nix
              # also see comment at top of file for explanation of `config.custom.niri.settings`
              (evalModules {
                modules = [
                  inputs.niri.lib.internal.settings-module
                  # overrides, currently just active and inactive focus-ring
                  {
                    programs.niri.settings = mkMerge [
                      config.custom.niri.settings
                      {
                        layout = {
                          focus-ring = {
                            active.gradient = {
                              from = mkForce "{{color4}}";
                              to = mkForce "{{color0}}";
                            };

                            inactive.color = mkForce "{{color0}}";
                          };
                        };
                      }
                    ];
                  }
                ];
              }).config.programs.niri.finalConfig;
            target = "${config.xdg.configHome}/niri/config.kdl";
          };
        };
      */

      wallust.nixJson = {
        niriBlur = config.custom.niri.blur.enable;
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
}
