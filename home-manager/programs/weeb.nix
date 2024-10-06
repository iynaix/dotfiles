{
  inputs,
  pkgs,
  lib,
  host,
  ...
}:
{
  imports = [ inputs.jerry.homeManagerModules.default ];
  config = lib.mkMerge [
    {
      programs.jerry = {
        enable = true;
        config = {
          player = "mpv";
          # the poor T450 can't take the graphics load shaders put on it
          player_arguments = if host != "t450" then "--profile=anime" else "";
          show_adult_content = "false";
          provider = "yugen";
          download_dir = "$HOME/Anime";
          manga_dir = "$HOME/Books/Manga";
          manga_format = "image";
          manga_opener = "zathura";
          history_file = "$HOME/.local/share/jerry/jerry_history.txt";
          subs_language = "english";
          use_external_menu = "true";
          image_preview = "true";
          json_output = "false";
          sub_or_dub = "sub";
          score_on_completion = "true";
          discord_presence = "false";
          presence_script_path = "$HOME/.config/jerry/jerrydiscordpresence.py";
        };
      };
      custom.persist = {
        home.directories = [
          ".local/share/jerry"
        ];
      };
      home = {
        packages = with pkgs; [
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
        };
      };
    }
  ];
}
