{
  tags = [ "laptop" ];

  config =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.brightnessctl
      ];

      custom = {
        programs.umbriel.settings.keybinds = {
          "XF86MonBrightnessDown" = {
            action = "spawn:brightnessctl set 5%-";
            allow_when_locked = true;
          };
          "XF86MonBrightnessUp" = {
            action = "spawn:brightnessctl set +5%";
            allow_when_locked = true;
          };
        };
      };
    };
}
