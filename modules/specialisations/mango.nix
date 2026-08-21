{
  enabled = false;

  config =
    { lib, ... }:
    {
      specialisation.mango = {
        configuration = {
          custom = {
            specialisation.current = "mango";
          };

          services.displayManager.defaultSession = lib.mkForce "mango";
        };
      };
    };
}
