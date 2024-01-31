{pkgs, ...}: {
  imports = [
    ./bash.nix
    ./btop.nix
    ./cava.nix
    ./direnv.nix
    ./fish.nix
    ./git.nix
    ./neovim
    ./nix.nix
    ./rice.nix
    ./shell.nix
    ./starship.nix
    ./tmux.nix
    ./yazi.nix
  ];

  home.packages = with pkgs; [
    # dysk # better disk info
    fd
    fx
    htop
    sd
    ugrep
  ];

  programs = {
    bat.enable = true;

    eza = {
      enable = true;
      enableAliases = true;
      icons = true;
      extraOptions = ["--group-directories-first" "--header" "--octal-permissions"];
    };

    fzf = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };
  };

  custom.persist = {
    home = {
      cache = [
        ".local/share/zoxide"
      ];
    };
  };
}
