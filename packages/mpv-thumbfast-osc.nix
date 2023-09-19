{
  lib,
  mkMpvPlugin,
  source,
}:
mkMpvPlugin (
  source
  // {
    inFile = "player/lua/osc.lua";
    outFile = "thumbfast-osc.lua";

    meta = {
      description = "High-performance on-the-fly thumbnailer for mpv";
      homepage = "https://github.com/po5/thumbfast/vanilla-osc";
      license = lib.licenses.mpl20;
    };
  }
)
