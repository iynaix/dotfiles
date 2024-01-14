{pkgs, ...}: let
  ytdl = pkgs.writeShellApplication {
    name = "ytdl";
    runtimeInputs = with pkgs; [yt-dlp];
    text = ''
      cd "$HOME/Downloads"

      # add and remove torrent lines
      if command -v "torrents-add" &> /dev/null; then
        torrents-add
      fi

      # remove ugly unicode characters, sleep to wait for renames to complete
      yt-dlp -a "$HOME/Desktop/yt.txt" && \
      sleep 3 && \
      find -L "$HOME/Downloads" -maxdepth 1 -type f \( \
        -name '*？*' \
        -o -name '*｜*' \
        -o -name '*|*' \
        -o -name '*:*' \
        -o -name '*：*' \
        -o -name '*—*' \) \
        -execdir rename '？' "" {} \; \
        -execdir rename '｜' "-" {} \; \
        -execdir rename '|' "" {} \; \
        -execdir rename ':' " -" {} \; \
        -execdir rename '：' " -" {} \; \
        -execdir rename '—' "-" {} \;

      cd - > /dev/null
    '';
  };
in {
  programs = {
    yt-dlp = {
      enable = true;
      settings = {
        add-metadata = true;
        no-mtime = true;
        format = "best[ext=mp4]";
        sponsorblock-mark = "all";
        output = "%(title)s.%(ext)s";
      };
    };
  };

  home = {
    packages = [ytdl];

    shellAliases = {
      yt = "yt-dlp";
      ytaudio = "yt-dlp --audio-format mp3 --extract-audio";
      ytsub = "yt-dlp --write-auto-sub --sub-lang='en,eng' --convert-subs srt";
      ytplaylist = "yt-dlp --output '%(playlist_index)d - %(title)s.%(ext)s'";
    };
  };
}
