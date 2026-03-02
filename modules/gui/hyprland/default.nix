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
            patches = [
              # black cursor on vertical monitor
              # https://github.com/hyprwm/Hyprland/discussions/13391
              (pkgs.fetchpatch {
                url = "https://github.com/hyprwm/Hyprland/commit/6b2c08d3e89b1cb6f9e609664915236bbe5115da.patch";
                hash = "sha256-N2zj/txbkqBAeEyUpRoUQVzNfrhpJmSfYkV/DDCeIsE=";
              })
            ];

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
            lib.assertMsg (lib.versionOlder config.programs.hyprland.package.version "0.55") "hyprland updated, sync with hyprnstack?"
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
