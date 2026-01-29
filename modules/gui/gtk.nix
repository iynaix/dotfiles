{ lib, ... }:
let
  accents = {
    Default = "#2e7de9";
    Green = "#387068";
    Grey = "#414868";
    Orange = "#b15c00";
    Pink = "#d20065";
    Purple = "#7847bd";
    Red = "#f52a65";
    Teal = "#118c74";
    Yellow = "#8c6c3e";
  };
  defaultAccent = "Default";
in
{
  flake.nixosModules.core =
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

          theme = {
            accents = lib.mkOption {
              type = lib.types.attrs;
              default = accents;
              description = "GTK theme accents colors";
            };

            package = lib.mkOption {
              type = lib.types.package;
              default = pkgs.tokyonight-gtk-theme.override {
                colorVariants = [ "dark" ];
                sizeVariants = [ "compact" ];
                themeVariants = [ "all" ];
              };
              description = "Package providing the theme.";
            };

            name = lib.mkOption {
              type = lib.types.str;
              default = "Tokyonight-Dark-Compact";
              description = "The name of the theme within the package.";
            };
          };

          iconTheme = {
            package = lib.mkOption {
              type = lib.types.package;
              default = pkgs.custom.tela-dynamic-icon-theme.override { colors = accents; };
              description = "Package providing the icon theme.";
            };

            name = lib.mkOption {
              type = lib.types.str;
              default = "Tela-${defaultAccent}-dark";
              description = "The name of the icon theme within the package.";
            };
          };

          cursor = {
            package = lib.mkOption {
              type = lib.types.package;
              default = pkgs.simp1e-cursors;
              description = "Package providing the cursor theme.";
            };

            name = lib.mkOption {
              type = lib.types.str;
              default = "Simp1e-Tokyo-Night";
              description = "The cursor name within the package.";
            };

            size = lib.mkOption {
              type = lib.types.int;
              default = 28;
              description = "The cursor size.";
            };
          };
        };
      };
    };

  flake.nixosModules.gui =
    { config, pkgs, ... }:
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
      defaultIndexThemePackage = pkgs.writeTextFile {
        name = "index.theme";
        destination = "/share/icons/default/index.theme";
        # Set name in icons theme, for compatibility with AwesomeWM etc. See:
        # https://github.com/nix-community/home-manager/issues/2081
        # https://wiki.archlinux.org/title/Cursor_themes#XDG_specification
        text = ''
          [Icon Theme]
          Name=Default
          Comment=Default Cursor Theme
          Inherits=${gtkCfg.cursor.name}
        '';
      };
      gtkSharedSettings = {
        gtk-theme-name = gtkCfg.theme.name;
        gtk-icon-theme-name = gtkCfg.iconTheme.name;
        gtk-font-name = "${gtkCfg.font.name} 10";
      };
      toGtk2File =
        key: value:
        let
          value' =
            if lib.isBool value then
              (if value then "true" else "false")
            else if lib.isString value then
              "\"${value}\""
            else
              toString value;
        in
        "${key} = ${value'}";
      gtkIni = toIni {
        Settings = gtkSharedSettings // {
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
          "xdg/gtk-2.0/gtkrc".text = lib.concatLines (lib.mapAttrsToList toGtk2File gtkSharedSettings);
        };

        sessionVariables = {
          GTK2_RC_FILES = "/etc/xdg/gtk-2.0/gtkrc";
          XCURSOR_SIZE = gtkCfg.cursor.size;
          XCURSOR_THEME = gtkCfg.cursor.name;
          HYPRCURSOR_SIZE = gtkCfg.cursor.size;
          HYPRCURSOR_THEME = gtkCfg.cursor.name;
        };

        systemPackages = with gtkCfg; [
          theme.package
          iconTheme.package
          cursor.package
        ];
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
                  # set dark theme for gtk 4
                  color-scheme = "prefer-dark";
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

      # Add cursor icon link to $XDG_DATA_HOME/icons as well for redundancy.
      hj.xdg = {
        # use per user settings
        config.files."gtk-3.0/bookmarks".text = lib.concatMapStringsSep "\n" (
          b: "file://${b}"
        ) gtkCfg.bookmarks;

        data.files = {
          "icons/default/index.theme".source = "${defaultIndexThemePackage}/share/icons/default/index.theme";
          "icons/${gtkCfg.cursor.name}".source = "${gtkCfg.cursor.package}/share/icons/${gtkCfg.cursor.name}";
        };
      };

      custom.programs.noctalia.colors.templates = {
        # use dynamic gtk theme and icon theme
        "gtk-theme" = {
          colors_to_compare = lib.mapAttrsToList (name: value: {
            name = if name == "Default" then "Tokyonight-Dark-Compact" else "Tokyonight-${name}-Dark-Compact";
            color = value;
          }) config.custom.gtk.theme.accents;
          compare_to = "{{colors.primary.default.hex}}";
          post_hook = ''dconf write "/org/gnome/desktop/interface/gtk-theme" "'{{closest_color}}'"'';
          # dummy values so noctalia doesn't complain
          input_path = "${config.hj.xdg.config.directory}/user-dirs.conf";
          output_path = "/dev/null";
        };

        "gtk-icon-theme" = {
          colors_to_compare = lib.mapAttrsToList (name: value: {
            name = "Tela-${name}-dark";
            color = value;
          }) config.custom.gtk.theme.accents;
          compare_to = "{{colors.primary.default.hex}}";
          post_hook = ''dconf write "/org/gnome/desktop/interface/icon-theme" "'{{closest_color}}'"'';
          # dummy values so noctalia doesn't complain
          input_path = "${config.hj.xdg.config.directory}/user-dirs.conf";
          output_path = "/dev/null";
        };
      };
    };
}
