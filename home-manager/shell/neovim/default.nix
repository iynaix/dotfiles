{ ... }:
{
  imports = [
    ./completion.nix
    ./keymaps.nix
    ./lsp.nix
    ./plugins.nix
  ];

  programs.nixvim = {
    enable = true;
    enableMan = false; # do not generate manpages

    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    clipboard = {
      providers.wl-copy.enable = true;
      register = "unnamedplus";
    };

    colorschemes.catppuccin = {
      enable = true;
      settings.flavour = "mocha";
      # transparentBackground = true;
    };

    opts = {
      autoread = true;
      cursorline = true;
      fileformat = "unix";
      hidden = true;
      hlsearch = true;
      ignorecase = true;
      magic = true;
      matchtime = 2; # briefly jump to a matching bracket for 0.2s
      number = true;
      relativenumber = true;
      scrolloff = 8; # jump 5 lines when running out of the screen
      smartcase = true;
      exrc = true; # use project specific vimrc
      smartindent = true;
      virtualedit = "block"; # allow cursor to move anywhere in visual block mode
      gdefault = true; # set global flag by default for substitute
      backup = false;
      # Use 4 spaces for <Tab> and :retab
      tabstop = 4;
      softtabstop = 4;
      shiftwidth = 4;
      expandtab = true;
      shiftround = true; # round indent to multiple of 'shiftwidth' for > and < command
      # swap options
      swapfile = false;
      directory = "/tmp";
      viewdir = "/tmp";
      undodir = "/tmp";
      # more natural splits
      splitright = true;
      splitbelow = true;
    };

    globals = {
      mapleader = " ";
    };

    autoCmd = [
      # remove trailing whitespace on save
      {
        event = "BufWritePre";
        pattern = "*";
        command = "silent! %s/\\s\\+$//e";
      }
      # save on focus lost
      {
        event = "FocusLost";
        pattern = "*";
        command = "silent! wa";
      }
      # absolute line numbers in insert mode, relative otherwise
      {
        event = "InsertEnter";
        pattern = "*";
        command = "set number norelativenumber";
      }
      {
        event = "InsertLeave";
        pattern = "*";
        command = "set number relativenumber";
      }
    ];
  };

  # fix default neovim wrapper desktop entry to run direnv before starting
  # adapted from notashelf, see:
  # https://github.com/NotAShelf/nyx/blob/90915f1c6ba4944a3474f44ac036b940db860ee5/homes/notashelf/terminal/editors/neovim/default.nix#L357
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
      };
      associations.added = {
        "text/csv" = "nvim.desktop";
      };
    };
  };

  home.shellAliases = {
    nano = "nvim";
    v = "nvim";
  };

  custom.persist = {
    home.directories = [
      ".local/share/nvim" # data directory
      ".local/state/nvim" # persistent session info
    ];
  };
}
