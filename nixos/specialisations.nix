{ isLaptop, lib, ... }:
let
  inherit (lib) mkForce optionalAttrs;
in
{
  specialisation =
    {
      # boot into a tty without a DE / WM
      tty.configuration = {
        hm.custom.hyprland.enable = mkForce false;

        services = {
          xserver = {
            enable = mkForce false;
            desktopManager.plasma5.enable = mkForce false;
          };
          desktopManager.plasma6.enable = mkForce false;
        };
      };
    }
    # create an otg specialisation for laptops
    // optionalAttrs isLaptop {
      otg.configuration = { };
    };
}
