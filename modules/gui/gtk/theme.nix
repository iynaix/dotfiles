{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      tokyonight-theme = pkgs.tokyonight-gtk-theme.override {
        colorVariants = [ "dark" ];
        sizeVariants = [ "compact" ];
        themeVariants = [ "default" ];
      };
      tokyonight-template = pkgs.runCommand "tokyonight-template" { } /* sh */ ''
        mkdir -p $out/share/themes

        src="${tokyonight-theme}";
        cp -RT "$src/share/themes/Tokyonight-Dark-Compact/" "$out/"
      '';
    in
    {
      packages = {
        # fix some ugly styling for nemo in tokyonight
        tokyonight-gtk-theme =
          (pkgs.tokyonight-gtk-theme.override {
            colorVariants = [ "dark" ];
            sizeVariants = [ "compact" ];
            themeVariants = [ "all" ];
          }).overrideAttrs
            (o: {
              patches = (o.patches or [ ]) ++ [ ./tokyonight-style.patch ];

              # make it impossible to have a light theme XD
              postInstall = (o.postInstall or "") + ''
                rm -rf $out/share/themes/*Light*

                for theme in "$out"/share/themes/*Dark*; do
                  ln -s "$theme" "''${theme/Dark/Light}";
                done
              '';
            });

        tokyonight-dynamic-gtk-theme = pkgs.writeShellApplication {
          name = "tokyonight-dynamic-gtk-theme";
          runtimeInputs = [
            pkgs.dconf
          ];
          text = /* sh */ ''
            if [[ -z "''${1:-}" || -z "''${2:-}" ]]; then
                echo "ERROR: Two hex colors are required (e.g., #FF0000)."
                exit 1
            fi

            # strip the leading #s
            THEME_NAME="Tokyonight-''${1#\#}-''${2#\#}"
            THEME_DIR="/tmp/$THEME_NAME"

            # uncomment for debugging
            # rm -rf "$THEME_DIR"

            if [[ ! -d "$THEME_DIR" ]]; then
              cp -r ${tokyonight-template} "$THEME_DIR"
              chmod -R +w "$THEME_DIR"

              # replace the accents ($1) and on-accent ($2) colors
              find "$THEME_DIR" -name "*.css" -type f -exec sed -i \
                -e "s/#27a1b9/$1/g" \
                -e "s/rgba(26, 27, 38, 0.87)/$1/g" \
                -e "s/#e1e2e7/$2/g" \
                {} +
              sed -i "s/Tokyonight-Dark-Compact/$THEME_NAME/g" "$THEME_DIR/index.theme"

              # add overrides at the end of the file
              # wow this indentation is ass
              cat <<-EOF | tee -a "$THEME_DIR/gtk-3.0/gtk.css" "$THEME_DIR/gtk-3.0/gtk-dark.css" > /dev/null
            /* nemo selected item expander color */
            treeview.view.expander:selected {
              color: $1;
            }

            /* nemo selected item rename highlight color */
            treeview entry selection {
              color: #ffffff;
              background-color: $2;
            }
            EOF
            fi

            mkdir -p "$HOME/.local/share/themes"
            ln -sfn "$THEME_DIR" "$HOME/.local/share/themes/$THEME_NAME"
            dconf write "/org/gnome/desktop/interface/gtk-theme" "'$THEME_NAME'"
          '';
        };
      };
    };

  flake.modules.nixos.core =
    { pkgs, ... }:
    {
      options.custom = {
        gtk = {
          theme = {
            package = lib.mkOption {
              type = lib.types.package;
              default = pkgs.custom.tokyonight-gtk-theme;
              description = "Package providing the theme.";
            };

            name = lib.mkOption {
              type = lib.types.str;
              default = "Tokyonight-Dark-Compact";
              description = "The name of the theme within the package.";
            };
          };
        };
      };
    };

  flake.modules.nixos.gui =
    { config, pkgs, ... }:
    {
      environment.systemPackages = [
        config.custom.gtk.theme.package
      ];

      # set dynamic icon theme with noctalia
      custom.programs.noctalia.colors.templates = {
        "gtk-theme" = {
          post_hook = ''${lib.getExe pkgs.custom.tokyonight-dynamic-gtk-theme} "{{ colors.primary.default.hex }}" "{{ colors.on_primary.default.hex | set_alpha 0.8 }}"'';
          # dummy values so noctalia doesn't complain
          input_path = "${config.hj.xdg.config.directory}/user-dirs.conf";
          output_path = "/dev/null";
        };
      };
    };
}
