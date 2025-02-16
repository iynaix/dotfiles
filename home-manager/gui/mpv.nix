{
  config,
  isNixOS,
  lib,
  pkgs,
  ...
}:
{
  options.custom = with lib; {
    mpv-anime.enable = mkEnableOption "mpv-anime" // {
      default = true;
    };
  };

  config = lib.mkIf (!config.custom.headless) (
    lib.mkMerge [
      {
        programs.mpv = {
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
            force-seekable = true;
            cursor-autohide = 100;

            vo = "gpu-next";
            gpu-api = "vulkan";
            hwdec-codecs = "all";

            # forces showing subtitles while seeking through the video
            demuxer-mkv-subtitle-preroll = true;

            deband = true;
            deband-grain = 0;
            deband-range = 12;
            deband-threshold = 32;

            dither-depth = "auto";
            dither = "fruit";

            sub-auto = "fuzzy";
            # some settings fixing VOB/PGS subtitles (creating blur & changing yellow subs to gray)
            sub-gauss = "1.0";
            sub-gray = true;
            sub-use-margins = false;
            sub-font-size = 45;
            sub-scale-by-window = true;
            sub-scale-with-window = false;

            screenshot-directory = "${config.xdg.userDirs.pictures}/Screenshots";

            slang = "en,eng,english";
            alang = "jp,jpn,japanese,en,eng,english";

            write-filename-in-watch-later-config = true;
          };
          scripts = with pkgs; [
            mpvScripts.dynamic-crop
            mpvScripts.seekTo
            # custom packaged scripts
            custom.mpv-deletefile
            custom.mpv-nextfile
            custom.mpv-subsearch
          ];
        };

        wayland.windowManager.hyprland.settings.windowrulev2 = [
          # do not idle while watching videos
          "idleinhibit focus,class:(mpv)"
          # fix mpv-dynamic-crop unmaximizing the window
          "suppressevent maximize,class:(mpv)"
        ];

        home.packages = with pkgs; [ ffmpeg ];

        custom.persist = {
          home.directories = [
            ".local/state/mpv" # watch later
          ];
        };
      }

      # modernz settings
      {
        programs.mpv = {
          config = lib.mkAfter {
            osc = false;
            border = false;
          };
          scripts = with pkgs.mpvScripts; [
            modernz
            thumbfast
          ];
          scriptOpts = {
            modernz = {
              window_top_bar = false;
              greenandgrumpy = true;
              jump_buttons = false;
              speed_button = true;
              ontop_button = false; # pin button
              chapter_skip_buttons = true;
              track_nextprev_buttons = false;
              hover_effect_color = "#7F7F7F"; # 50% gray
              seekbarfg_color = "#FFFFFF";
              seekbarbg_color = "#7F7F7F"; # 50% gray
            };
          };
        };
      }

      # mpv-cut settings
      {
        programs.mpv = {
          scripts = [ pkgs.custom.mpv-cut ];
        };

        # disable bookmarks functionality
        xdg.configFile."mpv-cut/config.lua".text = # lua
          ''
            KEY_BOOKMARK_ADD = ""
          '';
      }

      # sub-select settings
      {
        programs.mpv = {
          scripts = [ pkgs.custom.mpv-sub-select ];
        };

        xdg.configFile."mpv/script-opts/sub-select.json".text = lib.strings.toJSON [
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
      }

      # sponsorblock + smartskip settings
      {
        programs.mpv = {
          scripts = with pkgs.mpvScripts; [
            smartskip
            sponsorblock
          ];
          scriptOpts = {
            "SmartSkip" = {
              add_chapter_on_skip = false;
              smart_next_keybind = ''[ "PGUP" ]'';
              smart_prev_keybind = ''[ "PGDWN" ]'';
              autoload_playlist = false;
              max_skip_duration = 60 * 5;
              # sponsorblock overrides
              categories =
                let
                  categories = {
                    prologue = "Prologue/^Intro";
                    opening = "^OP / OP$/^Opening";
                    ending = "^ED / ED$/^Ending";
                    preview = "Preview$";
                    credit = "^Credit";
                    sponsorblock = "Sponsor/SponsorBlock";
                  };
                  categoriesStr = lib.concatStringsSep "; " (lib.mapAttrsToList (k: v: "${k}>${v}") categories);
                in
                ''[ ["internal-chapters", "${categoriesStr}"] ]'';
              skip = ''[ ["internal-chapters", "toggle;toggle_idx;opening;ending;preview;credit;sponsorblock"], ["external-chapters", "toggle;toggle_idx"] ]'';
              skip_once = true; # allow going back after initial skip
              autoskip_countdown = 0;
              last_chapter_skip_behavior = ''[ ["no-chapters", "silence-skip"], ["internal-chapters", "silence-skip"], ["external-chapters", "silence-skip"] ]'';
            };
          };
        };
      }

      # anime profile settings
      (
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
        lib.mkIf config.custom.mpv-anime.enable {
          programs.mpv = {
            # auto apply anime shaders for anime videos
            profiles.anime = {
              profile-desc = "Anime";
              # only activate within anime directory
              profile-cond = "path:find('Anime/')";

              # https://kokomins.wordpress.com/2019/10/14/mpv-config-guide/#advanced-video-scaling-config
              # deband-iterations = 2; # Range 1-16. Higher = better quality but more GPU usage. >5 is redundant.
              # deband-threshold = 35; # Range 0-4096. Deband strength.
              # deband-range = 20; # Range 1-64. Range of deband. Too high may destroy details.
              # deband-grain = 5; # Range 0-4096. Inject grain to cover up bad banding, higher value needed for poor sources.

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
          };
        }
      )
    ]
  );
}
