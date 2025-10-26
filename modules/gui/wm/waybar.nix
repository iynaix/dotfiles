{ lib, ... }:
let
  inherit (lib)
    concatMapStringsSep
    getExe
    getExe'
    head
    last
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkOrder
    optionals
    optionalString
    range
    replaceStrings
    ;
  inherit (lib.types) lines submodule;
in
{
  flake.nixosModules.core =
    { pkgs, ... }:
    {
      options.custom = {
        programs.waybar = {
          config = mkOption {
            type = submodule { freeformType = (pkgs.formats.json { }).type; };
            default = { };
            description = "Additional waybar config (wallust templating can be used)";
          };
          idleInhibitor = mkEnableOption "Idle inhibitor";
          extraCss = mkOption {
            type = lines;
            default = "";
            description = "Additional css to add to the waybar style.css";
          };
          hidden = mkEnableOption "Hidden waybar by default";
        };
      };
    };

  flake.nixosModules.wm =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib.strings) toJSON;
      cfg = config.custom.programs.waybar;
    in
    {
      programs.waybar.enable = true;

      systemd.user.services.waybar = {
        # wait for colorscheme to be ready on boot
        unitConfig = {
          AssertPathExists = [
            "${config.hj.xdg.config.directory}/waybar/config.jsonc"
            "${config.hj.xdg.config.directory}/waybar/style.css"
          ];
          Wants = [ "wallpaper.service" ];
        };
      };

      custom.programs = {
        hyprland.settings = {
          layerrule = [
            "blur,waybar"
            "ignorealpha 0,waybar"
          ];

          bind = [
            "$mod, a, exec, ${getExe' pkgs.procps "pkill"} -SIGUSR1 .waybar-wrapped"
            "$mod_SHIFT, a, exec, ${getExe' pkgs.procps "pkill"} -SIGUSR2 .waybar-wrapped"
          ];
        };

        niri.settings = {
          binds = {
            "Mod+A".action.spawn = [
              (getExe' pkgs.procps "pkill")
              "-SIGUSR1"
              ".waybar-wrapped"
            ];
            "Mod+Shift+A".action.spawn = [
              (getExe' pkgs.procps "pkill")
              "-SIGUSR2"
              ".waybar-wrapped"
            ];
          };
        };

        mango.settings = {
          bind = [
            "$mod, a, spawn, ${getExe' pkgs.procps "pkill"} -SIGUSR1 .waybar-wrapped"
            "$mod+SHIFT, a, spawn, ${getExe' pkgs.procps "pkill"} -SIGUSR2 .waybar-wrapped"
          ];
        };

        waybar.config = {
          clock = {
            calendar = {
              actions = {
                on-click-right = "mode";
                on-scroll-down = "shift_down";
                on-scroll-up = "shift_up";
              };
              format = {
                days = "<span color='{{color4}}'><b>{}</b></span>";
                months = "<span color='{{foreground}}'><b>{}</b></span>";
                today = "<span color='{{color3}}'><b><u>{}</u></b></span>";
                weekdays = "<span color='{{color5}}'><b>{}</b></span>";
              };
              mode = "year";
              mode-mon-col = 3;
              on-scroll = 1;
            };
            format = "󰥔   {:%H:%M}";
            format-alt = "󰸗   {:%a, %d %b %Y}";
            # format-alt = "  {:%a, %d %b %Y}";
            interval = 10;
            tooltip-format = "<tt><small>{calendar}</small></tt>";
          };

          "custom/nix" = {
            format = "󱄅";
            on-click = "rofi-power-menu";
            tooltip = false;
          };

          idle_inhibitor = mkIf cfg.idleInhibitor {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
          };

          layer = "top";

          margin = "0";

          modules-left = [ "custom/nix" ] ++ (optionals cfg.idleInhibitor [ "idle_inhibitor" ]);

          modules-center = [
            "hyprland/workspaces"
            "niri/workspaces"
            "dwl/tags"
          ];

          # allow ordering from other files, e.g. battery / backlight
          modules-right = mkMerge [
            (mkOrder 400 [
              "network"
              "pulseaudio"
            ])
            (mkOrder 2000 [ "clock" ])
          ];

          network = {
            format-disconnected = "󰖪    Offline";
            format-ethernet = "";
            tooltip = false;
          };

          position = "top";

          pulseaudio = {
            format = "{icon}  {volume}%";
            format-icons = {
              default = [
                "󰕿"
                "󰖀"
                "󰕾"
              ];
              headphone = "󰋋";
              headphone-muted = "󰟎";
            };
            format-muted = "󰖁  Muted";
            on-click = "${getExe pkgs.pamixer} -t";
            on-click-right = getExe pkgs.pavucontrol;
            scroll-step = 1;
            tooltip = false;
          };

          start_hidden = cfg.hidden;
        };
      };

      custom.programs.wallust = {
        templates = {
          "waybar.jsonc" = {
            text = toJSON cfg.config;
            target = "${config.hj.xdg.config.directory}/waybar/config.jsonc";
          };
          "waybar.css" =
            let
              margin = "12px";
              # define colors as gtk css variables
              colorNames = [
                "background"
                "foreground"
                "cursor"
              ]
              ++ map (i: "color${toString i}") (range 0 15);
              colorDefinitions = # css
              ''
                @define-color accent {{foreground}};
                @define-color complementary {{color4}};
              ''
              + (concatMapStringsSep "\n" (name: "@define-color ${name} {{${name}}};") colorNames);
              baseModuleCss = # css
                ''
                  font-family: "${config.custom.fonts.regular}";
                  font-weight: bold;
                  color: @accent;
                  text-shadow: 1px 1px 2px rgba(0,0,0,0.8);
                  border: none;
                  border-radius: 0;
                  transition: none;
                  border-bottom:  2px solid transparent;
                  padding-left: ${margin};
                  padding-right: ${margin};
                '';
              mkModuleClassName = mod: "#${replaceStrings [ "hyprland/" "/" ] [ "" "-" ] mod}";
              mkModulesCss =
                arr:
                concatMapStringsSep "\n" (mod: ''
                  ${mkModuleClassName mod} {
                    ${baseModuleCss}
                  }'') arr;
            in
            {
              text = # css
              ''
                ${colorDefinitions}

                #waybar {
                  background: rgba(0,0,0,0.75);
                }

                ${mkModulesCss cfg.config.modules-left}
                ${mkModulesCss cfg.config.modules-center}
                ${mkModulesCss cfg.config.modules-right}

                ${mkModuleClassName "custom/nix"} {
                  font-size: 20px;
                }

                #workspaces button {
                  ${baseModuleCss}
                  /* the fuck is this bullshit */
                  /* https://github.com/Alexays/Waybar/issues/450#issuecomment-527635548 */
                  min-width: 0;
                }

                #workspaces button.active {
                  border-bottom:  2px solid @accent;
                  background-color: rgba(255,255,255, 0.25);
                }

                #workspaces button.empty {
                  opacity: 0.6;
                }

                /* mango uses tags instead of workspaces */
                #tags button {
                  ${baseModuleCss}
                  /* mango seems to add excess padding */
                  padding-left: 0px;
                  padding-right: 0px;
                }

                #tags button.focused {
                  border-bottom:  2px solid @accent;
                  background-color: rgba(255,255,255, 0.25);
                }
              ''
              +
                # remove padding for the outermost modules
                # css
                ''
                  ${mkModuleClassName (head cfg.config.modules-left)} {
                    padding-left: 0;
                    margin-left: ${margin};
                  }
                  ${mkModuleClassName (last cfg.config.modules-right)} {
                    padding-right: 0;
                    margin-right: ${margin};
                  }
                ''
              # idle inhibitor icon is wonky, add extra padding
              +
                optionalString cfg.idleInhibitor
                  # css
                  ''
                    ${mkModuleClassName "idle_inhibitor"} {
                      font-size: 17px;
                      padding-right: 16px;
                    }
                    ${mkModuleClassName "idle_inhibitor.activated"} {
                      color: @complementary;
                    }
                  ''
              # add complementary classes
              # css
              + ''
                ${
                  concatMapStringsSep ", " mkModuleClassName [
                    "network.disconnected"
                    "pulseaudio.muted"
                    "custom/focal"
                  ]
                } {
                  color: @complementary;
                }
              ''
              + cfg.extraCss;

              target = "${config.hj.xdg.config.directory}/waybar/style.css";
            };
        };
      };
    };
}
