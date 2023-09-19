{
  source,
  mkMpvPlugin,
}:
mkMpvPlugin (
  source
  // {
    outFile = "chapterskip.lua";

    meta = {
      description = "Automatically skip chapters based on title";
      homepage = "https://github.com/po5/chapterskip";
    };
  }
)
