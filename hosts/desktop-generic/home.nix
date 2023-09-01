{
  pkgs,
  lib,
  isNixOS,
  ...
}: {
  iynaix = {
    pathofbuilding.enable = false;
    trimage.enable = false;
  };

  home = {
    packages = lib.mkIf isNixOS (
      with pkgs; [deadbeef ffmpeg]
    );
  };

  programs.obs-studio.enable = isNixOS;

  # required for vial to work?
  # services.udev.extraRules = ''KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"'';
}
