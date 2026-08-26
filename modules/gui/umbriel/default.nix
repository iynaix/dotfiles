{
  tags = [ "wm" ];

  config =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      tomlFormat = pkgs.formats.toml { };
    in
    {
      # TODO: use package from nixpkgs when more stable?
      imports = [ inputs.umbriel.nixosModules.default ];

      options.custom = {
        programs.umbriel = {
          settings = lib.mkOption {
            inherit (tomlFormat) type;
            default = { };
            example = lib.literalExpression ''
              animation = {
                enabled = true;
                duration_ms = 150;
                curve = "easeout";
              };
            '';
            description = ''
              Configuration for umbriel, this will be prepended to the umbriel includes
            '';
          };
        };
      };

      config = {
        programs.umbriel = {
          enable = true;
        };

        hj.xdg.config.files = {
          "umbriel/host.toml" = {
            generator = tomlFormat.generate "umbriel-host.toml";
            value = config.custom.programs.umbriel.settings;
          };

          "umbriel/config.toml" = {
            generator = tomlFormat.generate "umbriel-config.toml";
            value = {
              include.files = [
                # use nix generated host.toml first
                "${config.hj.xdg.config.directory}/umbriel/host.toml"
                # TODO: temporarily use the config.toml from this directory
                "/persist${config.hj.directory}/projects/dotfiles/modules/gui/umbriel/umbriel.toml"
                # use noctalia colors
                "${config.hj.xdg.config.directory}/umbriel/noctalia.toml"
              ];
            };
            type = "copy";
          };
        };

        xdg.portal = {
          config = {
            umbriel = {
              "org.freedesktop.impl.portal.FileChooser" = "gtk";
            };
          };
        };

        custom.programs = {
          print-config = {
            umbriel = /* sh */ ''
              cat "${config.hj.xdg.config.directory}/umbriel/host.toml" \
                "/persist${config.hj.directory}/projects/dotfiles/modules/gui/umbriel/umbriel.toml" \
                "${config.hj.xdg.config.directory}/umbriel/noctalia.toml" | \
                moor --lang toml
            '';
          };
        };
      };
    };
}
