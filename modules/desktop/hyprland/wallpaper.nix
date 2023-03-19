{ pkgs, inputs, system, user, lib, config, ... }:
let
  # cfg = config.iynaix.hyprland;
  # hypr-wallpaper = pkgs.writeShellScriptBin "hypr-wallpaper" (lib.concatStringsSep "\n" (
  #   (lib.mapAttrsToList
  #     (monitor: wallpaper: "swww img -o ${monitor} --transition-type grow ${wallpaper}")
  #     cfg.wallpapers)
  # ));
  hypr-wallpaper = pkgs.writeShellScriptBin "hypr-wallpaper" /* sh */ ''
    wal -n -i $HOME/Pictures/Wallpapers

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
  '';
in
{
  options.iynaix.hyprland = {
    wallpapers = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = { };
      description = "Attrset of wallpapers to use for swww";
      example = ''{
        DP-2 = "/path/to/wallpaper.png";
      }'';
    };
  };

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
