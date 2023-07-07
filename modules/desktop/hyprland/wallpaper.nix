{
  pkgs,
  user,
  config,
  lib,
  ...
}: let
  # sets up all the colors but DOES NOT change the wallpaper
  hypr-reset = pkgs.writeShellScriptBin "hypr-reset" ''
    # hyprland doesnt accept leading #
    source $HOME/.cache/wallust/colors-hexless.sh

    hyprctl keyword general:col.active_border "rgb($color4) rgb($color6) 45deg";
    hyprctl keyword general:col.inactive_border "rgb($color0)";

    # pink border for monocle windows
    hyprctl keyword windowrulev2 bordercolor "rgb($color5),fullscreen:1"
    # teal border for floating windows
    hyprctl keyword windowrulev2 bordercolor "rgb($color6),floating:1"
    # yellow border for sticky (must be floating) windows
    hyprctl keyword windowrulev2 bordercolor "rgb($color3),pinned:1"

    swww query || swww init
    if [ -z "$1" ]; then
      swww img --transition-type grow "$wallpaper"
    else
      swww img --transition-type grow "$1"
    fi

    launch-waybar
  '';
  # sets a random wallpaper and changes the colors
  hypr-wallpaper = pkgs.writeShellScriptBin "hypr-wallpaper" ''
    if [ -z "$1" ]; then
      wallpaper=$(random-wallpaper)
    else
      wallpaper="$1"
    fi
    wallust ${lib.optionalString (!config.iynaix.wallust.zsh) "--skip-sequences "} "$wallpaper"
    hypr-reset "$wallpaper"
  '';
  # applies a set theme
  hypr-theme = pkgs.writeShellScriptBin "hypr-theme" ''
    theme=''${1:-catppuccin-mocha}

    wal --theme "$theme"

    if [ $theme = "catppuccin-mocha" ]; then
      hypr-reset "${../wallpapers/gits-catppuccin.jpg}"
    else
      hypr-reset
    fi
  '';
in {
  config = {
    home-manager.users.${user} = {
      home = {
        packages = [
          hypr-reset
          hypr-theme
          hypr-wallpaper
          pkgs.swww
        ];
      };
    };
  };
}
