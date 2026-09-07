{
  enabled = false;

  config =
    { lib, ... }:
    {
      # boot into a tty without a DE / WM
      specialisation.tty = {
        configuration = {
          custom = {
            specialisation.current = "tty";
          };

          services.displayManager.noctalia-greeter.enable = lib.mkForce false;
        };
      };
    };
}
