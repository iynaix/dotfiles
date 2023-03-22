{
  pkgs,
  user,
  config,
  ...
}: {
  services.gvfs.enable = true;

  home-manager.users.${user} = {
    home = {packages = with pkgs; [dconf gnome.dconf-editor];};

    gtk = {
      enable = true;
      theme = {
        name = "Catppuccin-Mocha-Compact-Blue-Dark";
        package = pkgs.catppuccin-gtk.override {
          accents = ["blue"];
          variant = "mocha";
          size = "compact";
        };
      };
      iconTheme = {
        name = "Numix";
        package = pkgs.numix-icon-theme;
      };
      font = {
        name = "${config.iynaix.font.regular} Regular";
        package = pkgs.inter;
        size = 10;
      };
      gtk3 = {
        extraConfig = {
          gtk-application-prefer-dark-theme = 1;
        };
      };
    };
  };
}
