{
  config,
  host,
  isNixOS,
  lib,
  pkgs,
  user,
  ...
}: let
  wallpapers_proj = "/persist/home/${user}/projects/wallpaper-utils";
  # crop wallpaper before displaying with swww
  swww-crop = pkgs.writeShellApplication {
    name = "swww-crop";
    runtimeInputs = with pkgs; [swww imagemagick];
    text = ''
      convert "$1" -crop "$2" - | swww img --outputs "$3" "''${@:4}" -;
    '';
  };
  imv-search = pkgs.writeShellApplication {
    name = "imv-search";
    runtimeInputs = with pkgs; [imv pkgs.iynaix.rclip];
    text = ''
      rclip -f "$@" | imv;
    '';
  };
  # backup wallpapers to secondary drive
  wallpapers-backup = pkgs.writeShellApplication {
    name = "wallpapers-backup";
    runtimeInputs = with pkgs; [rsync];
    text = ''
      rsync -aP --delete --no-links "$HOME/Pictures/Wallpapers" "/media/6TBRED"
    '';
  };
  # sync wallpapers with laptop
  wallpapers-remote = pkgs.writeShellApplication {
    name = "wallpapers-remote";
    runtimeInputs = with pkgs; [rsync wallpapers-backup];
    text = ''
      wallpapers-backup
      rsync -aP --delete --no-links -e "ssh -o StrictHostKeyChecking=no" "$HOME/Pictures/Wallpapers" "${user}@''${1:-iynaix-framework}:$HOME/Pictures"
    '';
  };
  # process wallpapers with upscaling and vertical crop
  wallpapers-process = pkgs.writeShellApplication {
    name = "wallpapers-process";
    runtimeInputs = [wallpapers-backup];
    text = ''
      wallpapers-backup

      cd ${wallpapers_proj}
      # activate direnv
      direnv allow && eval "$(direnv export bash)"
      python main.py "$@"
      cd - > /dev/null
    '';
  };
  # choose vertical crop for wallpapper
  wallpapers-choose = pkgs.writeShellApplication {
    name = "wallpapers-choose";
    text = ''
      cd ${wallpapers_proj}
      # activate direnv
      direnv allow && eval "$(direnv export bash)"
      python choose.py "$@"
      cd - > /dev/null
    '';
  };
  # delete current wallpaper
  wallpaper-delete = pkgs.writeShellApplication {
    name = "wallpaper-delete";
    runtimeInputs = with pkgs; [swww];
    text = ''
      wall=$(cat "$HOME/.cache/current_wallpaper")
      if [ -n "$wall" ]; then rm "$wall"; fi
    '';
  };
in {
  config = lib.mkMerge [
    (lib.mkIf (host == "desktop") {
      home.packages = [
        swww-crop
        wallpapers-backup
        wallpapers-choose
        wallpapers-remote
        wallpapers-process
        wallpaper-delete
      ];

      gtk.gtk3.bookmarks = [
        "file://${wallpapers_proj}/in Walls In"
      ];

      programs.imv.settings.binds = {
        m = "exec mv \"$imv_current_file\" ${wallpapers_proj}/in";
      };
    })
    (lib.mkIf config.iynaix.rclip.enable {
      home.packages = [
        imv-search
        pkgs.iynaix.rclip
      ];

      iynaix.persist = {
        home.directories = [
          ".cache/clip"
          ".local/share/rclip"
        ];
      };
    })
    (lib.mkIf isNixOS {
      home.packages = [pkgs.swww];
    })
    {
      home.shellAliases = {
        current-wallpaper = "command cat $HOME/.cache/current_wallpaper";
      };
    }
  ];
}
