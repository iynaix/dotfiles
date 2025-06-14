{
  pkgs,
  lib,
  dots ? null,
  host ? "desktop",
  ...
}:
{
  # nvf options can be found at:
  # https://notashelf.github.io/nvf/options.html
  imports = [
    ./keymaps.nix
  ];

  vim = {
    viAlias = true;
    vimAlias = true;

    theme = {
      enable = true;
      name = "catppuccin";
      style = "mocha";
    };

    extraPlugins = with pkgs.vimPlugins; {
      direnv = {
        package = direnv-vim;
      };
      oil = {
        package = oil-nvim;
        setup = "require('oil').setup()";
      };
      rooter = {
        package = vim-rooter;
      };
      spectre = {
        package = nvim-spectre;
      };
      vim-tmux-navigator = {
        package = vim-tmux-navigator;
      };
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

    # misc meta settings
    clipboard = {
      enable = true;
      registers = "unnamedplus";
    };
    lineNumberMode = "relNumber";
    preventJunkFiles = true;
    searchCase = "smart";

    # spellcheck = {
    #   enable = true;
    #   programmingWordlist.enable = true;
    # };

    # autocmds
    luaConfigPost = # lua
      ''
        -- use default colorscheme in tty
        -- https://github.com/catppuccin/nvim/issues/588#issuecomment-2272877967
        vim.g.has_ui = #vim.api.nvim_list_uis() > 0
        vim.g.has_gui = vim.g.has_ui and (vim.env.DISPLAY ~= nil or vim.env.WAYLAND_DISPLAY ~= nil)

        if not vim.g.has_gui then
          if vim.g.has_ui then
            vim.o.termguicolors = false
            vim.cmd.colorscheme('default')
          end
          return
        end

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

    dashboard = {
      startify = {
        enable = true;
        changeToVCRoot = true;
      };
    };

    languages = {
      enableFormat = true;
      enableTreesitter = true;

      # TODO: misc plugins
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
        lsp = {
          server = "nixd";
          options = lib.mkIf (dots != null) {
            nixos.expr = "(builtins.getFlake \"${dots}\").nixosConfigurations.${host}.options";
            home-manager.expr = "(builtins.getFlake \"${dots}\").homeConfigurations.${host}.options";
          };
        };
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
      enable = true;
      formatOnSave = true;
      # lightbulb.enable = true;
      lspkind.enable = true;
      otter-nvim.enable = true; # provide lsp for embedded languages
      trouble.enable = true;
      # lspSignature?
      # mappings?
    };

    autocomplete.nvim-cmp.enable = true;
    autopairs.nvim-autopairs.enable = true;
    binds.whichKey.enable = true;
    comments.comment-nvim.enable = true;
    # filetree.nvimTree = {
    #   enable = true;
    #   openOnSetup = false;
    # };
    git.enable = true;
    # enable dashboard?
    lazy.enable = true;
    notes.todo-comments.enable = true;
    projects.project-nvim.enable = true;
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
}
