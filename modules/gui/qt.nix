{ lib, ... }:
{
  flake.nixosModules.gui =
    # make qt use a dark theme, adapted from:
    # https://github.com/fufexan/dotfiles/blob/main/home/programs/qt.nix
    # also see:
    # https://discourse.nixos.org/t/struggling-to-configure-gtk-qt-theme-on-laptop/42268/
    { config, pkgs, ... }:
    {
      environment = {
        sessionVariables = {
          QT_QPA_PLATFORMTHEME = "qt5ct";
          QT_STYLE_OVERRIDE = "kvantum";
        };

        systemPackages = with pkgs; [
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

      hj.xdg.config.files =
        let
          defaultFont = "${config.custom.gtk.font.name},${toString config.custom.gtk.font.size}";
          createQtctConf =
            font:
            lib.generators.toINI { } {
              Appearance = {
                custom_palette = false;
                # NOTE: matugen does not support closest_color in templates
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
          # Kvantum
          "Kvantum/Kvantum-Tokyo-Night".source =
            "${pkgs.custom.tokyo-night-kvantum}/share/Kvantum/Kvantum-Tokyo-Night";

          "Kvantum/kvantum.kvconfig".text = lib.generators.toINI { } {
            General.theme = "Kvantum-Tokyo-Night";
          };

          # qtct configs
          "qt6ct.conf".text = createQtctConf ''"${defaultFont},-1,5,50,0,0,0,0,0"'';
        };
    };
}
