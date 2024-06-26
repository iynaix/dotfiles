_: {
  programs.nixvim = {
    plugins = {
      lsp.servers = {
        emmet-ls.enable = true;
        graphql.enable = true;
        prismals.enable = true;
        tailwindcss.enable = true;
        tsserver.enable = true;
      };

      conform-nvim = {
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
        };
      };
    };
  };

  custom.persist = {
    home = {
      cache = [ ".cache/yarn" ];
    };
  };
}
