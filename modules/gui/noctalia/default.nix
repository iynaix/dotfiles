{ lib, ... }:
let
  inherit (lib) mkIf;
in
{
  flake.nixosModules.wm =
    { config, ... }:
    let
      noctaliaSettings = import ./_settings.nix;
    in
    mkIf (config.custom.specialisation.current == "noctalia") {
      services.noctalia-shell = {
        enable = true;
        # TODO: set custom target for niri / mango?
        target = "hyprland-session.target";
      };

      hj.xdg.config.files = {
        "noctalia/settings.json".text = lib.strings.toJSON noctaliaSettings;
      };

      custom.persist = {
        home = {
          directories = [
            ".config/noctalia"
          ];
        };
      };
    };
}
