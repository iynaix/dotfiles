{
  flake.nixosModules.wallfacer =
    { config, pkgs, ... }:
    let
      tomlFormat = pkgs.formats.toml { };
      wallpapers_dir = "${config.hj.directory}/Pictures/Wallpapers";
    in
    {
      custom.shell.packages = {
        wallfacer =
          let
            wallfacerConf = {
              wallpapers_path = wallpapers_dir;
              min_width = 3840; # 4k width
              min_height = 2880; # lg dualup height
              show_faces = false;

              resolutions = [
                {
                  name = "FW";
                  description = "Framework";
                  resolution = "2880x1920";
                }
                {
                  name = "HD";
                  description = "Full HD (1920x1080)";
                  resolution = "1920x1080";
                }
                {
                  name = "Thumb";
                  description = "Square";
                  resolution = "1x1";
                }
                {
                  name = "UW";
                  description = "Ultrawide 34 inch";
                  resolution = "3440x1440";
                }
                {
                  name = "Vert";
                  description = "Vertical 1440p";
                  resolution = "1440x2560";
                }
                {
                  name = "FW Vert";
                  description = "Framework Vertical";
                  resolution = "1504x2256";
                }
              ];
              wallpaper_command = "wallpaper $1";
            };
          in
          {
            text = /* sh */ ''
              direnv-cargo-run "/persist${config.hj.directory}/projects/wallfacer" --config "${tomlFormat.generate "wallfacer.toml" wallfacerConf}" "$@"
            '';
            # completion for wallpaper gui, bash completion isn't helpful as there are 1000s of images
            fishCompletion = # fish
              ''
                function _wallfacer_gui
                  find ${wallpapers_dir} -maxdepth 1 -name "*.webp"
                end
                complete -c wallfacer -n '__fish_seen_subcommand_from gui' -a '(_wallfacer_gui)'
              '';
          };
      };
    };
}
