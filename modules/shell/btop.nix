{user, ...}: {
  config = {
    home-manager.users.${user} = {
      programs.btop = {
        enable = true;
        settings = {
          color_theme = "TTY";
          theme_background = false;
          cpu_single_graph = true;
          show_disks = false;
        };
      };

      xdg.configFile."btop/themes/catppuccin-mocha.theme".source = ./btop-catppuccin-mocha.theme;
    };
  };
}
