{
  config,
  host,
  isLaptop,
  isNixOS,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.waybar;
in
{
  options.custom = with lib; {
    backlight.enable = mkEnableOption "Backlight" // {
      default = isLaptop;
    };
    battery.enable = mkEnableOption "Battery" // {
      default = isLaptop;
    };
    wifi.enable = mkEnableOption "Wifi" // {
      default = isLaptop;
    };

    waybar = {
      enable = mkEnableOption "waybar" // {
        default = config.custom.hyprland.enable && !config.custom.headless;
      };
      config = mkOption {
        type = types.submodule { freeformType = (pkgs.formats.json { }).type; };
        default = { };
        description = "Additional waybar config (wallust templating can be used)";
      };
      complementary_classes = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "List of waybar classes to use the complementary accent color";
      };
      idleInhibitor = mkEnableOption "Idle inhibitor" // {
        default = host == "desktop";
      };
      extraCss = mkOption {
        type = types.lines;
        default = "";
        description = "Additional css to add to the waybar style.css";
      };
      persistentWorkspaces = mkEnableOption "Persistent workspaces";
      hidden = mkEnableOption "Hidden waybar by default";
    };
  };

  config = lib.mkIf config.custom.waybar.enable {
    programs.waybar = {
      enable = isNixOS;
      package = pkgs.waybar.override { cavaSupport = false; };
      systemd.enable = true;
    };

    # toggle / launch waybar
    wayland.windowManager.hyprland.settings = {
      layerrule = [
        "blur,waybar"
        "ignorealpha 0,waybar"
      ];

      bind = [
        ''$mod, a, exec, ${lib.getExe' pkgs.procps "pkill"} -SIGUSR1 waybar''
        "$mod_SHIFT, a, exec, systemctl --user restart waybar.service"
      ];
    };

    custom = {
      waybar.config = {
        backlight = lib.mkIf config.custom.backlight.enable {
          format = "{icon}   {percent}%";
          format-icons = [
            "󰃞"
            "󰃟"
            "󰃝"
            "󰃠"
          ];
          on-scroll-down = "${lib.getExe pkgs.brightnessctl} s 1%-";
          on-scroll-up = "${lib.getExe pkgs.brightnessctl} s +1%";
        };

        battery = lib.mkIf config.custom.battery.enable {
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
          on-click = "rofi -show drun";
          on-click-right = "hypr-wallpaper --rofi";
          tooltip = false;
        };

        idle_inhibitor = lib.mkIf cfg.idleInhibitor {
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

        modules-left = [ "custom/nix" ] ++ (lib.optional cfg.idleInhibitor "idle_inhibitor");

        modules-right =
          [
            "network"
            "pulseaudio"
          ]
          ++ (lib.optional config.custom.backlight.enable "backlight")
          ++ (lib.optional config.custom.battery.enable "battery")
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
                on-click = lib.getExe pkgs.custom.rofi-wifi-menu;
                on-click-right = "${config.custom.terminal.exec} nmtui";
              }
            else
              { format-ethernet = ""; }
          );

        position = "top";

        pulseaudio = {
          format = "{icon}  {volume}%";
          format-icons = [
            "󰕿"
            "󰖀"
            "󰕾"
          ];
          format-muted = "󰖁  Muted";
          on-click = "${lib.getExe pkgs.pamixer} -t";
          on-click-right = "pwvucontrol";
          scroll-step = 1;
          tooltip = false;
        };

        start_hidden = cfg.hidden;
      };

      waybar.complementary_classes = [
        "idle_inhibitor.activated"
        "network.disconnected"
        "pulseaudio.muted"
        "custom/focal"
      ];

      wallust = {
        nixJson = {
          waybar_persistent_workspaces = cfg.persistentWorkspaces;
        };

        templates = {
          "waybar.jsonc" = {
            text = lib.strings.toJSON cfg.config;
            target = "${config.xdg.configHome}/waybar/config.jsonc";
          };
          "waybar.css" =
            let
              margin = "12px";
              baseModuleCss = ''
                font-family: ${config.custom.fonts.regular};
                font-weight: bold;
                color: {{foreground}};
                transition: none;
                text-shadow: 1px 1px 2px rgba(0,0,0,0.8);
                border-bottom:  2px solid transparent;
                padding-left: ${margin};
                padding-right: ${margin};
              '';
              mkModuleClassName =
                mod:
                "#${
                  lib.replaceStrings
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
                lib.concatMapStringsSep "\n" (mod: ''
                  ${mkModuleClassName mod} {
                    ${baseModuleCss}
                  }'') arr;
            in
            {
              text =
                ''
                  * {
                    border: none;
                    border-radius: 0;
                  }

                  #waybar {
                    background: rgba(0,0,0,0.5)
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
                    border-bottom:  2px solid {{foreground}};
                    background-color: rgba(255,255,255, 0.25);
                  }
                ''
                + lib.optionalString cfg.idleInhibitor ''
                  ${mkModuleClassName "idle_inhibitor"} {                  ;
                  }
                ''
                +
                  # remove padding for the outermost modules
                  ''
                    ${mkModuleClassName (lib.head cfg.config.modules-left)} {
                      padding-left: 0;
                      margin-left: ${margin};
                    }
                    ${mkModuleClassName (lib.last cfg.config.modules-right)} {
                      padding-right: 0;
                      margin-right: ${margin};
                    }
                  ''
                # idle inhibitor icon is wonky, add extra padding
                + lib.optionalString cfg.idleInhibitor ''
                  ${mkModuleClassName "idle_inhibitor"} {
                    font-size: 17px;
                    padding-right: 16px;
                  }
                ''
                # add complementary classes to be modified by hypr-wallpaper at the bottom
                + lib.concatMapStringsSep "\n" (class: ''
                  ${mkModuleClassName class} {
                    color: {{color4}}; /* complementary */
                  }
                '') cfg.complementary_classes
                # additional css at the end for highest priority
                + cfg.extraCss;

              target = "${config.xdg.configHome}/waybar/style.css";
            };
        };
      };
    };
  };
}
