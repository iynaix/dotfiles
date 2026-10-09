{
  tags = [ "wm" ];

  config =
    {
      config,
      inputs,
      lib,
      pkgs,
      system,
      user,
      ...
    }:
    let
      tomlFormat = pkgs.formats.toml { };
      umbrielWrapper = import ./_wrapper.nix { inherit inputs; };
    in
    {
      options.custom = {
        programs.umbriel = {
          settings = lib.mkOption {
            inherit (tomlFormat) type;
            default = { };
            description = "Configuration for umbriel";
          };
        };
      };

      config = {
        programs.umbriel = {
          enable = true;
          package = umbrielWrapper.wrap {
            inherit pkgs;
            package = inputs.umbriel.packages.${system}.default;
            inherit (config.custom.programs.umbriel) settings;

            includeOptional = [
              # use noctalia colors
              "/home/${user}/.config/umbriel/noctalia.toml"
              # dynamic cursor
              "/home/${user}/.config/umbriel/cursor.toml"
            ];
          };
        };

        xdg.portal = {
          config = {
            common.default = [ "gnome" ];
            obs.default = [ "gnome" ];
            umbriel = {
              "org.freedesktop.impl.portal.FileChooser" = "gtk";
            };
          };

          extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        };

        custom.programs = {
          print-config = {
            umbriel =
              let
                inherit (config.programs.umbriel.package.configuration.constructFiles) generatedConfig userConfig;
              in
              /* sh */ ''cat "${generatedConfig.outPath}" "${userConfig.outPath}" | moor --lang toml'';
          };
        };
      };
    };
}
