{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  nixpkgs.overlays = [ inputs.niri.overlays.niri ];

  environment.systemPackages = [ pkgs.xwayland-satellite ];

  programs.niri = mkIf (config.hm.custom.wm == "niri") {
    enable = true;

    inherit (config.hm.programs.niri) package;
  };
}
