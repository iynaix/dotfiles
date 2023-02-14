{ pkgs, theme, ... }: {
  programs = {
    alacritty = {
      enable = true;
      settings = {
        window.padding = {
          x = 20;
          y = 12;
        };
        font = {
          normal = {
            family = "JetBrainsMono Nerd Font";
            style = "Medium";
          };
          bold = { style = "Bold"; };
          italic = { style = "Italic"; };
          bold_italic = { style = "Bold Italic"; };
          size = 11;
        };
        selection.save_to_clipboard = true;
        # window.opacity = 0.5;
        # catppuccin theme
        colors = {
          primary = {
            background = theme.base;
            foreground = theme.text;
            # Bright and dim foreground colors
            dim_foreground = theme.text;
            bright_foreground = theme.text;
          };

          # Cursor colors
          cursor = {
            text = theme.base;
            cursor = theme.rosewater;
          };
          vi_mode_cursor = {
            text = theme.base;
            cursor = theme.lavender;
          };

          # Search colors
          search = {
            matches = {
              foreground = theme.base;
              background = theme.subtext0;
            };
            focused_match = {
              foreground = theme.base;
              background = theme.green;
            };
            footer_bar = {
              foreground = theme.base;
              background = theme.subtext0;
            };
          };

          # Keyboard regex hints
          hints = {
            start = {
              foreground = theme.base;
              background = theme.yellow;
            };
            end = {
              foreground = theme.base;
              background = theme.subtext0;
            };
          };

          # Selection colors
          selection = {
            text = theme.base;
            background = theme.rosewater;
          };

          # Normal colors
          normal = {
            black = theme.surface1;
            red = theme.red;
            green = theme.green;
            yellow = theme.yellow;
            blue = theme.blue;
            magenta = theme.pink;
            cyan = theme.teal;
            white = theme.subtext1;
          };
          # Bright colors
          bright = {
            black = theme.surface2;
            red = theme.red;
            green = theme.green;
            yellow = theme.yellow;
            blue = theme.blue;
            magenta = theme.pink;
            cyan = theme.teal;
            white = theme.subtext0;
          };

          # Dim colors
          dim = {
            black = theme.surface1;
            red = theme.red;
            green = theme.green;
            yellow = theme.yellow;
            blue = theme.blue;
            magenta = theme.pink;
            cyan = theme.teal;
            white = theme.subtext1;
          };

          indexed_colors = [
            {
              index = 16;
              color = "#FAB387";
            }
            {
              index = 17;
              color = "#F5E0DC";
            }
          ];
        };
      };
    };
  };
}