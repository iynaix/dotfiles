{
  inputs,
  pkgs,
  ...
}:
let
  mkFormat =
    height: ''"bestvideo[height<=?${toString height}][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"'';
  yt-dlp-config = pkgs.writeText "yt-dlp.conf" ''
    --add-metadata
    --format ${mkFormat 720};
    --no-mtime
    --output %(title)s.%(ext)s
    --sponsorblock-mark all
    --windows-filenames
  '';
  yt-dlp-wrapped = inputs.wrapper-manager.lib.wrapWith pkgs {
    basePackage = pkgs.yt-dlp;
    prependFlags = [
      "--config-locations"
      yt-dlp-config
    ];
  };
in
{
  environment = {
    systemPackages = [ yt-dlp-wrapped ];

    shellAliases = {
      yt = "yt-dlp";
      yt1080 = "ytdl --format ${mkFormat 1080}";
      ytaudio = "ytdl --audio-format mp3 --extract-audio";
      ytsubonly = "ytdl --skip-download --write-subs";
      ytplaylist = "ytdl --output '%(playlist_index)d - %(title)s.%(ext)s'";
    };
  };
}
