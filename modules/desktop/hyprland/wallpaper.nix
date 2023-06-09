{
  pkgs,
  config,
  user,
  ...
}: let
  # sets up all the colors but DOES NOT change the wallpaper
  hypr-reset =
    pkgs.writeShellScriptBin "hypr-reset"
    /*
    sh
    */
    ''
      # hyprland doesnt accept leading #
      source /home/${user}/.cache/wal/colors-hexless.sh

      hyprctl keyword general:col.active_border "rgb(''${color4}) rgb(''${color6}) 45deg";
      hyprctl keyword general:col.inactive_border "rgb(''${color0})";

      # pink border for monocle windows
      hyprctl keyword windowrulev2 bordercolor "rgb(''${color5}),fullscreen:1"
      # teal border for floating windows
      hyprctl keyword windowrulev2 bordercolor "rgb(''${color6}),floating:1"
      # yellow border for sticky (must be floating) windows
      hyprctl keyword windowrulev2 bordercolor "rgb(''${color3}),pinned:1"

      swww query || swww init
      if [ -z "$1" ]; then
        swww img --transition-type grow "$(< "/home/${user}/.cache/wal/wal")"
      else
        swww img --transition-type grow "$1"
      fi

      launch-waybar
    '';
  # sets a random wallpaper and changes the colors
  hypr-wallpaper =
    pkgs.writeShellScriptBin "hypr-wallpaper"
    /*
    sh
    */
    ''
      wal --backend ${config.iynaix.pywal.backend} -n -i "/home/${user}/Pictures/Wallpapers"

      hypr-reset
    '';
  # applies a set theme
  hypr-theme =
    pkgs.writeShellScriptBin "hypr-theme"
    /*
    sh
    */
    ''
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
