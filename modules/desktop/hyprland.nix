{ pkgs, host, user, lib, config, ... }:
let cfg = config.iynaix.hyprland; in
{
  options.iynaix.hyprland = {
    # mutually exclusive with bspwm
    enable = lib.mkEnableOption "Hyprland" // { default = (!config.iynaix.bspwm && !config.iynaix.gnome3); };
  };

  config = lib.mkIf cfg.enable {
    services.xserver.desktopManager.gnome.enable = lib.mkForce false;

    home-manager.users.${user} = {
      wayland.windowManager.hyprland = {
        enable = true;
        systemdIntegration = true;
        nvidiaPatches = true;
      };
    };
  };
}
