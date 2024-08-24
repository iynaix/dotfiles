{ config, pkgs, ... }:
let
  mkFormat =
    height: "bestvideo[height<=${toString height}][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best";

  # use positional arguments if provided, otherwise use yt.txt
  mkYtDlpWrapper = args: {
    runtimeInputs = [ pkgs.yt-dlp ];
    text = ''
      is_flag() {
          [[ "$1" == -* ]]
      }

      has_positional=false
      read -ra args <<< "${args}"

      for arg in "$@"; do
          if ! is_flag "$arg"; then
              has_positional=true
          fi
          args+=("$arg")
      done

      if ! $has_positional; then
          args+=("-a" "${config.xdg.userDirs.desktop}/yt.txt")
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
    yt1080 = mkYtDlpWrapper (mkFormat 1080);
    ytdl = mkYtDlpWrapper "--no-cache";
    ytaudio = mkYtDlpWrapper "--audio-format mp3 --extract-audio";
    ytsub = mkYtDlpWrapper "--write-auto-sub --sub-lang='en,eng' --convert-subs srt";
    ytsubonly = mkYtDlpWrapper "--skip-download --write-subs --write-auto-sub --sub-lang='en,eng' --convert-subs srt ";
    ytplaylist = mkYtDlpWrapper "--output '%(playlist_index)d - %(title)s.%(ext)s'";
  };
}
