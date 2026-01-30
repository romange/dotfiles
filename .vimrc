" Simplified .vimrc compatible with vi (Vim Tiny)
" Note: Many advanced features require full Vim. Install with: sudo apt install vim

" Make Vim more useful
set nocompatible

" Allow cursor keys in insert mode
set esckeys
" Allow backspace in insert mode
set backspace=indent,eol,start
" Optimize for fast terminal connections
set ttyfast
" Add the g flag to search/replace by default
set gdefault

" Centralize backups and swapfiles
set backupdir=~/.vim/backups
set directory=~/.vim/swaps

" Don't create backups when editing files in certain directories
set backupskip=/tmp/*,/private/tmp/*

" Respect modeline in files
set modeline
set modelines=4
" Enable per-directory .vimrc files and disable unsafe commands in them
set exrc
set secure
" Enable line numbers
set number
" Make tabs as wide as two spaces
set tabstop=2
" Highlight searches
set hlsearch
" Ignore case of searches
set ignorecase
" Highlight dynamically as pattern is typed
set incsearch
" Always show status line
set laststatus=2
" Disable error bells
set noerrorbells
" Don't reset cursor to start of line when moving around.
set nostartofline
" Show the cursor position
set ruler
" Don't show the intro message when starting Vim
set shortmess=atI
" Show the current mode
set showmode
" Show the filename in the window titlebar
set title
" Show the (partial) command as it's being typed
set showcmd
" Start scrolling three lines before the horizontal window border
set scrolloff=3

" Automatic commands (vi Tiny has +autocmd support)
if has("autocmd")
" Enable file type detection
filetype on
" Treat .json files as .js
autocmd BufNewFile,BufRead *.json setfiletype json
" Treat .md files as Markdown
autocmd BufNewFile,BufRead *.md setlocal filetype=markdown
endif

" Features below require full Vim (not available in vi Tiny):
" - colorscheme (requires +syntax and +eval)
" - syntax highlighting (requires +syntax)
" - let commands (requires +eval)
" - function/call (requires +eval)
" - clipboard integration (requires +clipboard)
" - mouse support (requires +mouse)
" - cursorline (requires +syntax)
" - relativenumber (requires +eval for conditionals)
" - custom key mappings with functions (requires +eval)
