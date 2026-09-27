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
  vim = {
    viAlias = true;
    vimAlias = true;

    theme = {
      enable = true;
      name = "tokyonight";
      style = "night";
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

    diagnostics = {
      enable = true;
      config = {
        virtual_lines = {
          current_line = true;
        };
        virtual_text = true;
      };
    };

    # autocmds
    luaConfigPost = /* lua */ ''
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

      -- reload with direnv when opening file
      vim.api.nvim_create_autocmd("User", {
        pattern = "DirenvLoaded",
        callback = function()
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf)
              and vim.bo[buf].buftype == ""
              and vim.bo[buf].filetype == "rust"
            then
              vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
            end
          end
        end,
      })

      -- fix kitty color when entering neovim
      vim.api.nvim_create_autocmd({ "UIEnter", "ColorScheme" }, {
        callback = function()
          local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
          if not normal.bg then return end
          io.write(string.format("\027]11;#%06x\027\\", normal.bg))
        end,
      })

      vim.api.nvim_create_autocmd("UILeave", {
        callback = function() io.write("\027]111\027\\") end,
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
      clang.enable = true;
      html.enable = true;
      lua.enable = true;
      markdown = {
        enable = true;
        extensions.render-markdown-nvim.enable = true;
      };
      nix = {
        enable = true;
        format = {
          enable = true;
          type = [ "nixfmt" ];
        };
        lsp.servers = [
          "nil"
          "nixd"
        ];
      };
      python.enable = true;
      qml = {
        enable = true;
        format.enable = true;
        lsp.enable = true;
      };
      rust = {
        enable = true;
        extensions.crates-nvim.enable = false;
      };
      typescript = {
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
      presets = {
        tailwindcss-language-server.enable = true;
      };
      otter-nvim.enable = true; # provide lsp for embedded languages
      trouble.enable = true;
      # lspSignature?
      # mappings?
      servers = {
        nixd = {
          settings.options = lib.mkIf (dots != null) {
            nixos.expr = "(builtins.getFlake \"${dots}\").nixosConfigurations.${host}.options";
            nixpkgs.expr = "(import \"${dots}/.tack\").nixpkgs";
          };
        };
        rust-analyzer = {
          settings.rust-analyzer = {
            check = {
              command = "clippy";
            };
          };
        };
      };
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
      extensions = [
        {
          name = "live_grep_args";
          packages = [ pkgs.vimPlugins.telescope-live-grep-args-nvim ];
        }
      ];
      mappings = {
        buffers = "<leader>fb";
        findFiles = "<leader><space>";
        gitBranches = "<leader>gb";
        gitStatus = "<leader>gs";
        # liveGrep = "<leader>/";
      };
      setupOpts = {
        extensions = {
          live_grep_args = {
            auto_quoting = true;
            additional_args = [
              "--smart-case"
              "--hidden"
            ];
            mappings = lib.mkLuaInline ''
              {
                i = {
                  ["<C-k>"] = require("telescope-live-grep-args.actions").quote_prompt(),
                  ["<C-w>"] = require("telescope-live-grep-args.actions").quote_prompt({ postfix = ' --word-regexp' }),
                },
              }
            '';
          };
        };
      };
    };
    treesitter.autotagHtml = true;
    ui = {
      colorizer.enable = true;
      smartcolumn.enable = true;
    };
    utility = {
      direnv.enable = true;
      motion.leap.enable = true;
      # preview.markdownPreview.enable
      surround.enable = true;
    };
    visuals.nvim-web-devicons.enable = true;
  };
}
