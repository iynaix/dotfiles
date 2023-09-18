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

    hm = {...} @ hmCfg: {
      # add wifi indicator to waybar
      iynaix.waybar = lib.mkIf hmCfg.config.iynaix.waybar.enable {
        config.backlight = {
          format = "{icon}  {percent}%";
          format-icons = ["󰃞" "󰃟" "󰃝" "󰃠"];
          on-scroll-down = "brightnessctl s 1%-";
          on-scroll-up = "brightnessctl s +1%";
        };
      };
    };
  };
}
