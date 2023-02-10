{ pkgs, ... }: {
  services = {
    dunst = {
      enable = true;
      settings = {
        global = {
          transparency = 15;
          separator_height = 1;
          horizontal_padding = 10;
          frame_width = 0;
          frame_color = "#788388";
          separator_color = "#263238";
          font = "Inter Regular 12";
          ellipsize = "end";
          show_indicators = "no";
          max_icon_size = 72;
          dmenu = "${pkgs.rofi} -p dunst:";
          browser = "${pkgs.brave} -new-tab";
          # keyboard shortcuts
          mouse_left_click = "do_action";
          mouse_middle_click = "do_action";
          mouse_right_click = "close_current";
          history = "ctrl + mod4 + grave";
          context = "ctrl + mod4 + period";
        };
        urgency_low = {
          background = "#2d303b";
          foreground = "#f9f9f9";
          timeout = 10;
        };
        urgency_normal = {
          background = "#2d303b";
          foreground = "#f9f9f9";
          timeout = 10;
        };
        urgency_critical = {
          background = "#D62929";
          foreground = "#F9FAF9";
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
