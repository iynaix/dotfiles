{pkgs, ...}: {
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # vim support
  programs.nixvim = {
    extraPlugins = [pkgs.vimPlugins.direnv-vim];
  };

  home.sessionVariables = {
    # silence direnv
    DIRENV_LOG_FORMAT = "";
  };

  iynaix.persist = {
    home.directories = [
      ".local/share/direnv"
    ];
    cache = [
      ".cargo"
      ".cache/pip"
      ".cache/torch" # pytorch models
      ".cache/yarn"
    ];
  };
}
