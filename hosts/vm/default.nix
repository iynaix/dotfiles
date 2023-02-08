{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # enable clipboard and file sharing
  services.spice-vdagentd.enable = true;

  environment.systemPackages = with pkgs; [ nixfmt ];
}