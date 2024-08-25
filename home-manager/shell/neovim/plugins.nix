{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  {
    programs.nixvim = {
      plugins = {
        bufferline.enable = true;
        comment.enable = true;
        fugitive.enable = true;
        gitsigns.enable = true;
        harpoon.enable = true;
        lightline.enable = true;
        luasnip.enable = true;
        nvim-autopairs.enable = true;
        nvim-tree.enable = true;
        project-nvim.enable = true;
        surround.enable = true;
        tmux-navigator.enable = true;
        treesitter = {
          enable = true;
          settings.indent.enable = true;

          grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
            bash
            c
            cmake
            comment
            cpp
            css
            csv
            diff
            dockerfile
            fish
            gitcommit
            gitignore
            git_rebase
            graphql
            html
            ini
            javascript
            json
            jsonc
            lua
            make
            markdown
            markdown_inline
            meson
            ninja
            nix
            prisma
            po
            python
            rasi
            requirements # pip requirements.txt
            rst
            rust
            sql
            toml
            tsv
            tsx
            typescript
            vim
            vimdoc
            xml
            yaml
          ];
        };

        telescope = {
          enable = true;
          extensions = {
            fzf-native.enable = true;
          };
          keymaps = {
            "<leader>pf" = {
              action = "git_files";
              options.desc = "Telescope git files";
            };
            "<leader>fc" = {
              action = "git_status";
              options.desc = "Telescope git status";
            };
            "<leader>fb" = {
              action = "buffers";
              options.desc = "Telescope buffers";
            };
            "<leader>fr" = {
              action = "oldfiles";
              options.desc = "Telescope recent files";
            };
            "<leader>fq" = {
              action = "quickfix";
              options.desc = "Telescope quickfix";
            };
            "<leader>gb" = {
              action = "git_branches";
              options.desc = "Telescope git branches";
            };
            "<leader>/" = {
              action = "live_grep";
              options.desc = "Telescope grep";
            };
            # TODO: harpoon marks?
            # TODO: tmux windows?
          };
        };

        # trouble.enable = true;
        # incsearch-vim
        # matchit-zip
        # neoscroll-nvim
        # nvim-bufdel
        # nvim-colorizer-lua
        # nvim-web-devicons
        # vim-abolish
        # vim-exchange
        # vim-indexed-search
        # vim-indent-object
        # vim-numbertoggle
        # vim-repeat
        # vim-unimpaired

        # vimux
      };

      extraConfigVim = ''
        let g:lightline = {
            \ 'enable': {'tabline': 0 }
            \ }
      '';
    };
  }

  # supermaven
  {
    programs.nixvim = {
      extraPlugins = with pkgs.vimPlugins; [ supermaven-nvim ];
      extraConfigLua = ''
        require("supermaven-nvim").setup({})
      '';
    };
  }
]
