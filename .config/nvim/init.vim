set runtimepath^=~/.vim runtimepath+=~/.vim/after

let &packpath = &runtimepath
" vim-plug directory
call plug#begin('~/.nvim/plugged')
    " TODO: replace vim-airline with my own
    " (https://irrellia.github.io/blogs/vim-statusline/) 
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'

    Plug 'godlygeek/tabular'
    Plug 'plasticboy/vim-markdown'
    Plug 'iamcco/markdown-preview.nvim', {'do': { -> mkdp#util#install() }}

    " Focused writing
    Plug 'junegunn/limelight.vim'
    Plug 'junegunn/goyo.vim'

    Plug 'fatih/vim-go'
    Plug 'nsf/gocode'

    Plug 'liuchengxu/vim-clap', { 'do': ':Clap install-binary!' }

    " Colorschemes
    " Plug 'lifepillar/vim-colortemplate'
    Plug 'jacoborus/tender.vim'
    Plug 'sonph/onehalf', {'rtp': 'vim/'}
    Plug 'NLKNguyen/papercolor-theme'
    Plug 'arzg/vim-colors-xcode'
    Plug 'connorholyday/vim-snazzy'

    Plug 'Shougo/deoplete.nvim' 
    Plug 'zchee/deoplete-clang'
    Plug 'zchee/deoplete-go' 
    Plug 'zchee/deoplete-jedi'

    Plug 'scrooloose/nerdcommenter'

    Plug 'ludovicchabant/vim-gutentags'

    Plug 'lervag/vimtex'

    Plug 'dense-analysis/ale'
call plug#end()
" :PlugInstall, :PlugUpdate, :PlugUpgrade :PlugClean are the necessary commands


" Options from vim
set number
highlight LineNr ctermfg=DarkGrey
set showtabline=2
set noshowmode
set cmdheight=1
set ignorecase
set smartcase
set showmatch
set foldcolumn=1

" Set indentation
set autoindent 
set smartindent
set expandtab
set shiftwidth=4
set tabstop=4

" Set splits
set splitbelow
set splitright


" Use <C-L> to clear the highlighting of :set hlsearch.
if maparg('<C-L>', 'n') ==# ''
  nnoremap <silent> <C-L> :nohlsearch<CR><C-L>
endif


" Filetype-specific tab widths
autocmd FileType ocaml setlocal expandtab shiftwidth=2 softtabstop=2
autocmd FileType javascript setlocal expandtab shiftwidth=2 softtabstop=2


" Search for a whole word using <leader><backslash>
nnoremap <leader>/ /\<\><left><left>


" Deal effectively with wrapped lines
set wrap
set linebreak
noremap <buffer> <silent> j gj
noremap <buffer> <silent> k gk
noremap <buffer> <silent> 0 g0
noremap <buffer> <silent> $ g$


" Enable system clipboard integration
set clipboard+=unnamedplus
" Workaround for neovim wl-clipboard and netrw interaction hang 
" (see: https://github.com/neovim/neovim/issues/6695 and
" https://github.com/neovim/neovim/issues/9806) 
" let g:clipboard = {
      " \ }


" Mouse support
set mouse=a
map <MiddleMouse> <Nop>
imap <MiddleMouse> <Nop>
map <2-MiddleMouse> <Nop>
imap <2-MiddleMouse> <Nop>
map <3-MiddleMouse> <Nop>
imap <3-MiddleMouse> <Nop>
map <4-MiddleMouse> <Nop>
imap <4-MiddleMouse> <Nop>


" Speed up python startup
let g:python_host_skip_check = 1
let g:python3_host_skip_check = 1


" Use vim-clap buffer, filer lists
cnoreabbrev <expr> b getcmdtype() == ":" && getcmdline() == 'b' ? 'Clap buffers' : 'b'
cnoreabbrev <expr> e getcmdtype() == ":" && getcmdline() == 'e' ? 'Clap filer' : 'e'


" vim-clap override popup mappings 
autocmd FileType clap_input inoremap <silent> <buffer> <Esc> <Esc>:call clap#handler#exit()<CR>
autocmd FileType clap_input inoremap <silent> <buffer> <C-n> <C-R>=clap#navigation#linewise('down')<CR>
autocmd FileType clap_input inoremap <silent> <buffer> <C-p> <C-R>=clap#navigation#linewise('up')<CR>


" use <leader>ll to compile
if !exists("*User_compile") 
    " placed in an `if` block to avoid error message on re-sourcing
    " vimrc/nvim.init
    function User_compile()
        " compiling vimrc/nvim.init is just reloading it
        if &ft == 'vim'
            source $MYVIMRC
            " latex 
        elseif &ft == 'tex' || &ft == 'latex'
            VimtexCompile
            " markdown
        elseif &ft == 'markdown'
            MarkdownPreview
        end
    endfunction
    nnoremap <leader>ll :call User_compile()<CR>
endif


" Disable annoying <F1> behavior
map <F1> <Esc>
imap <F1> <Esc>

" Map <C-s> in insert mode to save, to de-condition <Esc>:w<C-R>i keyboard tic
inoremap <C-s> <Esc>:w<CR>i

" De-condition myself from pressing <Esc> twice to escape insert mode
" nnoremap <Esc> <C-z>
" imap <Esc><Esc> <Esc><C-z>

" use C-S-j and C-S-k to move lines (or blocks of lines) up or down 
let g:C_Ctrl_j = 'off'
nnoremap <C-S-j> :m .+1<CR>==
nnoremap <C-S-k> :m .-2<CR>==
inoremap <C-S-j> <Esc>:m .+1<CR>==gi
inoremap <C-S-k> <Esc>:m .-2<CR>==gi
vnoremap <C-S-j> :m '>+1<CR>gv=gv
vnoremap <C-S-k> :m '<-2<CR>gv=gv


" improved w and q
command! WW w !SUDO_ASKPASS=/usr/lib/ssh/ssh-askpass sudo -A tee % > /dev/null
command! W w
command! Q q


" Spell checking 
set spell


" Distraction-free writing
let g:limelight_conceal_ctermfg = 'gray'
autocmd! User GoyoEnter Limelight
autocmd! User GoyoLeave Limelight!

function! s:goyo_enter()
  let b:quitting = 0
  let b:quitting_bang = 0
  autocmd QuitPre <buffer> let b:quitting = 1
  cabbrev <buffer> q! let b:quitting_bang = 1 <bar> q!
endfunction

function! s:goyo_leave()
  " Quit Vim if this is the only remaining buffer
  if b:quitting && len(filter(range(1, bufnr('$')), 'buflisted(v:val)')) == 1
    if b:quitting_bang
      qa!
    else
      qa
    endif
  endif
endfunction

autocmd! User GoyoEnter call <SID>goyo_enter()
autocmd! User GoyoLeave call <SID>goyo_leave()


" Airline customization
set encoding=utf-8
" let g:airline_section_z = airline#section#create(['windowswap', '%3p%% ', 'linenr', ':%3v'])
" let g:airline_section_error = ''
" let g:airline_section_warning = ''
let g:airline_skip_empty_sections = 1
let g:airline_powerline_fonts = 1 
" let g:airline_left_sep = ''
" let g:airline_right_sep = ''
let g:airline_theme='tender'


" Color schemes
if (has("termguicolors"))
 set termguicolors
endif

" PaperColor 
set background=light | colorscheme PaperColor

" colorscheme xcodedark

" Tender 
" colorscheme tender

" user terminal background color for vim
" hi Normal ctermbg=none

" Make comments italic and bright green (good for dark backgrounds)
" hi Comment ctermfg=49 guifg=#00ffaf
" hi Comment cterm=italic gui=italic



" Deoplete settings
let g:deoplete#enable_at_startup = 0 
autocmd InsertEnter * call deoplete#enable()
" <TAB>: completion.
inoremap <expr><TAB> pumvisible() ? "\<C-N>" : "\<TAB>"
inoremap <expr><S-TAB> pumvisible() ? "\<C-P>" : "\<C-D>"
inoremap <expr><ESC> pumvisible() ? "\<C-E>\<ESC>" : "\<ESC>"
inoremap <expr><CR> pumvisible() ? "\<C-Y>" : "\<CR>"
call deoplete#custom#option('ignore_sources', {'_': ['buffer', 'around']})
set completeopt=menu,preview,longest,menuone
if !exists('g:deoplete#omni#input_patterns')
    let g:deoplete#omni#input_patterns = {}
endif

" latex autocomplete
let g:deoplete#omni#input_patterns.tex = g:vimtex#re#deoplete

" OCaml autocomplete (Merlin deoplete integration)
let g:deoplete#omni#input_patterns.ocaml = '[^. *\t]\.\w*|\s\w+|#'
" call deoplete#custom#option('ignore_sources', {'ocaml': ['buffer', 'around', 'member', 'tag']})
let g:deoplete#ignore_sources = {}
let g:deoplete#ignore_sources.ocaml = ['buffer', 'around', 'member', 'tag']


" Ale customization
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_save = 1
let g:ale_sign_error = '⤫'
let g:ale_sign_warning = '⚠'
let g:ale_linters = {
            \    'python': ['yapf'],
            \    'markdown': []
            \}
" let g:ale_linters_explicit = 1


" nerdcommenter settings
nmap <C-_> <Plug>NERDCommenterToggle
vmap <C-_> <Plug>NERDCommenterToggle<CR>gv
let g:NERDSpaceDelims = 1
let g:NERDCompactSexyComs = 1
let g:NERDefaultAlign = 'left'
let g:NERDCommentEmptyLines = 1
let g:NERDTrimTrailingWhitespace = 0


" Go customization
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_operators = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_generate_tags = 1
let g:go_highlight_build_constraints = 1
let g:go_auto_sameids = 1
let g:go_gocode_propose_builtins = 1
let g:go_auto_type_info = 1


" Latex customization 
" vimtex neovim support
let g:vimtex_compiler_progname = 'nvr'
let g:tex_flavor = 'latex'
" vimtex pdf viewer
let g:vimtex_view_general_viewer = 'okular'
let g:vimtex_view_general_options = '--unique file:@pdf\#src:@line@tex'
let g:vimtex_view_general_options_latexmk = '--unique'


" vim-markdown settings
set conceallevel=2
let g:vim_markdown_folding_disabled = 1
let g:tex_conceal = ""
let g:vim_markdown_math = 1
let g:vim_markdown_strikethrough = 1
let g:vim_markdown_new_list_item_indent = 4


" Merlin (OCaml)
let g:opamshare = substitute(system('opam config var share'),'\n$','','''')
execute "set rtp+=" . g:opamshare . "/merlin/vim"

" ## added by OPAM user-setup for vim / base ## 93ee63e278bdfc07d1139a748ed3fff2 ## you can edit, but keep this line
let s:opam_share_dir = system("opam config var share")
let s:opam_share_dir = substitute(s:opam_share_dir, '[\r\n]*$', '', '')

let s:opam_configuration = {}

" function! OpamConfOcpIndent()
  " execute "set rtp^=" . s:opam_share_dir . "/ocp-indent/vim"
" endfunction
" let s:opam_configuration['ocp-indent'] = function('OpamConfOcpIndent')

function! OpamConfOcpIndex()
  execute "set rtp+=" . s:opam_share_dir . "/ocp-index/vim"
endfunction
let s:opam_configuration['ocp-index'] = function('OpamConfOcpIndex')

function! OpamConfMerlin()
  let l:dir = s:opam_share_dir . "/merlin/vim"
  execute "set rtp+=" . l:dir
endfunction
let s:opam_configuration['merlin'] = function('OpamConfMerlin')

" let s:opam_packages = ["ocp-indent", "ocp-index", "merlin"]
let s:opam_packages = ["ocp-index", "merlin"]
let s:opam_check_cmdline = ["opam list --installed --short --safe --color=never"] + s:opam_packages
let s:opam_available_tools = split(system(join(s:opam_check_cmdline)))
for tool in s:opam_packages
  " Respect package order (merlin should be after ocp-index)
  if count(s:opam_available_tools, tool) > 0
    call s:opam_configuration[tool]()
  endif
endfor
" ## end of OPAM user-setup addition for vim / base ## keep this line
