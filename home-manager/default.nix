{user, ...}: {
  imports = [
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
  };
}
