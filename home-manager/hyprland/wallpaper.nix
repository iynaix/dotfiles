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
      wallpapers-backup
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
    runtimeInputs = [ wallpapers-backup ];
    text = ''
      cd ${wallpapers_proj}
      # activate direnv
      direnv allow && eval "$(direnv export bash)"
      cargo run --bin wallpaper-pipeline "$@"
      cd - > /dev/null
      wallpapers-backup
    '';
  };
  # choose vertical crop for wallpapper
  wallpapers-ui = pkgs.writeShellApplication {
    name = "wallpapers-ui";
    text = ''
      cd ${wallpapers_proj}
      # activate direnv
      direnv allow && eval "$(direnv export bash)"
      cargo run --bin wallpaper-ui "$@"
      cd - > /dev/null
    '';
  };
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
in
lib.mkMerge [
  (lib.mkIf (host == "desktop") {
    home.packages = [
      wallpapers-backup
      wallpapers-ui
      wallpapers-remote
      wallpapers-pipeline
    ];

    gtk.gtk3.bookmarks = [ "file://${walls_in_dir} Walls In" ];

    programs.pqiv.extraConfig = lib.mkAfter ''
      m { command(mv $1 ${walls_in_dir}) }
    '';
  })

  # TODO: rofi rclip?
  (lib.mkIf config.custom.rclip.enable {
    home.packages = [
      wallpapers-search
      pkgs.rclip
    ];

    home.shellAliases = {
      wallrg = "wallpapers-search -t 50";
      # edit the current wallpaper
      wallpaper-edit = "${lib.getExe wallpapers-ui} $(command cat $XDG_RUNTIME_DIR/current_wallpaper)";
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
