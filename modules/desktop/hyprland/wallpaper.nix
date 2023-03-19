{ pkgs, inputs, system, user, lib, config, ... }:
let
  cfg = config.iynaix.hyprland;
  hypr-wallpaper = pkgs.writeShellScriptBin "hypr-wallpaper" (lib.concatStringsSep "\n" (
    (lib.mapAttrsToList
      (monitor: wallpaper: "swww img -o ${monitor} --transition-type grow ${wallpaper}")
      cfg.wallpapers)
  ));
  hypr-test = pkgs.writeShellScriptBin "hypr-test" /* sh */ ''
    wal -n -i $HOME/Pictures/Wallpapers
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
          hypr-test
        ];
      };
    };
  };
}
