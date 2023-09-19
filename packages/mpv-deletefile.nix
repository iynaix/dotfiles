{
  lib,
  mkMpvPlugin,
  source,
}:
mkMpvPlugin (
  source
  // {
    inFile = "delete_file.lua";
    outFile = "deletefile.lua";

    meta = {
      description = "Deletes files played through mpv";
      homepage = "https://github.com/zenyd/mpv-scripts";
      license = lib.licenses.gpl3;
    };
  }
)
