syntax enable
" set ruler

" Uncomment the following to have Vim jump to the last position when
" reopening a file
if has("autocmd")
  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
    \| exe "normal! g'\"" | endif
endif

" This escape sequence is the well known ANSI sequence for
" Remove Character Under The Cursor (RCUTC[tm])
" map! <Esc>[3~ <Delete>
" map  <ESC>[3~    x

" Emulate standard status line with 'ruler' set
set statusline=%<%f\ %h%m%r%=%-14.(%l,%c%V%)\ %P
" set statusline=%<%f%=\ [%1*%M%*%n%R%H]\ %-19(%3l,%02c%03V%)%O'%02b'
set laststatus=2

" Disable parentheses matching depends on system. This way we should address all cases (?)
set noshowmatch
" NoMatchParen " This doesnt work as it belongs to a plugin, which is only loaded _after_ all files are.
" Trying disable MatchParen after loading all plugins
"
function! g:FuckThatMatchParen ()
    if exists(":NoMatchParen")
        :NoMatchParen
    endif
endfunction

augroup plugin_initialize
    autocmd!
    autocmd VimEnter * call FuckThatMatchParen()
augroup END

"
" LATEX
"
" via latex-box plugin
"
" REQUIRED. This makes vim invoke Latex-Suite when you open a tex file.
filetype plugin on

" OPTIONAL: This enables automatic indentation as you type.
filetype indent on

" OPTIONAL: Starting with Vim 7, the filetype of empty .tex files defaults to
" 'plaintex' instead of 'tex', which results in vim-latex not being loaded.
" The following changes the default filetype back to 'tex':
"let g:tex_flavor='latex'

" my vim-latex need
:set tabstop=4
:set softtabstop=4
:set shiftwidth=4
"if set expandtab tab transf into spaces => horrible when erasing in escp mode
:set noexpandtab

"stupid extending single-line coment in C to next new line
au FileType c,cpp setlocal comments-=:// comments+=f://

"my config
:set paste
