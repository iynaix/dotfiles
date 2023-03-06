{ pkgs, host, user, lib, config, ... }:
let
  cfg = config.iynaix.hyprland;
in
{
  config = lib.mkIf cfg.enable {
    home-manager.users.${user} = {
      programs.waybar = {
        enable = true;
      };
    };
  };
}
