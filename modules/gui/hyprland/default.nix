{ lib, self, ... }:
{
  flake.modules.nixos.wm =
    {
      config,
      pkgs,
      ...
    }:
    let
      hyprlandWrapped = self.wrapperModules.hyprland.apply (
        {
          inherit pkgs;
          # remove the uwsm session
          package = pkgs.hyprland.overrideAttrs (o: {
            passthru = o.passthru // {
              providedSessions = [ "hyprland" ];
            };
          });
          filesToExclude = [ "share/wayland-sessions/hyprland-uwsm.desktop" ];
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
            default = "hyprland";
            "org.freedesktop.impl.portal.FileChooser" = "gtk";
          };
        };
      };

      programs.hyprland = {
        enable = true;
        package = hyprlandWrapped.wrapper;
      };

      custom.programs.print-config = {
        hyprland = /* sh */ ''cat "${
          hyprlandWrapped.flags."--config"
        }" "${config.hj.xdg.config.directory}/hypr/hyprland.conf" "${config.hj.xdg.config.directory}/hypr/noctalia-colors.conf" | moor'';
      };

      custom.persist = {
        home.cache.directories = [ ".cache/hyprland" ];
      };
    };
}
