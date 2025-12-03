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
        environment = {
          systemPackages = with pkgs; [
            python3Packages.faster-whisper
            whisper-ctranslate2
          ];
        };

        custom.persist = {
          home.directories = [
            ".cache/huggingface"
          ];
        };
      }
    ];
}
