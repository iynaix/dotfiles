{ pkgs, host, user, lib, config, ... }:
let
  cfg = config.iynaix.hyprland;
in
{
  options.iynaix.hyprland = {
    wallpapers = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = { };
      description = ''
        Attrset of wallpapers to use for $XDG_CONFIG_HOME/hyprpaper/hyprpaper.conf, see
        https://github.com/hyprwm/hyprpaper#usage
      '';
      example = ''{
        DP-2 = "/path/to/wallpaper.png";
      }'';
    };
  };

  config = {
    home-manager.users.${user} = {
      home = {
        packages = [ pkgs.hyprpaper ];

        file.".config/hypr/hyprpaper.conf".text = lib.concatStringsSep "\n" (
          (lib.mapAttrsToList
            (monitor: wallpaper: "preload = ${wallpaper}")
            cfg.wallpapers) ++

          (lib.mapAttrsToList
            (monitor: wallpaper: "wallpaper = ${monitor},${wallpaper}")
            cfg.wallpapers)
        );
      };
    };
  };
}
