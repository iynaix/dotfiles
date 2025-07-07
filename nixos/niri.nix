{ inputs, pkgs, ... }:
{
  nixpkgs.overlays = [ inputs.niri.overlays.niri ];

  programs = {
    niri.package = pkgs.niri;
  };
}
