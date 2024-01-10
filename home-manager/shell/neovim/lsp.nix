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
            # autostart = false;
            installLanguageServer = false;
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
      lsp-format.enable = true;
    };
  };
}
