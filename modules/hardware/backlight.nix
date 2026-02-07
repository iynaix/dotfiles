{
  flake.nixosModules.backlight =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.brightnessctl
      ];

      custom.programs = {
        hyprland.settings.bind = [
          ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
          ",XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ];

        niri.settings.binds = {
          "XF86MonBrightnessDown" = {
            spawn = [
              "brightnessctl"
              "set"
              "5%-"
            ];
            parameters = {
              allow-when-locked = true;
            };
          };
          "XF86MonBrightnessUp" = {
            spawn = [
              "brightnessctl"
              "set"
              "+5%"
            ];
            parameters = {
              allow-when-locked = true;
            };
          };
        };

        mango.settings.bind = [
          "NONE,XF86MonBrightnessDown, spawn, brightnessctl set 5%-"
          "NONE,XF86MonBrightnessUp, spawn, brightnessctl set +5%"
        ];
      };
    };
}
