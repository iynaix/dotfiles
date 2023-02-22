{ pkgs, user, config, ... }: {
  services.gvfs.enable = true;

  home-manager.users.${user} = {
    home = { packages = with pkgs; [ dconf ]; };

    gtk = {
      enable = true;
      theme = {
        name = "Catppuccin-Mocha-Compact-Blue-Dark";
        package = pkgs.catppuccin-gtk.override {
          accents = [ "blue" ];
          variant = "mocha";
          size = "compact";
        };
      };
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      font = {
        name = "${config.iynaix.font.regular} Regular";
        package = pkgs.inter;
      };
      gtk3 = {
        bookmarks = [
          "file:///home/iynaix/Downloads"
          "file:///home/iynaix/projects/coinfc"
          "file:///home/iynaix/projects"
          "file:///home/iynaix/Pictures"
        ];
        extraConfig = {
          gtk-application-prefer-dark-theme = 1;
        };
      };
    };
  };
}
