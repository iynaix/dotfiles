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
          package = inputs.umbriel.packages.${system}.default.override {
            # awakened-poe-trade and exiled-exchange-2 don't work because xwayland-satellite doesn't implement X11 overlays (override_redirect):
            # https://github.com/Supreeeme/xwayland-satellite/issues/429
            xwayland-satellite = pkgs.xwayland-satellite.overrideAttrs (o: rec {
              # https://github.com/niri-wm/niri/discussions/3986#discussioncomment-16848571
              # NOTE: this patch was vibe coded
              patches = (o.patches or [ ]) ++ [
                (pkgs.fetchpatch {
                  url = "https://github.com/iynaix/xwayland-satellite/commit/fcfa43dded63b9a22046424bfbb7fc6cedc35f61.patch";
                  hash = "sha256-eV66yKSUxTUtwNr4HuEco/k+xiQehBfrLtqjI+PCf1I=";
                })
              ];

              cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
                inherit (o) src;
                inherit patches;
                hash = "sha256-63/e8BMfkOqdR2B9+00GpMPor5Vt5PUx4pxjlqfao2s=";
              };
            });
          };
        };

        hj.xdg.config.files =
          let
            hostToml = tomlFormat.generate "umbriel-host.toml" config.custom.programs.umbriel.settings;
          in
          {
            "umbriel/host.toml" = {
              source = pkgs.runCommand "umbriel-host-toml" { } ''
                ${lib.getExe config.programs.umbriel.package} config validate -c ${hostToml}
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
                    # dynamic cursor
                    "${config.hj.xdg.config.directory}/umbriel/cursor.toml"
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
