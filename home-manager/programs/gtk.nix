{
  pkgs,
  config,
  lib,
  isNixOS,
  ...
}: {
  home = {
    packages = with pkgs; [
      dconf
      # gnome.dconf-editor
    ];

    pointerCursor = lib.mkIf isNixOS {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-Mocha-Compact-Blue-dark";
      package = pkgs.catppuccin-gtk.override {
        accents = ["blue"];
        variant = "mocha";
        size = "compact";
      };
      # TODO: it's horrendous lol
      # name = "wallust-Dark-Compact";
    };
    iconTheme = {
      name = "Numix";
      package = pkgs.numix-icon-theme;
    };
    font = {
      name = "${config.iynaix.fonts.regular} Regular";
      package = pkgs.inter;
      size = 10;
    };
    gtk3 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };
    gtk4 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };
  };
}
