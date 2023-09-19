{
  lib,
  mkMpvPlugin,
  source,
}:
mkMpvPlugin (
  source
  // {
    outFile = "dynamic-crop.lua";

    meta = {
      description = ''Script to "cropping" dynamically, hard-coded black bars detected with lavfi-cropdetect filter for Ultra Wide Screen or any screen (Smartphone/Tablet).'';
      homepage = "https://github.com/Ashyni/mpv-scripts";
      license = lib.licenses.mit;
    };
  }
)
