{ dots, ... }:
{
  programs.nixvim = {
    plugins = {
      lsp = {
        enable = true;
        servers = {
          bashls.enable = true;
          # ccls.enable = true; # c / c++
          denols.enable = true;
          eslint.enable = true;
          jsonls.enable = true;
          # lua-ls.enable = true;
          nixd = {
            enable = true;
            settings = {
              diagnostic.suppress = [ "sema-escaping-with" ];
              options = {
                nixos = {
                  expr = "(builtins.getFlake \"${dots}\").nixosConfigurations.desktop.options";
                };
                home-manager = {
                  expr = "(builtins.getFlake \"${dots}\").homeConfigurations.desktop.options";
                };
              };
            };
          };
          pyright.enable = true;
        };

        keymaps = {
          silent = true;
          diagnostic = {
            # Navigate in diagnostics
            "<leader>k" = "goto_prev";
            "<leader>j" = "goto_next";
          };
          lspBuf = {
            gd = "definition";
            "<C-LeftMouse>" = "definition";
            "<F2>" = "rename";
            gD = "implementation";
            ca = "code_action";
            K = "hover";
          };
        };
      };
      conform-nvim = {
        enable = true;
        settings = {
          format_on_save = {
            lspFallback = true;
            timeoutMs = 500;
          };
          formatters_by_ft = {
            python = [ "black" ];
            # lua = [ "stylua" ];
            nix = [ "nixfmt" ];
            markdown = [
              [
                "prettierd"
                "prettier"
              ]
            ];
          };
        };
      };
    };
  };
}
