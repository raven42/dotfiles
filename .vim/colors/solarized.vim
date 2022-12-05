"
" Solarized Vim Color Setup
"
syntax on					" ---- turn on syntax highlighting
set background=dark
set hlsearch

highlight Normal				ctermfg=White ctermbg=232

highlight Comment				ctermfg=DarkRed
highlight Constant				ctermfg=Yellow
highlight CursorLine			cterm=bold ctermbg=DarkGray
highlight Delimiter				ctermfg=Gray
highlight DiffAdded				ctermfg=34
highlight DiffChanged			ctermfg=128
highlight DiffRemoved			ctermfg=160
highlight DiffFile				ctermfg=75
highlight DiffLine				ctermfg=Blue
highlight DiffText				cterm=bold ctermbg=12
highlight Directory				ctermfg=Yellow
highlight Error					ctermfg=White ctermbg=Red
highlight ErrorMsg				ctermfg=fg ctermbg=DarkRed
highlight FoldColumn			ctermfg=Yellow ctermbg=bg
highlight Folded				cterm=none ctermfg=128 ctermbg=bg
highlight GitGutterAdd			ctermfg=46 ctermbg=bg
highlight GitGutterAddLine		ctermbg=235
highlight GitGutterChange		ctermfg=128 ctermbg=bg
highlight GitGutterChangeLine	ctermbg=DarkGray
highlight GitGutterDelete		ctermfg=160 ctermbg=bg
highlight GitGutterDeleteLine	ctermbg=52
highlight Identifier			ctermfg=DarkBlue
highlight Ignore				ctermfg=Gray
highlight IncSearch				cterm=reverse
highlight LineNr				ctermfg=239 ctermbg=bg
highlight ModeMsg				ctermfg=White ctermbg=DarkRed
highlight MoreMsg				ctermfg=White ctermbg=DarkRed
highlight NonText				ctermfg=LightGreen
highlight PreProc				ctermfg=DarkYellow
highlight Question				ctermfg=Red
highlight Search				ctermfg=White ctermbg=DarkMagenta
highlight SignColumn			ctermfg=White ctermbg=bg
highlight Special				ctermfg=DarkGreen
highlight SpecialKey			ctermbg=bg
highlight Statement				ctermfg=DarkCyan
highlight StatusLine			ctermfg=DarkGray ctermbg=White
highlight StatusLineNC			ctermfg=128 ctermbg=White
highlight TabLine				ctermbg=DarkMagenta ctermfg=DarkMagenta
highlight TabLineFill			ctermbg=DarkGray ctermfg=White
highlight TabLineSel			ctermbg=LightGray ctermfg=White
highlight TagbarHighlight		ctermfg=White ctermbg=88
highlight Title					ctermfg=Red
highlight Todo					ctermfg=DarkYellow ctermbg=bg
highlight Type					ctermfg=DarkMagenta
highlight Underlined			cterm=underline ctermfg=12
highlight VertSplit				ctermfg=128 ctermbg=128
highlight Visual				cterm=reverse ctermfg=fg ctermbg=bg
highlight VisualNOS				cterm=bold
highlight WarningMsg			ctermfg=Red
highlight Whitespace			ctermbg=DarkRed
highlight WildMenu				ctermfg=Black ctermbg=Yellow

" Update lightline configuration... this is used in .vimrc in the
" LightlineColorScheme() routine
let g:lightline_colorscheme = 'powerline'

" Need both the autocmd and normal highlight. The autocmd is needed for
" opening the file, and the normal command is needed when switching
" colorscheme after file has been opened
if &filetype ==# 'diff'
	execute ':highlight Folded ctermfg=' . blue . ' ctermbg=bg'
endif
augroup colors
	autocmd!
	autocmd FileType diff execute ':highlight Folded ctermfg=' . blue . ' ctermbg=bg'
augroup END
