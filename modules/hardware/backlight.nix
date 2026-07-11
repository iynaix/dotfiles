{
  flake.modules.nixos.hardware_backlight =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.brightnessctl
      ];

      custom = {
        wm.binds = {
          "XF86MonBrightnessDown" = _: {
            spawn = "brightnessctl set 5%-";
            hyprlandArgs = {
              locked = true;
            };
            niriArgs = {
              allow-when-locked = true;
            };
          };
          "XF86MonBrightnessUp" = _: {
            spawn = "brightnessctl set +5%";
            hyprlandArgs = {
              locked = true;
            };
            niriArgs = {
              allow-when-locked = true;
            };
          };
        };
      };
    };
}
