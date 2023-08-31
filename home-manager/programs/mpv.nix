{
  pkgs,
  isNixOS,
  ...
}: {
  xdg.configFile = {
    "mpv/script-opts/chapterskip.conf".text = "categories=sponsorblock>SponsorBlock";
    "mpv/script-opts/sub-select.json".text = builtins.toJSON [
      {
        alang = "jpn";
        slang = ["en" "eng"];
        blacklist = ["signs" "songs" "translation only"];
      }
      {
        alang = "eng";
        slang = ["forced" "no"];
      }
      {
        alang = "*";
        slang = "eng";
      }
    ];
  };

  programs = {
    mpv = {
      enable = isNixOS;
      bindings = {
        MBTN_LEFT = "cycle pause";
        WHEEL_UP = "ignore";
        WHEEL_DOWN = "ignore";
        RIGHT = "seek 10";
        LEFT = "seek -10";
        l = "seek  10";
        h = "seek -10";
        j = "seek  -60";
        k = "seek 60";
        S = "cycle sub";
        PGUP = "add chapter 1"; # skip to next chapter
        PGDWN = "add chapter -1"; # skip to previous chapter
        "[" = "add speed -0.1";
        "]" = "add speed 0.1";

        I = ''cycle-values vf "sub,lavfi=negate" ""''; # invert colors

        # disable annoying defaults
        "1" = "ignore";
        "2" = "ignore";
        "3" = "ignore";
        "4" = "ignore";
        "5" = "ignore";
        "6" = "ignore";
        "7" = "ignore";
        "8" = "ignore";
        "9" = "ignore";
        "0" = "ignore";
        "/" = "ignore";
        "*" = "ignore";
        "Alt+left" = "ignore";
        "Alt+right" = "ignore";
        "Alt+up" = "ignore";
        "Alt+down" = "ignore";
      };
      config = {
        profile = "gpu-hq";
        input-ipc-server = "/tmp/mpvsocket";
        # no-border = true;
        save-position-on-quit = true;

        sub-auto = "fuzzy";
        sub-use-margins = "no";
        sub-font-size = 45;
        sub-scale-by-window = "yes";
        sub-scale-with-window = "no";

        slang = "en,eng,english";
        alang = "jp,jpn,japanese,en,eng,english";

        write-filename-in-watch-later-config = true;
        script-opts = "chapterskip-skip=opening;ending;sponsorblock";

        # ModernX
        # osc = "no";
        # border = "no";
      };
      scripts = with pkgs.mpvScripts;
        [
          seekTo
          sponsorblock
          thumbfast
        ]
        # custom packaged scripts
        ++ (with pkgs.iynaix; [
          mpv-chapterskip
          mpv-deletefile
          # mpv-modernx
          mpv-nextfile
          mpv-sub-select
          mpv-subsearch
          mpv-thumbfast-osc
        ]);
    };
  };

  # setup subliminal
  home.packages = with pkgs; [
    python3Packages.subliminal
  ];

  home.shellAliases = {
    subs = "subliminal download -l 'en' -l 'eng' -s";
  };

  iynaix.persist.home.directories = [
    ".local/state/mpv" # watch later
  ];
}
