{ pkgs, theme, ... }: {
  services = {
    dunst = {
      enable = true;
      settings = {
        global = {
          transparency = 15;
          separator_height = 1;
          horizontal_padding = 10;
          frame_width = 0;
          frame_color = theme.base;
          separator_color = theme.mantle;
          font = "Inter Regular 12";
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
          background = theme.rosewater;
          foreground = theme.text;
          timeout = 10;
        };
        urgency_normal = {
          background = theme.rosewater;
          foreground = theme.text;
          timeout = 10;
        };
        urgency_critical = {
          background = theme.red;
          foreground = theme.text;
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
}
