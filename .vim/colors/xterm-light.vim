"
" XTERM Vim Color Setup - This primarily uses the terminal color scheme with a
" few extras. Most noteably the 'darkest' and 'lightest' values to provide
" some more flexibility in shading.
"
syntax on					" ---- turn on syntax highlighting
set background=light
set hlsearch

let white = '230'
let black = '232'

let fg = black
let bg = white

let lightestred = '225'
let lightred = 'Red'
let red = 'Red'
let darkred = 'DarkRed'
let darkestred = '52'

let lightestgreen = '193'
let lightgreen = 'Green'
let green = 'Green'
let darkgreen = 'DarkGreen'
let darkestgreen = '22'

let lightestblue = '195'
let lightblue = 'Blue'
let blue = 'Blue'
let darkblue = 'DarkBlue'
let darkestblue = '17'

let lightestcyan = '195'
let lightcyan = 'Cyan'
let cyan = 'Cyan'
let darkcyan = 'DarkCyan'
let darkestcyan = '39'

let lightestmagenta = '219'
let lightmagenta = 'Magenta'
let magenta = 'Magenta'
let darkmagenta = 'DarkMagenta'
let darkestmagenta = '54'

let lightestyellow = '230'
let lightyellow = 'Yellow'
let yellow = 'Yellow'
let darkyellow = 'DarkYellow'
let darkestyellow = '136'

let lightestgray = '229'
let lightgray = 'Gray'
let gray = 'Gray'
let darkgray = 'DarkGray'
let darkestgray = '235'

execute ':highlight Normal				ctermfg=' . fg . ' ctermbg=' . bg

execute ':highlight Comment				ctermfg=' . red
execute ':highlight Constant			ctermfg=' . darkgray
execute ':highlight CursorLine			cterm=bold ctermbg=' . lightgray
execute ':highlight Delimiter			ctermfg=' . gray
execute ':highlight DiffAdded			ctermfg=' . green
execute ':highlight DiffChanged			ctermfg=' . blue
execute ':highlight DiffFile			ctermfg=' . magenta
execute ':highlight DiffLine			ctermfg=' . blue
execute ':highlight DiffRemoved			ctermfg=' . red
execute ':highlight DiffText			cterm=bold ctermbg=' . gray
execute ':highlight Directory			ctermfg=' . magenta
execute ':highlight Error				ctermfg=' . white
execute ':highlight ErrorMsg			ctermfg=' . white . ' ctermbg=' . lightred
execute ':highlight FoldColumn			ctermfg=' . magenta . ' ctermbg=' . bg
execute ':highlight Folded				ctermfg=' . magenta . ' ctermbg=' . bg
execute ':highlight GitGutterAdd		ctermfg=' . green . ' ctermbg=' . bg
execute ':highlight GitGutterAddLine	ctermbg=' . lightestgray
execute ':highlight GitGutterChange		ctermfg=' . lightblue . ' ctermbg=' . bg
execute ':highlight GitGutterChangeLine	ctermbg=' . lightestblue
execute ':highlight GitGutterDelete		ctermfg=' . red . ' ctermbg=' . bg
execute ':highlight GitGutterDeleteLine	ctermbg=' . lightestred
execute ':highlight Identifier			ctermfg=' . blue
execute ':highlight Ignore				ctermfg=' . gray
execute ':highlight IncSearch			cterm=reverse'
execute ':highlight LineNr				ctermfg=' . darkgray . ' ctermbg=' . bg
execute ':highlight ModeMsg				ctermfg=' . white . ' ctermbg=' . lightred
execute ':highlight MoreMsg				ctermfg=' . white . ' ctermbg=' . lightred
execute ':highlight NonText				ctermfg=' . green
execute ':highlight PreProc				ctermfg=' . darkestyellow
execute ':highlight Question			ctermfg=' . red
execute ':highlight Search				ctermfg=' . white . ' ctermbg=' . lightmagenta
execute ':highlight SignColumn			ctermfg=' . white . ' ctermbg=' . bg
execute ':highlight Special				ctermfg=' . darkestyellow
execute ':highlight SpecialKey			cterm=bold ctermfg=' . blue . ' ctermbg=' . bg
execute ':highlight Statement			ctermfg=' . darkgreen
execute ':highlight StatusLine			ctermfg=' . lightgray . ' ctermbg=' . white
execute ':highlight StatusLineNC		ctermfg=' . lightmagenta . ' ctermbg=' . white
execute ':highlight TabLine				ctermbg=' . lightmagenta . ' ctermfg=' . lightmagenta
execute ':highlight TabLineFill			ctermbg=' . lightgray . ' ctermfg=' . white
execute ':highlight TabLineSel			ctermbg=' . gray . ' ctermfg=' . white
execute ':highlight TagbarHighlight		ctermfg=' . white . ' ctermbg=' . lightestred
execute ':highlight Title				ctermfg=' . red
execute ':highlight Todo				ctermfg=' . darkestyellow. ' ctermbg=' . bg
execute ':highlight Type				ctermfg=' . magenta
execute ':highlight Underlined			cterm=underline ctermfg=' . gray
execute ':highlight VertSplit			ctermfg=' . lightmagenta . ' ctermbg=' . lightmagenta
execute ':highlight Visual				cterm=reverse ctermfg=' . fg . ' ctermbg=' . bg
execute ':highlight VisualNOS			cterm=bold'
execute ':highlight WarningMsg			ctermfg=' . red
execute ':highlight Whitespace			ctermbg=' . lightred
execute ':highlight WildMenu			ctermfg=' . black . ' ctermbg=' . magenta

" Update lightline configuration... this is used in .vimrc in the
" LightlineColorScheme() routine
let g:lightline_colorscheme = 'solarized'

" Need both the autocmd and normal highlight. The autocmd is needed for
" opening the file, and the normal command is needed when switching
" colorscheme after file has been opened
if &filetype ==# 'diff'
	execute ':highlight Folded ctermfg=' . darkgray . ' ctermbg=' . bg
endif
augroup colors
	autocmd!
	autocmd FileType diff execute ':highlight Folded ctermfg=' . darkgray . ' ctermbg=' bg
augroup END
