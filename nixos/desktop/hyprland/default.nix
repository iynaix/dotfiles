{
  system,
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.iynaix.hyprland;
in {
  imports = [
    ./lock.nix
    ./waybar.nix
  ];

  config = lib.mkIf cfg.enable {
    services.xserver.desktopManager.gnome.enable = lib.mkForce false;
    services.xserver.displayManager.lightdm.enable = lib.mkForce false;
    # services.xserver.displayManager.sddm.enable = lib.mkForce true;

    programs.hyprland = {
      enable = true;
      # package = inputs.hyprland.packages.${system}.hyprland;
    };

    environment.systemPackages = [
      inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland
    ];
  };
}
