{
  inputs,
  lib,
  self,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    # mpv options and settings config from home-manager:
    # https://github.com/nix-community/home-manager/blob/master/modules/programs/mpv.nix
    let
      renderOption =
        option:
        rec {
          int = toString option;
          float = int;
          bool = if option then "yes" else "no";
          string = option;
        }
        .${lib.typeOf option};
      renderOptionValue =
        value:
        let
          rendered = renderOption value;
          length = toString (builtins.stringLength rendered);
        in
        "%${length}%${rendered}";
      # add trailing newline so strings can be concatenated
      renderOptions =
        options:
        (lib.generators.toKeyValue {
          mkKeyValue = lib.generators.mkKeyValueDefault { mkValueString = renderOptionValue; } "=";
          listsAsDuplicateKeys = true;
        } options)
        + "\n";
      renderBindings =
        bindings:
        (lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: "${name} ${value}") bindings)) + "\n";
      renderScriptOptions = lib.generators.toKeyValue {
        mkKeyValue = lib.generators.mkKeyValueDefault { mkValueString = renderOption; } "=";
        listsAsDuplicateKeys = true;
      };
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

      # NOTE: the custom function is used to be able
      mpvConfig = self.libCustom.recursiveMergeAttrsList [
        {
          "mpv.input".content = renderBindings {
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
          "mpv.conf".content = renderOptions {
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
            sub-pos = 100;
            # some settings fixing VOB/PGS subtitles (creating blur & changing yellow subs to gray)
            sub-gauss = "1.0";
            sub-gray = true;
            sub-use-margins = false;
            sub-font-size = 45;
            sub-scale-by-window = true;
            sub-scale-with-window = false;

            # circumvent subtitle or OSD bad positioning when watch later options are used
            watch-later-options-remove = "sub-pos,osd-margin-y";

            screenshot-directory = "~/Pictures/Screenshots";

            slang = "en,eng,english";
            alang = "jp,jpn,japanese,en,eng,english";

            write-filename-in-watch-later-config = true;
          };

          scripts = with pkgs; [
            mpvScripts.dynamic-crop
            mpvScripts.mpris
            mpvScripts.seekTo
            # custom packaged scripts
            custom.mpv-deletefile
            custom.mpv-nextfile
            custom.mpv-subsearch
          ];
        }

        # modernz settings
        {
          scripts = with pkgs.mpvScripts; [
            modernz
            thumbfast
          ];

          "mpv.conf".content = renderOptions {
            osc = false;
            border = false;
          };

          configDir."script-opts/modernz.conf".content = renderScriptOptions {
            chapter_skip_buttons = true;
            fullscreen_button = false;
            greenandgrumpy = true; # disable santa hat in december
            hidetimeout = 1000;
            hover_effect_color = "#7F7F7F"; # 50% gray
            info_button = false;
            jump_buttons = false;
            loop_button = false;
            nibble_color = "#7F7F7F"; # 50% gray
            nibbles_top = false;
            ontop_button = false; # pin button
            playlist_button = false;
            screenshot_button = false;
            seekbarbg_color = "#7F7F7F"; # 50% gray
            seekbarfg_color = "#FFFFFF";
            speed_button = true;
            sub_margins = false; # don't raise subtitles over OSC
            track_nextprev_buttons = false;
            volume_control = false;
            window_top_bar = false;
          };
        }

        # mpv-cut settings
        {
          scripts = [
            (pkgs.custom.mpv-cut.override {
              # disable bookmarks functionality
              configLua = /* lua */ ''
                KEY_BOOKMARK_ADD = ""
              '';
            })
          ];
        }

        # sub-select settings
        {
          scripts = [ pkgs.custom.mpv-sub-select ];

          configDir."script-opts/sub-select.json".content = lib.strings.toJSON [
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
          scripts = with pkgs.mpvScripts; [
            smartskip
            sponsorblock
          ];

          configDir."script-opts/SmartSkip.conf".content = renderScriptOptions {
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
        }

        # anime profile settings
        # NOTE: this **MUST BE THE LAST ENTRY** in the list to be merged, so the profile appears at the bottom of mpv.conf
        {
          # auto apply anime shaders for anime videos
          "mpv.conf".content = ''
            [anime]
            ${renderOptions {
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
            }}
          '';
          "mpv.input".content = renderBindings (
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
            )
          );
        }

      ];
    in
    {
      packages.mpv = inputs.wrappers.wrappers.mpv.wrap {
        inherit pkgs;
        package = pkgs.mpv.override { inherit (mpvConfig) scripts; };
        inherit (mpvConfig) "mpv.conf" "mpv.input" configDir;
      };
    };

  flake.modules.nixos.gui =
    { pkgs, ... }:
    {
      custom.programs = {
        hyprland.settings.windowrule = [
          # do not idle while watching videos
          "match:class mpv, idle_inhibit focus"
          # fix mpv-dynamic-crop unmaximizing the window
          "match:class mpv, suppress_event maximize"
        ];
      };

      nixpkgs.overlays = [
        (_: _prev: {
          mpv = pkgs.custom.mpv;
        })
      ];

      environment.systemPackages = with pkgs; [
        ffmpeg
        mpv # overlay-ed above
      ];

      custom.programs.print-config =
        let
          mpvDir = pkgs.mpv.configuration.flags."--config-dir".data;
        in
        {
          mpv = /* sh */ ''moor "${mpvDir}/mpv.conf"'';
          mpv-input = /* sh */ ''moor "${mpvDir}/input.conf"'';
          mpv-plugins = /* sh */ "moor ${mpvDir}/script-opts/*";
        };

      custom.persist = {
        home.directories = [
          ".local/state/mpv" # watch later
        ];
      };
    };
}
