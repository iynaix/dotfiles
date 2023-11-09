{
  host,
  isNixOS,
  lib,
  pkgs,
  user,
  ...
}: let
  wallpapers_proj = "/persist/home/${user}/projects/wallpaper-utils";
  # backup wallpapers to secondary drive
  wallpapers-backup = pkgs.writeShellApplication {
    name = "wallpapers-backup";
    runtimeInputs = with pkgs; [rsync];
    text = ''
      rsync -aP --delete --no-links "$HOME/Pictures/Wallpapers" "/media/6TBRED"
      rsync -aP --delete --no-links "$HOME/Pictures/WallpapersVertical" "/media/6TBRED"
    '';
  };
  # sync wallpapers with laptop
  wallpapers-remote = pkgs.writeShellApplication {
    name = "wallpapers-remote";
    runtimeInputs = with pkgs; [rsync wallpapers-backup];
    text = ''
      wallpapers-backup
      rsync -aP --delete --no-links -e "ssh -o StrictHostKeyChecking=no" "$HOME/Pictures/Wallpapers" "${user}@''${1:-iynaix-laptop}:$HOME/Pictures"
    '';
  };
  # process wallpapers with upscaling and vertical crop
  wallpapers-process = pkgs.writeShellApplication {
    name = "wallpapers-process";
    runtimeInputs = [wallpapers-backup];
    text = ''
      wallpapers-backup

      pushd ${wallpapers_proj}
      # activate direnv
      direnv allow && eval "$(direnv export bash)"
      python main.py
      popd
    '';
  };
in {
  config = lib.mkMerge [
    (lib.mkIf (host == "desktop") {
      home.packages = [
        wallpapers-backup
        wallpapers-remote
        wallpapers-process
      ];

      gtk.gtk3.bookmarks = [
        "file://${wallpapers_proj}/in Wallpapers Pending"
      ];

      programs.imv.settings.binds = {
        m = "exec mv \"$imv_current_file\" ${wallpapers_proj}/in";
      };
    })
    (lib.mkIf isNixOS {
      home.packages = [pkgs.swww];
    })
    {
      iynaix.persist = {
        home.directories = [
          ".cache/swww"
        ];
      };
    }
  ];
}
