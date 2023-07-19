{
  user,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./hyprland
    ./programs
    ./shell
  ];

  # mounting and unmounting of disks
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    # do not change this value
    stateVersion = "22.11";

    packages = with pkgs; [
      config.iynaix.terminal.fakeGnomeTerminal
      libreoffice
    ];

    # copy wallpapers
    file."Pictures/Wallpapers/gits-catppuccin.jpg" = {
      source = ./gits-catppuccin.jpg;
      recursive = true;
    };
  };
}
