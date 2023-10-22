{...}: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.sessionVariables = {
    # silence direnv
    DIRENV_LOG_FORMAT = "";
  };

  iynaix.persist = {
    home.directories = [
      ".cargo"
      ".cache/pip"
      ".cache/yarn"
      ".local/share/direnv"
    ];
  };
}
