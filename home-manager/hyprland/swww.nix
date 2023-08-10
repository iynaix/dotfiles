{
  pkgs,
  lib,
  isNixOS,
  ...
}: let
  # sets a random wallpaper and changes the colors
  hypr-wallpaper = pkgs.writeShellScriptBin "hypr-wallpaper" ''
    ${pkgs.python3}/bin/python3 ${../programs/wallust/hypr-wallpaper.py} "$@"
  '';
  preload-wallpapers = pkgs.writeShellApplication {
    name = "preload-wallpapers";
    runtimeInputs = [pkgs.wallust hypr-wallpaper];
    text = ''
      rm -rf "$HOME/.cache/swww/*"

      curr=$(hypr-wallpaper --current)

      for img in "$HOME/Pictures/Wallpapers"/*; do
          wallust "$img"
      done

      hypr-wallpaper "$curr"
    '';
  };
in {
  home.packages =
    [
      hypr-wallpaper
      preload-wallpapers
    ]
    ++ (lib.optional isNixOS pkgs.swww);

  iynaix.persist.home.directories = [
    ".cache/swww"
  ];
}
