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
          # remove the uwsm session
          filesToExclude = [ "share/wayland-sessions/hyprland-uwsm.desktop" ];
          passthru.providedSessions = [ "hyprland" ];
        }
        // config.custom.programs.hyprland
      );
      inherit (config.custom.constants) host;
    in
    {
      environment = {
        shellAliases = {
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
      };

      custom.programs.print-config = {
        hyprland = /* sh */ ''
          cat "${hyprland'.configuration.constructFiles.generatedConfig.outPath}" "${config.hj.xdg.config.directory}/hypr/noctalia/noctalia-colors.lua" | \
            ${lib.getExe pkgs.stylua} --indent-type Spaces --indent-width 2 - | \
            moor --lang lua'';
      };

      custom.persist = {
        home.cache.directories = [ ".cache/hyprland" ];
      };
    };
}
