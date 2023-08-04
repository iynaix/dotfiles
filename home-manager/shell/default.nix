{pkgs, ...}: {
  imports = [
    ./btop.nix
    ./git.nix
    ./lf.nix
    ./neovim.nix
    ./nix.nix
    ./rice
    ./tmux.nix
    ./zsh.nix
  ];

  home.packages = with pkgs; [
    bat
    fd
    fzf
    htop
    lazygit
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
