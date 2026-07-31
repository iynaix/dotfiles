{ inputs, lib, ... }:
{
  flake.modules.nixos.core = {
    options.custom = {
      programs.hyprland = {
        settings = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = "Hyprland lua config";
        };
      };
    };
  };

  flake.modules.nixos.wm =
    {
      config,
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
      inherit (config.custom.constants) host;
    in
    {
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
          cat "${hyprland'.configuration.constructFiles.generatedConfig.outPath}" "${config.hj.xdg.config.directory}/hypr/noctalia.lua" | \
            ${lib.getExe pkgs.stylua} --indent-type Spaces --indent-width 2 - | \
            moor --lang lua'';
      };

      custom.persist = {
        home.cache.directories = [ ".cache/hyprland" ];
      };
    };
}
