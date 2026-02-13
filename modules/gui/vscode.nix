{
  flake.nixosModules.gui =
    { pkgs, ... }:
    let
      inherit (pkgs.vscode-utils) buildVscodeMarketplaceExtension;
      vscodium' = pkgs.vscode-with-extensions.override {
        vscode = pkgs.vscodium;
        vscodeExtensions =
          with pkgs.vscode-extensions;
          [
            aaron-bond.better-comments
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
            ms-python.python
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
          ]
          ++
            # for qml
            [
              (buildVscodeMarketplaceExtension {
                mktplcRef = {
                  name = "qt-core";
                  publisher = "TheQtCompany";
                  version = "1.11.1";
                  hash = "sha256-PQmNWezNYVGGNFAJrlMRhXHe3o0XV6LxE2omU1mqZM0=";
                };
              })
              (buildVscodeMarketplaceExtension {
                mktplcRef = {
                  name = "qt-qml";
                  publisher = "TheQtCompany";
                  version = "1.11.1";
                  hash = "sha256-lUXx2VAXK0Av4T3bRW7hXpP0u7zJbDvMbKkpPACT4WE=";
                };
              })
            ];
      };
    in
    {
      environment.systemPackages = [ vscodium' ];

      custom.persist = {
        home.directories = [
          ".config/VSCodium"
          ".supermaven"
          ".vscode-oss"
        ];
      };
    };
}
