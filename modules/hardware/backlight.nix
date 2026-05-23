{ lib, ... }:
{
  flake.modules.nixos.hardware_backlight =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.brightnessctl
      ];

      custom.programs = {
        hyprland.settings = /* lua */ ''
          hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))
          hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"))
        '';

        niri.settings.binds = {
          "XF86MonBrightnessDown" = _: {
            props = {
              allow-when-locked = true;
            };
            content = {
              spawn = [
                "brightnessctl"
                "set"
                "5%-"
              ];
            };
          };
          "XF86MonBrightnessUp" = _: {
            props = {
              allow-when-locked = true;
            };
            content = {
              spawn = [
                "brightnessctl"
                "set"
                "+5%"
              ];
            };
          };
        };

        mango.settings.bind = [
          "NONE,XF86MonBrightnessDown, spawn, brightnessctl set 5%-"
          "NONE,XF86MonBrightnessUp, spawn, brightnessctl set +5%"
        ];

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
    };
}
