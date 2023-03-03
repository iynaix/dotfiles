{ pkgs, user, ... }: {
  imports = [
    ./desktop
    ./hardware
    ./programs
    ./shell
  ];

  home-manager.users.${user} = {
    services.udiskie = {
      enable = true;
      automount = true;
      notify = true;
    };
  };
}
