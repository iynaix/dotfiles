{pkgs, ...}: {
  imports = [
    ./btop.nix
    ./git.nix
    ./neovim.nix
    ./ranger.nix
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
}
