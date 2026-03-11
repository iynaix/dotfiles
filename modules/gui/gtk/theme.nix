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
in
{
  flake.modules.nixos.core =
    { pkgs, ... }:
    {
      options.custom = {
        gtk = {
          theme = {
            accents = lib.mkOption {
              type = lib.types.attrs;
              default = accents;
              description = "GTK theme accents colors";
            };

            package = lib.mkOption {
              type = lib.types.package;
              default =
                (pkgs.tokyonight-gtk-theme.override {
                  colorVariants = [ "dark" ];
                  sizeVariants = [ "compact" ];
                  themeVariants = [ "all" ];
                }).overrideAttrs
                  (o: {
                    # make it impossible to have a light theme XD
                    postInstall = (o.postInstall or "") + ''
                      rm -rf $out/share/themes/*Light*

                      for theme in "$out"/share/themes/*Dark*; do
                        ln -s "$theme" "''${theme/Dark/Light}";
                      done
                    '';
                  });
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
    { config, ... }:
    {
      environment.systemPackages = [
        config.custom.gtk.theme.package
      ];

      # set dynamic gtk theme with noctalia
      custom.programs.noctalia.colors.templates = {
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
      };
    };
}
