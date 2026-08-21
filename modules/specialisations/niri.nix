{
  enabled = false;

  config =
    { lib, ... }:
    {
      specialisation.niri = {
        configuration = {
          custom = {
            specialisation.current = "niri";
          };

          services.displayManager.defaultSession = lib.mkForce "niri";
        };
      };
    };
}
