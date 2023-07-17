{user, ...}: {
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
  };

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    # do not change this value
    stateVersion = "22.11";
  };
}
