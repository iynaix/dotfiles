{
  enabled = false;

  config =
    { lib, ... }:
    {
      specialisation.umbriel = {
        configuration = {
          custom = {
            specialisation.current = "umbriel";
          };

          services.displayManager.defaultSession = lib.mkForce "umbriel";
        };
      };
    };
}
