{ pkgs, ... }: {
  home = {
    file.".config/mpv" = {
      source = ./mpv;
    recursive = true;
    };
  };
  
  programs = {
    mpv = {
      enable = true;
    };
  };
}

       
