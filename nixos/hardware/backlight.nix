{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.iynaix-nixos.backlight;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.brightnessctl];
  };
}
