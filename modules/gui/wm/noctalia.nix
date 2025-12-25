{ lib, ... }:
let
  inherit (lib) mkIf;
in
{
  flake.nixosModules.wm =
    { config, ... }:
    mkIf (config.custom.specialisation.current == "noctalia") {
      services.noctalia-shell = {
        enable = true;
        # TODO: set custom target for niri / mango?
        target = "hyprland-session.target";
      };
    };
}
