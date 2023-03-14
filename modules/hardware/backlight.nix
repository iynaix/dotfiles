{ pkgs, lib, host, user, config, ... }:
let cfg = config.iynaix.backlight; in
{
  options.iynaix.backlight = {
    enable = lib.mkEnableOption "backlight";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.brightnessctl ];

    home-manager.users.${user} = {
      services = {
        sxhkd.keybindings = {
          "XF86MonBrightnessDown" = "brightnessctl set 5%-";
          "XF86MonBrightnessUp" = "brightnessctl set +5%";
        };
      };
    };

    iynaix.hyprland.extraBinds = {
      bind = {
        ",XF86MonBrightnessDown" = "exec, brightnessctl set 5%-";
        ",XF86MonBrightnessUp" = "exec, brightnessctl set +5%";
      };
    };
  };
}
