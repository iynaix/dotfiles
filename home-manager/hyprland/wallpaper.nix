{
  host,
  isNixOS,
  lib,
  pkgs,
  user,
  ...
}: let
  # backup wallpapers to secondary drive
  backup-wallpapers = pkgs.writeShellApplication {
    name = "backup-wallpapers";
    runtimeInputs = with pkgs; [rsync];
    text = ''
      rsync -aP --delete --no-links "$HOME/Pictures/Wallpapers" "/media/6TBRED"
      rsync -aP --delete --no-links "$HOME/Pictures/WallpapersVertical" "/media/6TBRED"
    '';
  };
  # sync wallpapers with laptop
  sync-wallpapers = pkgs.writeShellApplication {
    name = "sync-wallpapers";
    runtimeInputs = with pkgs; [rsync backup-wallpapers];
    text = ''
      backup-wallpapers
      rsync -aP --delete --no-links -e "ssh -o StrictHostKeyChecking=no" "$HOME/Pictures/Wallpapers" "${user}@''${1:-iynaix-laptop}:$HOME/Pictures"
    '';
  };
in {
  config = lib.mkMerge [
    (lib.mkIf (host == "desktop") {
      home.packages = [
        backup-wallpapers
        sync-wallpapers
      ];
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
