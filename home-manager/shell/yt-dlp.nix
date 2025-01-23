{ config, pkgs, ... }:
let
  mkFormat =
    height: ''"bestvideo[height<=?${toString height}][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"'';

  # use positional arguments if provided, otherwise use yt.txt
  mkYtDlpWrapper = args: {
    runtimeInputs = with pkgs; [
      gawk
      yt-dlp
    ];
    text = ''
      is_flag() {
          [[ "$1" == -* ]]
      }

      args=(${args})

      has_positional=false
      for arg in "$@"; do
          if ! is_flag "$arg"; then
              has_positional=true
          fi
          args+=("$arg")
      done

      if ! $has_positional; then
          # filter out non urls
          while IFS= read -r url; do
              if [[ $url == http* ]]; then
                  args+=("$url")
              fi
          done < <(awk '!x[$0]++' "${config.xdg.userDirs.desktop}/yt.txt")
      fi

      pushd "${config.xdg.userDirs.download}" > /dev/null
      yt-dlp "''${args[@]}"
      popd > /dev/null
    '';
  };
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
    };
  };

  custom.shell.packages = {
    yt1080 = mkYtDlpWrapper "--format ${mkFormat 1080}";
    ytdl = mkYtDlpWrapper "--no-cache";
    ytaudio = mkYtDlpWrapper "--audio-format mp3 --extract-audio";
    ytsub = mkYtDlpWrapper "--write-auto-sub --sub-lang='en,eng' --convert-subs srt";
    ytsubonly = mkYtDlpWrapper "--write-auto-sub --sub-lang='en,eng' --convert-subs srt --skip-download --write-subs";
    ytplaylist = mkYtDlpWrapper "--output '%(playlist_index)d - %(title)s.%(ext)s'";
  };
}
