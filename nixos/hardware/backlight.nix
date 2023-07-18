{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.iynaix.backlight;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.brightnessctl];

    iynaix.hyprland.extraBinds = {
      bind = {
        ",XF86MonBrightnessDown" = "exec, brightnessctl set 5%-";
        ",XF86MonBrightnessUp" = "exec, brightnessctl set +5%";
      };
    };
  };
}
