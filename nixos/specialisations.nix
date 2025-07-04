{ isLaptop, lib, ... }:
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
    # create an otg specialisation for laptops
    // optionalAttrs isLaptop { otg.configuration = { }; };
}
