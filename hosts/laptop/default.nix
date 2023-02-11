{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  environment.systemPackages = with pkgs; [ ];
}