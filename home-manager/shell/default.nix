{pkgs, ...}: {
  imports = [
    ./btop.nix
    ./git.nix
    ./lf.nix
    ./neovim.nix
    ./nix.nix
    ./rice
    ./starship.nix
    ./tmux.nix
    ./zsh.nix
  ];

  home.packages = with pkgs; [
    bat
    fd
    fzf
    htop
    sd
    vimv
    ugrep
  ];

  programs.exa = {
    enable = true;
    enableAliases = true;
    icons = true;
    extraOptions = ["--group-directories-first" "--color-scale"];
  };

  programs.nix-index.enable = true;
}
