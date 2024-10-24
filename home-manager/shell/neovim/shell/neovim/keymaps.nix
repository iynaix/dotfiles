_:
let
  mkKeymap = mode: key: action: { inherit mode key action; };
  mkKeymapWithOpts =
    mode: key: action: opts:
    (mkKeymap mode key action) // { options = opts; };
in
{
  programs.nixvim.keymaps = [
    # fix page up and page down so the cursor doesn't move
    (mkKeymap "n" "<PageUp>" "<C-U>")
    (mkKeymap "n" "<PageDown>" "<C-D>")
    (mkKeymap "i" "<PageUp>" "<C-O><C-U>")
    (mkKeymap "i" "<PageDown>" "<C-O><C-D>")
    # ctrl-s to save
    (mkKeymap "n" "<C-S>" ":w<CR>")
    (mkKeymap "i" "<C-S>" "<C-O>:up<CR>")
    (mkKeymap "v" "<C-S>" "<C-C>:up<CR>")
    # L to go to the end of the line
    (mkKeymap "n" "L" "$")
    # Y copies to end of line
    (mkKeymap "n" "Y" "y$")
    # keep cursor in place when joining lines
    (mkKeymap "n" "J" "mzJ`z")
    # visual shifting (does not exit visual mode)
    (mkKeymap "v" "<" "<gv")
    (mkKeymap "v" ">" ">gv")
    # copy and paste to clipboard
    (mkKeymap "v" "<C-C>" ''"+y'')
    (mkKeymap "n" "<C-V>" ''"+P'')
    (mkKeymap "i" "<C-V>" ''<C-O>"+P'')
    # replace highlighted text when pasting
    (mkKeymap "v" "<C-V>" ''"+P'')
    # automatically jump to end of text pasted
    (mkKeymapWithOpts "v" "y" "y`]" { silent = true; })
    (mkKeymapWithOpts "v" "p" "p`]" { silent = true; })
    (mkKeymapWithOpts "n" "p" "p`]" { silent = true; })
    # reselect text
    (mkKeymap "v" "gV" "`[v`]")
    # disable F1 key
    (mkKeymap "n" "<F1>" "<Esc>")
    (mkKeymap "i" "<F1>" "<Esc>")
    (mkKeymap "v" "<F1>" "<Esc>")
    # TODO: disable manual key k?
    # jk or kj to escape insert mode
    (mkKeymap "i" "jk" "<Esc>")
    (mkKeymap "i" "kj" "<Esc>")
    # center display after searches
    (mkKeymap "n" "n" "nzzzv")
    (mkKeymap "n" "N" "Nzzzv")
    (mkKeymap "n" "*" "*zzzv")
    (mkKeymap "n" "#" "#zzzv")
    (mkKeymap "n" "g*" "g*zzzv")
    (mkKeymap "n" "g#" "g#zzzv")
    # only jumps of more than 5 lines are added to the jumplist
    (mkKeymapWithOpts "n" "k" "(v:count > 5 ? \"m'\" . v:count : \"\") . 'k'" { expr = true; })
    (mkKeymapWithOpts "n" "j" "(v:count > 5 ? \"m'\" . v:count : \"\") . 'j'" { expr = true; })
    # vv enter visual block mode
    (mkKeymap "n" "vv" "<C-V>")
    # ; is an alias for :
    (mkKeymap "n" ";" ":")
    # better command line editing
    (mkKeymap "c" "<C-A>" "<Home>")
    (mkKeymap "c" "<C-E>" "<End>")
    # easier buffer navigation
    (mkKeymap "n" "<Tab>" ":bnext<CR>")
    (mkKeymap "n" "<S-Tab>" ":bprevious<CR>")
    # swap functionality of gj and gk
    (mkKeymap "n" "j" "gj")
    (mkKeymap "n" "k" "gk")
    (mkKeymap "n" "gj" "j")
    (mkKeymap "n" "gk" "k")
    # TODO: incsearch?
    # better quickfix navigation
    (mkKeymap "n" "<C-J>" ":cnext<CR>")
    (mkKeymap "n" "<C-K>" ":cprevious<CR>")
    # vim fugitive
    (mkKeymap "n" "<leader>gs" ":G<CR>")
  ];
}
