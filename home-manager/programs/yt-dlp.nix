{ config, pkgs, ... }:
let
  yt-dlp' = pkgs.yt-dlp;
in
# .overrideAttrs rec {
#   version = "2024.7.9";
#   src = pkgs.fetchPypi {
#     inherit version;
#     pname = "yt_dlp";
#     hash = "sha256-4Z8A+eVekLyhyUvK+AmqM+UWNL6fDeLfhKctMgaTT5Q=";
#   };
# };
{
  programs = {
    yt-dlp = {
      enable = true;
      package = yt-dlp';
      settings = {
        add-metadata = true;
        format = "best[ext=mp4]";
        no-mtime = true;
        output = "%(title)s.%(ext)s";
        sponsorblock-mark = "all";
        windows-filenames = true;
      };
    };
  };

  home = {
    shellAliases = {
      yt = "yt-dlp";
      ytaudio = "yt-dlp --audio-format mp3 --extract-audio";
      ytsub = "yt-dlp --write-auto-sub --sub-lang='en,eng' --convert-subs srt";
      ytplaylist = "yt-dlp --output '%(playlist_index)d - %(title)s.%(ext)s'";
    };
  };

  custom.shell.packages = {
    ytdl = {
      runtimeInputs = [ yt-dlp' ];
      text = ''
        pushd "${config.xdg.userDirs.download}" > /dev/null
        yt-dlp --no-cache -a "${config.xdg.userDirs.desktop}/yt.txt"
        popd > /dev/null
      '';
    };
  };
}
