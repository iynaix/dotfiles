{
  tags = [ "wm" ];

  config =
    {
      config,
      host,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      # NOTE: hyprland wrapper module has not been merged upstream:
      # https://github.com/BirdeeHub/nix-wrapper-modules/pull/567
      hyprland' = inputs.wrappers.wrappers.hyprland.wrap rec {
        inherit pkgs;
        package = pkgs.hyprland;
        inherit (package) passthru;
        configFile = config.custom.programs.hyprland.settings;
      };
    in
    {
      options.custom = {
        programs.hyprland = {
          # use the option from the hyprland wrapper module
          settings = inputs.wrappers.wrappers.hyprland.wrapperOptions.configFile;
        };
      };

      config = {
        environment = {
          variables = {
            HYPRCURSOR_SIZE = config.custom.gtk.cursor.size;
            HYPRCURSOR_THEME = config.custom.gtk.cursor.name;
          }
          // (lib.optionalAttrs (host == "vm" || host == "vm-hyprland") {
            WLR_RENDERER_ALLOW_SOFTWARE = "1";
          });
        };

        xdg.portal = {
          config = {
            hyprland = {
              default = [
                "hyprland"
                "gtk"
              ];
              "org.freedesktop.impl.portal.FileChooser" = "gtk";
            };
          };
        };

        programs.hyprland = {
          enable = true;
          package = hyprland';
          withUWSM = true;
        };

        custom.programs.print-config = {
          hyprland = /* sh */ ''
            cat "${hyprland'.configuration.constructFiles.generatedConfig.outPath}" | \
              ${lib.getExe pkgs.stylua} --indent-type Spaces --indent-width 2 - | \
              moor --lang lua'';
        };

        custom.persist = {
          home.cache.directories = [ ".cache/hyprland" ];
        };
      };
    };
}
