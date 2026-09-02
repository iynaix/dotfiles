{
  tags = [ "laptop" ];

  config =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.brightnessctl
      ];

      custom = {
        wm.binds = {
          "XF86MonBrightnessDown" = {
            spawn = "brightnessctl set 5%-";
            hyprlandArgs = {
              locked = true;
            };
            umbrielArgs = {
              allow-when-locked = true;
            };
          };
          "XF86MonBrightnessUp" = {
            spawn = "brightnessctl set +5%";
            hyprlandArgs = {
              locked = true;
            };
            umbrielArgs = {
              allow-when-locked = true;
            };
          };
        };
      };
    };
}
