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
      # add backlight indicator to waybar
      iynaix.waybar = lib.mkIf hmCfg.config.iynaix.waybar.enable {
        config.backlight = {
          format = "{icon}  {percent}%";
          format-icons = ["󰃞" "󰃟" "󰃝" "󰃠"];
          on-scroll-down = "brightnessctl s 1%-";
          on-scroll-up = "brightnessctl s +1%";
        };
      };

      # add keybinds for backlight
      wayland.windowManager.hyprland.settings = {
        bind = [
          ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
          ",XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ];
      };
    };
  };
}
