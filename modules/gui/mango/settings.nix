{ lib, ... }:
{
  flake.modules.nixos.wm =
    { config, ... }:
    {
      custom.programs = {
        mango.settings = {
          # Window effect
          blur = 0;
          blur_layer = 0;
          blur_optimized = 1;
          blur_params_num_passes = 2;
          blur_params_radius = 5;
          blur_params_noise = 0.02;
          blur_params_brightness = 0.9;
          blur_params_contrast = 0.9;
          blur_params_saturation = 1.2;

          shadows = 0;
          layer_shadows = 0;
          shadow_only_floating = 1;
          shadows_size = 10;
          shadows_blur = 15;
          shadows_position_x = 0;
          shadows_position_y = 0;
          shadowscolor = "0x000000ff";

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
