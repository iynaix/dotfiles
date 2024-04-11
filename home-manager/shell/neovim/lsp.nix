_: {
  programs.nixvim = {
    plugins = {
      lsp = {
        enable = true;
        servers = {
          bashls.enable = true;
          # ccls.enable = true; # c / c++
          eslint.enable = true;
          jsonls.enable = true;
          # lua-ls.enable = true;
          nil_ls.enable = true;
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
        formatOnSave = {
          lspFallback = true;
          timeoutMs = 500;
        };
        formattersByFt = {
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
}
