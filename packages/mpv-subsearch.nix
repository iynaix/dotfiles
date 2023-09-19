{
  mkMpvPlugin,
  source,
}:
mkMpvPlugin (
  source
  // {
    outFile = "sub-search.lua";

    meta = {
      description = "Search for a phrase in subtitles and skip to it";
      homepage = "https://github.com/kelciour/mpv-scripts";
    };
  }
)
