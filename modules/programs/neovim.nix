{
  pkgs,
  user,
  ...
}: {
  config = {
    home-manager.users.${user} = {
      xdg.configFile."nvim" = {
        source = ./nvim;
        recursive = true;
      };

      programs.neovim = {
        enable = true;
        # defaultEditor = true;
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;

        withNodeJs = true;
        withPython3 = true;
        extraPackages = with pkgs; [fzf gcc nodePackages.typescript-language-server];
        plugins = with pkgs.vimPlugins; [
          bufferline-nvim
          catppuccin-nvim
          editorconfig-nvim
          incsearch-vim
          lualine-nvim
          vim-numbertoggle
          neoscroll-nvim
          nvim-web-devicons
          gitsigns-nvim
          emmet-vim
          vim-indent-object
          nvim-colorizer-lua
          nvim-bufdel
          vim-prisma
          vim-exchange
          vim-abolish
          vim-commentary
          vim-eunuch
          vim-fugitive
          vim-repeat
          vim-sensible
          vim-surround
          vim-unimpaired
          vim-indexed-search
          matchit-zip
          nvim-autopairs
          vim-nix
          # lsp stuff
          nvim-lspconfig
          nvim-compe
          lspsaga-nvim
          trouble-nvim
          formatter-nvim
          # file management
          telescope-nvim
          telescope-fzf-native-nvim
          plenary-nvim
          nvim-tree-lua
          # syntax highlighting
          nvim-treesitter.withAllGrammars
          vim-jsx-pretty
          # tmux plugins
          vim-tmux-navigator
          vimux
        ];
      };
    };

    iynaix.persist.home.directories = [
      ".local/share/nvim" # data directory
      ".local/state/nvim" # persistent session info
    ];
  };
}
