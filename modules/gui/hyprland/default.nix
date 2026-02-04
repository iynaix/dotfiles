{ lib, self, ... }:
{
  flake.nixosModules.wm =
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

        variables = lib.mkIf (host == "vm" || host == "vm-hyprland") {
          WLR_RENDERER_ALLOW_SOFTWARE = "1";
        };
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
        enable =
          assert (
            lib.assertMsg (lib.versionOlder config.programs.hyprland.package.version "0.54") "hyprland updated, sync with hyprnstack?"
          );
          true;
        package = hyprlandWrapped.wrapper;
      };

      custom.programs.print-config = {
        hyprland = /* sh */ ''cat "${hyprlandWrapped.flags."--config"}"'';
      };

      custom.persist = {
        home.cache.directories = [ ".cache/hyprland" ];
      };
    };
}
