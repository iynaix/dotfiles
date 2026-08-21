{
  enabled = true;

  config =
    { lib, ... }:
    {
      specialisation.hyprland = {
        configuration = {
          custom = {
            specialisation.current = "hyprland";
          };

          services.displayManager.defaultSession = lib.mkForce "hyprland-uwsm";
        };
      };
    };
}
