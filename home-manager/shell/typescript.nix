_: {
  # programs.nixvim = {
  #   plugins = {
  #     lsp.servers = {
  #       emmet_ls.enable = true;
  #       graphql.enable = true;
  #       prismals = {
  #         enable = true;
  #         package = pkgs.nodePackages."@prisma/language-server";
  #       };
  #       tailwindcss.enable = true;
  #       ts_ls.enable = true;
  #     };

  #     conform-nvim = {
  #       settings = {
  #         formatters_by_ft =
  #           let
  #             js_formatters = {
  #               __unkeyed-1 = "prettierd";
  #               __unkeyed-2 = "prettier";
  #               stop_after_first = true;
  #             };
  #           in
  #           {
  #             html = js_formatters;
  #             css = js_formatters;
  #             javascript = js_formatters;
  #             javascriptreact = js_formatters;
  #             typescript = js_formatters;
  #             typescriptreact = js_formatters;
  #           };
  #         notify_no_formatters = false;
  #       };
  #     };
  #   };
  # };

  programs.git.ignores = [
    "node_modules"
  ];

  custom.persist = {
    home = {
      cache.directories = [ ".cache/yarn" ];
    };
  };
}
