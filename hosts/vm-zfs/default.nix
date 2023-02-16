{ config, pkgs, ... }:

{
  imports = [
    ../zfs.nix
    ./hardware-configuration.nix
    ../../modules/media/download.nix # torrenting stuff
  ];

  # enable clipboard and file sharing
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
  services.spice-webdavd.enable = true;

  environment.systemPackages = with pkgs; [ nixfmt ];
}
