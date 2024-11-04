{
  config,
  isNixOS,
  lib,
  pkgs,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
  wallpapers_dir = "${config.xdg.userDirs.pictures}/Wallpapers";
  walls_in_dir = "${config.xdg.userDirs.pictures}/wallpapers_in";
  wallpapers_proj = "/persist${config.home.homeDirectory}/projects/wallfacer";
in
{
  options.custom = with lib; {
    rclip.enable = mkEnableOption "rclip";
    wallpaper-utils.enable = mkEnableOption "wallpaper-utils";
  };

  config = lib.mkMerge [
    (lib.mkIf config.custom.wallpaper-utils.enable {
      custom.shell.packages = {
        # choose custom crops for wallpapers
        wallfacer = {
          text = lib.custom.useDirenv wallpapers_proj ''
            cargo run --release --bin wallfacer -- "$@"
          '';
          # bash completion isn't helpful as there are 1000s of images
          fishCompletion = ''
            function _wallfacer
              find ${wallpapers_dir} -maxdepth 1 -name "*.webp"
            end
            complete -c wallfacer -f -a '(_wallfacer)'
          '';
        };
        # fetch wallpapers from pixiv for user
        pixiv = lib.custom.useDirenv "/persist${config.home.homeDirectory}/projects/pixiv" ''
          cargo run --release --bin pixiv -- "$@"
        '';
      };

      gtk.gtk3.bookmarks = [ "file://${walls_in_dir} Walls In" ];

      home.packages = [ (pkgs.nomacs.override { libsForQt5 = pkgs.kdePackages; }) ];

      programs.pqiv.extraConfig = lib.mkAfter ''
        c { command(nomacs $1) }
        m { command(mv $1 ${walls_in_dir}) }
      '';

      custom.persist = {
        home = {
          directories = [
            ".cache/czkawka"
            ".config/nomacs"
          ];
        };
      };
    })

    (lib.mkIf config.custom.rclip.enable {
      home = {
        packages = [ pkgs.rclip ];

        shellAliases = {
          wallrg = "wallpaper search -t 50";
        };
      };

      custom.persist = {
        home = {
          directories = [ ".cache/clip" ];
          cache.directories = [ ".local/share/rclip" ];
        };
      };
    })

    (lib.mkIf (config.custom.hyprland.enable && isNixOS) {
      home = {
        packages = [ pkgs.swww ];
      };

      # config file for wallfacer
      xdg.configFile = {
        "wallfacer/wallfacer.toml".source = tomlFormat.generate "wallfacer.toml" (
          {
            wallpapers_path = wallpapers_dir;
            min_width = 3840; # 4k width
            min_height = 2560; # vertical 1440p
            show_faces = true;

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
          }
          // lib.optionalAttrs config.custom.hyprland.enable { wallpaper_command = "wallpaper $1"; }
        );
      };
    })
  ];
}
