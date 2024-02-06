{ config, ... }:
{
  programs.nixvim = {
    plugins = {
      bufferline.enable = true;
      comment-nvim.enable = true;
      # perform initial setup with
      # :Copilot setup
      # TODO: switch to copilot lua?
      copilot-vim.enable = true;
      fugitive.enable = true;
      gitsigns.enable = true;
      # harpoon.enable = true;
      lualine.enable = true;
      luasnip.enable = true;
      nvim-autopairs.enable = true;
      nvim-tree.enable = true;
      surround.enable = true;
      tmux-navigator.enable = true;
      treesitter = {
        enable = true;
        indent = true;

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
            desc = "Telescope git files";
          };
          "<leader>fc" = {
            action = "git_status";
            desc = "Telescope git status";
          };
          "<leader>fb" = {
            action = "buffers";
            desc = "Telescope buffers";
          };
          "<leader>fr" = {
            action = "oldfiles";
            desc = "Telescope recent files";
          };
          "<leader>fq" = {
            action = "quickfix";
            desc = "Telescope quickfix";
          };
          "<leader>gb" = {
            action = "git_branches";
            desc = "Telescope git branches";
          };
          "<leader>/" = {
            action = "live_grep";
            desc = "Telescope grep";
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
  };
}
