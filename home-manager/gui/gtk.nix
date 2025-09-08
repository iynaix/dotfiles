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
          Default = "#2e7de9";
          Green = "#387068";
          Grey = "#414868";
          Orange = "#b15c00";
          Pink = "#d20065";
          Purple = "#7847bd";
          Red = "#f52a65";
          Teal = "#118c74";
          Yellow = "#8c6c3e";
        };
        description = "GTK theme accents";
      };

      defaultAccent = mkOption {
        type = enum (attrNames config.custom.gtk.accents);
        default = "Default";
        description = "Default GTK theme accent";
      };
    };
  };

  config =
    let
      inherit (config.custom.gtk) accents defaultAccent;
    in
    mkIf (config.custom.wm != "tty") {
      home = {
        pointerCursor = {
          package = pkgs.simp1e-cursors;
          name = "Simp1e-Tokyo-Night";
          size = 28;
          gtk.enable = true;
          x11.enable = true;
          hyprcursor.enable = config.custom.wm == "hyprland";
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
          cursor-theme = config.home.pointerCursor.name;
        };
      };

      gtk = {
        enable = true;
        theme = {
          name = "Tokyonight-Dark-Compact";
          package = pkgs.tokyo-night-gtk.override {
            colorVariants = [ "dark" ];
            sizeVariants = [ "compact" ];
            themeVariants = [ "all" ];
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
        gtk2 = {
          configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
          force = true; # plasma seems to override this file?
        };
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
