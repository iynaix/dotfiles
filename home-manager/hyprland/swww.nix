{
  isNixOS,
  lib,
  pkgs,
  ...
}: let
  preload-wallpapers = pkgs.writeShellApplication {
    name = "preload-wallpapers";
    runtimeInputs = [pkgs.wallust pkgs.iynaix.dotfiles-utils];
    text = ''
      rm -rf "$HOME/.cache/wallust/Resized"

      curr=$(swww query | head -n1 | awk -F 'image: ' '{print $2}')

      for img in "$HOME/Pictures/Wallpapers"/*; do
          wallust "$img"
      done

      hypr-wallpaper "$curr"
    '';
  };
in {
  home.packages = [preload-wallpapers] ++ (lib.optional isNixOS pkgs.swww);

  iynaix.persist = {
    home.directories = [
      ".cache/swww"
    ];
  };
}
