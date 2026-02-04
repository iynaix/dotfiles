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

      # use dynamic theme for qt5ct.conf and qt6ct.conf
      custom.programs.noctalia.colors.templates =
        let
          defaultFont = "${config.custom.gtk.font.name},${toString config.custom.gtk.font.size}";
          createQtctConf = filename: font: {
            colors_to_compare = lib.mapAttrsToList (name: value: {
              name = "Tela-${name}-dark";
              color = value;
            }) config.custom.gtk.theme.accents;
            compare_to = "{{colors.primary.default.hex}}";
            # dummy values so noctalia doesn't complain
            input_path = pkgs.writeText filename (
              lib.generators.toINI { } {
                Appearance = {
                  custom_palette = false;
                  icon_theme = "{{ closest_color }}";
                  standard_dialogs = "xdgdesktopportal";
                  style = "kvantum";
                };
                Fonts = {
                  fixed = font;
                  general = font;
                };
              }
            );
            output_path = "${config.hj.xdg.config.directory}/${filename}";
          };
        in
        {
          "qt5ct.conf" = createQtctConf "qt5ct.conf" ''"${defaultFont},-1,5,50,0,0,0,0,0"'';
          "qt6ct.conf" =
            createQtctConf "qt6ct.conf" ''"${defaultFont},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'';
        };

      hj.xdg.config.files = {
        # Kvantum
        "Kvantum/Kvantum-Tokyo-Night".source =
          "${pkgs.custom.tokyo-night-kvantum}/share/Kvantum/Kvantum-Tokyo-Night";

        "Kvantum/kvantum.kvconfig".text = lib.generators.toINI { } {
          General.theme = "Kvantum-Tokyo-Night";
        };
      };
    };
}
