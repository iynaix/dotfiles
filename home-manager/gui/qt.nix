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
  inherit (lib) mkIf;
in
{
  config = mkIf (config.custom.wm != "tty") {
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
        libsForQt5.qt5ct
        libsForQt5.qtstyleplugin-kvantum
        libsForQt5.qtwayland
        qt6Packages.qt6ct
        qt6Packages.qtstyleplugin-kvantum
        qt6Packages.qtwayland
      ];
    };

    xdg.configFile = {
      # Kvantum looks for themes here
      "Kvantum/Kvantum-Tokyo-Night" = {
        source = "${pkgs.custom.tokyo-night-kvantum}/share/Kvantum/Kvantum-Tokyo-Night";
        recursive = true;
      };

      "Kvantum/kvantum.kvconfig".text = lib.generators.toINI { } {
        General.theme = "Kvantum-Tokyo-Night";
      };
    };

    # qtct config
    custom.wallust.templates =
      let
        defaultFont = "${config.gtk.font.name},${builtins.toString config.gtk.font.size}";
        createQtctConf =
          font:
          lib.generators.toINI { } {
            Appearance = {
              custom_palette = false;
              icon_theme = config.gtk.iconTheme.name;
              standard_dialogs = "xdgdesktopportal";
              style = "kvantum";
            };
            Fonts = {
              fixed = font;
              general = font;
            };
          };
      in
      {
        "qt5ct.conf" = {
          text = createQtctConf ''"${defaultFont},-1,5,50,0,0,0,0,0"'';
          target = "${config.xdg.configHome}/qt5ct/qt5ct.conf";
        };

        "qt6ct.conf" = {
          text = createQtctConf ''"${defaultFont},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'';
          target = "${config.xdg.configHome}/qt6ct/qt6ct.conf";
        };
      };
  };
}
