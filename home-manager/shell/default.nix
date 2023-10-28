{pkgs, ...}: {
  imports = [
    ./bash.nix
    ./btop.nix
    ./direnv.nix
    ./fish.nix
    ./git.nix
    ./neovim.nix
    ./nix.nix
    ./rice
    ./shell.nix
    ./starship.nix
    ./tmux.nix
    ./yazi.nix
  ];

  home.packages = with pkgs; [
    bat
    dysk # better disk info
    fd
    fx
    fzf
    htop
    sd
    ugrep
  ];

  programs.eza = {
    enable = true;
    enableAliases = true;
    icons = true;
    extraOptions = ["--group-directories-first" "--color-scale" "--header" "--octal-permissions"];
  };

  programs.nix-index.enable = true;
}
