{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  programs.helix.languages = {
    grammar = [
      {
        name = "gohtml";
        source.git = "https://github.com/heisfer/tree-sitter-go-html-template";
        source.rev = "d9b4f708018403be8a120cb25917c20bf297cff5";
      }
      {
        name = "cpp";
        source.git = "https://github.com/tree-sitter/tree-sitter-cpp";
        source.rev = "a90f170f92d5d70e7c2d4183c146e61ba5f3a457";
      }
    ];

    language = [
      {
        name = "gohtml";
        scope = "source.gohtml";
        injection-regex = "gohtml";
        file-types = [ "gohtml" ];
        language-servers = [
          "vscode-html-language-server"
          "emmet-lsp"
        ];
      }
      {
        name = "html";
        language-servers = [
          "emmet-lsp"
          "vscode-html-language-server"
        ];
        auto-pairs = true;
        injection-regex = "html";
        file-types = [ "html" ];
      }
      {
        name = "javascript";
        auto-format = true;
        language-servers = [ "tsserver" ];
      }
      {
        name = "markdown";
        language-servers = [
          "mdpls"
          "marksman"
        ];
      }
      {
        name = "nix";
        language-servers = [
          "nixd"
          "scls"
        ];
        scope = "source.nix";
        injection-regex = "nix";
        auto-format = true;
        file-types = [ "nix" ];
        comment-token = "#";
      }
      {
        name = "rust";
        language-servers = [ "rust-analyzer" ];
        file-types = [ "rs" ];
      }
      {
        name = "typescript";
        auto-format = true;
        language-servers = [ "tsserver" ];
      }
    ];

    language-server = {
      # don't need to specify bash in languages because I'm only rewriting lsp command
      bash-language-server = {
        command = lib.getExe pkgs.nodePackages_latest.bash-language-server;
        args = [ "start" ];
      };

      emmet-lsp = {
        command = lib.getExe pkgs.emmet-language-server;
        args = [ "--stdio" ];
      };

      marksman = {
        command = lib.getExe pkgs.marksman;
        args = [ "server" ];
      };

      nil = {
        command = lib.getExe inputs.nil.packages.${pkgs.system}.default;
        config.nil.formatting.command = [ "${lib.getExe pkgs.nixfmt-rfc-style}" ];
      };

      nixd = {
        command = lib.getExe inputs.nixd.packages.${pkgs.system}.default;
        config.nixd = {
          formatting.command = [ "${lib.getExe pkgs.nixfmt-rfc-style}" ];
          nixos.expr = "(builtins.getFlake \"/etc/nixos\").nixosConfigurations.voyage.options";
          home-manager.expr = "(builtins.getFlake \"/etc/nixos\").nixosConfigurations.voyage.options";
        };
      };

      rust-analyzer = {
        command = lib.getExe pkgs.rust-analyzer;
        # args = [ "--stdio" ];
        config = {
          inlayHints = {
            bindingModeHints.enable = false;
            closingBraceHints.minLines = 10;
            closureReturnTypeHints.enable = "with_block";
            discriminantHints.enable = "fieldless";
            lifetimeElisionHints.enable = "skip_trivial";
            typeHints.hideClosureInitialization = false;
          };
        };
      };

      tailwindcss-ls = {
        command = lib.getExe pkgs.tailwindcss-language-server;
        args = [ "--stdio" ];
      };

      tsserver = {
        command = lib.getExe' pkgs.nodePackages_latest.typescript-language-server "typescript-language-server";
        args = [ "--stdio" ];
      };

      vscode-html-language-server = {
        command = lib.getExe' pkgs.vscode-langservers-extracted "vscode-html-language-server";
        args = [ "--stdio" ];
        config = {
          provideFormatter = true;
        };
      };

    };
  };
}
