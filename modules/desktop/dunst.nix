{ user, config, ... }: {
  config = {
    home-manager.users.${user} = {
      services = {
        dunst = {
          enable = true;
          settings =
            with config.iynaix.xrdb; {
              global = {
                follow = "mouse";
                transparency = 15;
                separator_height = 1;
                horizontal_padding = 10;
                frame_width = 0;
                corner_radius = 8;
                frame_color = background;
                separator_color = color7;
                font = "${config.iynaix.font.regular} Regular 12";
                ellipsize = "end";
                show_indicators = "no";
                max_icon_size = 72;
                dmenu = "rofi -p dunst:";
                browser = "brave -new-tab";
                # keyboard shortcuts
                mouse_left_click = "do_action";
                mouse_middle_click = "do_action";
                mouse_right_click = "close_current";
                history = "ctrl + mod4 + grave";
                context = "ctrl + mod4 + period";
              };
              urgency_low = {
                background = "${color0}E5"; # 0.9 opacity
                foreground = foreground;
                timeout = 10;
              };
              urgency_normal = {
                background = "${color0}E5"; # 0.9 opacity
                foreground = foreground;
                timeout = 10;
              };
              urgency_critical = {
                background = "${color1}E5"; # 0.9 opacity
                foreground = foreground;
                timeout = 0;
              };
              brightness-change = {
                appname = "brightness-change";
                history_ignore = "yes";
              };
              volume-change = {
                appname = "volume-change";
                history_ignore = "yes";
              };
            };
        };
      };
    };
  };
}
