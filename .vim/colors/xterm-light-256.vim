"
" XTERM Vim Color Setup with explicit color definitions. This will override
" the terminal colors and use hardcoded values
"
syntax on					" ---- turn on syntax highlighting
set background=light
set hlsearch

let white = '230'
let black = '232'

let fg = black
let bg = white

let lightestred = '225'
let lightred = '225'
let red = '196'
let darkred = '160'
let darkestred = '52'

let lightestgreen = '193'
let lightgreen = '193'
let green = '82'
let darkgreen = '28'
let darkestgreen = '22'

let lightestblue = '195'
let lightblue = '195'
let blue = '33'
let darkblue = '26'
let darkestblue = '17'

let lightestcyan = '195'
let lightcyan = '195'
let cyan = '51'
let darkcyan = '45'
let darkestcyan = '39'

let lightestmagenta = '219'
let lightmagenta = '219'
let magenta = '164'
let darkmagenta = '56'
let darkestmagenta = '54'

let lightestyellow = '230'
let lightyellow = '230'
let yellow = '227'
let darkyellow = '178'
let darkestyellow = '136'

let lightestgray = '229'
let lightgray = '254'
let gray = '248'
let darkgray = '242'
let darkestgray = '235'

execute ':highlight Normal				ctermfg=' . fg . ' ctermbg=' . bg

execute ':highlight Comment				ctermfg=' . darkred
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
execute ':highlight GitGutterAddLine	ctermbg=' . lightgreen
execute ':highlight GitGutterChange		ctermfg=' . blue . ' ctermbg=' . bg
execute ':highlight GitGutterChangeLine	ctermbg=' . lightblue
execute ':highlight GitGutterDelete		ctermfg=' . red . ' ctermbg=' . bg
execute ':highlight GitGutterDeleteLine	ctermbg=' . lightred
execute ':highlight Identifier			ctermfg=' . blue
execute ':highlight Ignore				ctermfg=' . gray
execute ':highlight IncSearch			cterm=reverse'
execute ':highlight LineNr				ctermfg=' . gray . ' ctermbg=' . bg
execute ':highlight ModeMsg				ctermfg=' . white . ' ctermbg=' . darkred
execute ':highlight MoreMsg				ctermfg=' . white . ' ctermbg=' . darkred
execute ':highlight NonText				ctermfg=' . green
execute ':highlight PreProc				ctermfg=' . darkestyellow
execute ':highlight Question			ctermfg=' . red
execute ':highlight Search				ctermfg=' . white . ' ctermbg=' . lightmagenta
execute ':highlight SignColumn			ctermfg=' . white . ' ctermbg=' . bg
execute ':highlight Special				ctermfg=' . darkgreen
execute ':highlight SpecialKey			cterm=bold ctermfg=' . fg . ' ctermbg=' . bg
execute ':highlight Statement			ctermfg=' . darkgreen
execute ':highlight StatusLine			ctermfg=' . darkgray . ' ctermbg=' . white
execute ':highlight StatusLineNC		ctermfg=' . darkmagenta . ' ctermbg=' . white
execute ':highlight TabLine				ctermbg=' . darkmagenta . ' ctermfg=' . darkmagenta
execute ':highlight TabLineFill			ctermbg=' . darkgray . ' ctermfg=' . white
execute ':highlight TabLineSel			ctermbg=' . lightgray . ' ctermfg=' . white
execute ':highlight TagbarHighlight		ctermfg=' . white . ' ctermbg=' . red
execute ':highlight Title				ctermfg=' . red
execute ':highlight Todo				ctermfg=' . darkestyellow . ' ctermbg=' . bg
execute ':highlight Type				ctermfg=' . magenta
execute ':highlight Underlined			cterm=underline ctermfg=' . gray
execute ':highlight VertSplit			ctermfg=' . magenta . ' ctermbg=' . magenta
execute ':highlight Visual				cterm=reverse ctermfg=' . fg . ' ctermbg=' . bg
execute ':highlight VisualNOS			cterm=bold'
execute ':highlight WarningMsg			ctermfg=' . red
execute ':highlight Whitespace			ctermbg=' . red
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
