{ lib, ... }:
{
  flake.modules.nixos.wm =
    { config, ... }:
    {
      custom.programs = {
        mango.settings = {
          monitorrule = map (
            mon:
            lib.concatMapStringsSep "," toString [
              "name:${mon.name}"
              "rr:${toString mon.transform}"
              "scale:${toString mon.scale}"
              "x:${toString mon.x}"
              "y:${toString mon.y}"
              "width:${toString mon.width}"
              "height:${toString mon.height}"
              "refresh:${toString mon.refreshRate}"
            ]
          ) config.custom.hardware.monitors;

          tagrule = lib.flatten (
            map (
              mon:
              map (
                wksp:
                lib.concatMapStringsSep "," toString [
                  "id:${toString wksp}"
                  "monitor_name:${mon.name}"
                  "layout_name:${if mon.isVertical then "vertical_tile" else "tile"}"
                  "mfact:0.5"
                  "nmaster:1"
                ]
              ) (lib.range 1 9)
            ) config.custom.hardware.monitors
          );
        };
      };
    };
}
