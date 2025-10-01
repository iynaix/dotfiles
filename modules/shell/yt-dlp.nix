{ pkgs, ... }:
let
  mkFormat =
    height: ''bestvideo[height<=?${toString height}][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best'';
in
{
  custom.wrappers = [
    (_: _prev: {
      yt-dlp = {
        flags = {
          "--add-metadata" = { };
          "--format" = mkFormat 720;
          "--no-mtime" = { };
          "--output" = "%(title)s.%(ext)s";
          "--sponsorblock-mark" = "all";
          "--windows-filenames" = { };
        };
      };
    })
  ];

  environment = {
    shellAliases = {
      yt = "yt-dlp";
      yt1080 = ''ytdl --format "${mkFormat 1080}"'';
      ytaudio = "ytdl --audio-format mp3 --extract-audio";
      ytsubonly = "ytdl --skip-download --write-subs";
      ytplaylist = "ytdl --output '%(playlist_index)d - %(title)s.%(ext)s'";
    };

    systemPackages = [ pkgs.yt-dlp ];
  };
}
