{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  programs.helix.languages = {
    language-server = {
      nil = {
        command = lib.getExe inputs.nil.packages.${pkgs.system}.default;
        config.nil.formatting.command = [ "${lib.getExe pkgs.nixfmt-rfc-style}" ];
      };

      # scls = {
      #   command = lib.getExe self'.packages.simple-completion-language-server;
      # };

      # mdpls = {
      #   command = lib.getExe self'.packages.mdpls;
      #   config = {
      #     markdown.preview.auto = true;
      #     markdown.preview.browser = "firefox-devedition";
      #   };
      # };

      marksman = {
        command = lib.getExe pkgs.marksman;
        args = [ "server" ];
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

      vscode-html-language-server = {
        command = lib.getExe' pkgs.vscode-langservers-extracted "vscode-html-language-server";
        args = [ "--stdio" ];
        config = {
          provideFormatter = true;
        };
      };

      tsserver = {
        command = lib.getExe' pkgs.nodePackages_latest.typescript-language-server "typescript-language-server";
        args = [ "--stdio" ];
      };

      # don't need to specify bash in languages because I'm only rewriting lsp command
      bash-language-server = {
        command = lib.getExe pkgs.nodePackages_latest.bash-language-server;
        args = [ "start" ];
      };

      emmet-lsp = {
        command = lib.getExe pkgs.emmet-language-server;
        args = [ "--stdio" ];
      };

      intelephense = {
        command = lib.getExe' pkgs.nodePackages_latest.intelephense "intelephense";
        args = [ "--stdio" ];
      };

      # phpactor = {
      #   command = lib.getExe' pkgs.phpactor "phpactor";
      #   args = [ "language-server" ];
      # };

      tailwindcss-ls = {
        command = lib.getExe pkgs.tailwindcss-language-server;
        args = [ "--stdio" ];
      };
      lua-language-server = {
        command = lib.getExe pkgs.lua-language-server;
      };

    };
    language = [
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
        name = "typescript";
        auto-format = true;
        language-servers = [ "tsserver" ];
      }
      # {
      # name = "php";
      # auto-format = true;
      # language-servers = phplsp;
      # }
      # {
      #   name = "blade";
      #   auto-format = true;
      #   formatter = {
      #     command = lib.getExe pkgs.blade-formatter;
      #     args = [ "--stdin" ];
      #   };
      #   scope = "source.blade.php";
      #   file-types = [
      #     { glob = "*.blade.php"; }
      #     "blade"
      #   ];
      #   injection-regex = "blade";
      #   language-servers = [
      #     "vscode-html-language-server"
      #     "tailwindcss-ls"
      #   ];
      #   block-comment-tokens = {
      #     start = "{{--";
      #     end = "--}}";
      #   };
      #   roots = [
      #     "composer.json"
      #     "index.php"
      #   ];
      # }
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
        name = "markdown";
        language-servers = [
          "mdpls"
          "marksman"
        ];
      }
    ];
    grammar = [
      {
        name = "gohtml";
        source.git = "https://github.com/heisfer/tree-sitter-go-html-template";
        source.rev = "d9b4f708018403be8a120cb25917c20bf297cff5";
      }
    ];
  };
}
