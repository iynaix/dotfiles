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
    optional
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
        default = config.custom.hyprland.enable && !config.custom.headless;
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
      persistentWorkspaces = mkEnableOption "Persistent workspaces";
      hidden = mkEnableOption "Hidden waybar by default";
    };
  };

  config = mkIf config.custom.waybar.enable {
    programs.waybar = {
      enable = isNixOS;
      systemd.enable = true;
    };

    # toggle / launch waybar
    wayland.windowManager.hyprland.settings = {
      layerrule = [
        "blur,waybar"
        "ignorealpha 0,waybar"
      ];

      bind = [
        ''$mod, a, exec, ${getExe' pkgs.procps "pkill"} -SIGUSR1 waybar''
        "$mod_SHIFT, a, exec, systemctl --user restart waybar.service"
      ];
    };

    # wait for colorscheme to be ready on boot
    systemd.user.services.waybar = {
      Unit.AssertPathExists = [ "${config.xdg.configHome}/waybar/config.jsonc" ];
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
          on-click = "exec, uwsm app -- rofi-power-menu";
          tooltip = false;
        };

        idle_inhibitor = mkIf cfg.idleInhibitor {
          format = "{icon}";
          format-icons = {
            activated = "";
            deactivated = "";
          };
        };

        "hyprland/workspaces" = {
          # TODO: pacman, remove active inverse circle
          # format = "{icon}";
          # format-icons = {
          #   active = "󰮯";
          #   default = "·";
          #   urgent = "󰊠";
          # };
          format = "{name}";
        };

        # "hyprland/window" = {
        #   rewrite = {
        #     # strip the application name
        #     "(.*) - (.*)" = "$1";
        #   };
        #   separate-outputs = true;
        # };

        layer = "top";
        margin = "0";

        modules-center = [ "hyprland/workspaces" ];

        modules-left = [ "custom/nix" ] ++ (optional cfg.idleInhibitor "idle_inhibitor");

        modules-right =
          [
            "network"
            "pulseaudio"
          ]
          ++ (optional config.custom.backlight.enable "backlight")
          ++ (optional config.custom.battery.enable "battery")
          ++ [ "clock" ];

        network =
          {
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
                on-click-right = "${config.custom.terminal.exec} nmtui";
              }
            else
              { format-ethernet = ""; }
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
        nixJson = {
          waybarPersistentWorkspaces = cfg.persistentWorkspaces;
        };

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
              ] ++ map (i: "color${toString i}") (range 0 15);
              colorDefinitions = # css
                ''
                  @define-color accent {{foreground}};
                  @define-color complementary {{color4}};
                ''
                + (concatMapStringsSep "\n" (name: ''@define-color ${name} {{${name}}};'') colorNames);
              baseModuleCss = # css
                ''
                  transition: none;
                  border-bottom:  2px solid transparent;
                  padding-left: ${margin};
                  padding-right: ${margin};
                '';
              mkModuleClassName =
                mod:
                "#${
                  replaceStrings
                    [
                      "hyprland/"
                      "/"
                    ]
                    [
                      ""
                      "-"
                    ]
                    mod
                }";
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

                  * {
                    font-family: ${config.custom.fonts.regular};
                    font-weight: bold;
                    color: @accent;
                    text-shadow: 1px 1px 2px rgba(0,0,0,0.8);
                    border: none;
                    border-radius: 0;
                  }

                  #waybar {
                    background: rgba(0,0,0,0.5);
                  }

                  ${mkModulesCss cfg.config.modules-left}
                  ${mkModulesCss cfg.config.modules-center}
                  ${mkModulesCss cfg.config.modules-right}

                  ${mkModuleClassName "custom/nix"} {
                    font-size: 20px;
                  }

                  #workspaces button {
                    ${baseModuleCss}
                    padding-left: 8px;
                    padding-right: 8px;
                  }

                  #workspaces button.active {
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

              target = "${config.xdg.configHome}/waybar/style.css";
            };
        };
      };
    };
  };
}
