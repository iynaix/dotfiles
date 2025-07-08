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

  programs.niri = mkIf (config.hm.custom.wm == "niri") {
    enable = true;
    package = pkgs.niri;
  };
}
