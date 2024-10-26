# make qt use a dark theme, adapted from:
# https://github.com/fufexan/dotfiles/blob/main/home/programs/qt.nix
# also see:
# https://discourse.nixos.org/t/struggling-to-configure-gtk-qt-theme-on-laptop/42268/
{
  lib,
  pkgs,
  config,
  ...
}:
let
  qtctConf = {
    Appearance = {
      custom_palette = false;
      icon_theme = config.gtk.iconTheme.name;
      standard_dialogs = "xdgdesktopportal";
      style = "kvantum";
    };
  };
  defaultFont = "${config.gtk.font.name},${builtins.toString config.gtk.font.size}";
in
{
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  home = {
    sessionVariables = {
      XCURSOR_SIZE = builtins.div config.home.pointerCursor.size 2;
    };

    packages = with pkgs; [
      # qt6Packages.qtstyleplugin-kvantum
      # qt6Packages.qt6ct
      libsForQt5.qtstyleplugin-kvantum
      libsForQt5.qt5ct
    ];
  };

  xdg.configFile = {
    # Kvantum looks for themes here
    "Kvantum" = {
      source = "${pkgs.catppuccin-kvantum.src}/themes";
      recursive = true;
    };
  };

  # qtct config
  custom.wallust.templates = {
    "kvantum.kvconfig" = {
      text = lib.generators.toINI { } {
        General.theme = "catppuccin-mocha-${config.custom.gtk.defaultAccent}";
      };
      target = "${config.xdg.configHome}/Kvantum/kvantum.kvconfig";
    };

    "qt5ct.conf" = {
      text =
        let
          default = ''"${defaultFont},-1,5,50,0,0,0,0,0"'';
        in
        lib.generators.toINI { } (
          qtctConf
          // {
            Fonts = {
              fixed = default;
              general = default;
            };
          }
        );
      target = "${config.xdg.configHome}/qt5ct/qt5ct.conf";
    };

    "qt6ct.conf" = {
      text =
        let
          default = ''"${defaultFont},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'';
        in
        lib.generators.toINI { } (
          qtctConf
          // {
            Fonts = {
              fixed = default;
              general = default;
            };
          }
        );
      target = "${config.xdg.configHome}/qt6ct/qt6ct.conf";
    };
  };
}
