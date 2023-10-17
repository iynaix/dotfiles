{pkgs, ...}: {
  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    withNodeJs = true;
    withPython3 = true;
    extraPackages = with pkgs; [fzf gcc nodePackages.typescript-language-server];
    plugins = with pkgs.vimPlugins; [
      bufferline-nvim
      catppuccin-nvim
      direnv-vim
      editorconfig-nvim
      emmet-vim
      gitsigns-nvim
      incsearch-vim
      lualine-nvim
      matchit-zip
      neoscroll-nvim
      nvim-autopairs
      nvim-bufdel
      nvim-colorizer-lua
      nvim-web-devicons
      vim-abolish
      vim-commentary
      vim-eunuch
      vim-exchange
      vim-fugitive
      vim-indent-object
      vim-indexed-search
      vim-nix
      vim-numbertoggle
      vim-prisma
      vim-repeat
      vim-sensible
      vim-surround
      vim-unimpaired
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

  iynaix.persist = {
    home.directories = [
      ".local/share/nvim" # data directory
      ".local/state/nvim" # persistent session info
    ];
  };
}
