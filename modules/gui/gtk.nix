{ lib, ... }:
let
  inherit (lib)
    concatLines
    concatMapStringsSep
    gvariant
    isBool
    isString
    literalExpression
    mapAttrs'
    mapAttrsToList
    mkMerge
    mkOption
    nameValuePair
    ;
  inherit (lib.types)
    attrs
    int
    package
    number
    listOf
    str
    ;
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
        dconf.settings = mkOption {
          type = attrs;
          default = { };
          description = "An attrset used to generate dconf keyfile.";
          example = literalExpression ''
            with lib.gvariant;
            {
              "com/raggesilver/BlackBox" = {
                scrollback-lines = mkUint32 10000;
                theme-dark = "Tommorow Night";
              };
            }
          '';
        };
        gtk = {
          bookmarks = mkOption {
            type = listOf str;
            default = [ ];
            example = [ "/home/jane/Documents" ];
            description = "File browser bookmarks.";
          };

          font = {
            package = mkOption {
              type = package;
              default = pkgs.geist-font;
              description = "Package providing the font";
            };

            name = mkOption {
              type = str;
              default = config.custom.fonts.regular;
              description = "The family name of the font within the package.";
            };

            size = mkOption {
              type = number;
              default = 10;
              description = "The size of the font.";
            };
          };

          theme = {
            package = mkOption {
              type = package;
              default = pkgs.tokyonight-gtk-theme.override {
                colorVariants = [ "dark" ];
                sizeVariants = [ "compact" ];
                themeVariants = [ "all" ];
              };
              description = "Package providing the theme.";
            };

            name = mkOption {
              type = str;
              default = "Tokyonight-Dark-Compact";
              description = "The name of the theme within the package.";
            };
          };

          iconTheme = {
            package = mkOption {
              type = package;
              default = pkgs.custom.tela-dynamic-icon-theme.override { colors = accents; };
              description = "Package providing the icon theme.";
            };

            name = mkOption {
              type = str;
              default = "Tela-${defaultAccent}-dark";
              description = "The name of the icon theme within the package.";
            };
          };

          cursor = {
            package = mkOption {
              type = package;
              default = pkgs.simp1e-cursors;
              description = "Package providing the cursor theme.";
            };

            name = mkOption {
              type = str;
              default = "Simp1e-Tokyo-Night";
              description = "The cursor name within the package.";
            };

            size = mkOption {
              type = int;
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
            if isBool value then
              (if value then "true" else "false")
            else if isString value then
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
          "xdg/gtk-2.0/gtkrc".text = concatLines (mapAttrsToList toGtk2File gtkSharedSettings);
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
            settings = mkMerge [
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
                  cursor-size = gvariant.mkUint32 gtkCfg.cursor.size;
                  font-name = "${gtkCfg.font.name} 10";
                  gtk-theme = "Tokyonight-Dark-Compact";
                  icon-theme = "Tela-${defaultAccent}-dark";
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
        config.files."gtk-3.0/bookmarks".text = concatMapStringsSep "\n" (
          b: "file://${b}"
        ) gtkCfg.bookmarks;

        data.files = {
          "icons/default/index.theme".source = "${defaultIndexThemePackage}/share/icons/default/index.theme";
          "icons/${gtkCfg.cursor.name}".source = "${gtkCfg.cursor.package}/share/icons/${gtkCfg.cursor.name}";
        }
        //
          # create symlink in $XDG_DATA_HOME/.icons for each icon accent variant
          # allows dunst to be able to refer to icons by name, $XDG_DATA_HOME is used as
          # /usr/share/icons does not exist on nixos
          mapAttrs' (
            accent: _:
            let
              iconTheme = "Tela-${accent}-dark";
            in
            nameValuePair "icons/${iconTheme}" {
              source = "${config.custom.gtk.iconTheme.package}/share/icons/${iconTheme}";
            }
          ) accents;
      };

      # write theme accents into nix.json for rust to read
      custom.programs.wallust.nixJson = {
        themeAccents = accents;
      };
    };
}
