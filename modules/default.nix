{ pkgs, user, ... }: {
  imports = [
    ./shell
    ./programs
    ./desktop
    ./desktop/gtk.nix
  ];

  home-manager.users.${user} = {
    services.udiskie = {
      enable = true;
      automount = true;
      notify = true;
    };
  };
}
