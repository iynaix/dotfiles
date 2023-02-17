{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/media/download.nix # torrenting stuff
  ];

  boot.loader.efi.efiSysMountPoint = lib.mkForce "/boot/efi";

  # enable clipboard and file sharing
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
  services.spice-webdavd.enable = true;

  environment.systemPackages = with pkgs; [ nixfmt ];
}
