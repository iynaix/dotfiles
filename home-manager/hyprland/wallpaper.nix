{
  config,
  isNixOS,
  lib,
  pkgs,
  user,
  ...
}:
let
  wallpapers_dir = "${config.xdg.userDirs.pictures}/Wallpapers";
  walls_in_dir = "${config.xdg.userDirs.pictures}/wallpapers_in";
  wallpapers_proj = "/persist${config.home.homeDirectory}/projects/wallpaper-ui";
in
lib.mkMerge [
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
      # process wallpapers with upscaling and vertical crop
      wallpapers-add = {
        runtimeInputs = [ pkgs.custom.shell.wallpapers-backup ];
        text = ''
          ${lib.custom.useDirenv wallpapers_proj ''
            cargo run --release --bin add-wallpapers -- --format webp "$@" "${walls_in_dir}"
          ''}
          wallpapers-backup
        '';
      };
      # choose custom crops for wallpapers
      wallpapers-ui = {
        text = lib.custom.useDirenv wallpapers_proj ''
          cargo run --release --bin wallpaper-ui -- "$@"
        '';
        # bash completion isn't helpful as there are 1000s of images
        fishCompletion = ''
          function _wallpapers_ui
            find ${wallpapers_dir} -maxdepth 1 -name "*.webp"
          end
          complete -c wallpapers-ui -f -a '(_wallpapers_ui)'
        '';
      };
      # finds duplicate wallpapers
      wallpapers-dedupe = {
        runtimeInputs = [ pkgs.czkawka ];
        text = ''
          czkawka_cli image --directories ${wallpapers_dir} --directories ${walls_in_dir}
        '';
      };
      # download wallpapers from pixiv
      wallpapers-pixiv = lib.custom.useDirenv "/persist${config.home.homeDirectory}/projects/wall-dl" ''
        cargo run --release --bin wall-dl -- "$@"
      '';
    };

    gtk.gtk3.bookmarks = [ "file://${walls_in_dir} Walls In" ];

    home = {
      packages = [ pkgs.nomacs ];
      shellAliases = {
        # edit the current wallpaper
        wallpapers-edit = "${lib.getExe pkgs.custom.shell.wallpapers-ui} $(command cat $XDG_RUNTIME_DIR/current_wallpaper)";
      };
    };

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
        cache = [ ".local/share/rclip" ];
      };
    };
  })

  (lib.mkIf (config.custom.hyprland.enable && isNixOS) {
    home = {
      packages = [ pkgs.swww ];

      shellAliases = {
        current-wallpaper = "command cat $XDG_RUNTIME_DIR/current_wallpaper";
      };
    };

    # config file for wallpapers-ui
    xdg.configFile = {
      "wallpaper-ui/config.ini".text = lib.generators.toINIWithGlobalSection { } {
        globalSection = {
          csv_path = "${wallpapers_dir}/wallpapers.csv";
          wallpapers_path = wallpapers_dir;
          min_width = 3440; # ultrawide width
          min_height = 1504; # framework height
          show_faces = true;
        } // lib.optionalAttrs config.custom.hyprland.enable { wallpaper_command = "hypr-wallpaper $1"; };

        sections = {
          resolutions = {
            Framework = "2256x1504";
            HD = "1920x1080";
            Thumbnail = "1x1";
            Ultrawide = "3440x1440";
            Vertical = "1440x2560";
          };
        };
      };
    };

  })
]
