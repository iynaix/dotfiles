_: {
  programs.nixvim = {
    plugins = {
      lsp = {
        enable = true;
        servers = {
          bashls.enable = true;
          # ccls.enable = true; # c / c++
          emmet_ls.enable = true;
          eslint.enable = true;
          graphql.enable = true;
          jsonls.enable = true;
          # lua-ls.enable = true;
          prismals.enable = true;
          pyright.enable = true;
          rust-analyzer = {
            enable = true;
            # do not install the language server
            package = null;
            # autostart = false;
            cmd = null;
            installCargo = false;
            installRustc = false;
            settings.check.command = "clippy";
          };
          tailwindcss.enable = true;
          tsserver.enable = true;
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
        formatOnSave = {
          lspFallback = true;
          timeoutMs = 500;
        };
        formattersByFt = {
          html = [
            [
              "prettierd"
              "prettier"
            ]
          ];
          css = [
            [
              "prettierd"
              "prettier"
            ]
          ];
          javascript = [
            [
              "prettierd"
              "prettier"
            ]
          ];
          javascriptreact = [
            [
              "prettierd"
              "prettier"
            ]
          ];
          typescript = [
            [
              "prettierd"
              "prettier"
            ]
          ];
          typescriptreact = [
            [
              "prettierd"
              "prettier"
            ]
          ];
          python = [ "black" ];
          # lua = [ "stylua" ];
          nix = [ "nixfmt" ];
          markdown = [
            [
              "prettierd"
              "prettier"
            ]
          ];
          rust = [ "rustfmt" ];
        };
      };
    };
  };
}
