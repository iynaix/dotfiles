{ lib, ... }:
{
  flake.nixosModules.core =
    { config, pkgs, ... }:
    {
      options.custom = {
        programs = {
          dotfiles-rs = lib.mkOption {
            type = lib.types.package;
            default = pkgs.custom.dotfiles-rs;
            description = "dotfiles-rs package";
          };
        };

        nixJson = lib.mkOption {
          type = lib.types.submodule { freeformType = (pkgs.formats.json { }).type; };
          default = { };
          description = "Data to be written to nix.json for use in other programs at runtime.";
        };
      };

      config = {
        environment.systemPackages = [
          config.custom.programs.dotfiles-rs
        ];

        hj.xdg.state.files = {
          # misc information for nix
          "nix.json" = {
            text = lib.strings.toJSON (
              # use pywal template syntax here
              {
                fallbackWallpaper = "${../wallpaper-default.jpg}";
                inherit (config.custom.hardware) monitors;
                inherit (config.custom.constants) host;
              }
              // config.custom.nixJson
            );
          };
        };
      };
    };
}
