{ lib, ... }:
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
            action.spawn = [
              "brightnessctl"
              "set"
              "5%-"
            ];
            allow-when-locked = true;
          };
          "XF86MonBrightnessUp" = {
            action.spawn = [
              "brightnessctl"
              "set"
              "+5%"
            ];
            allow-when-locked = true;
          };
        };

        waybar.config = {
          backlight = {
            format = "{icon}   {percent}%";
            format-icons = [
              "󰃞"
              "󰃟"
              "󰃝"
              "󰃠"
            ];
            on-scroll-down = "brightnessctl s 1%-";
            on-scroll-up = "brightnessctl s +1%";
          };

          modules-right = lib.mkOrder 600 [ "backlight" ];
        };
      };
    };
}
