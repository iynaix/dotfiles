{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
in
mkIf (config.custom.wm != "tty") {
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      aaron-bond.better-comments
      bbenoist.nix
      bradlc.vscode-tailwindcss
      christian-kohler.npm-intellisense
      dbaeumer.vscode-eslint
      denoland.vscode-deno
      donjayamanne.githistory
      eamodio.gitlens
      enkia.tokyo-night
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

  custom.shell.packages = {
    rofi-edit-proj = {
      runtimeInputs = [
        config.programs.rofi.package
        config.programs.vscode.package
      ];
      text = # sh
        ''
          proj_dir="/persist${config.home.homeDirectory}/projects";
          projects=$(find "$proj_dir" -maxdepth 1 -type d | sort | sed "s|$proj_dir||" | grep -v "^$" | sed 's|^/||')

          selected=$(echo "$projects" | rofi -dmenu -i -p "Open Project:")

          # Check if a project was selected
          if [ -z "$selected" ]; then
              echo "No project selected"
              exit 0
          fi

          # Open the project in VS Code
          codium "$proj_dir/$selected"
        '';
    };
  };

  custom.persist = {
    home.directories = [
      ".config/VSCodium"
      ".supermaven"
      ".vscode-oss"
    ];
  };
}
