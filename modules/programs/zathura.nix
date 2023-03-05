{ pkgs, config, user, ... }: {
  config = {
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
            options = with config.iynaix.xrdb; {
              statusbar-h-padding = 0;
              statusbar-v-padding = 0;
              page-padding = 1;
              adjust-open = "best-fit";
              # catppuccin mocha theme
              default-fg = foreground;
              default-bg = background;

              completion-bg = color0;
              completion-fg = foreground;
              completion-highlight-bg = color8;
              completion-highlight-fg = foreground;
              completion-group-bg = color0;
              completion-group-fg = color4;

              statusbar-fg = foreground;
              statusbar-bg = color0;

              notification-bg = color0;
              notification-fg = foreground;
              notification-error-bg = color0;
              notification-error-fg = color1;
              notification-warning-bg = color0;
              notification-warning-fg = color3;

              inputbar-fg = foreground;
              inputbar-bg = color0;

              recolor-lightcolor = background;
              recolor-darkcolor = foreground;

              index-fg = foreground;
              index-bg = background;
              index-active-fg = foreground;
              index-active-bg = color0;

              render-loading-bg = background;
              render-loading-fg = foreground;

              highlight-color = color8;
              highlight-fg = color5;
              highlight-active-color = color5;
            };
          };
        };
      };
  };
}
