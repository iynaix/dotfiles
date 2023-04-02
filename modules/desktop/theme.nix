{
  pkgs,
  user,
  lib,
  config,
  ...
}: let
  # cappuccin mocha
  theme = {
    base = "#1e1e2e";
    mantle = "#181825";
    crust = "#11111b";

    text = "#cdd6f4";
    subtext0 = "#a6adc8";
    subtext1 = "#bac2de";

    surface0 = "#313244";
    surface1 = "#45475a";
    surface2 = "#585b70";

    overlay0 = "#6c7086";
    overlay1 = "#7f849c";
    overlay2 = "#9399b2";

    blue = "#89b4fa";
    lavender = "#b4befe";
    sapphire = "#74c7ec";
    sky = "#89dceb";
    teal = "#94e2d5";
    green = "#a6e3a1";
    yellow = "#f9e2af";
    peach = "#fab387";
    maroon = "#eba0ac";
    red = "#f38ba8";
    mauve = "#cba6f7";
    pink = "#f5c2e7";
    flamingo = "#f2cdcd";
    rosewater = "#f5e0dc";

    transparent = "#FF00000";
  };
  xrdb = {
    background = theme.base;
    foreground = theme.text;
    color0 = theme.surface1;
    color8 = theme.surface2;
    color1 = theme.red;
    color9 = theme.red;
    color2 = theme.green;
    color10 = theme.green;
    color3 = theme.yellow;
    color11 = theme.yellow;
    color4 = theme.blue;
    color12 = theme.blue;
    color5 = theme.pink;
    color13 = theme.pink;
    color6 = theme.teal;
    color14 = theme.teal;
    color7 = theme.subtext1;
    color15 = theme.subtext0;
  };
in {
  config = {
    home-manager.users.${user} = {
      # create xresources
      xresources.properties = {
        "Xft.dpi" = 96;
        "Xft.antialias" = true;
        "Xft.hinting" = true;
        "Xft.rgba" = "rgb";
        "Xft.autohint" = false;
        "Xft.hintstyle" = "hintslight";
        "Xft.lcdfilter" = "lcddefault";

        "*.font" = "JetBrainsMono Nerd Font Mono:Medium:size=12";
        "*.bold_font" = "JetBrainsMono Nerd Font Mono:Bold:size=12";
      };

      xdg.configFile."wal/colorschemes/dark/catppuccin-mocha.json".text = builtins.toJSON {
        special = {
          inherit (xrdb) background foreground;
          cursor = theme.rosewater;
        };
        colors = {
          inherit (xrdb) color0 color8 color1 color9 color2 color10 color3 color11 color4 color12 color5 color13 color6 color14 color7 color15;
        };
      };
    };
  };
}
