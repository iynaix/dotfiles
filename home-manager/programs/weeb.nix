{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkMerge [
    {
      home = {
        packages = with pkgs; [
          inputs.jerry.packages.${system}.default
          mangal
        ];
        file = {
          ".config/mangal/mangal.toml" = {
            force = true;
            text = ''
              downloader.path = "$HOME/Books/Manga"
              downloader.create_manga_dir = true
              downloader.create_volume_dir = true
              downloader.download_cover = true
              mangadex.nsfw = false # to hell with degeneracy...it'll land you in hell literally
            '';
          };
          ".config/jerry/jerry.conf" = {
            force = true;
            text = ''
              player="mpv"
              player_arguments=""
              chafa_options=""
              show_adult_content=false
              provider="yugen"
              download_dir="$HOME/Anime"
              manga_dir="$HOME/Books/Manga"
              manga_format="image"
              manga_opener="feh"
              history_file="$HOME/.local/share/jerry/jerry_history.txt"
              subs_language="english"
              use_external_menu=true
              image_preview=true
              json_output=false
              sub_or_dub="sub"
              score_on_completion=false
              discord_presence=false
              presence_script_path="jerrydiscordpresence.py"          
            '';
          };
        };
      };

      custom.persist = {
        home.directories = [
          ".local/share/jerry"
        ];
      };
    }
  ];
}
