{ pkgs, inputs, system, user, ... }:
let
  hypr-wallpaper = pkgs.writeShellScriptBin "hypr-wallpaper" /* sh */ ''
    wal -n -i ''${1:-$HOME/Pictures/Wallpapers}

    source $HOME/.cache/wal/colors-hexless.sh

    # hyprland doesnt accept leading #

    hyprctl keyword general:col.active_border "rgb(''${color4}) rgb(''${color6}) 45deg";
    hyprctl keyword general:col.inactive_border "rgb(''${color0})";

    # pink border for monocle windows
    hyprctl keyword windowrulev2 bordercolor "rgb(''${color5}),fullscreen:1"
    # teal border for floating windows
    hyprctl keyword windowrulev2 bordercolor "rgb(''${color6}),floating:1"
    # yellow border for sticky (must be floating) windows
    hyprctl keyword windowrulev2 bordercolor "rgb(''${color3}),pinned:1"

    swww img --transition-type grow "$(< "$HOME/.cache/wal/wal")"

    launch-waybar
  '';
in
{
  config = {
    home-manager.users.${user} = {
      home = {
        packages = [
          hypr-wallpaper
          inputs.nixpkgs-wayland.packages.${system}.swww
        ];
      };
    };
  };
}
