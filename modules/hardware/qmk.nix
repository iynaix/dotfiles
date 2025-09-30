{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.custom.hardware.qmk = {
    enable = mkEnableOption "QMK";
  };

  config = mkIf config.custom.hardware.qmk.enable {
    hardware.keyboard.qmk.enable = true;

    # via / vial can be run with nix run / nix shell
  };
}
