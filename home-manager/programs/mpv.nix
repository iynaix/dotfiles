{
  config,
  isNixOS,
  lib,
  pkgs,
  ...
}:
let
  shaders_dir = "${pkgs.mpv-shim-default-shaders}/share/mpv-shim-default-shaders/shaders";
  shaderList =
    shaders:
    lib.concatMapStringsSep ":"
      (s: if (lib.hasSuffix ".hook" s) then "${shaders_dir}/${s}" else "${shaders_dir}/${s}.glsl")
      (
        # Adds a very small amount of static noise to help with debanding.
        [
          "noise_static_luma.hook"
          "noise_static_chroma.hook"
        ]
        ++ shaders
      );
in
{
  xdg.configFile = {
    "mpv/script-opts/chapterskip.conf".text = "categories=sponsorblock>SponsorBlock";
    "mpv/script-opts/sub-select.json".text = lib.strings.toJSON [
      {
        alang = "jpn";
        slang = [
          "en"
          "eng"
        ];
        blacklist = [
          "signs"
          "songs"
          "translation only"
          "forced"
        ];
      }
      {
        alang = [
          "eng"
          "en"
          "unk"
          "unknown"
        ];
        slang = [
          "eng"
          "en"
          "unk"
          "unknown"
        ];
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
        # recommended mpv settings can be referenced here:
        # https://iamscum.wordpress.com/guides/videoplayback-guide/mpv-conf
        profile = "gpu-hq";
        input-ipc-server = "/tmp/mpvsocket";
        # no-border = true;
        save-position-on-quit = true;
        force-seekable = "yes";
        cursor-autohide = 100;

        vo = "gpu-next";
        gpu-api = "vulkan";
        hwdec-codecs = "all";

        # forces showing subtitles while seeking through the video
        demuxer-mkv-subtitle-preroll = "yes";

        deband = true;
        deband_grain = 0;
        deband_range = 12;
        deband_threshold = 32;

        dither_depth = "auto";
        dither = "fruit";

        sub-auto = "fuzzy";
        # some settings fixing VOB/PGS subtitles (creating blur & changing yellow subs to gray)
        sub-gauss = "1.0";
        sub-gray = "yes";
        sub-use-margins = "no";
        sub-font-size = 45;
        sub-scale-by-window = "yes";
        sub-scale-with-window = "no";

        screenshot-directory = "${config.xdg.userDirs.pictures}/Screenshots";

        slang = "en,eng,english";
        alang = "jp,jpn,japanese,en,eng,english";

        write-filename-in-watch-later-config = true;
        script-opts = "chapterskip-skip=opening;ending;sponsorblock";

        # ModernX
        # osc = "no";
        # border = "no";
      };
      scripts =
        with pkgs.mpvScripts;
        [
          chapterskip
          seekTo
          sponsorblock
          thumbfast
        ]
        # custom packaged scripts
        ++ (with pkgs.custom; [
          mpv-deletefile
          mpv-dynamic-crop
          # mpv-modernx
          mpv-nextfile
          mpv-sub-select
          mpv-subsearch
          mpv-thumbfast-osc
        ]);
    }

    # anime profile settings
    (
      let
        anime4k_shaders = map (s: "Anime4K_" + s) [
          "Clamp_Highlights"
          "Restore_CNN_VL"
          "Upscale_CNN_x2_VL"
          "AutoDownscalePre_x2"
          "AutoDownscalePre_x4"
          "Upscale_CNN_x2_M"
        ];
        createShaderKeybind =
          shaders: description:
          ''no-osd change-list glsl-shaders set "${shaderList shaders}"; show-text "${description}"'';
      in
      lib.optionalAttrs config.custom.mpv-anime.enable {
        # auto apply anime shaders for anime videos
        profiles.anime = {
          profile-desc = "Anime";
          profile-cond = "path:find('[Aa]nime') or path:find('Erai-raws')";
          profile-restore = "copy-equal";

          # https://kokomins.wordpress.com/2019/10/14/mpv-config-guide/#advanced-video-scaling-config
          deband-iterations = 2; # Range 1-16. Higher = better quality but more GPU usage. >5 is redundant.
          deband-threshold = 35; # Range 0-4096. Deband strength.
          deband-range = 20; # Range 1-64. Range of deband. Too high may destroy details.
          deband-grain = 5; # Range 0-4096. Inject grain to cover up bad banding, higher value needed for poor sources.

          # set shader defaults
          glsl-shaders = shaderList anime4k_shaders;

          dscale = "mitchell";
          cscale = "spline64"; # or ewa_lanczossoft
        };
        bindings =
          {
            # clear all shaders
            "CTRL+0" = ''no-osd change-list glsl-shaders clr ""; show-text "Shaders cleared"'';
          }
          // lib.listToAttrs (
            lib.imap
              (i: v: {
                name = "CTRL+${toString i}";
                value = v;
              })
              [
                # Anime4K shaders
                (createShaderKeybind anime4k_shaders "Anime4K: Mode A (HQ)")
                # NVScaler shaders
                (createShaderKeybind [ "NVScaler" ] "NVScaler x2")
                # AMD FSR shaders
                (createShaderKeybind [ "FSR" ] "AMD FidelityFX Super Resolution")
                # AMD Contrast Adaptive Sharpening
                (createShaderKeybind [ "CAS-scaled" ] "AMD FidelityFX Contrast Adaptive Sharpening")
                # FSRCNNX shaders
                (createShaderKeybind [ "FSRCNNX_x2_16-0-4-1" ] "FSRCNNX High")
                (createShaderKeybind [ "FSRCNNX_x2_8-0-4-1" ] "FSRCNNX")
                # NNEDI3 shaders
                (createShaderKeybind [ "nnedi3-nns256-win8x6.hook" ] "NNEDI3")
              ]
          );
      }
    )
  ];

  wayland.windowManager.hyprland.settings = {
    # fix mpv-dynamic-crop unmaximizing the window
    windowrulev2 = [ "nomaximizerequest,class:(mpv)" ];
  };

  home.shellAliases = {
    # subliminal is broken
    # subs = "subliminal download -l 'en' -l 'eng' -s";
  };

  custom.persist = {
    home.directories = [
      ".local/state/mpv" # watch later
    ];
  };
}
