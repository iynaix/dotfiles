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

    home = {
      file.".config/rofi" = {
        source = ./rofi;
        recursive = true;
      };

      file.".config/sxiv" = {
        source = ./sxiv;
        recursive = true;
      };
    };
  };
}
