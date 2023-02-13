{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  services.xserver.videoDrivers = [ "nvidia" ];

  environment.systemPackages = with pkgs; [ ];
}
