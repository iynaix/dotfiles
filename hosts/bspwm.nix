{ config, pkgs, user, ... }:

{
  services.xserver = {
    enable = true;
    windowManager.bspwm.enable = true;
  };

  home-manager.users.${user} = {
    xsession = {
      enable = true;
      windowManager.bspwm.enable = true;
    };
  };
}
