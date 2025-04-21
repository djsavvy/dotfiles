" Unset all autocmds
autocmd!

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
command! Vs vs

" Change shell for ! commands to powershell on windows
if has('win32')
  set shell=pwsh.exe\ -NoLogo
  set shellpipe=\|
  set shellxquote=
  set shellcmdflag=-NoLogo\ -ExecutionPolicy\ RemoteSigned\ -Command
  set shellredir=\|\ Out-File\ -Encoding\ UTF8
endif

" Disable ctrl+z in windows
if has('win32')
  map <C-z> <Nop>
endif

autocmd! FileType fzf set laststatus=0 noshowmode noruler
  \| autocmd BufLeave <buffer> set laststatus=2 showmode ruler


" Use <C-Backspace> (which is interpreted as <C-H> to delete a word)
inoremap <C-H> <C-W>


" Navigate between tabs
nnoremap <Tab> :tabnext<CR>
nnoremap <S-Tab> :tabprevious<CR>
" Fix the fact that <C-i> is now broken --- remap it to ",i". Note that <C-i>
" and <Tab> are identical to vim.
nnoremap ,i <C-i>


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


if has("patch-8.1.1564")
  " Recently vim can merge signcolumn and number column into one
  set signcolumn=number
else
  set signcolumn=yes
endif

" gh - get hint on whatever's under the cursor
nnoremap <silent> gh :call <SID>show_documentation()<CR>
function! s:show_documentation()
  if &filetype == 'vim'
    execute 'h '.expand('<cword>')
  endif
endfunction



" settings for auto-closing plugins
let g:closetag_filenames = '*.html,*.xhtml,*.phtml,*.js'
let g:closetag_filetypes = 'html,xhtml,phtml,javascript,jsx,javascript.jsx,javascriptreact,typescript.jsx,typescript.tsx,typescriptreact'
