{ lib, ... }:
{
  imports = [ ../vm/home.nix ];

  # hyprland can be used within a VM on AMD
  config.custom.hyprland.enable = lib.mkForce true;
}
