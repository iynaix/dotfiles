{
  flake.nixosModules.hardware_qmk = {
    hardware.keyboard.qmk.enable = true;
    # via / vial can be run with nix run / nix shell
  };
}
