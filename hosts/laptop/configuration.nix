{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  environment.systemPackages = with pkgs; [ ];

  # do not autologin on laptop!
  services.xserver.displayManager.autoLogin.enable = false;
}
