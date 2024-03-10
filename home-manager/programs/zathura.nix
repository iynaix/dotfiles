{ config, lib, ... }:
{
  programs = {
    zathura = {
      enable = true;
      mappings = {
        u = "scroll half-up";
        d = "scroll half-down";
        D = "toggle_page_mode";
        r = "reload";
        R = "rotate";
        K = "zoom in";
        J = "zoom out";
        p = "print";
        i = "recolor";
      };
      extraConfig = ''
        include "${config.xdg.cacheHome}/wallust/zathurarc"
      '';
      options = {
        statusbar-h-padding = 0;
        statusbar-v-padding = 0;
        page-padding = 1;
        adjust-open = "best-fit";
        recolor = true; # invert by default
      };
    };
  };

  custom.wallust.templates.zathurarc = lib.mkIf config.programs.zathura.enable {
    text = ''
      set default-bg                  "{{color0}}"
      set default-fg                  "{{color10}}"

      set statusbar-fg                "{{color10}}"
      set statusbar-bg                "{{color0}}"

      set inputbar-bg                 "{{color0}}"
      set inputbar-fg                 "{{color15}}"

      set notification-bg             "{{color0}}"
      set notification-fg             "{{color15}}"

      set notification-error-bg       "{{color0}}"
      set notification-error-fg       "{{color1}}"

      set notification-warning-bg     "{{color0}}"
      set notification-warning-fg     "{{color1}}"

      set highlight-color             "{{color3}}"
      set highlight-active-color      "{{color4}}"

      set completion-bg               "{{color10}}"
      set completion-fg               "{{color4}}"

      set completion-highlight-fg     "{{color15}}"
      set completion-highlight-bg     "{{color4}}"

      set recolor-lightcolor          "{{color0}}"
      set recolor-darkcolor           "{{color15}}"

      set recolor                     "false"
      set recolor-keephue             "false"
    '';
    target = "${config.xdg.cacheHome}/wallust/zathurarc";
  };
}
