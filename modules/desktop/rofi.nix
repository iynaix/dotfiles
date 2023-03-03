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
    bin = lib.mkOption {
      type = lib.types.str;
      default = "${pkgs.rofi}/bin/rofi";
      description = "Path to the rofi executable";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user} = {
      programs.rofi = {
        enable = true;
        package = pkgs.rofi;
        location = "center";
        terminal = "alacritty";
        font = "${config.iynaix.font.regular} 14";
        extraConfig = {
          modi = "run,drun,window";
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
          "*" = {
            bg-col = mkLiteral theme.base;
            bg-col-light = mkLiteral theme.base;
            border-col = mkLiteral theme.base;
            selected-col = mkLiteral theme.base;
            blue = mkLiteral theme.blue;
            fg-col = mkLiteral theme.text;
            fg-col2 = mkLiteral theme.red;
            grey = mkLiteral theme.overlay0;
            width = 600;
          };

          "element-text, element-icon, mode-switcher" = {
            background-color = mkLiteral "inherit";
            text-color = mkLiteral "inherit";
          };

          window = {
            height = mkLiteral "360px";
            border = mkLiteral "3px";
            border-color = mkLiteral "@border-col";
            background-color = mkLiteral "@bg-col";
          };

          mainbox = {
            background-color = mkLiteral "@bg-col";
          };

          inputbar = {
            children = mkLiteral "[prompt,entry]";
            background-color = mkLiteral "@bg-col";
            border-radius = mkLiteral "5px";
            padding = mkLiteral "2px";
          };

          prompt = {
            background-color = mkLiteral "@blue";
            padding = mkLiteral "6px";
            text-color = mkLiteral "@bg-col";
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
            text-color = mkLiteral "@fg-col";
            background-color = mkLiteral "@bg-col";
          };

          listview = {
            border = mkLiteral "0px 0px 0px";
            padding = mkLiteral "6px 0px 0px";
            margin = mkLiteral "10px 0px 0px 20px";
            columns = 2;
            lines = 5;
            background-color = mkLiteral "@bg-col";
          };

          element = {
            padding = mkLiteral "5px";
            background-color = mkLiteral "@bg-col";
            text-color = mkLiteral "@fg-col";
          };

          element-icon = {
            size = mkLiteral "25px";
          };

          "element selected" = {
            background-color = mkLiteral "@selected-col";
            text-color = mkLiteral "@fg-col2";
          };

          mode-switcher = {
            spacing = 0;
          };

          button = {
            padding = mkLiteral "10px";
            background-color = mkLiteral "@bg-col-light";
            text-color = mkLiteral "@grey";
            vertical-align = mkLiteral "0.5";
            horizontal-align = mkLiteral "0.5";
          };

          "button selected" = {
            background-color = mkLiteral "@bg-col";
            text-color = mkLiteral "@blue";
          };

          message = {
            background-color = mkLiteral "@bg-col-light";
            margin = mkLiteral "2px";
            padding = mkLiteral "2px";
            border-radius = mkLiteral "5px";
          };

          textbox = {
            padding = mkLiteral "6px";
            margin = mkLiteral "20px 0px 0px 20px";
            text-color = mkLiteral "@blue";
            background-color = mkLiteral "@bg-col-light";
          };
        };
      };

      home = {
        packages = with pkgs; [ rofi-power-menu ];
      };
    };
  };
}
