{
  config,
  lib,
  pkgs,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
  wallpapers_dir = "${config.xdg.userDirs.pictures}/Wallpapers";
  walls_in_dir = "${config.xdg.userDirs.pictures}/wallpapers_in";
in
{
  options.custom = with lib; {
    rclip.enable = mkEnableOption "rclip";
    wallfacer.enable = mkEnableOption "wallfacer";
    wallpaper-extras.enable = mkEnableOption "additional tools for wallpapers, e.g. fetching and editing";
    dotfiles = {
      package = mkOption {
        type = types.package;
        default = pkgs.custom.dotfiles-rs.override {
          useDedupe = config.custom.wallpaper-extras.enable;
          useRclip = config.custom.rclip.enable;
          useWallfacer = config.custom.wallfacer.enable;
        };
        description = "Package to use for dotfiles";
      };
    };
  };

  config = lib.mkIf config.custom.hyprland.enable (
    lib.mkMerge [
      {
        home.packages = [ config.custom.dotfiles.package ];
      }

      (lib.mkIf config.custom.wallfacer.enable {
        custom.shell.packages = {
          wallfacer = {
            text = lib.custom.direnvCargoRun {
              dir = "${config.home.homeDirectory}/projects/wallfacer";
            };
            # bash completion isn't helpful as there are 1000s of images
            fishCompletion = ''
              function _wallfacer
                find ${wallpapers_dir} -maxdepth 1 -name "*.webp"
              end
              complete -c wallfacer -f -a '(_wallfacer)'
            '';
          };
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

      (lib.mkIf config.custom.wallpaper-extras.enable {
        custom.shell.packages = {
          # fetch wallpapers from pixiv for user
          pixiv = lib.custom.direnvCargoRun {
            dir = "${config.home.homeDirectory}/projects/pixiv";
          };
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
    ]
  );
}
