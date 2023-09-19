{
  mkMpvPlugin,
  source,
}:
mkMpvPlugin (
  source
  // {
    outFile = "sub-select.lua";

    meta = {
      description = "Automatically skip chapters based on title";
      homepage = "https://github.com/CogentRedTester/mpv-sub-select";
    };
  }
)
