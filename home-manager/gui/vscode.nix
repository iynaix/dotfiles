{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (!config.custom.headless) {
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      aaron-bond.better-comments
      bbenoist.nix
      bradlc.vscode-tailwindcss
      catppuccin.catppuccin-vsc
      christian-kohler.npm-intellisense
      dbaeumer.vscode-eslint
      denoland.vscode-deno
      donjayamanne.githistory
      eamodio.gitlens
      esbenp.prettier-vscode
      formulahendry.auto-rename-tag
      graphql.vscode-graphql-syntax
      gruntfuggly.todo-tree
      jnoortheen.nix-ide
      mhutchie.git-graph
      mkhl.direnv
      ms-python.black-formatter
      ms-python.flake8
      ms-python.vscode-pylance
      pkief.material-icon-theme
      prisma.prisma
      rust-lang.rust-analyzer
      sumneko.lua
      supermaven.supermaven
      tamasfe.even-better-toml
      usernamehw.errorlens
      vscodevim.vim
      xadillax.viml
      yzhang.markdown-all-in-one
    ];
  };

  home = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };

  custom.persist = {
    home.directories = [
      ".config/VSCodium"
      ".vscode-oss"
    ];
  };
}
