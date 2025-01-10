_: {
  imports = [
    ./keymaps.nix
  ];

  # nvf options can be found at:
  # https://notashelf.github.io/nvf/options.html
  programs.nvf = {
    enable = true;
    settings.vim = {
      viAlias = true;
      vimAlias = true;

      theme = {
        enable = true;
        name = "catppuccin";
        style = "mocha";
      };

      options = {
        cursorline = true;
        gdefault = true;
        magic = true;
        matchtime = 2; # briefly jump to a matching bracket for 0.2s
        exrc = true; # use project specific vimrc
        smartindent = true;
        virtualedit = "block"; # allow cursor to move anywhere in visual block mode
        # Use 4 spaces for <Tab> and :retab
        tabstop = 4;
        softtabstop = 4;
        shiftwidth = 4;
        expandtab = true;
        shiftround = true; # round indent to multiple of 'shiftwidth' for > and < command
      };

      # autocmds
      luaConfigPost = ''
        -- remove trailing whitespace on save
        vim.api.nvim_create_autocmd("BufWritePre", {
          pattern = "*",
          command = "silent! %s/\\s\\+$//e",
        })

        -- save on focus lost
        vim.api.nvim_create_autocmd("FocusLost", {
          pattern = "*",
          command = "silent! wa",
        })

        -- absolute line numbers in insert mode, relative otherwise
        vim.api.nvim_create_autocmd("InsertEnter", {
          pattern = "*",
          command = "set number norelativenumber",
        })
        vim.api.nvim_create_autocmd("InsertLeave", {
          pattern = "*",
          command = "set number relativenumber",
        })
      '';

      languages = {
        enableFormat = true;
        enableLSP = true;
        enableTreesitter = true;

        # TODO: misc plugins
        # * direnv
        # * supermaven
        # harpoon
        # luasnip

        bash.enable = true;
        html.enable = true;
        lua.enable = true;
        markdown = {
          enable = true;
          extensions.render-markdown-nvim.enable = true;
        };
        nix = {
          enable = true;
          format.type = "nixfmt";
          # TODO: change to nixd when supported:
          # https://github.com/NotAShelf/nvf/pull/458
          lsp.server = "nil";
        };
        python.enable = true;
        rust = {
          enable = true;
          crates.enable = true;
        };
        tailwind.enable = true;
        ts = {
          enable = true;
          extensions.ts-error-translator.enable = true;
          # lsp.server = "denols"; # enable for deno?
        };
      };

      lsp = {
        formatOnSave = true;
        # lightbulb.enable = true;
        lspkind.enable = true;
        lsplines.enable = true;
        trouble.enable = true;
        # lspSignature?
        # mappings?
      };

      disableArrows = true; # no arrow keys
      preventJunkFiles = true;
      useSystemClipboard = true;

      autocomplete.nvim-cmp.enable = true;
      autopairs.nvim-autopairs.enable = true;
      binds.whichKey.enable = true;
      comments.comment-nvim.enable = true;
      filetree.nvimTree = {
        enable = true;
        openOnSetup = false;
      };
      git.enable = true;
      # enable dashboard?
      lazy.enable = true;
      lineNumberMode = "relNumber";
      notes.todo-comments.enable = true;
      projects.project-nvim.enable = true;
      searchCase = "smart";
      snippets.luasnip.enable = true;
      statusline.lualine.enable = true;
      tabline.nvimBufferline = {
        enable = true;
        setupOpts.options = {
          numbers = "none";
          show_close_icon = false;
        };
      };
      telescope = {
        enable = true;
        mappings = {
          buffers = "<leader>fb";
          findFiles = "<leader>ff";
          gitBranches = "<leader>gb";
          gitStatus = "<leader>gs";
          liveGrep = "<leader>/";
        };
      };
      treesitter.autotagHtml = true;
      ui = {
        colorizer.enable = true;
        smartcolumn.enable = true;
      };
      utility = {
        motion.leap.enable = true;
        # preview.markdownPreview.enable
        surround.enable = true;
      };
      visuals.nvim-web-devicons.enable = true;
    };
  };

  xdg = {
    desktopEntries.nvim = {
      name = "Neovim";
      genericName = "Text Editor";
      icon = "nvim";
      terminal = true;
      exec = "nvim %f";
    };

    mimeApps = {
      defaultApplications = {
        "text/plain" = "nvim.desktop";
        "application/x-shellscript" = "nvim.desktop";
        "application/xml" = "nvim.desktop";
      };
      associations.added = {
        "text/csv" = "nvim.desktop";
      };
    };
  };

  home.shellAliases = {
    nano = "nvim";
    neovim = "nvim";
    v = "nvim";
  };

  custom.persist = {
    home.directories = [
      ".local/share/nvim" # data directory
      ".local/state/nvim" # persistent session info
      ".local/share/supermaven"
    ];
  };
}
