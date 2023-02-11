{ pkgs, ... }: {
  home = {
    packages = with pkgs; [ zsh zsh-powerlevel10k ];

    file.".config/zsh" = {
      source = ./zsh;
      recursive = true;
    };
  };
}
