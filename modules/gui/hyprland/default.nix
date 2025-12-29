{ lib, ... }:
let
  inherit (lib)
    assertMsg
    mkIf
    versionOlder
    ;
in
{
  flake.nixosModules.wm =
    {
      config,
      host,
      pkgs,
      self,
      ...
    }:
    let
      hyprlandWrapped = self.wrapperModules.hyprland.apply (
        {
          inherit pkgs;
          package = pkgs.hyprland;
        }
        // config.custom.programs.hyprland
      );
    in
    {
      environment = {
        shellAliases = {
          hyprland = "Hyprland";
          hypr-log = "hyprctl rollinglog --follow";
        };

        variables = mkIf (host == "vm" || host == "vm-hyprland") {
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
            assertMsg (versionOlder config.programs.hyprland.package.version "0.53") "hyprland updated, sync with hyprnstack?"
          );
          true;
        package = hyprlandWrapped.wrapper;
      };

      custom.shell.packages = {
        # similar helper function to nvf-print-config
        hyprland-print-config = {
          text = /* sh */ ''
            cat "${hyprlandWrapped.flags."--config"}"
          '';
        };
      };

      custom.persist = {
        home.cache.directories = [ ".cache/hyprland" ];
      };
    };
}
