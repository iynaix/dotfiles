{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe mkIf;
in
{
  imports = [ ./nixos-hardware.nix ];

  custom = { };

  networking.hostId = "17521d0b"; # required for zfs

  # larger runtime directory size to not run out of ram while building
  # https://discourse.nixos.org/t/run-usr-id-is-too-small/4842
  services.logind.extraConfig = "RuntimeDirectorySize=3G";

  # touchpad support
  services.libinput.enable = true;

  security.wrappers = mkIf config.hm.programs.btop.enable {
    btop = {
      capabilities = "cap_perfmon=+ep";
      group = "wheel";
      owner = "root";
      permissions = "0750";
      source = getExe pkgs.btop;
    };
  };
}
