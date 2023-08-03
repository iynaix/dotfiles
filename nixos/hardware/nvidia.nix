{
  config,
  lib,
  user,
  ...
}: let
  cfg = config.iynaix-nixos.nvidia;
in {
  config = lib.mkIf cfg.enable {
    # enable nvidia support
    services.xserver.videoDrivers = ["nvidia"];

    hardware.opengl = {
      enable = true;
      driSupport = true;
    };

    hardware.nvidia = {
      modesetting.enable = true;
      # prevents crashes with nvidia on resuming, see:
      # https://github.com/hyprwm/Hyprland/issues/804#issuecomment-1369994379
      powerManagement.enable = false;
    };

    # NOTE: environment variables are set in hyprland config

    home-manager.users.${user}.wayland.windowManager.hyprland.enableNvidiaPatches = config.iynaix-nixos.hyprland-nixos.enable;
  };
}
