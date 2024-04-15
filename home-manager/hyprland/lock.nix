{
  config,
  isLaptop,
  lib,
  pkgs,
  ...
}:
let
  lockEnable = config.custom.hyprland.lock;
in
lib.mkIf lockEnable {
  home.packages = [ pkgs.hyprlock ];

  wayland.windowManager.hyprland.settings = {
    bind = [ "$mod, x, exec, hyprlock" ];

    # handle laptop lid
    bindl = lib.mkIf isLaptop [ ",switch:Lid Switch, exec, hyprlock" ];
  };

  custom.wallust = {
    templates = {
      "hyprlock.conf" = lib.mkIf lockEnable {
        text =
          let
            rgba = colorname: alpha: "rgba({{ ${colorname} | rgb }}, ${toString alpha})";
          in
          ''
            general {
              disable_loading_bar = false
              grace = 0
              hide_cursor = false
            }

            background {
              monitor =
              path = {{wallpaper}}
              color = ${rgba "background" 1}
            }

            input-field {
              monitor =
              size = 300, 50
              outline_thickness = 3
              dots_size = 0.330000
              dots_spacing = 0.150000
              dots_center = true
              outer_color = ${rgba "background" 0.8}
              inner_color = ${rgba "foreground" 0.9}
              font_color = ${rgba "background" 0.8}
              fade_on_empty = false
              placeholder_text =
              hide_input = false

              position = 0, -20
              halign = center
              valign = center
            }

            label {
              monitor =
              text = cmd[update:1000] echo "<b><big>$(date +"%H:%M")</big></b>"
              color = ${rgba "foreground" 1}
              font_size = 150
              font_family = ${config.custom.fonts.regular}

              position = 0, 90
              halign = center
              valign = center
            }

            label {
              monitor =
              text = cmd[update:1000] echo "<b><big>$(date +"%A, %B %-d")</big></b>"
              color = ${rgba "foreground" 1}
              font_size = 40
              font_family = ${config.custom.fonts.regular}

              position = 0, 40
              halign = center
              valign = center
            }
          '';
        target = "${config.xdg.configHome}/hypr/hyprlock.conf";
      };
    };

    # FIXME: remove when hyprlock has support for jpegs?
    nixJson.hyprlock = lockEnable;
  };
}
