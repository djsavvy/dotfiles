" Unset all autocmds
autocmd!

" Plugins
let &packpath = &runtimepath
" vim-plug directory
call plug#begin('~/.nvim/plugged')
    " TODO: replace vim-airline with my own
    " (https://irrellia.github.io/blogs/vim-statusline/)
    Plug 'vim-airline/vim-airline'
    Plug 'vim-airline/vim-airline-themes'

    " Fuzzy finding and jumping
    Plug 'junegunn/fzf'
    Plug 'junegunn/fzf.vim'

    " Focused writing
    Plug 'junegunn/limelight.vim'
    Plug 'junegunn/goyo.vim'

    " Specific languages
    Plug 'fatih/vim-go'
    Plug 'nsf/gocode'
    Plug 'rust-lang/rust.vim'
    Plug 'lervag/vimtex'
    Plug 'plasticboy/vim-markdown'
    Plug 'iamcco/markdown-preview.nvim', {'do': { -> mkdp#util#install() }}
    Plug 'neoclide/jsonc.vim'
    Plug 'yuezk/vim-js'
    Plug 'maxmellon/vim-jsx-pretty'
    Plug 'neoclide/jsonc.vim'

    " Autocompleting pairs/autoclosing tags
    Plug 'jiangmiao/auto-pairs'
    Plug 'alvan/vim-closetag'

    " Snippets

    " Colorschemes
    Plug 'jacoborus/tender.vim'
    Plug 'NLKNguyen/papercolor-theme'
    Plug 'noahfrederick/vim-noctu'
    Plug 'averak/laserwave.vim'

    " Improved comments
    Plug 'scrooloose/nerdcommenter'

    " Better tags
    " Plug 'ludovicchabant/vim-gutentags'
    Plug 'majutsushi/tagbar'

    " Language Server Protocol (LSP)
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
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
set wildmenu
set inccommand=split

" Allow moving away from an unsaved buffer
set hidden

" Spell checking
set spell

" Set indentation
set autoindent
set smartindent
set expandtab
set shiftwidth=2
set tabstop=2

" Set splits
set splitbelow
set splitright


" fzf keybindings
nmap <C-;> :Buffers<CR>
nmap <C-P> :Files<CR>
" [Buffers] Jump to the existing window if possible
let g:fzf_buffers_jump = 1

nnoremap <silent> <c-g> :Rg<CR>

autocmd! FileType fzf set laststatus=0 noshowmode noruler
  \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler


" Use <C-Backspace> (which is interpreted as <C-H> to delete a word)
inoremap <C-H> <C-W>


" Navigate between tabs
nnoremap <Tab> :tabnext<CR>
nnoremap <S-Tab> :tabprevious<CR>


" Use <C-L> to clear the highlighting of :set hlsearch.
if maparg('<C-L>', 'n') ==# ''
  nnoremap <silent> <C-L> :nohlsearch<CR><C-L>
endif


" Filetype-specific tab widths
autocmd FileType ocaml setlocal expandtab shiftwidth=2 softtabstop=2 tabstop=2
autocmd FileType javascript setlocal expandtab shiftwidth=2 softtabstop=2 tabstop=2
autocmd FileType html setlocal expandtab shiftwidth=2 softtabstop=2 tabstop=2

" Remove trailing spaces from certain file types
" autocmd FileType c,cpp,java,php,ocaml,lua,latex,tex autocmd BufWritePre <buffer> %s/\s\+$//e

" Function/command to delete all trailing whitespace in a document
" (see https://vi.stackexchange.com/a/456/14073)
if !exists("*TrimTrailingWhitespace")
    " placed in an `if` block to avoid error message on re-sourcing
    function TrimTrailingWhitespace()
        let l:save = winsaveview()
        keeppatterns %s/\s\+$//e
        call winrestview(l:save)
    endfunction

    command! TrimTrailingWhitespace call TrimTrailingWhitespace()
    command! TRimTrailingWhitespace call TrimTrailingWhitespace()
endif


" Search for a whole word using <leader><backslash>
nnoremap <leader>/ /\<\><left><left>


" Deal effectively with wrapped lines
set wrap
set linebreak
noremap <silent> j gj
noremap <silent> k gk
noremap <silent> 0 g0
noremap <silent> $ g$


" Enable system clipboard integration
set clipboard+=unnamedplus


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


" Options for sessions (useful for changing init.nvim and reloading)
set ssop-=options
set ssop-=folds


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
            :execute "normal \<Plug>MarkdownPreviewToggle"
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
command! Qa qa


" Distraction-free writing
let g:limelight_conceal_ctermfg = 'gray'
let g:goyo_width = 100
autocmd User GoyoEnter Limelight
autocmd User GoyoLeave Limelight!

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

autocmd User GoyoEnter call <SID>goyo_enter()
autocmd User GoyoLeave call <SID>goyo_leave()


" Airline customization
set encoding=utf-8
let g:airline_skip_empty_sections = 1
let g:airline_powerline_fonts = 1
let g:airline_theme='tender'
let g:airline_extensions=[]


" Color schemes
" Note: for PaperColor light, set termguicolors. For noctu, don't.
" if (has("termguicolors"))
 " set termguicolors
" endif
" set background=light | colorscheme PaperColor
colorscheme noctu


" user terminal background color for vim
" hi Normal ctermbg=none

" Make comments italic and bright green (good for dark backgrounds)
" hi Comment ctermfg=49 guifg=#00ffaf
" hi Comment cterm=italic gui=italic




" Language Server Protocol (LSP) customizations (COC)
set updatetime=300
set signcolumn=yes

" gd - go to definition of word under cursor
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> <C-]> <Plug>(coc-definition)

" gy - go to type definition
nmap <silent> gy <Plug>(coc-type-definition)

" gi - go to implementation
nmap <silent> gi <Plug>(coc-implementation)

" gr - find references
nmap <silent> gr <Plug>(coc-references)

" gh - get hint on whatever's under the cursor
nnoremap <silent> gh :call <SID>show_documentation()<CR>
function! s:show_documentation()
  if &filetype == 'vim'
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

nnoremap <silent> <leader>co  :<C-u>CocList outline<cr>
nnoremap <silent> <leader>cs  :<C-u>CocList -I symbols<cr>

" restart Coc when it gets wonky
nnoremap <silent> <leader>cR  :<C-u>CocRestart<CR>

" view all errors
nnoremap <silent> <leader>ce :<C-u>CocList diagnostics<CR>

" rename the current word in the cursor
nmap <leader>cr  <Plug>(coc-rename)

" coc-format
nmap <leader>cf  <Plug>(coc-format)
vmap <leader>cf  <Plug>(coc-format-selected)

" run prettier on a file with ":Prettier" using coc
command! -nargs=0 Prettier :call CocAction('runCommand', 'prettier.formatFile')

" tab-completion
imap <expr><C-J> pumvisible() ? "\<C-N>" : "<C-J>"
imap <expr><C-K> pumvisible() ? "\<C-P>" : "<C-K>"
inoremap <expr><ESC> pumvisible() ? "\<C-E>\<ESC>" : "\<ESC>"
inoremap <expr><CR> pumvisible() ? "\<C-Y>" : "\<CR>"
set completeopt=menu,preview,longest,menuone
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current
" position. Coc only does snippet and additional edit on confirm.
if exists('*complete_info')
  inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
else
  inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
endif

" Use <c-space> to trigger completion.
inoremap <silent><expr> <c-space> coc#refresh()


" Coc Snippets
let g:coc_snippet_next = '<tab>'
" Use <C-j> for select text for visual placeholder of snippet.
vmap <C-j> <Plug>(coc-snippets-select)

" Use <C-j> for jump to next placeholder, it's default of coc.nvim
let g:coc_snippet_next = '<c-j>'
" Use <C-k> for jump to previous placeholder, it's default of coc.nvim
let g:coc_snippet_prev = '<c-k>'

" Use <C-j> for both expand and jump (make expand higher priority.)
imap <C-j> <Plug>(coc-snippets-expand-jump)

" inoremap <silent><expr> <TAB>
      " \ pumvisible() ? coc#_select_confirm() :
      " \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      " \ <SID>check_back_space() ? "\<TAB>" :
      " \ coc#refresh()



" nerdcommenter settings
let g:NERDCreateDefaultMappings = 0
imap <C-_> <Esc><Plug>NERDCommenterToggle i
nmap <C-_> <Plug>NERDCommenterToggle
vmap <C-_> <Plug>NERDCommenterToggle<CR>gv
let g:NERDSpaceDelims = 1
let g:NERDCompactSexyComs = 1
let g:NERDefaultAlign = 'left'
let g:NERDCommentEmptyLines = 1
let g:NERDTrimTrailingWhitespace = 0


" settings for auto-closing plugins
let g:closetag_filenames = '*.html,*.xhtml,*.phtml,*.js'
let g:closetag_filetypes = 'html,xhtml,phtml,javascript,jsx,javascript.jsx,javascriptreact,typescript.jsx,typescript.tsx,typescriptreact'



" settings for tags
let g:tagbar_left = 0
let g:tagbar_autofocus = 1
let g:tagbar_width = 50
let g:tagbar_sort = 0
let g:gutentags_exclude_filetypes = ['gitcommit', 'gitconfig', 'gitrebase', 'gitsendemail', 'git', 'md', 'markdown']


" use <leader>lt to open a table of contents or tagbar
if !exists("*User_toggle_table_of_contents")
    " placed in an `if` block to avoid error message on re-sourcing
    " vimrc/nvim.init
    function User_toggle_table_of_contents()
        if &ft == 'tex' || &ft == 'latex'
            :call b:vimtex.toc.open()
        else
            TagbarToggle
        end
    endfunction
    nnoremap <leader>lt :call User_toggle_table_of_contents()<CR>
endif


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
let g:go_auto_sameids = 0


" Rust customization
let g:rustfmt_autosave = 1


" Python customization
autocmd FileType python let b:coc_root_patterns = ['app.json', '.git', '.env', 'pyproject.toml', 'pytest.ini']


" Latex customization
" vimtex neovim support
let g:vimtex_compiler_progname = 'nvr'
let g:tex_flavor = 'latex'
let g:vimtex_compiler_latexmk = {
    \ 'backend' : 'nvim',
    \ 'background' : 1,
    \ 'build_dir' : '',
    \ 'callback' : 1,
    \ 'continuous' : 1,
    \ 'executable' : 'latexmk',
    \ 'hooks' : [],
    \ 'options' : [
    \   '--shell-escape',
    \   '-verbose',
    \   '-file-line-error',
    \   '-synctex=1',
    \   '-interaction=nonstopmode',
    \ ],
    \}
" vimtex pdf viewer
let g:vimtex_view_general_viewer = 'okular'
let g:vimtex_view_general_options = '--unique file:@pdf\#src:@line@tex'
let g:vimtex_view_general_options_latexmk = '--unique'
let g:vimtex_toc_config = {}
let g:vimtex_toc_config.split_pos = 'vert rightbelow'
let g:vimtex_toc_config.split_width = 50
" Prevent using latex-box's async compiler
let g:polyglot_disabled = ['latex', 'tex']


" vim-markdown and preview settings
set conceallevel=2
let g:vim_markdown_folding_disabled = 1
let g:tex_conceal = ""
let g:vim_markdown_math = 1
let g:vim_markdown_strikethrough = 1
let g:vim_markdown_new_list_item_indent = 2
let g:mkdp_open_to_the_world = 1
let g:mkdp_open_ip = '127.0.0.1'
" let g:mkdp_port = 8080
function! g:OpenBrowser(url)
    " :echo a:url
    silent execute "!" . shellescape("/mnt/c/Program\ Files/Firefox\ Nightly/firefox.exe") shellescape(a:url)
endfunction
let g:mkdp_browserfunc = 'g:OpenBrowser'
let g:mkdp_auto_close = 0
let g:mkdp_refresh_slow = 1
let g:mkdp_page_title = "${name}.md"
