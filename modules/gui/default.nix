{ lib, ... }:
{
  flake.nixosModules.core =
    { config, pkgs, ... }:
    {
      options.custom = {
        nixJson = lib.mkOption {
          type = lib.types.submodule { freeformType = (pkgs.formats.json { }).type; };
          default = { };
          description = "Data to be written to nix.json for use in other programs at runtime.";
        };
      };

      config = {
        environment.systemPackages = [
          pkgs.custom.dotfiles-rs
        ];

        hj.xdg.state.files = {
          # misc information for nix
          "nix.json" = {
            generator = lib.strings.toJSON;
            value = {
              fallbackWallpaper = "${../wallpaper-default.jpg}";
              inherit (config.custom.hardware) monitors;
              inherit (config.custom.constants) host;
            }
            // config.custom.nixJson;
          };
        };
      };
    };
}
