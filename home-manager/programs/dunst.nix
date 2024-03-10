{
  config,
  lib,
  pkgs,
  ...
}:
let
  opacity = "E5";
in
{
  services.dunst = {
    enable = true;
    configFile = "${config.xdg.cacheHome}/wallust/dunstrc";
  };

  custom.wallust.templates.dunstrc = lib.mkIf config.services.dunst.enable {
    text = pkgs.custom.lib.toQuotedINI {
      global = {
        browser = "brave -new-tab";
        corner_radius = 8;
        dmenu = "rofi -p dunst:";
        ellipsize = "end";
        follow = "mouse";
        font = "${config.custom.fonts.regular} Regular 12";
        frame_color = "{{background}}";
        frame_width = 0;
        horizontal_padding = 10;
        max_icon_size = 72;
        mouse_left_click = "do_action";
        mouse_middle_click = "do_action";
        mouse_right_click = "close_current";
        separator_color = "{{color7}}";
        separator_height = 1;
        show_indicators = "no";
        inherit (config.services.dunst.settings.global) icon_path;
      };

      urgency_critical = {
        background = "{{color1}}";
        foreground = "{{foreground}}";
        timeout = 0;
      };

      urgency_low = {
        background = "{{background}}${opacity}";
        foreground = "{{foreground}}";
        timeout = 10;
      };

      urgency_normal = {
        background = "{{background}}${opacity}";
        foreground = "{{foreground}}";
        timeout = 10;
      };
    };
    target = "${config.xdg.cacheHome}/wallust/dunstrc";
  };
}
