{ lib, ... }:
{
  imports = [ ../vm/default.nix ];

  # hyprland can be used within a VM on AMD
  config.custom.hyprland.enable = lib.mkForce true;
}
