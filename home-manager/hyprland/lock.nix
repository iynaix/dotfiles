{
  config,
  isLaptop,
  isNixOS,
  lib,
  pkgs,
  ...
}:
let
  lockCmd = lib.getExe config.custom.shell.packages.lock;
in
{
  options.custom = with lib; {
    hyprland = {
      lock = mkEnableOption "locking of host" // {
        default = isLaptop && isNixOS;
      };
    };
  };

  config = lib.mkIf (config.custom.hyprland.enable && config.custom.hyprland.lock) {
    programs.hyprlock.enable = true;

    custom.shell.packages = {
      lock = {
        runtimeInputs = [
          pkgs.procps
          config.programs.hyprlock.package
        ];
        text = # sh
          ''pidof hyprlock || hyprlock'';
      };
    };

    home.packages = [ config.custom.shell.packages.lock ];

    wayland.windowManager.hyprland.settings = {
      bind = [ "$mod_SHIFT, x, exec, ${lockCmd}" ];

      # handle laptop lid
      bindl = lib.mkIf isLaptop [ ",switch:Lid Switch, exec, ${lockCmd}" ];
    };

    # lock on idle
    services.hypridle = {
      settings = {
        general = {
          lock_cmd = lockCmd;
        };

        listener = [
          {
            timeout = 5 * 60;
            on-timeout = lockCmd;
          }
        ];
      };
    };

    custom.wallust.templates."hyprlock.conf" = {
      text =
        let
          rgba = colorname: alpha: "rgba({{ ${colorname} | rgb }},${toString alpha})";
        in
        lib.hm.generators.toHyprconf {
          attrs = {
            general = {
              disable_loading_bar = false;
              grace = 0;
              hide_cursor = false;
            };

            background = map (mon: {
              monitor = "${mon.name}";
              # add trailing comment with monitor name for wallpaper to replace later
              path = "/tmp/swww__${mon.name}.webp";
              color = "${rgba "background" 1}";
            }) config.custom.monitors;

            input-field = {
              monitor = "";
              size = "300, 50";
              outline_thickness = 2;
              dots_size = 0.33;
              dots_spacing = 0.15;
              dots_center = true;
              outer_color = "${rgba "background" 0.8}";
              inner_color = "${rgba "foreground" 0.9}";
              font_color = "${rgba "background" 0.8}";
              fade_on_empty = false;
              placeholder_text = "";
              hide_input = false;

              position = "0, -20";
              halign = "center";
              valign = "center";
            };

            label = [
              {
                monitor = "";
                text = ''cmd[update:1000] echo "<b><big>$(date +"%H:%M")</big></b>"'';
                color = "${rgba "foreground" 1}";
                font_size = 150;
                font_family = "${config.custom.fonts.regular}";

                # shadow makes it more readable on light backgrounds
                shadow_passes = 1;
                shadow_size = 4;

                position = "0, 190";
                halign = "center";
                valign = "center";
              }
              {
                monitor = "";
                text = ''cmd[update:1000] echo "<b><big>$(date +"%A, %B %-d")</big></b>"'';
                color = "${rgba "foreground" 1}";
                font_size = 40;
                font_family = "${config.custom.fonts.regular}";

                # shadow makes it more readable on light backgrounds
                shadow_passes = 1;
                shadow_size = 2;

                position = "0, 60";
                halign = "center";
                valign = "center";
              }
            ];
          };
        };
      target = "${config.xdg.configHome}/hypr/hyprlock.conf";
    };
  };
}
