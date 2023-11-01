{...}: {
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

  home.shellAliases = {
    yt = "yt-dlp";
    ytdl = "cd ~/Downloads && yt-dlp -a ~/Desktop/yt.txt";
    ytaudio = "yt --audio-format mp3 --extract-audio";
    ytsub = "yt --write-auto-sub --sub-lang='en,eng' --convert-subs srt";
    ytplaylist = "yt --output '%(playlist_index)d - %(title)s.%(ext)s'";
  };
}
