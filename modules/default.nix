{ pkgs, user, ... }: {
  imports = [
    ./shell
    ./programs
    ./desktop/gtk.nix
    # bspwm are mutually exclusive via a config option
    ./desktop/bspwm.nix
    ./desktop/gnome3.nix
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
