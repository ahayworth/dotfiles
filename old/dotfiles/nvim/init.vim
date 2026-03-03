lua require('plugins')

lua <<EOF
require 'nvim-treesitter.configs'.setup {
  ensure_installed = 'maintained',
  highlight = {
    enable = false,
  },
  incremental_selection = {
    enable = true,
  },
}
EOF

"Display
set number
set showmatch "jump when completing a brace
set mat=3 "highlight that match for .3 seconds
set linebreak "dont wrap in the middle of a word

hi CursorLine   cterm=NONE ctermbg=darkgrey ctermfg=white guibg=darkred guifg=white
hi CursorColumn cterm=NONE ctermbg=grey ctermfg=white guibg=darkred guifg=white

"Tabs
set expandtab "spaces, yo
set tabstop=2
set shiftwidth=2

"Search
set ic "ignore case
set smartcase "care about case if you type something uppercase

"Code Fold
set foldmethod=manual
set nofoldenable
set foldnestmax=5

"Randoms
set copyindent "Auto-indent for new lines should use whatever indents are in-use
" let g:is_posix=1 "Yes, we have a 'posix' shell.
"Stay out of ex-mode unless you really, really mean it.
nnoremap Q gQ
set wildmode=list:longest "match up to the point of ambiguity
set title "set terminal title intelligently
nnoremap <Leader>l :set cursorline! <CR>
nnoremap <Leader>c :set cursorcolumn! <CR>

"remap j/k to treat long lines as broken lines
map j gj
map k gk

"colors!
set termguicolors
colorscheme gruvbox
let g:gruvbox_contrast_dark = 'hard'
let g:gruvbox_italic = 1

" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>

"show-me-my-whitespace stuff. needs to be at the end.
highlight WhiteSpaceEOL ctermbg=darkgreen
match WhiteSpaceEOL /\s\+$/
