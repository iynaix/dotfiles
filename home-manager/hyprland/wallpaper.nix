{
  config,
  isNixOS,
  lib,
  pkgs,
  user,
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
        # backup wallpapers to secondary drive
        wallpapers-backup = {
          runtimeInputs = [
            pkgs.direnv
            pkgs.rsync
          ] ++ lib.optionals config.custom.rclip.enable [ pkgs.rclip ];
          text = ''
            rsync -aP --delete --no-links "${wallpapers_dir}" "/media/6TBRED"
            # update rclip database
            ${lib.optionalString config.custom.rclip.enable ''
              pushd "${wallpapers_dir}" > /dev/null
              # do not use previous python
              eval "$(direnv export bash)"
              rclip -f "cat" >  /dev/null
              popd > /dev/null
            ''}
          '';
        };
        # sync wallpapers with laptop
        wallpapers-remote = {
          runtimeInputs = with pkgs; [
            rsync
            custom.shell.wallpapers-backup
          ];
          text =
            let
              remote = "\${1:-${user}-framework}";
              rclip_dir = "${config.xdg.dataHome}/rclip";
              rsync = dir: ''rsync -aP --no-links --mkpath --delete "${dir}/" "${user}@${remote}:${dir}/"'';
            in
            ''
              wallpapers-backup
              ${rsync wallpapers_dir}

              if [ "${remote}" == "iynaix-framework" ]; then
                  ${rsync rclip_dir}
              fi
            '';
        };
        # quick recropping of current wallpaper
        wallpaper-edit = {
          runtimeInputs = [ pkgs.custom.dotfiles-rs ];
          text = ''
            ${lib.custom.useDirenv wallpapers_proj ''
              cargo run --release --bin wallfacer "$(cat "$XDG_RUNTIME_DIR"/current_wallpaper)";
              wallpaper --reload
            ''}
          '';
        };
        # process wallpapers with upscaling and vertical crop
        wallfacer-add = {
          runtimeInputs = [ pkgs.custom.shell.wallpapers-backup ];
          text = ''
            ${lib.custom.useDirenv wallpapers_proj ''
              cargo run --release --bin wallfacer -- add --format webp "$@" "${walls_in_dir}"
            ''}
            wallpapers-backup
          '';
        };
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
        # finds duplicate wallpapers
        wallpapers-dedupe = {
          runtimeInputs = [ pkgs.czkawka ];
          text = ''
            czkawka_cli image --directories ${wallpapers_dir} --directories ${walls_in_dir}
          '';
        };
        # fetch wallpapers from pixiv for user
        pixiv = lib.custom.useDirenv "/persist${config.home.homeDirectory}/projects/wall-dl" ''
          cargo run --release --bin wall-dl -- "$@"
        '';
        # fetch latest followed wallpapers from pixiv
        pixiv-latest = lib.custom.useDirenv "/persist${config.home.homeDirectory}/projects/wall-dl" ''
          cargo run --release --bin latest -- "$@"
        '';
      };

      gtk.gtk3.bookmarks = [ "file://${walls_in_dir} Walls In" ];

      home.packages = [ pkgs.nomacs ];

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
      home.packages = [ pkgs.rclip ];

      custom.shell.packages = {
        # search wallpapers with rclip
        wallpapers-search = {
          runtimeInputs = with pkgs; [
            rclip
            pqiv
          ];
          text = ''
            pushd "${wallpapers_dir}" > /dev/null
            rclip --filepath-only "$@" | pqiv --additional-from-stdin
            popd > /dev/null
          '';
        };
      };

      home.shellAliases = {
        wallrg = "wallpapers-search -t 50";
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

        shellAliases = {
          current-wallpaper = "command cat $XDG_RUNTIME_DIR/current_wallpaper";
          wallpapers-history = "wallpaper --history";
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
  ];
}
