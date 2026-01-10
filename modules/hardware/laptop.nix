topLevel:
let
  inherit (topLevel) lib;
in
{
  flake.nixosModules.laptop = {
    imports = with topLevel.config.flake.nixosModules; [
      backlight
      bluetooth
      keyd
      wifi
    ];

    # required for noctalia's battery module
    services.upower.enable = true;

    custom.programs.noctalia.settingsReducers = [
      # enable control center brightness card
      (
        prev:
        lib.recursiveUpdate prev {
          controlCenter.cards = map (
            card: if card.id == "brightness-card" then card // { enabled = true; } else card
          ) prev.controlCenter.cards;
        }
      )
      # add bluetooth shortcut after network
      (
        prev:
        lib.recursiveUpdate prev {
          controlCenter.shortcuts.left = lib.concatMap (
            shortcut:
            if shortcut.id == "Network" then
              [
                shortcut
                { id = "Bluetooth"; }
              ]
            else
              [ shortcut ]
          ) prev.controlCenter.shortcuts.left;
        }
      )
    ];
  };
}
