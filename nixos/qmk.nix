{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.custom-nixos.qmk.enable {
  hardware.keyboard.qmk.enable = true;

  # required for vial to work
  environment.systemPackages = with pkgs; [vial via];

  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl
  '';
}
