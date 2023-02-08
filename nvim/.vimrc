"modern vim, forget about vi compatibility
set nocompatible

" initialize plugins
" Specify a directory for plugins
call plug#begin('~/.vim/plugged')

Plug 'akinsho/nvim-bufferline.lua'
Plug 'editorconfig/editorconfig-vim'
Plug 'haishanh/night-owl.vim'
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
Plug 'haya14busa/incsearch.vim'
Plug 'hoob3rt/lualine.nvim'
Plug 'jeffkreeftmeijer/vim-numbertoggle'
Plug 'karb94/neoscroll.nvim'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'lewis6991/gitsigns.nvim'
Plug 'mattn/emmet-vim'
Plug 'michaeljsmith/vim-indent-object'
Plug 'norcalli/nvim-colorizer.lua'
Plug 'ojroques/nvim-bufdel'
Plug 'pantharshit00/vim-prisma'
Plug 'tommcdo/vim-exchange' " cxiw ., cxx ., cxc
Plug 'tpope/vim-abolish' " :%S
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-unimpaired' " helpful shorthand like [b ]b
Plug 'vim-scripts/IndexedSearch'
Plug 'vim-scripts/matchit.zip'
Plug 'windwp/nvim-autopairs'

" Language Server Protocol
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-compe'
Plug 'glepnir/lspsaga.nvim', { 'branch': 'main' }
Plug 'folke/trouble.nvim'
Plug 'mhartington/formatter.nvim'

" File Management
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
Plug 'nvim-lua/plenary.nvim'
Plug 'kyazdani42/nvim-tree.lua'

" Syntax Highlighting
" https://github.com/nvim-treesitter/nvim-treesitter/issues/1111
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'MaxMEllon/vim-jsx-pretty' " fix indentation in jsx until treesitter can

" tmux plugins
Plug 'christoomey/vim-tmux-navigator'
Plug 'preservim/vimux'

call plug#end()

" enable 24bit true color
if (has("termguicolors"))
    set termguicolors
endif

"Enable loading filetype and indentation plugins
set fileformat=unix
set ignorecase
set smartcase "overrides ignorecase if search contains uppercase
set hlsearch
set showmode "Shows the current editing mode
set noeb vb t_vb= "disable beeping
set novisualbell "disable screen blinking
set synmaxcol=0  "full syntax highlighting including long lines

set title "Set title of the window
set autoread " auto reload the file if it changes

set showcmd "show (partial) commands (or size of selection in Visual mode) in status line
set number
set relativenumber

"Always show number of lines changed
set report=0

set showmatch
set matchtime=2 "briefly jump to a matching bracket for 0.2s
set scrolloff=8 "jump 5 lines when running out of the screen

"Use 4 spaces for <Tab> and :retab
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set shiftround "round indent to multiple of 'shiftwidth' for > and < commands

set termencoding=utf-8

set cursorline "Better highlighting of the current line

set magic "some characters in pattern are taken literally
set hidden "Allows u to have unwritten buffers

"Go back to the position the cursor was on the last time this file was edited
au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | execute("normal `\"") | endif

"Use menu to show command-line completion (in 'full' case)
"improve the way autocomplete works

"Set command-line completion mode:
"   - on first <Tab>, when more than one match, list all matches and complete
"     the longest common  string
"   - on second <Tab>, complete the next full match and show menu

set wildmode=list:longest,list:full
" set completeopt=menu,longest
set completeopt=menuone,noselect
set pumheight=15 "menu contains a max of 15 items

"change to a centralised swap directory
set directory=/tmp
set viewdir=/tmp
set undodir=/tmp
" always change to same directory as current file
set autochdir

set noswapfile
set nobackup "do not use backups
set nowritebackup
" use system clipboard
set clipboard=unnamed

"right clicking produces a menu
set mouse=a
set mousemodel=popup
set mousehide "hides the mouse while typing

set exrc " use project specific vimrc

"Show 3 lines between a change and a fold that contains unchanged lines
set diffopt+=context:3

"check if running in terminal and set to 256 colors
colorscheme catppuccin-mocha

"Sign column same color as line numbers
highlight clear SignColumn

set smartindent
set foldlevelstart=99 "disable initial folding of file

set noerrorbells
set shortmess=atToOI "disable welcome message

let mapleader = " " "Set mapleader
set timeoutlen=500 "Lower the timeout after typing the leader key
set modeline
set noshowmode

set virtualedit=block "virtual edit mode in visual block so can go past EOL
set gdefault "set substitution to be global by default e.g. :s///g
set ttyfast "set fast terminal for better redrawing

set guifont=Fira\ Code\ Nerd\ Font\ Medium\ 11

"more natural splits
set splitright splitbelow

" easier navigation of windows
nnoremap <c-j> <c-w><c-j>
nnoremap <c-k> <c-w><c-k>
nnoremap <c-l> <c-w><c-l>
nnoremap <c-h> <c-w><c-h>

" easier resizing of windows
nnoremap <M-Down> :resize -2<CR>
nnoremap <M-Up> :resize +2<CR>
nnoremap <M-Right> :vertical resize -2<CR>
nnoremap <M-Left> :vertical resize +2<CR>

"swap exists warning, edit anyway
:au SwapExists * let v:swapchoice = 'e'

if exists('$TMUX')
    let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>[6 q\<Esc>\\"
    let &t_SR = "\<Esc>Ptmux;\<Esc>\<Esc>[4 q\<Esc>\\"
    let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>[2 q\<Esc>\\"
else
	let &t_SI = "\<Esc>[6 q"
	let &t_SR = "\<Esc>[4 q"
	let &t_EI = "\<Esc>[2 q"
endif

" Remove trailing whitespace from end of line
autocmd BufWritePre * :%s/\s\+$//e

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Mappings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"fix page up and page down so that cursor doesnt move
noremap <PageUp> <C-U><C-U>
noremap <PageDown> <C-D><C-D>
inoremap <PageUp> <C-O><C-U><C-O><C-U>
inoremap <PageDown> <C-O><C-D><C-O><C-D>

"To save, press ctrl-s.
nnoremap <c-s> :up<CR>
inoremap <c-s> <Esc>:up<CR>
vnoremap <c-s> :up<CR>

" L is easier to type
noremap L $

"Y copies to end of line
noremap Y y$

" keep cursor in place when joining lines
nnoremap J mzJ`z

"visual shifting (does not exit Visual mode)
vnoremap < <gv
vnoremap > >gv

"Edit the vimrc file
nnoremap <silent> <leader>ev :e $HOME/.dotfiles/nvim/.vimrc<CR>
nnoremap <silent> <leader>ez :e $HOME/.dotfiles/zsh/.zshrc<CR>
au BufWritePost .vimrc source %

set pastetoggle=<F12>

" copy and paste to clipboard
vnoremap <C-c> "+y
map <C-v> "+P
inoremap <C-v> <Esc>"+P

" replace highlighted text when pasting
vnoremap <leader>p "_dP

" Automatically jump to end of text you pasted:
vnoremap <silent> y y`]
vnoremap <silent> p p`]
nnoremap <silent> p p`]


" Quickly select text you just pasted:
noremap gV `[v`]

" vp doesn't replace paste buffer
function! RestoreRegister()
  let @" = s:restore_reg
  return ''
endfunction
function! s:Repl()
  let s:restore_reg = @"
  return "p@=RestoreRegister()\<cr>"
endfunction
vnoremap <silent> <expr> p <sid>Repl()

nnoremap <leader>/ :noh<cr>

"prevent the f1 key from triggering
inoremap <F1> <ESC>
nnoremap <F1> <ESC>
vnoremap <F1> <ESC>

"prevent manual key
nnoremap K <nop>

" stop command line history
" map q: :q

"save on losing focus, saves file when tabbing away from the editor
"do not save if buffer is untitled
au FocusLost ^(\[No Name\]) :wa

"jk / kj exits insert mode
inoremap jk <ESC>
inoremap kj <ESC>

" absolute line numbers in insert mode, relative otherwise for easy movement
au InsertEnter * :set nu nornu
au InsertLeave * :set nu rnu

"center display after searches
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap J mzJ`z
nnoremap * *zzzv
nnoremap # #zzzvv
nnoremap g* g*zzzv
nnoremap g# g#zzzv

" undo breakpoints after punctuation
inoremap , ,<c-g>u
inoremap . .<c-g>u
inoremap ! !<c-g>u
inoremap ? ?<c-g>u

" only jumps of more than 5 lines make it into the jumplist
nnoremap <expr> k (v:count > 5 ? "m'" . v:count : "") . 'k'
nnoremap <expr> j (v:count > 5 ? "m'" . v:count : "") . 'j'

" moving text by lines
" vnoremap J :m '>+1<CR>gv=gv
" vnoremap K :m '>-2<CR>gv=gv
" nnoremap <leader>k :m .-2<CR>==
" nnoremap <leader>j :m .+1<CR>==

"easily enter visual block mode
nnoremap vv <C-v>

" ; is an alias for :
nnoremap ; :

" Better command line editing
cnoremap <C-j> <t_kd>
cnoremap <C-k> <t_ku>
cnoremap <C-a> <Home>
cnoremap <C-e> <End>"

" for when we forget to use sudo to open/edit a file
cnoremap w!! w !sudo tee % >/dev/null

"easier buffer navigation
nnoremap <Tab> :bnext<cr>
nnoremap <S-Tab> :bprevious<cr>

"open help in a vertical split
cnoremap vh :vert help

" prevent bad habits
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
inoremap <esc> <nop>

"mappings for convenience of browsing lines
"gj and gk now perform up and down on real lines instead
nnoremap j gj
nnoremap gj j
nnoremap k gk
nnoremap gk k

" incsearch
map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)
let g:incsearch#consistent_n_direction = 1
let g:incsearch#do_not_save_error_message_history = 1
let g:incsearch#magic = '\v' " very magic (sane use of regexes for searching)

" better quickfix navigation
nnoremap ]q :cnext<cr>
nnoremap [q :cprev<cr>

" nvm-bufdel
nnoremap <silent> <leader>db :BufDel<CR>

" windwp/nvim-autopairs
lua << EOF
require('nvim-autopairs').setup()
EOF

" akinsho/nvim-bufferline.lua
lua << EOF
local symbols = {error = " ", warning = " ", info = " "}

require("bufferline").setup {
    highlights = {
        fill = {
            guifg = "#011627",
        },
        -- separator = {
        --     guifg = "#ffffff",
        -- },
    },
    options = {
        -- separator_style = {"|", "|"},
        separator_style = "thin",
        diagnostics = "nvim_lsp",
        diagnostics_indicator = function(count, level, diagnostics_dict, context)
            local s = " "
            for e, n in pairs(diagnostics_dict) do
                local sym = e == "error" and " "
                or (e == "warning" and " " or "" )
                s = s .. n .. sym
            end
            return s
        end

    }
}
EOF
nnoremap <silent> gb :BufferLinePick<CR>

" norcalli/nvim-colorizer.lua
lua << EOF
require'colorizer'.setup()
EOF

" lewis6991/gitsigns.nvim
lua << EOF
  require('gitsigns').setup({})
EOF

" tpope/vim-fugitive
nnoremap <leader>gg :G<cr>

" karb94/neoscroll.nvim
lua << EOF
require('neoscroll').setup()
EOF

" neovim/nvim-lspconfig
" npm i -g typescript typescript-language-server
lua << EOF
local util = require "lspconfig/util"
require 'lspconfig'.tsserver.setup{
    on_attach = function(client)
        client.server_capabilities.documentFormattingProvider = false
    end,
    root_dir = util.root_pattern(".git", "tsconfig.json", "jsconfig.json")
}
EOF

nnoremap <silent> gd    <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <C-LeftMouse>    <cmd>lua vim.lsp.buf.definition()<CR>
" nnoremap <silent> gh    <cmd>lua vim.lsp.buf.hover()<CR>
" nnoremap <silent> gH    <cmd>:Telescope lsp_code_actions<CR>
nnoremap <silent> gD    <cmd>lua vim.lsp.buf.implementation()<CR>
" nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<CR>
" noremap <silent> gR    <cmd>lua vim.lsp.buf.references()<CR>

lua require 'lspsaga'.init_lsp_saga()
nnoremap <silent> gH <cmd>lua require'lspsaga.provider'.lsp_finder()<CR>
nnoremap <silent><leader>ca <cmd>lua require('lspsaga.codeaction').code_action()<CR>
vnoremap <silent><leader>ca :<C-U>lua require('lspsaga.codeaction').range_code_action()<CR>
nnoremap <silent> gh <cmd>lua require('lspsaga.hover').render_hover_doc()<CR>
nnoremap <silent> <C-f> <cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<CR>
nnoremap <silent> <C-b> <cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<CR>
nnoremap <silent> gs <cmd>lua require('lspsaga.signaturehelp').signature_help()<CR>
nnoremap <silent> gr <cmd>lua require('lspsaga.rename').rename()<CR>
nnoremap <silent> gp <cmd>lua require'lspsaga.provider'.preview_definition()<CR>
nnoremap <silent> <M-d> <cmd>lua require('lspsaga.floaterm').open_float_terminal()<CR>
nnoremap <silent> <M-g> <cmd>lua require('lspsaga.floaterm').open_float_terminal("lazygit")<CR>
tnoremap <silent> <M-g> <C-\><C-n>:lua require('lspsaga.floaterm').close_float_terminal()<CR>
tnoremap <silent> <M-d> <C-\><C-n>:lua require('lspsaga.floaterm').close_float_terminal()<CR>
nnoremap <silent> <leader>cd <cmd>lua require'lspsaga.diagnostic'.show_line_diagnostics()<CR>
nnoremap <silent> <leader>cc <cmd>lua require'lspsaga.diagnostic'.show_cursor_diagnostics()<CR>
nnoremap <silent> [e <cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_prev()<CR>
nnoremap <silent> ]e <cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_next()<CR>

lua << EOF
require 'trouble'.setup {}
EOF
nnoremap <leader>xx <cmd>TroubleToggle<cr>
nnoremap <leader>xw <cmd>TroubleToggle lsp_workspace_diagnostics<cr>
nnoremap <leader>xd <cmd>TroubleToggle lsp_document_diagnostics<cr>
nnoremap <leader>xq <cmd>TroubleToggle quickfix<cr>
nnoremap <leader>xl <cmd>TroubleToggle loclist<cr>
nnoremap gR <cmd>TroubleToggle lsp_references<cr>

" nvim-telescope/telescope.nvim
lua << EOF
require('telescope').setup {
  defaults = {
    file_ignore_patterns = { "yarn.lock" }
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = false,
      override_file_sorter = true,
      case_mode = "smart_case"
    }
  },
  pickers = {
    buffers = {
      show_all_buffers = true,
      sort_lastused = true,
      theme = "dropdown",
      previewer = false,
      mappings = {
        i = {
          ["<c-d>"] = "delete_buffer",
        }
      }
    }
  }
}
require('telescope').load_extension('fzf')
EOF
nnoremap <leader>pf :lua require'telescope.builtin'.git_files{ hidden = true }<cr>
" nnoremap <leader>ff :lua require'telescope.builtin'.find_files{ hidden = true }<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <Leader>fs :lua require'telescope.builtin'.file_browser{ cwd = vim.fn.expand('%:p:h') }<cr>
nnoremap <Leader>fc :lua require'telescope.builtin'.git_status{}<cr>
nnoremap <Leader>fr :lua require'telescope.builtin'.oldfiles{}<cr>
nnoremap <Leader>fq :lua require'telescope.builtin'.quickfix{}<cr>
nnoremap <Leader>cb :lua require'telescope.builtin'.git_branches{}<cr>
nnoremap <leader>fw <cmd>Telescope tmux windows<cr>
" nnoremap <leader>fm :lua require('telescope').extensions.harpoon.marks{}<cr>
nnoremap <leader>/ <cmd>lua require('telescope.builtin').live_grep()<cr>
" nnoremap <leader>fh <cmd>Telescope help_tags<cr>

" 'hrsh7th/nvim-compe'
lua << EOF
require'compe'.setup {
  enabled = true;
  autocomplete = true;
  source = {
    path = true;
    buffer = true;
    nvim_lsp = true;
    nvim_lua = true;
    -- treesitter = true;
  };
}
EOF
inoremap <silent><expr> <C-Space> compe#complete()
inoremap <silent><expr> <CR>      compe#confirm('<CR>')

" nvim-treesitter
lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = {
    'html', 'javascript', 'typescript', 'tsx', 'css', 'json'
  },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = true
  },
  indent = {
    enable = false
  }
}
EOF

" hoob3rt/lualine.nvim
lua << EOF
require('plenary.reload').reload_module('lualine', true)
require('lualine').setup({
  options = {
    theme = 'auto',
    disabled_types = { 'NvimTree' }
  },
  sections = {
    lualine_x = {},
    -- lualine_y = {},
    -- lualine_z = {},
  }
})
EOF

" mhartington/formatter.nvim
lua << EOF
-- Prettier function for formatter
local prettier = function()
  return {
    exe = "prettier",
    args = { "--stdin-filepath", vim.api.nvim_buf_get_name(0), "--double-quote" },
    stdin = true,
  }
end

require("formatter").setup({
  logging = false,
  filetype = {
    javascript = { prettier },
    typescript = { prettier },
    typescriptreact = { prettier },
    html = { prettier },
    markdown = { prettier },
    lua = {
      -- Stylua
      function()
        return {
          exe = "stylua",
          args = { "--indent-width", 2, "--indent-type", "Spaces" },
          stdin = false,
        }
      end,
    },
  },
})

-- Runs Formatter on save
vim.api.nvim_exec([[
augroup FormatAutogroup
  autocmd!
  autocmd BufWritePost *.js,*.ts,*.tsx,*.css,*.scss,*.md,*.html,*.lua FormatWrite
augroup END
]], true)
EOF
