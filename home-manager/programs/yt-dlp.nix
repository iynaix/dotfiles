{ config, pkgs, ... }:
let
  yt-dlp' = pkgs.yt-dlp.overrideAttrs rec {
    version = "2024.8.1";
    # src = pkgs.fetchFromGitHub {
    #   owner = "yt-dlp";
    #   repo = "yt-dlp";
    #   rev = "f0993391e6052ec8f7aacc286609564f226943b9";
    #   hash = "sha256-2/pCHRzCi5m/7gDd1HxFEZUNGZOV0EICPGA4mtAadgg=";
    # };
    src = pkgs.fetchPypi {
      inherit version;
      pname = "yt_dlp";
      hash = "sha256-QxiqUjaUYRVi8BQZyNUmtmKnLfNO+LpFQBazTINmwVg=";
    };
  };

  mkFormat =
    height: "bestvideo[height<=${toString height}][ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best";

  # use positional arguments if provided, otherwise use yt.txt
  mkYtDlpWrapper = args: {
    runtimeInputs = [ yt-dlp' ];
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
      package = yt-dlp';
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
      # ytaudio = "yt-dlp --audio-format mp3 --extract-audio";
      # ytsub = "yt-dlp --write-auto-sub --sub-lang='en,eng' --convert-subs srt";
      # ytplaylist = "yt-dlp --output '%(playlist_index)d - %(title)s.%(ext)s'";
    };
  };

  custom.shell.packages = {
    yt1080 = mkYtDlpWrapper (mkFormat 1080);
    ytdl = mkYtDlpWrapper "--no-cache";
    ytaudio = mkYtDlpWrapper "--audio-format mp3 --extract-audio";
    ytsub = mkYtDlpWrapper "--write-auto-sub --sub-lang='en,eng' --convert-subs srt";
    ytplaylist = mkYtDlpWrapper "--output '%(playlist_index)d - %(title)s.%(ext)s'";
  };
}
