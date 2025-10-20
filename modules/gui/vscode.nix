{
  flake.modules.nixos.gui =
    { config, pkgs, ... }:
    let
      vscodium' = pkgs.vscode-with-extensions.override {
        vscode = pkgs.vscodium;
        vscodeExtensions = with pkgs.vscode-extensions; [
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
    in
    {
      environment.systemPackages = [ vscodium' ];

      custom = {
        shell.packages = {
          rofi-edit-proj = /* sh */ ''
            proj_dir="/persist${config.hj.directory}/projects";
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
    };
}
