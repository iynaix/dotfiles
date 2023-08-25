{pkgs, ...}: {
  imports = [
    ./bash.nix
    ./btop.nix
    ./fish.nix
    ./git.nix
    ./lf.nix
    ./neovim.nix
    ./nix.nix
    ./rice
    ./shell.nix
    ./starship.nix
    ./tmux.nix
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
