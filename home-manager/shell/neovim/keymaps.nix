_: {
  programs.nixvim.keymaps = [
    # fix page up and page down so the cursor doesn't move
    {
      mode = "n";
      key = "<PageUp>";
      action = "<C-U>";
    }
    {
      mode = "n";
      key = "<PageDown>";
      action = "<C-D>";
    }
    {
      mode = "i";
      key = "<PageUp>";
      action = "<C-O><C-U>";
    }
    {
      mode = "i";
      key = "<PageDown>";
      action = "<C-O><C-D>";
    }
    # ctrl-s to save
    {
      mode = "n";
      key = "<C-S>";
      action = ":up<CR>";
    }
    {
      mode = "i";
      key = "<C-S>";
      action = "<C-O>:up<CR>";
    }
    {
      mode = "v";
      key = "<C-S>";
      action = "<C-C>:up<CR>";
    }
    # L to go to the end of the line
    {
      mode = "n";
      key = "L";
      action = "$";
    }
    # Y copies to end of line
    {
      mode = "n";
      key = "Y";
      action = "y$";
    }
    # keep cursor in place when joining lines
    {
      mode = "n";
      key = "J";
      action = "mzJ`z";
    }
    # visual shifting (does not exit visual mode)
    {
      mode = "v";
      key = "<";
      action = "<gv";
    }
    {
      mode = "v";
      key = ">";
      action = ">gv";
    }
    # copy and paste to clipboard
    {
      mode = "v";
      key = "<C-C>";
      action = ''"+y'';
    }
    {
      mode = "n";
      key = "<C-V>";
      action = ''"+P'';
    }
    {
      mode = "i";
      key = "<C-V>";
      action = ''<C-O>"+P'';
    }
    # replace highlighted text when pasting
    {
      mode = "v";
      key = "<C-V>";
      action = ''"+P'';
    }
    # automatically jump to end of text pasted
    {
      mode = "v";
      key = "y";
      action = "y`]";
      options.silent = true;
    }
    {
      mode = "v";
      key = "p";
      action = "p`]";
      options.silent = true;
    }
    {
      mode = "n";
      key = "p";
      action = "p`]";
      options.silent = true;
    }
    # reselect text
    {
      mode = "v";
      key = "gV";
      action = "`[v`]";
    }
    # disable F1 key
    {
      mode = "n";
      key = "<F1>";
      action = "<Esc>";
    }
    {
      mode = "i";
      key = "<F1>";
      action = "<Esc>";
    }
    {
      mode = "v";
      key = "<F1>";
      action = "<Esc>";
    }
    # TODO: disable manual key k?
    # jk or kj to escape insert mode
    {
      mode = "i";
      key = "jk";
      action = "<Esc>";
    }
    {
      mode = "i";
      key = "kj";
      action = "<Esc>";
    }
    # center display after searches
    {
      mode = "n";
      key = "n";
      action = "nzzzv";
    }
    {
      mode = "n";
      key = "N";
      action = "Nzzzv";
    }
    {
      mode = "n";
      key = "*";
      action = "*zzzv";
    }
    {
      mode = "n";
      key = "#";
      action = "#zzzv";
    }
    {
      mode = "n";
      key = "g*";
      action = "g*zzzv";
    }
    {
      mode = "n";
      key = "g#";
      action = "g#zzzv";
    }
    # only jumps of more than 5 lines are added to the jumplist
    {
      mode = "n";
      key = "k";
      action = "(v:count > 5 ? \"m'\" . v:count : \"\") . 'k'";
      options.expr = true;
    }
    {
      mode = "n";
      key = "j";
      action = "(v:count > 5 ? \"m'\" . v:count : \"\") . 'j'";
      options.expr = true;
    }
    # vv enter visual block mode
    {
      mode = "n";
      key = "vv";
      action = "<C-V>";
    }
    # ; is an alias for :
    {
      mode = "n";
      key = ";";
      action = ":";
    }
    # better command line editing
    {
      mode = "c";
      key = "<C-A>";
      action = "<Home>";
    }
    {
      mode = "c";
      key = "<C-E>";
      action = "<End>";
    }
    # easier buffer navigation
    {
      mode = "n";
      key = "<Tab>";
      action = ":bnext<CR>";
    }
    {
      mode = "n";
      key = "<S-Tab>";
      action = ":bprevious<CR>";
    }
    # swap functionality of gj and gk
    {
      mode = "n";
      key = "j";
      action = "gj";
    }
    {
      mode = "n";
      key = "k";
      action = "gk";
    }
    {
      mode = "n";
      key = "gj";
      action = "j";
    }
    {
      mode = "n";
      key = "gk";
      action = "k";
    }
    # TODO: incsearch?
    # better quickfix navigation
    {
      mode = "n";
      key = "<C-J>";
      action = ":cnext<CR>";
    }
    {
      mode = "n";
      key = "<C-K>";
      action = ":cprevious<CR>";
    }
    # TODO: bufdel?
    # vim fugitive
    {
      mode = "n";
      key = "<leader>gs";
      action = ":G<CR>";
    }
  ];
}
