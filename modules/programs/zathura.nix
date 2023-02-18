{ pkgs, theme, user, ... }: {
  home-manager.users.${user} =
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
          options = {
            statusbar-h-padding = 0;
            statusbar-v-padding = 0;
            page-padding = 1;
            adjust-open = "best-fit";
            # catppuccin mocha theme
            default-fg = theme.text;
            default-bg = theme.base;

            completion-bg = theme.surface0;
            completion-fg = theme.text;
            completion-highlight-bg = theme.surface2;
            completion-highlight-fg = theme.text;
            completion-group-bg = theme.surface0;
            completion-group-fg = theme.blue;

            statusbar-fg = theme.text;
            statusbar-bg = theme.surface0;

            notification-bg = theme.surface0;
            notification-fg = theme.text;
            notification-error-bg = theme.surface0;
            notification-error-fg = theme.red;
            notification-warning-bg = theme.surface0;
            notification-warning-fg = theme.yellow;

            inputbar-fg = theme.text;
            inputbar-bg = theme.surface0;

            recolor-lightcolor = theme.base;
            recolor-darkcolor = theme.text;

            index-fg = theme.text;
            index-bg = theme.base;
            index-active-fg = theme.text;
            index-active-bg = theme.surface0;

            render-loading-bg = theme.base;
            render-loading-fg = theme.text;

            highlight-color = theme.surface2;
            highlight-fg = theme.pink;
            highlight-active-color = theme.pink;
          };
        };
      };
    };
}
