{
  config,
  host,
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
  (lib.mkIf (host == "desktop") {
    custom.shell.packages = {
      # backup wallpapers to secondary drive
      wallpapers-backup = pkgs.writeShellApplication {
        name = "wallpapers-backup";
        runtimeInputs = with pkgs; [ rsync ];
        text = ''
          rsync -aP --delete --no-links "${wallpapers_dir}" "/media/6TBRED"
          # update rclip database
          ${lib.optionalString config.custom.rclip.enable ''
            cd "${wallpapers_dir}"
            rclip -f "cat" >  /dev/null
            cd - > /dev/null
          ''}
        '';
      };
      # sync wallpapers with laptop
      wallpapers-remote = pkgs.writeShellApplication {
        name = "wallpapers-remote";
        runtimeInputs = with pkgs; [
          rsync
          custom.shell.wallpapers-backup
        ];
        text =
          let
            rsync = ''rsync -aP --delete --no-links -e "ssh -o StrictHostKeyChecking=no"'';
            remote = "\${1:-${user}-framework}";
            rclip_dir = "${config.xdg.dataHome}/rclip";
          in
          ''
            wallpapers-backup
            ${rsync} "${wallpapers_dir}/" "${user}@${remote}:${wallpapers_dir}/"

            if [ "${remote}" == "iynaix-framework" ]; then
                ${rsync} "${rclip_dir}/" "${user}@${remote}:${rclip_dir}/"
            fi
          '';
      };
      # process wallpapers with upscaling and vertical crop
      wallpapers-pipeline = pkgs.writeShellApplication {
        name = "wallpapers-pipeline";
        runtimeInputs = [ pkgs.custom.shell.wallpapers-backup ];
        text = ''
          ${pkgs.custom.lib.useDirenv wallpapers_proj ''
            cargo run --release --bin pipeline "$@"
          ''}
          wallpapers-backup
        '';
      };
      # choose custom crops for wallpapers
      wallpapers-ui = pkgs.custom.lib.useDirenv wallpapers_proj ''
        cargo run --release --bin wallpaper-ui "$@"
      '';
    };

    gtk.gtk3.bookmarks = [ "file://${walls_in_dir} Walls In" ];

    home.shellAliases = {
      # edit the current wallpaper
      wallpapers-edit = "${lib.getExe pkgs.custom.shell.wallpapers-ui} $(command cat $XDG_RUNTIME_DIR/current_wallpaper)";
    };

    programs.pqiv.extraConfig = lib.mkAfter ''
      m { command(mv $1 ${walls_in_dir}) }
    '';
  })

  # TODO: rofi rclip?
  (lib.mkIf config.custom.rclip.enable {
    home.packages = [ pkgs.rclip ];

    custom.shell.packages = {
      # search wallpapers with rclip
      wallpapers-search = pkgs.writeShellApplication {
        name = "wallpapers-search";
        runtimeInputs = with pkgs; [
          rclip
          pqiv
        ];
        text = ''
          cd "${wallpapers_dir}"
          rclip --filepath-only "$@" | pqiv --additional-from-stdin
          cd - > /dev/null
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
  (lib.mkIf isNixOS { home.packages = [ pkgs.swww ]; })
  {
    home.shellAliases = {
      current-wallpaper = "command cat $XDG_RUNTIME_DIR/current_wallpaper";
    };
  }
]
