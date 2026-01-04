{ lib, ... }:
let
  inherit (lib) mkOption;
  inherit (lib.types) submodule;
in
{
  flake.nixosModules.core =
    {
      config,
      host,
      pkgs,
      ...
    }:
    {
      options.custom = {
        nixJson = mkOption {
          type = submodule { freeformType = (pkgs.formats.json { }).type; };
          default = { };
          description = "Data to be written to nix.json for use in other programs at runtime.";
        };
      };

      config = {
        hj.xdg.state.files = {
          # misc information for nix
          "nix.json" = {
            text = lib.strings.toJSON (
              # use pywal template syntax here
              {
                fallbackWallpaper = "${../wallpaper-default.jpg}";
                inherit (config.custom.hardware) monitors;
                inherit host;
              }
              // config.custom.nixJson
            );
          };
        };
      };
    };
}
