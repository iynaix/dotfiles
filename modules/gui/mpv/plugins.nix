{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    mapAttrsToList
    mkAfter
    mkIf
    mkMerge
    mkEnableOption
    ;
in
{
  options.custom = {
    programs = {
      subliminal.enable = mkEnableOption "subliminal" // {
        default = true;
      };
    };
  };

  config = mkMerge [
    # subliminal
    (mkIf config.custom.programs.subliminal.enable {
      environment = {
        systemPackages = with pkgs; [
          python3Packages.subliminal
        ];

        shellAliases = {
          subs = "subliminal download -l 'en' -l 'eng' -s";
        };
      };
    })

    # modernz settings
    {
      custom.programs.mpv = {
        config = mkAfter {
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
      custom.programs.mpv = {
        scripts = [
          (pkgs.custom.mpv-cut.override {
            # disable bookmarks functionality
            configLua = # lua
              ''
                KEY_BOOKMARK_ADD = ""
              '';
          })
        ];
      };
    }

    # sub-select settings
    {
      custom.programs.mpv = {
        scripts = [ pkgs.custom.mpv-sub-select ];

        scriptOptsFiles = {
          "sub-select.json" = lib.strings.toJSON [
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
      };
    }

    # sponsorblock + smartskip settings
    {
      custom.programs.mpv = {
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
                categoriesStr = concatStringsSep "; " (mapAttrsToList (k: v: "${k}>${v}") categories);
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
  ];
}
