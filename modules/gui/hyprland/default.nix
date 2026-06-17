{ lib, self, ... }:
{
  flake.modules.nixos.wm =
    {
      config,
      pkgs,
      ...
    }:
    let
      hyprland' = self.wrappers.hyprland.wrap (
        {
          inherit pkgs;
          package = pkgs.hyprland;
          inherit (pkgs.hyprland) passthru;
        }
        // config.custom.programs.hyprland
      );
      inherit (config.custom.constants) host;
    in
    {
      environment = {
        shellAliases = {
          hyprland = "Hyprland";
          hypr-log = "hyprctl rollinglog --follow";
        };

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
        hyprland = /* sh */ ''cat "${hyprland'.configuration.constructFiles.generatedConfig.outPath}" "${config.hj.xdg.config.directory}/hypr/noctalia/noctalia-colors.lua" | moor --lang lua'';
      };

      custom.persist = {
        home.cache.directories = [ ".cache/hyprland" ];
      };
    };
}
