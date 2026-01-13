{ lib, ... }:
let
  inherit (lib) mkMerge;
in
{
  flake.nixosModules.subtitles =
    { pkgs, ... }:
    mkMerge [
      # subliminal
      {
        environment = {
          systemPackages = with pkgs; [
            python3Packages.subliminal
          ];

          shellAliases = {
            subs = "subliminal download -l 'en' -l 'eng' -s";
          };
        };
      }

      # openai-whisper for transcribing audio / video
      {
        environment.systemPackages = with pkgs; [
          whisper-ctranslate2
        ];

        custom.shell.packages = {
          ai-subs = {
            runtimeInputs = [ pkgs.whisper-ctranslate2 ];
            # int8 is the fastest on cpu, according to the project page
            text = /* sh */ ''
              whisper-ctranslate2 ---language en --output_format srt --compute_type int8 --model medium "$@"
            '';
          };
        };

        custom.persist = {
          home.directories = [
            ".cache/huggingface"
          ];
        };
      }
    ];
}
