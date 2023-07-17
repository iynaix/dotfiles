{pkgs, ...}: {
  imports = [
    ./btop.nix
    ./git.nix
    ./ranger.nix
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
