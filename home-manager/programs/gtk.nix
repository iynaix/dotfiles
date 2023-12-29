{
  pkgs,
  config,
  lib,
  isNixOS,
  ...
}: let
  wallustGtk = false;
  gtkColor = color: value: ''@define-color ${color} ${value};'';
in {
  home = {
    packages = with pkgs; [
      dconf
      gnome.dconf-editor
    ];

    pointerCursor = lib.mkIf isNixOS {
      package = pkgs.simp1e-cursors;
      name = "Simp1e-Catppuccin-Mocha";
      size = 28;
      gtk.enable = true;
      x11.enable = true;
    };
  };

  dconf.settings = {
    # disable dconf first use warning
    "ca/desrt/dconf-editor" = {show-warning = false;};
    # set dark theme for gtk 4
    "org/gnome/desktop/interface" = {color-scheme = "prefer-dark";};
  };

  gtk = {
    enable = true;
    theme =
      if wallustGtk
      then {
        name = "adw-gtk3";
        package = pkgs.adw-gtk3;
      }
      else {
        name = "Catppuccin-Mocha-Compact-Blue-Dark";
        package = pkgs.catppuccin-gtk.override {
          accents = ["blue"];
          variant = "mocha";
          size = "compact";
        };
      };
    iconTheme = {
      name = "Tela-blue-dark";
      package = pkgs.tela-icon-theme;
    };
    font = {
      name = "${config.iynaix.fonts.regular} Regular";
      package = pkgs.inter;
      size = 10;
    };
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
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

  # use gtk theme on qt apps
  qt = {
    enable = true;
    platformTheme = "gtk";
  };

  iynaix.wallust.entries = let
    # https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1.3/named-colors.html
    cssText = lib.concatStringsSep "\n" (lib.mapAttrsToList gtkColor {
      accent_color = "{color13}";
      accent_bg_color = "mix({color13}, {color0},0.3)";
      accent_fg_color = "{foreground}";
      destructive_color = "{color13}";
      destructive_bg_color = "mix({color13}, {color0},0.3)";
      destructive_fg_color = "{color5}";
      success_color = "#8ff0a4";
      success_bg_color = "#26a269";
      success_fg_color = "{color5}";
      warning_color = "#f8e45c";
      warning_bg_color = "#cd9309";
      warning_fg_color = "rgba(0, 0, 0, 0.8)";
      error_color = "#ff7b63";
      error_bg_color = "mix({color13}, {color0},0.3)";
      error_fg_color = "{color5}";
      window_bg_color = "{background}";
      window_fg_color = "{foreground}";
      view_bg_color = "{background}";
      view_fg_color = "{foreground}";
      headerbar_bg_color = "mix({color0},black,0.2)";
      headerbar_fg_color = "{color5}";
      headerbar_border_color = "{color5}";
      headerbar_backdrop_color = "@window_bg_color";
      headerbar_shade_color = "rgba(0, 0, 0, 0.36)";
      card_bg_color = "rgba(255, 255, 255, 0.08)";
      card_fg_color = "{color5}";
      card_shade_color = "rgba(0, 0, 0, 0.36)";
      dialog_bg_color = "{color3}";
      dialog_fg_color = "{color5}";
      popover_bg_color = "{color3}";
      popover_fg_color = "{color5}";
      shade_color = "rgba(0,0,0,0.36)";
      scrollbar_outline_color = "rgba(0,0,0,0.5)";
      blue_1 = "{color13}";
      blue_2 = "{color13}";
      blue_3 = "{color13}";
      blue_4 = "{color13}";
      blue_5 = "{color13}";
      green_1 = "{color11}";
      green_2 = "{color11}";
      green_3 = "{color11}";
      green_4 = "{color11}";
      green_5 = "{color11}";
      yellow_1 = "{color10}";
      yellow_2 = "{color10}";
      yellow_3 = "{color10}";
      yellow_4 = "{color10}";
      yellow_5 = "{color10}";
      orange_1 = "{color9}";
      orange_2 = "{color9}";
      orange_3 = "{color9}";
      orange_4 = "{color9}";
      orange_5 = "{color9}";
      red_1 = "{color8}";
      red_2 = "{color8}";
      red_3 = "{color8}";
      red_4 = "{color8}";
      red_5 = "{color8}";
      purple_1 = "{color14}";
      purple_2 = "{color14}";
      purple_3 = "{color14}";
      purple_4 = "{color14}";
      purple_5 = "{color14}";
      brown_1 = "{color15}";
      brown_2 = "{color15}";
      brown_3 = "{color15}";
      brown_4 = "{color15}";
      brown_5 = "{color15}";
      light_1 = "{color5}";
      light_2 = "#f6f5f4";
      light_3 = "#deddda";
      light_4 = "#c0bfbc";
      light_5 = "#9a9996";
      dark_1 = "mix({color0},white,0.5)";
      dark_2 = "mix({color0},white,0.2)";
      dark_3 = "{color0}";
      dark_4 = "mix({color0},black,0.2)";
      dark_5 = "mix({color0},black,0.4)";
    });
  in {
    gtk3-css = {
      enable = wallustGtk;
      text = cssText;
      target = "~/.config/gtk-3.0/gtk.css";
    };
    gtk4-css = {
      enable = wallustGtk;
      text = cssText;
      target = "~/.config/gtk-4.0/gtk.css";
    };
  };
}
