{
  config,
  lib,
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
        blacklist = ["signs" "songs" "translation only" "forced"];
      }
      {
        alang = ["eng" "en" "unk" "unknown"];
        slang = ["eng" "en" "unk" "unknown"];
      }
      {
        alang = "*";
        slang = "eng";
      }
    ];
  };

  programs.mpv = lib.mkMerge [
    {
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
          chapterskip
          seekTo
          sponsorblock
          thumbfast
        ]
        # custom packaged scripts
        ++ (with pkgs.iynaix; [
          mpv-deletefile
          mpv-dynamic-crop
          # mpv-modernx
          mpv-nextfile
          mpv-sub-select
          mpv-subsearch
          mpv-thumbfast-osc
        ]);
    }

    # anime 4k
    (lib.optionalAttrs config.iynaix.anime4k.enable
      (let
        shaderList = files: (
          lib.pipe (["Clamp_Highlights"] ++ files) [
            (map (s: "${pkgs.iynaix.mpv-anime4k}/share/mpv/shaders/Anime4K_" + s + ".glsl"))
            (arr: lib.concatStringsSep ":" arr)
          ]
        );
        setShaders = text: files: ''no-osd change-list glsl-shaders set "${shaderList files}"; show-text "Anime4K: ${text} (HQ)"'';
      in {
        config = {
          # Optimized shaders for higher-end GPU: Mode A (HQ)
          # glsl-shaders = ''"~~/shaders/Anime4K_Clamp_Highlights.glsl:~~/shaders/Anime4K_Restore_CNN_VL.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_VL.glsl:~~/shaders/Anime4K_AutoDownscalePre_x2.glsl:~~/shaders/Anime4K_AutoDownscalePre_x4.glsl:~~/shaders/Anime4K_Upscale_CNN_x2_M.glsl"'';
        };
        bindings = {
          # clear shaders
          "CTRL+0" = ''no-osd change-list glsl-shaders clr ""; show-text "GLSL shaders cleared"'';
          # Optimized shaders for higher-end GPU:
          "CTRL+1" = setShaders "Mode A" [
            "Restore_CNN_VL"
            "Upscale_CNN_x2_VL"
            "AutoDownscalePre_x2"
            "AutoDownscalePre_x4"
            "Upscale_CNN_x2_M"
          ];
          "CTRL+2" = setShaders "Mode B" [
            "Restore_CNN_Soft_VL"
            "Upscale_CNN_x2_VL"
            "AutoDownscalePre_x2"
            "AutoDownscalePre_x4"
            "Upscale_CNN_x2_M"
          ];
          "CTRL+3" = setShaders "Mode C" [
            "Upscale_Denoise_CNN_x2_VL"
            "AutoDownscalePre_x2"
            "AutoDownscalePre_x4"
            "Upscale_CNN_x2_M"
          ];
          "CTRL+4" = setShaders "Mode A+A" [
            "Restore_CNN_VL"
            "Upscale_CNN_x2_VL"
            "Restore_CNN_M"
            "AutoDownscalePre_x2"
            "AutoDownscalePre_x4"
            "Upscale_CNN_x2_M"
          ];
          "CTRL+5" = setShaders "Mode B+B" [
            "Restore_CNN_Soft_VL"
            "Upscale_CNN_x2_VL"
            "AutoDownscalePre_x2"
            "AutoDownscalePre_x4"
            "Restore_CNN_Soft_M"
            "Upscale_CNN_x2_M"
          ];
          "CTRL+6" = setShaders "Mode C+A" [
            "Upscale_Denoise_CNN_x2_VL"
            "AutoDownscalePre_x2"
            "AutoDownscalePre_x4"
            "Restore_CNN_M"
            "Upscale_CNN_x2_M"
          ];
        };
      }))
  ];

  home.shellAliases = {
    # subliminal is broken
    # subs = "subliminal download -l 'en' -l 'eng' -s";
  };

  iynaix.persist = {
    home.directories = [
      ".local/state/mpv" # watch later
    ];
  };
}
