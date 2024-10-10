{ pkgs, ... }:
{
  programs.nixvim = {
    plugins = {
      lsp.servers = {
        emmet_ls.enable = true;
        graphql.enable = true;
        prismals = {
          enable = true;
          package = pkgs.nodePackages."@prisma/language-server";
        };
        tailwindcss.enable = true;
        ts_ls.enable = true;
      };

      conform-nvim = {
        settings = {
          formatters_by_ft = {
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
  };

  custom.persist = {
    home = {
      cache.directories = [ ".cache/yarn" ];
    };
  };
}
