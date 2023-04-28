{
  pkgs,
  user,
  config,
  lib,
  ...
}: let
  cfg = config.iynaix.torrenters;
in {
  imports = [
    ./mpv.nix
    ./pathofbuilding.nix
    ./smplayer.nix
    ./transmission.nix
    ./sonarr.nix
  ];

  options.iynaix.torrenters = {
    enable = lib.mkEnableOption "Torrenting Applications";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user} = {
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

        zsh.shellAliases = {
          yt = "yt-dlp";
          ytaudio = "yt --audio-format mp3 --extract-audio";
          ytsub = "yt --write-auto-sub --sub-lang='en,eng' --convert-subs srt";
          ytplaylist = "yt --output '%(playlist_index)d - %(title)s.%(ext)s'";
        };
      };
    };
  };
}
