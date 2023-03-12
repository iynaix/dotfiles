{ pkgs, user, theme, config, lib, ... }:
let
  # can't get the import to work, copied definition from rofi source
  mkLiteral = value: {
    _type = "literal";
    inherit value;
  };
  cfg = config.iynaix.rofi;
in
{
  options.iynaix.rofi = {
    enable = lib.mkEnableOption "Enable Rofi" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user} = {
      programs.rofi = {
        enable = true;
        package = lib.mkDefault pkgs.rofi;
        location = "center";
        terminal = "kitty";
        font = "${config.iynaix.font.regular} 14";
        extraConfig = {
          modi = lib.mkDefault "run,drun,window";
          icon-theme = "Papirus-Dark";
          show-icons = true;
          drun-display-format = "{icon} {name}";
          disable-history = false;
          hide-scrollbar = true;
          display-drun = "   Apps ";
          display-run = "   Run ";
          display-window = " 﩯  Window";
          display-Network = " 󰤨  Network";
          sidebar-mode = true;
        };
        theme = {
          "*" = with config.iynaix.xrdb; {
            bg-color = mkLiteral background;
            bg-color-light = mkLiteral background;
            border-color = mkLiteral color0;
            selected-color = mkLiteral background;
            accent = mkLiteral color4;
            foreground-color = mkLiteral foreground;
            foreground-selected-color = mkLiteral color1;
            button-text-color = mkLiteral color0;
            width = 600;
          };

          "element-text, element-icon, mode-switcher" = {
            background-color = mkLiteral "inherit";
            text-color = mkLiteral "inherit";
          };

          window = {
            height = mkLiteral "360px";
            border = mkLiteral "3px";
            border-color = mkLiteral "@border-color";
            background-color = mkLiteral "@bg-color";
          };

          mainbox = {
            background-color = mkLiteral "@bg-color";
          };

          inputbar = {
            children = mkLiteral "[prompt,entry]";
            background-color = mkLiteral "@bg-color";
            border-radius = mkLiteral "5px";
            padding = mkLiteral "2px";
          };

          prompt = {
            background-color = mkLiteral "@accent";
            padding = mkLiteral "6px";
            text-color = mkLiteral "@bg-color";
            border-radius = mkLiteral "3px";
            margin = mkLiteral "20px 0px 0px 20px";
          };

          textbox-prompt-colon = {
            expand = false;
            str = ":";
          };

          entry = {
            padding = mkLiteral "6px";
            margin = mkLiteral "20px 0px 0px 10px";
            text-color = mkLiteral "@foreground-color";
            background-color = mkLiteral "@bg-color";
          };

          listview = {
            border = mkLiteral "0px 0px 0px";
            padding = mkLiteral "6px 0px 0px";
            margin = mkLiteral "10px 0px 0px 20px";
            columns = 2;
            lines = 5;
            background-color = mkLiteral "@bg-color";
          };

          element = {
            padding = mkLiteral "5px";
            background-color = mkLiteral "@bg-color";
            text-color = mkLiteral "@foreground-color";
          };

          element-icon = {
            size = mkLiteral "25px";
          };

          "element selected" = {
            background-color = mkLiteral "@selected-color";
            text-color = mkLiteral "@foreground-selected-color";
          };

          mode-switcher = {
            enabled = false;
            spacing = 0;
          };

          button = {
            padding = mkLiteral "10px";
            background-color = mkLiteral "@bg-color-light";
            text-color = mkLiteral "@button-text-color";
            vertical-align = mkLiteral "0.5";
            horizontal-align = mkLiteral "0.5";
          };

          "button selected" = {
            background-color = mkLiteral "@bg-color";
            text-color = mkLiteral "@accent";
          };

          message = {
            background-color = mkLiteral "@bg-color-light";
            margin = mkLiteral "2px";
            padding = mkLiteral "2px";
            border-radius = mkLiteral "5px";
          };

          textbox = {
            padding = mkLiteral "6px";
            margin = mkLiteral "20px 0px 0px 20px";
            text-color = mkLiteral "@accent";
            background-color = mkLiteral "@bg-color-light";
          };
        };
      };

      home = {
        packages = with pkgs; [ rofi-power-menu ];

        file.".config/rofi/rofi-wifi-menu" = {
          source = ./rofi-wifi-menu;
          recursive = true;
        };
      };
    };
  };
}
