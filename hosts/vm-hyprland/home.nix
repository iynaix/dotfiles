{ lib, ... }:
let
  inherit (lib) mkOverride;
in
{
  imports = [ ../vm/home.nix ];

  # hyprland can be used within a VM on AMD
  config.custom.hyprland.enable = mkOverride (50 - 1) true;
}
