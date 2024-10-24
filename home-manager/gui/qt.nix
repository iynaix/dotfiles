# make qt use a dark theme, adapted from:
# https://github.com/fufexan/dotfiles/blob/main/home/programs/qt.nix
{
  lib,
  pkgs,
  config,
  ...
}:
let
  KvLibadwaita = pkgs.fetchFromGitHub {
    owner = "GabePoel";
    repo = "KvLibadwaita";
    rev = "87c1ef9f44ec48855fd09ddab041007277e30e37";
    hash = "sha256-K/2FYOtX0RzwdcGyeurLXAh3j8ohxMrH2OWldqVoLwo=";
    sparseCheckout = [ "src" ];
  };

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
      qt6Packages.qtstyleplugin-kvantum
      qt6Packages.qt6ct
      libsForQt5.qtstyleplugin-kvantum
      libsForQt5.qt5ct
    ];
  };

  xdg.configFile = {
    # Kvantum config
    "Kvantum" = {
      source = "${KvLibadwaita}/src";
      recursive = true;
    };

    "Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=KvLibadwaitaDark
    '';

  };

  # qtct config
  custom.wallust.templates = {
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
