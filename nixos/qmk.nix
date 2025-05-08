{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.custom.qmk = {
    enable = mkEnableOption "QMK";
  };

  config = mkIf config.custom.qmk.enable {
    hardware.keyboard.qmk.enable = true;

    # via / vial can be run with nix run / nix shell

    services.udev.extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl
    '';
  };
}
