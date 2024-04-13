{
  pkgs,
  config,
  lib,
  isNixOS,
  ...
}:
let
  gradienceCfg = config.custom.gradience;
in
{
  home = {
    packages = lib.optionals gradienceCfg.enable [ pkgs.gradience ];

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

  gtk =
    let
      catppuccinDefault = "Blue";
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-error-bell = 0;
      };
    in
    {
      enable = true;
      theme =
        if
          gradienceCfg.enable
        # gradience-cli monet --preset-name new-theme --image-path $(current-wallpaper) --theme dark
        # gradience-cli apply --preset-name adaiwata-dark --gtk both
        then
          {
            name = "adw-gtk3";
            package = pkgs.adw-gtk3;
          }
        else
          {
            name = "Catppuccin-Mocha-Compact-${catppuccinDefault}-Dark";
            package = pkgs.catppuccin-gtk.override {
              # allow all accents so the closest matching color can be selected by dotfiles-utils
              accents = [
                "blue"
                "flamingo"
                "green"
                "lavender"
                "maroon"
                "mauve"
                "peach"
                "pink"
                "red"
                "rosewater"
                "sapphire"
                "sky"
                "teal"
                "yellow"
              ];
              variant = "mocha";
              size = "compact";
            };
          };
      iconTheme = {
        name = "Tela-${catppuccinDefault}-dark";
        package = pkgs.custom.tela-catppuccin-icon-theme;
      };
      font = {
        name = "${config.custom.fonts.regular} Regular";
        package = pkgs.geist-font;
        size = 10;
      };
      gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
      gtk3 = {
        inherit extraConfig;
      };
      gtk4 = {
        inherit extraConfig;
      };
    };
}
