{
  config,
  lib,
  pkgs,
  ...
}:
# mpv options and settings config from home-manager:
# https://github.com/nix-community/home-manager/blob/master/modules/programs/mpv.nix
let
  inherit (lib)
    concatLines
    generators
    literalExpression
    mapAttrsToList
    mkIf
    mkMerge
    mkOption
    optionalString
    types
    typeOf
    ;
  cfg = config.custom.programs.mpv;
  # option types
  mpvOption = with types; either str (either int (either bool float));
  mpvOptionDup = with types; either mpvOption (listOf mpvOption);
  mpvOptions = with types; attrsOf mpvOptionDup;
  mpvProfiles = with types; attrsOf mpvOptions;
  # writing config files
  renderOption =
    option:
    rec {
      int = toString option;
      float = int;
      bool = if option then "yes" else "no";
      string = option;
    }
    .${typeOf option};
  renderOptionValue =
    value:
    let
      rendered = renderOption value;
      length = toString (builtins.stringLength rendered);
    in
    "%${length}%${rendered}";
  renderOptions = generators.toKeyValue {
    mkKeyValue = generators.mkKeyValueDefault { mkValueString = renderOptionValue; } "=";
    listsAsDuplicateKeys = true;
  };
  renderBindings =
    bindings: lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: "${name} ${value}") bindings);
  renderProfiles = generators.toINI {
    mkKeyValue = generators.mkKeyValueDefault { mkValueString = renderOptionValue; } "=";
    listsAsDuplicateKeys = true;
  };
  renderScriptOptions = generators.toKeyValue {
    mkKeyValue = generators.mkKeyValueDefault { mkValueString = renderOption; } "=";
    listsAsDuplicateKeys = true;
  };
in
{
  options.custom = {
    programs.mpv = {
      config = mkOption {
        description = ''
          Configuration written to mpv.conf. See
          {manpage}`mpv(1)` for the full list of options.
        '';
        type = mpvOptions;
        default = { };
        example = literalExpression ''
          {
            profile = "gpu-hq";
            force-window = true;
            ytdl-format = "bestvideo+bestaudio";
            cache-default = 4000000;
          }
        '';
      };
      bindings = mkOption {
        description = ''
          Input configuration written to input.conf. See
          {manpage}`mpv(1)` for the full list of options.
        '';
        type = with types; attrsOf str;
        default = { };
        example = literalExpression ''
          {
            WHEEL_UP = "seek 10";
            WHEEL_DOWN = "seek -10";
            "Alt+0" = "set window-scale 0.5";
          }
        '';
      };
      scripts = mkOption {
        type = with types; listOf package;
        default = [ ];
        example = literalExpression "[ pkgs.mpvScripts.mpris ]";
        description = ''
          List of scripts to use with mpv.
        '';
      };
      scriptOpts = mkOption {
        description = ''
          Script options added to script-opts/. See
          {manpage}`mpv(1)` for the full list of options of builtin scripts.
        '';
        type = types.attrsOf mpvOptions;
        default = { };
        example = {
          osc = {
            scalewindowed = 2.0;
            vidscale = false;
            visibility = "always";
          };
        };
      };
      scriptOptsFiles = mkOption {
        description = '''';
        type = types.attrsOf types.lines;
        default = { };
        example = literalExpression ''
          {
            "script-opts/osc.conf" = '''
              osc
              {
                scalewindowed = 2.0;
                vidscale = false;
                visibility = "always";
              };
            '''
          };
        '';
      };
      profiles = mkOption {
        description = ''
          Sub-configuration options for specific profiles written to
          {file}`$XDG_CONFIG_HOME/mpv/mpv.conf`. See
          {option}`programs.mpv.config` for more information.
        '';
        type = mpvProfiles;
        default = { };
        example = literalExpression ''
          {
            fast = {
              vo = "vdpau";
            };
            "protocol.dvd" = {
              profile-desc = "profile for dvd:// streams";
              alang = "en";
            };
          }
        '';
      };
    };
  };

  config = mkIf (config.custom.wm != "tty") (mkMerge [
    {
      custom.programs = {
        mpv = {
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

            screenshot-directory = "${config.hj.directory}/Pictures/Screenshots";

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

        hyprland.settings.windowrule = [
          # do not idle while watching videos
          "idleinhibit focus,class:(mpv)"
          # fix mpv-dynamic-crop unmaximizing the window
          "suppressevent maximize,class:(mpv)"
        ];

        # open full height in niri
        # niri.settings.window-rules = [
        #   {
        #     matches = [ { app-id = "^mpv$"; } ];
        #     default-window-height = {
        #       proportion = 1.0;
        #     };
        #   }
        # ];
      };

      environment.systemPackages = with pkgs; [
        ffmpeg
        # (mpv.override { inherit (cfg) scripts; })
        mpv
      ];

      custom.persist = {
        home.directories = [
          ".local/state/mpv" # watch later
        ];
      };
    }

    # wrapper implementation
    {
      custom.wrappers =
        let
          mpvDir = pkgs.runCommand "mpv-config" { } (
            ''
              mkdir -p $out/script-opts

              cat > $out/input.conf << 'EOF'
              ${renderBindings cfg.bindings}
              EOF

              cat > $out/mpv.conf << 'EOF'
              ${renderOptions cfg.config}
              ${optionalString (cfg.profiles != { }) (renderProfiles cfg.profiles)}
              EOF
            ''
            # write scriptOpts
            + (
              cfg.scriptOpts
              |> mapAttrsToList (
                name: opts: ''
                  cat > $out/script-opts/${name}.conf << 'EOF'
                  ${renderScriptOptions opts}
                  EOF
                ''
              )
              |> concatLines
            )
            # write scriptOptsFiles
            + (
              cfg.scriptOptsFiles
              |> mapAttrsToList (
                name: content: ''
                  cat > $out/script-opts/${name} << 'EOF'
                  ${content}
                  EOF
                ''
              )
              |> concatLines
            )
          );
        in
        [
          (_: prev: {
            mpv = {
              package = prev.mpv.override { inherit (cfg) scripts; };
              flags = {
                "--config-dir" = mpvDir;
              };
              flagSeparator = "=";
            };
          })
        ];
    }
  ]);
}
