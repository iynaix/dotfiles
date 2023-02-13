{ config, pkgs, ... }:

{
  # NOTE: this is a config for configuration.nix, not a home-manager config
  services.xserver = {
    enable = true;
    desktopManager.gnome.enable = true;
  };
}
