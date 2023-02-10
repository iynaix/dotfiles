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
  };
}
