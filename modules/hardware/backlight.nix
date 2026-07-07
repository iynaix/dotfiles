{ lib, ... }:
{
  flake.modules.nixos.hardware_backlight =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.brightnessctl
      ];

      custom = {
        programs = {
          noctalia.settingsReducers = [
            # enable control center brightness card
            (
              prev:
              lib.recursiveUpdate prev {
                controlCenter.cards = map (
                  card: if card.id == "brightness-card" then card // { enabled = true; } else card
                ) prev.controlCenter.cards;
              }
            )
          ];
        };

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
