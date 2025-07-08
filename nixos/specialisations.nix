{
  config,
  isLaptop,
  lib,
  ...
}:
let
  inherit (lib) optionalAttrs;
in
{
  specialisation =
    {
      # boot into a tty without a DE / WM
      tty.configuration = {
        hm.custom.wm = "tty";
      };
    }
    // optionalAttrs (config.hm.custom.wm == "hyprland") {
      niri.configuration = {
        hm.custom.wm = "niri";
      };
    }
    // optionalAttrs (config.hm.custom.wm == "niri") {
      hyprland.configuration = {
        hm.custom.wm = "hyprland";
      };
    }
    # create an otg specialisation for laptops
    // optionalAttrs isLaptop { otg.configuration = { }; };
}
