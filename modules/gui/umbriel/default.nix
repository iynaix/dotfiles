{
  tags = [ "wm" ];

  config =
    {
      config,
      inputs,
      lib,
      pkgs,
      system,
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
          package = inputs.umbriel.packages.${system}.default;
        };

        hj.xdg.config.files =
          let
            hostToml = tomlFormat.generate "umbriel-host.toml" config.custom.programs.umbriel.settings;
          in
          {
            "umbriel/host.toml" = {
              source = pkgs.runCommand "umbriel-host-toml" { } ''
                ${lib.getExe config.programs.umbriel.package} validate -c ${hostToml}
                cp ${hostToml} $out
              '';
              type = "copy";
            };

            "umbriel/config.toml" = {
              generator = tomlFormat.generate "umbriel-config.toml";
              value = {
                include = {
                  files = [
                    # use nix generated host.toml first
                    "${config.hj.xdg.config.directory}/umbriel/host.toml"
                  ];

                  optional.files = [
                    # use noctalia colors
                    "${config.hj.xdg.config.directory}/umbriel/noctalia.toml"
                  ];
                };
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
            umbriel = /* sh */ ''moor "${config.hj.xdg.config.directory}/umbriel/host.toml"'';
          };
        };
      };
    };
}
