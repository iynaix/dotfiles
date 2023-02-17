{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/media/download.nix # torrenting stuff
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  environment.systemPackages = with pkgs; [ ];
}
