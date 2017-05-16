" nocompatible
"set nocompatible

" tabs are 2 characters
set tabstop=2

" (auto)indent uses 2 characters
set shiftwidth=2

" spaces instead of tabs
set noexpandtab

" history
set history=50

" 1000 undo levels
set undolevels=1000

" encoding
"set encoding=utf8
set fileencoding=utf8

" line number
set number
set cursorline " :p
hi cursorline cterm=none
hi cursorlinenr term=bold ctermfg=yellow gui=bold guifg=yellow

" syntax highlight
syntax enable 

" highlight search
set hlsearch " :nohl

" background dark
set background=light

" status bar
set ruler
"set laststatus=2

" set internal shell
set shell=bash\ --rcfile\ ~/.bashrc

" colorful
"set grepprg=grep\ --color=always\ -n\ $*\ /dev/null

" search subdirs
set path+=**
