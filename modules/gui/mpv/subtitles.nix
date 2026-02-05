{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.ai-subs = pkgs.writeShellApplication {
        name = "ai-subs";
        runtimeInputs = [ pkgs.whisper-ctranslate2 ];
        # int8 is the fastest on cpu, according to the project page
        text = /* sh */ ''
          whisper-ctranslate2 --language en --output_format srt --compute_type int8 --model medium "$@"
        '';
      };
    };

  flake.nixosModules.subtitles =
    { pkgs, ... }:
    lib.mkMerge [
      # subliminal
      {
        environment = {
          systemPackages = [
            pkgs.python3Packages.subliminal
            pkgs.custom.ai-subs
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

        custom.persist = {
          home.directories = [
            ".cache/huggingface"
          ];
        };
      }
    ];
}
