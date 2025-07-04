{ config, lib, ... }:
let
  inherit (lib) mkIf;
in
{
  # NOTE: plasma is mainly meant to be used in a VM as hyprland doesn't work
  # it is not configured / customised beyond setting a dark theme from home-manager
  # a separate plasma.nix exists in home-manaager to prevent infinite recursion

  config = mkIf (config.hm.custom.wm == "plasma") {
    services = {
      xserver.enable = true;
      xserver.desktopManager.plasma6.enable = true;
    };
  };
}
