{user, ...}: {
  home-manager.users.${user} = {
    xdg.configFile."mpv" = {
      source = ./mpv;
      recursive = true;
    };

    programs = {
      mpv = {
        enable = true;
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
        };
      };
    };
  };
}
