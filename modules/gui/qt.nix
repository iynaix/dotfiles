{ lib, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      drv =
        {
          lib,
          stdenv,
          fetchFromGitHub,
        }:
        stdenv.mkDerivation {
          pname = "tokyo-night-kvantum";
          version = "0-unstable-2024-08-08";

          src = fetchFromGitHub {
            owner = "0xsch1zo";
            repo = "Kvantum-Tokyo-Night";
            rev = "82d104e0047fa7d2b777d2d05c3f22722419b9ee";
            hash = "sha256-Uy/WthoQrDnEtrECe35oHCmszhWg38fmDP8fdoXQgTk=";
          };
          installPhase = ''
            runHook preInstall
            mkdir -p $out/share/Kvantum
            cp -a Kvantum-Tokyo-Night $out/share/Kvantum
            runHook postInstall
          '';

          meta = {
            description = "Tokyo Night Kvantum theme";
            homepage = "https://github.com/0xsch1zo/Kvantum-Tokyo-Night";
            license = lib.licenses.gpl3Only;
            maintainers = with lib.maintainers; [ iynaix ];
            mainProgram = "kvantum-tokyo-night";
            platforms = lib.platforms.all;
          };
        };
    in
    {
      packages.tokyo-night-kvantum = pkgs.callPackage drv { };
    };

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
        "Kvantum/Kvantum-Tokyo-Night".source = "${
          self.packages.${pkgs.stdenv.hostPlatform.system}.tokyo-night-kvantum
        }/share/Kvantum/Kvantum-Tokyo-Night";

        "Kvantum/kvantum.kvconfig".text = lib.generators.toINI { } {
          General.theme = "Kvantum-Tokyo-Night";
        };
      };
    };
}
