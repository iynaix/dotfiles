{ pkgs, ... }:
let
  mkFormat =
    height: ''"bestvideo[height<=?${toString height}][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"'';
in
{
  programs = {
    yt-dlp = {
      enable = true;
      package = pkgs.yt-dlp;
      settings = {
        add-metadata = true;
        format = mkFormat 720;
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
      yt1080 = "ytdl --format ${mkFormat 1080}";
      ytaudio = "ytdl --audio-format mp3 --extract-audio";
      ytsub = "ytdl --write-auto-sub --sub-lang='en,eng' --convert-subs srt";
      ytsubonly = "ytdl --write-auto-sub --sub-lang='en,eng' --convert-subs srt --skip-download --write-subs";
      ytplaylist = "ytdl --output '%(playlist_index)d - %(title)s.%(ext)s'";
    };
  };
}
