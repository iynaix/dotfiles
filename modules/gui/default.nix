{ lib, ... }:
{
  flake.modules.nixos.core =
    { config, pkgs, ... }:
    {
      options.custom = {
        nixJson = lib.mkOption {
          type = lib.types.submodule { freeformType = (pkgs.formats.json { }).type; };
          default = { };
          description = "Data to be written to nix.json for use in other programs at runtime.";
        };
      };

      config =
        let
          inherit (config.custom.constants) user;
        in
        {
          environment.systemPackages = [
            # run gparted with all the permissions crap fixed, I don't want it permanently installed
            (pkgs.writeShellApplication {
              name = "gparted";
              # fix Authorization required, but no authorization protocol specified error
              # fix gparted "cannot open display: :0" error
              # respectively
              text = /* sh */ ''
                nix-shell -p xhost gparted --command "xhost si:localuser:root && xhost +local:${user} && sudo gparted"
              '';
            })
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
