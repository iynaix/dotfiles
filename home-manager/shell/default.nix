{pkgs, ...}: {
  imports = [
    ./bash.nix
    ./btop.nix
    ./direnv.nix
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
    dysk # better disk info
    fd
    fzf
    htop
    sd
    vimv
    ugrep
  ];

  programs.eza = {
    enable = true;
    enableAliases = true;
    icons = true;
    extraOptions = ["--group-directories-first" "--color-scale"];
  };

  programs.nix-index.enable = true;
}
