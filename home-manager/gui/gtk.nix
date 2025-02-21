{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) attrNames mkIf mkOption;
  inherit (lib.types) attrsOf enum str;
in
{
  options.custom = {
    gtk = {
      accents = mkOption {
        type = attrsOf str;
        default = {
          blue = "#89b4fa";
          flamingo = "#f2cdcd";
          green = "#a6e3a1";
          lavender = "#b4befe";
          maroon = "#eba0ac";
          mauve = "#cba6f7";
          peach = "#fab387";
          pink = "#f5c2e7";
          red = "#f38ba8";
          rosewater = "#f5e0dc";
          sapphire = "#74c7ec";
          sky = "#89dceb";
          teal = "#94e2d5";
          yellow = "#f9e2af";
        };
        description = "GTK theme accents";
      };

      defaultAccent = mkOption {
        type = enum (attrNames config.custom.gtk.accents);
        default = "blue";
        description = "Default GTK theme accent";
      };
    };
  };

  config =
    let
      inherit (config.custom.gtk) accents defaultAccent;
    in
    mkIf (!config.custom.headless) {
      home = {
        pointerCursor = {
          package = pkgs.simp1e-cursors;
          name = "Simp1e-Catppuccin-Frappe";
          size = 28;
          gtk.enable = true;
          x11.enable = true;
        };

        # plasma seems to override this file?
        file.${config.gtk.gtk2.configLocation}.force = true;
      };

      dconf.settings = {
        # disable dconf first use warning
        "ca/desrt/dconf-editor" = {
          show-warning = false;
        };
        # set dark theme for gtk 4
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          cursor-theme = config.home.pointerCursor.name;
        };
      };

      gtk = {
        enable = true;
        theme = {
          name = "catppuccin-mocha-${defaultAccent}-compact";
          package = pkgs.catppuccin-gtk.override {
            # allow all accents so the closest matching color can be selected by dotfiles-rs
            accents = attrNames accents;
            variant = "mocha";
            tweaks = [
              # "black" # black tweak for oled
              # "rimless"
            ];
            size = "compact";
          };
        };
        iconTheme = {
          name = "Tela-${defaultAccent}-dark";
          package = pkgs.custom.tela-dynamic-icon-theme.override { colors = accents; };
        };
        font = {
          name = config.custom.fonts.regular;
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

      qt.enable = true;

      # write theme accents into nix.json for rust to read
      custom.wallust.nixJson = {
        themeAccents = accents;
      };
    };
}
