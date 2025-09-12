{
  config,
  isNixOS,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatMapStringsSep
    getExe
    getExe'
    head
    last
    mkEnableOption
    mkIf
    mkOption
    optionals
    optionalString
    range
    replaceStrings
    ;
  inherit (lib.strings) toJSON;
  inherit (lib.types) lines submodule;
  cfg = config.custom.waybar;
in
{
  options.custom = {
    waybar = {
      enable = mkEnableOption "waybar" // {
        default = config.custom.isWm;
      };
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

  config = mkIf config.custom.waybar.enable {
    programs.waybar = {
      enable = isNixOS;
      systemd.enable = true;
    };

    systemd.user.services.waybar = {
      # wait for colorscheme to be ready on boot
      Unit = {
        AssertPathExists = [
          "${config.xdg.configHome}/waybar/config.jsonc"
          "${config.xdg.configHome}/waybar/style.css"
        ];
        Wants = [ "wallpaper.service" ];
      };
    };

    wayland.windowManager = {
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

    };

    programs.niri.settings = {
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

    custom = {
      mango.settings = {
        bind = [
          "$mod, a, spawn, ${getExe' pkgs.procps "pkill"} -SIGUSR1 .waybar-wrapped"
          "$mod+SHIFT, a, spawn, ${getExe' pkgs.procps "pkill"} -SIGUSR2 .waybar-wrapped"
        ];
      };
    };

    custom = {
      waybar.config = {
        backlight = mkIf config.custom.backlight.enable {
          format = "{icon}   {percent}%";
          format-icons = [
            "󰃞"
            "󰃟"
            "󰃝"
            "󰃠"
          ];
          on-scroll-down = "${getExe pkgs.brightnessctl} s 1%-";
          on-scroll-up = "${getExe pkgs.brightnessctl} s +1%";
        };

        battery = mkIf config.custom.battery.enable {
          format = "{icon}    {capacity}%";
          format-charging = "     {capacity}%";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
          states = {
            critical = 20;
          };
          tooltip = false;
        };

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
          on-click = getExe config.custom.rofi-power-menu.package;
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

        modules-center =
          if (config.custom.wm == "mango") then [ "dwl/tags" ] else [ "${config.custom.wm}/workspaces" ];

        modules-right = [
          "network"
          "pulseaudio"
        ]
        ++ (optionals config.custom.backlight.enable [ "backlight" ])
        ++ (optionals config.custom.battery.enable [ "battery" ])
        ++ [ "clock" ];

        network = {
          format-disconnected = "󰖪    Offline";
          tooltip = false;
        }
        // (
          if config.custom.wifi.enable then
            {
              format = "    {essid}";
              format-ethernet = " ";
              # rofi wifi script
              on-click = getExe pkgs.custom.rofi-wifi-menu;
              on-click-right = "${getExe config.custom.terminal.package} -e nmtui";
            }
          else
            {
              format-ethernet = "";
            }
        );

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
          on-click-right = getExe pkgs.pwvucontrol;
          scroll-step = 1;
          tooltip = false;
        };

        start_hidden = cfg.hidden;
      };

      wallust = {
        templates = {
          "waybar.jsonc" = {
            text = toJSON cfg.config;
            target = "${config.xdg.configHome}/waybar/config.jsonc";
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
              workspaceModuleName = if (config.custom.wm == "mango") then "tags" else "workspaces";
              workspaceActiveClass = if (config.custom.wm == "mango") then "focused" else "active";
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

                #${workspaceModuleName} button {
                  ${baseModuleCss}
                  padding-left: 8px;
                  padding-right: 8px;

                  ${lib.optionalString (config.custom.wm == "niri" || config.custom.wm == "mango") ''
                    /* niri workspaces seem to have excess padding */
                    padding-left: 0px;
                    padding-right: 0px;
                  ''}
                }

                #${workspaceModuleName} button.${workspaceActiveClass} {
                  border-bottom:  2px solid @accent;
                  background-color: rgba(255,255,255, 0.25);
                }
              ''
              # dwl (for mango) tags style on occupied instead of empty
              +
                optionalString (config.custom.wm != "mango") # css
                  ''
                    #${workspaceModuleName} button.empty {
                      opacity: 0.6;
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

              target = "${config.xdg.configHome}/waybar/style.css";
            };
        };
      };
    };
  };
}
