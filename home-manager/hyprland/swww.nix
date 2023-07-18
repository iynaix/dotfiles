{pkgs, ...}: let
  # sets a random wallpaper and changes the colors
  hypr-wallpaper = pkgs.writeShellScriptBin "hypr-wallpaper" ''
    ${pkgs.python3}/bin/python3 ${../../../home-manager/programs/wallust/hypr-wallpaper.py} "$@"
  '';
in {
  home.packages = [
    hypr-wallpaper
    pkgs.swww
  ];
}
