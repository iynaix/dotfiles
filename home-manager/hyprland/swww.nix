{
  config,
  isNixOS,
  lib,
  pkgs,
  ...
}: let
  # sets a random wallpaper and changes the colors
  hypr-wallpaper = pkgs.writeShellScriptBin "hypr-wallpaper" ''
    ${pkgs.python3}/bin/python3 ${../programs/wallust/hypr-wallpaper.py} ${lib.optionalString (!config.iynaix.wallust.enable) "--no-wallust"} --fallback "${../gits-catppuccin.jpg}" "$@"
  '';
  preload-wallpapers = pkgs.writeShellApplication {
    name = "preload-wallpapers";
    runtimeInputs = [pkgs.wallust hypr-wallpaper];
    text = ''
      rm -rf "$HOME/.cache/wallust/Resized"

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

  iynaix.persist = {
    home.directories = [
      ".cache/swww"
    ];
  };
}
