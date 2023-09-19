{
  lib,
  mkMpvPlugin,
  source,
}:
mkMpvPlugin (
  source
  // {
    outFile = "nextfile.lua";

    meta = {
      description = "Force open next or previous file in the currently playing files directory";
      homepage = "https://github.com/jonniek/mpv-nextfile";
      license = lib.licenses.unlicense;
    };
  }
)
