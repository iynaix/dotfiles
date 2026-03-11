{ lib, ... }:
{
  flake.modules.nixos.core =
    { config, pkgs, ... }:
    {
      options.custom = {
        # type referenced from nixpkgs:
        # https://github.com/NixOS/nixpkgs/blob/554be6495561ff07b6c724047bdd7e0716aa7b46/nixos/modules/programs/dconf.nix#L121C9-L134C11
        dconf.settings = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "An attrset used to generate dconf keyfile.";
          example = lib.literalExpression ''
            with lib.gvariant;
            {
              "com/raggesilver/BlackBox" = {
                scrollback-lines = mkUint32 10000;
                theme-dark = "Tommorrow Night";
              };
            }
          '';
        };
        gtk = {
          bookmarks = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [ "/home/jane/Documents" ];
            description = "File browser bookmarks.";
          };

          font = {
            package = lib.mkOption {
              type = lib.types.package;
              default = pkgs.geist-font;
              description = "Package providing the font";
            };

            name = lib.mkOption {
              type = lib.types.str;
              default = config.custom.fonts.regular;
              description = "The family name of the font within the package.";
            };

            size = lib.mkOption {
              type = lib.types.number;
              default = 10;
              description = "The size of the font.";
            };
          };

        };
      };
    };

  flake.modules.nixos.gui =
    { config, ... }:
    let
      gtkCfg = config.custom.gtk;
      toIni = lib.generators.toINI {
        mkKeyValue =
          key: value:
          let
            value' = if lib.isBool value then lib.boolToString value else toString value;
          in
          "${lib.escape [ "=" ] key}=${value'}";
      };
      gtkIni = toIni {
        Settings = {
          gtk-theme-name = gtkCfg.theme.name;
          gtk-icon-theme-name = config.custom.gtk.iconTheme.name;
          gtk-font-name = "${gtkCfg.font.name} 10";
          gtk-application-prefer-dark-theme = 1;
          gtk-error-bell = 0;
        };
      };
    in
    {
      environment = {
        etc = {
          "xdg/gtk-3.0/settings.ini".text = gtkIni;
          "xdg/gtk-4.0/settings.ini".text = gtkIni;
          "xdg/gtk-2.0/gtkrc".text = ''
            gtk-font-name = "${gtkCfg.font.name} 10";
            gtk-icon-theme-name = "${config.custom.gtk.iconTheme.name}";
            gtk-theme-name = "${gtkCfg.theme.name}";
          '';
        };

        sessionVariables = {
          GTK2_RC_FILES = "/etc/xdg/gtk-2.0/gtkrc";
        };
      };

      fonts.packages = [
        gtkCfg.font.package
      ];

      programs.dconf = {
        enable = true;

        # custom option, the default nesting is horrendous
        profiles.user.databases = [
          {
            settings = lib.mkMerge [
              {
                # disable dconf first use warning
                "ca/desrt/dconf-editor" = {
                  show-warning = false;
                };
                # gtk related settings
                "org/gnome/desktop/interface" = {
                  color-scheme = "prefer-dark"; # set dark theme for gtk 4
                  cursor-theme = gtkCfg.cursor.name;
                  cursor-size = lib.gvariant.mkUint32 gtkCfg.cursor.size;
                  font-name = "${gtkCfg.font.name} 10";
                  gtk-theme = gtkCfg.theme.name;
                  icon-theme = gtkCfg.iconTheme.name;
                  # disable middle click paste
                  gtk-enable-primary-paste = false;
                };
              }
              config.custom.dconf.settings
            ];
          }
        ];
      };

      hj.xdg = {
        # use per user settings
        config.files."gtk-3.0/bookmarks".text = lib.concatMapStringsSep "\n" (
          b: "file://${b}"
        ) gtkCfg.bookmarks;
      };
    };
}
