# make qt use a dark theme, adapted from:
# https://github.com/fufexan/dotfiles/blob/main/home/programs/qt.nix
# also see:
# https://discourse.nixos.org/t/struggling-to-configure-gtk-qt-theme-on-laptop/42268/
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf (config.custom.wm != "tty") {
    environment = {
      sessionVariables = {
        QT_QPA_PLATFORMTHEME = "qt5ct";
        QT_STYLE_OVERRIDE = "kvantum";
      };

      systemPackages = with pkgs; [
        libsForQt5.qt5ct
        libsForQt5.qtstyleplugin-kvantum
        libsForQt5.qtwayland
        qt6Packages.qt6ct
        qt6Packages.qtstyleplugin-kvantum
        qt6Packages.qtwayland
      ];
    };

    # use gtk theme on qt apps
    qt = {
      enable = true;
      platformTheme = "qt5ct";
      style = "kvantum";
    };

    # Kvantum looks for themes here
    hj.xdg.config.files = {
      "Kvantum/Kvantum-Tokyo-Night".source =
        "${pkgs.custom.tokyo-night-kvantum}/share/Kvantum/Kvantum-Tokyo-Night";

      "Kvantum/kvantum.kvconfig".text = lib.generators.toINI { } {
        General.theme = "Kvantum-Tokyo-Night";
      };
    };

    # qtct config
    custom.programs.wallust.templates =
      let
        defaultFont = "${config.custom.gtk.font.name},${builtins.toString config.custom.gtk.font.size}";
        createQtctConf =
          font:
          lib.generators.toINI { } {
            Appearance = {
              custom_palette = false;
              icon_theme = config.custom.gtk.iconTheme.name;
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
          target = "${config.hj.xdg.config.directory}/qt5ct/qt5ct.conf";
        };

        "qt6ct.conf" = {
          text = createQtctConf ''"${defaultFont},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'';
          target = "${config.hj.xdg.config.directory}/qt6ct/qt6ct.conf";
        };
      };
  };
}
