{
  pkgs,
  config,
  lib,
  isNixOS,
  ...
}:
let
  catppuccinDefault = "Blue";
  catppuccinAccents = {
    Blue = "#89b4fa";
    Flamingo = "#f2cdcd";
    Green = "#a6e3a1";
    Lavender = "#b4befe";
    Maroon = "#eba0ac";
    Mauve = "#cba6f7";
    Peach = "#fab387";
    Pink = "#f5c2e7";
    Red = "#f38ba8";
    # Rosewater = "#f5e0dc";
    Sapphire = "#74c7ec";
    Sky = "#89dceb";
    Teal = "#94e2d5";
    Yellow = "#f9e2af";
  };
in
{
  home = {
    pointerCursor = lib.mkIf isNixOS {
      package = pkgs.simp1e-cursors;
      name = "Simp1e-Catppuccin-Frappe";
      size = 28;
      gtk.enable = true;
      x11.enable = true;
    };

    sessionVariables = {
      XCURSOR_SIZE = config.home.pointerCursor.size;
    };
  };

  dconf.settings = {
    # disable dconf first use warning
    "ca/desrt/dconf-editor" = {
      show-warning = false;
    };
    # set dark theme for gtk 4
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-Mocha-Compact-${catppuccinDefault}-Dark";
      package = pkgs.catppuccin-gtk.override {
        # allow all accents so the closest matching color can be selected by dotfiles-utils
        accents = map lib.toLower (lib.attrNames catppuccinAccents);
        variant = "mocha";
        size = "compact";
      };
    };
    iconTheme = {
      name = "Tela-${catppuccinDefault}-dark";
      package = pkgs.custom.tela-dynamic-icon-theme.override { colors = catppuccinAccents; };
    };
    font = {
      name = "${config.custom.fonts.regular} Regular";
      package = pkgs.geist-font;
      size = 10;
    };
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-error-bell = 0;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-error-bell = 0;
    };
  };

  # write theme accents into nix.json for rust to read
  custom.wallust.nixJson = {
    theme_accents = catppuccinAccents;
  };
}
