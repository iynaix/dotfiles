{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  nixpkgs.overlays = [ inputs.niri.overlays.niri ];

  programs.niri = mkIf (config.hm.custom.wm == "niri") {
    enable = true;

    inherit (config.hm.programs.niri) package;
  };
}
