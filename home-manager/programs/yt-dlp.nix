{ config, pkgs, ... }:
let
  yt-dlp' = pkgs.yt-dlp.overrideAttrs rec {
    version = "2024.7.16";
    src = pkgs.fetchFromGitHub {
      owner = "yt-dlp";
      repo = "yt-dlp";
      rev = "f0993391e6052ec8f7aacc286609564f226943b9";
      hash = "sha256-2/pCHRzCi5m/7gDd1HxFEZUNGZOV0EICPGA4mtAadgg=";
    };
  };
in
{
  programs = {
    yt-dlp = {
      enable = true;
      package = yt-dlp';
      settings = {
        add-metadata = true;
        format = "bestvideo[height<=1080][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best";
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
