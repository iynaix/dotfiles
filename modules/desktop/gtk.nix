{ pkgs, ... }: {
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
      name = "Numix";
      package = pkgs.numix-icon-theme;
    };
    font = {
      name = "Inter Regular";
      package = pkgs.inter;
    };
    gtk3 = {
      bookmarks = [
        "file:///home/iynaix/Downloads"
        "file:///home/iynaix/projects/coinfc"
        "file:///home/iynaix/projects"
        "file:///home/iynaix/Pictures"
        "file:///media/6TBRED/Anime/Current"
        "file:///media/6TBRED/US/Current"
        "file:///media/6TBRED/New"
      ];
    };
  };
}
