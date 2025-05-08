{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkAfter
    mkEnableOption
    mkIf
    mkOption
    mkMerge
    optionalAttrs
    ;
  inherit (lib.types) package;
  tomlFormat = pkgs.formats.toml { };
  wallpapers_dir = "${config.xdg.userDirs.pictures}/Wallpapers";
  walls_in_dir = "${config.xdg.userDirs.pictures}/wallpapers_in";
in
{
  options.custom = {
    rclip.enable = mkEnableOption "rclip";
    wallfacer.enable = mkEnableOption "wallfacer";
    wallpaper-extras.enable = mkEnableOption "additional tools for wallpapers, e.g. fetching and editing";
    dotfiles = {
      package = mkOption {
        type = package;
        default = pkgs.custom.dotfiles-rs.override {
          useDedupe = config.custom.wallpaper-extras.enable;
          useRclip = config.custom.rclip.enable;
          useWallfacer = config.custom.wallfacer.enable;
        };
        description = "Package to use for dotfiles";
      };
    };
  };

  config = mkIf config.custom.hyprland.enable (mkMerge [
    {
      home = {
        shellAliases = {
          wall = "wallpaper";
        };
        packages = [ config.custom.dotfiles.package ];
      };
    }

    (mkIf config.custom.wallfacer.enable {
      custom.shell.packages = {
        wallfacer = {
          text =
            # workaround for Error 71 (Protocol error) dispatching to Wayland display. (nvidia only?)
            # https://github.com/tauri-apps/tauri/issues/10702
            lib.optionalString config.custom.nvidia.enable "export WEBKIT_DISABLE_DMABUF_RENDERER=1\n"
            + lib.custom.direnvCargoRun {
              dir = "${config.home.homeDirectory}/projects/wallfacer";
            };
          # bash completion isn't helpful as there are 1000s of images
          fishCompletion = # fish
            ''
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
          }
          // optionalAttrs config.custom.hyprland.enable { wallpaper_command = "wallpaper $1"; }
        );
      };
    })

    (mkIf config.custom.wallpaper-extras.enable {
      custom.shell.packages = {
        # fetch wallpapers from pixiv for user
        pixiv = lib.custom.direnvCargoRun {
          dir = "${config.home.homeDirectory}/projects/pixiv";
        };
      };

      gtk.gtk3.bookmarks = [ "file://${walls_in_dir} Walls In" ];

      home.packages = [ (pkgs.nomacs.override { libsForQt5 = pkgs.kdePackages; }) ];

      programs.pqiv.extraConfig = mkAfter ''
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

    (mkIf config.custom.rclip.enable {
      home = {
        packages = [ pkgs.rclip ];

        shellAliases = {
          wallrg = "wallpaper search -t 50";
        };
      };

      custom.persist = {
        home = {
          directories = [
            ".cache/clip"
            ".cache/huggingface"
          ];
          cache.directories = [ ".local/share/rclip" ];
        };
      };
    })
  ]);
}
