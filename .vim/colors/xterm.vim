"
" XTERM Vim Color Setup - This primarily uses the terminal color scheme with a
" few extras. Most noteably the 'darkest' and 'lightest' values to provide
" some more flexibility in shading.
"
syntax on					" ---- turn on syntax highlighting
set background=dark
set hlsearch

let s:xterm_colors = {
    \ '0':   '#000000', '1':   '#800000', '2':   '#008000', '3':   '#808000', '4':   '#000080',
    \ '5':   '#800080', '6':   '#008080', '7':   '#c0c0c0', '8':   '#808080', '9':   '#ff0000',
    \ '10':  '#00ff00', '11':  '#ffff00', '12':  '#0000ff', '13':  '#ff00ff', '14':  '#00ffff',
    \ '15':  '#ffffff', '16':  '#000000', '17':  '#00005f', '18':  '#000087', '19':  '#0000af',
    \ '20':  '#0000df', '21':  '#0000ff', '22':  '#005f00', '23':  '#005f5f', '24':  '#005f87',
    \ '25':  '#005faf', '26':  '#005fdf', '27':  '#005fff', '28':  '#008700', '29':  '#00875f',
    \ '30':  '#008787', '31':  '#0087af', '32':  '#0087df', '33':  '#0087ff', '34':  '#00af00',
    \ '35':  '#00af5f', '36':  '#00af87', '37':  '#00afaf', '38':  '#00afdf', '39':  '#00afff',
    \ '40':  '#00df00', '41':  '#00df5f', '42':  '#00df87', '43':  '#00dfaf', '44':  '#00dfdf',
    \ '45':  '#00dfff', '46':  '#00ff00', '47':  '#00ff5f', '48':  '#00ff87', '49':  '#00ffaf',
    \ '50':  '#00ffdf', '51':  '#00ffff', '52':  '#5f0000', '53':  '#5f005f', '54':  '#5f0087',
    \ '55':  '#5f00af', '56':  '#5f00df', '57':  '#5f00ff', '58':  '#5f5f00', '59':  '#5f5f5f',
    \ '60':  '#5f5f87', '61':  '#5f5faf', '62':  '#5f5fdf', '63':  '#5f5fff', '64':  '#5f8700',
    \ '65':  '#5f875f', '66':  '#5f8787', '67':  '#5f87af', '68':  '#5f87df', '69':  '#5f87ff',
    \ '70':  '#5faf00', '71':  '#5faf5f', '72':  '#5faf87', '73':  '#5fafaf', '74':  '#5fafdf',
    \ '75':  '#5fafff', '76':  '#5fdf00', '77':  '#5fdf5f', '78':  '#5fdf87', '79':  '#5fdfaf',
    \ '80':  '#5fdfdf', '81':  '#5fdfff', '82':  '#5fff00', '83':  '#5fff5f', '84':  '#5fff87',
    \ '85':  '#5fffaf', '86':  '#5fffdf', '87':  '#5fffff', '88':  '#870000', '89':  '#87005f',
    \ '90':  '#870087', '91':  '#8700af', '92':  '#8700df', '93':  '#8700ff', '94':  '#875f00',
    \ '95':  '#875f5f', '96':  '#875f87', '97':  '#875faf', '98':  '#875fdf', '99':  '#875fff',
    \ '100': '#878700', '101': '#87875f', '102': '#878787', '103': '#8787af', '104': '#8787df',
    \ '105': '#8787ff', '106': '#87af00', '107': '#87af5f', '108': '#87af87', '109': '#87afaf',
    \ '110': '#87afdf', '111': '#87afff', '112': '#87df00', '113': '#87df5f', '114': '#87df87',
    \ '115': '#87dfaf', '116': '#87dfdf', '117': '#87dfff', '118': '#87ff00', '119': '#87ff5f',
    \ '120': '#87ff87', '121': '#87ffaf', '122': '#87ffdf', '123': '#87ffff', '124': '#af0000',
    \ '125': '#af005f', '126': '#af0087', '127': '#af00af', '128': '#af00df', '129': '#af00ff',
    \ '130': '#af5f00', '131': '#af5f5f', '132': '#af5f87', '133': '#af5faf', '134': '#af5fdf',
    \ '135': '#af5fff', '136': '#af8700', '137': '#af875f', '138': '#af8787', '139': '#af87af',
    \ '140': '#af87df', '141': '#af87ff', '142': '#afaf00', '143': '#afaf5f', '144': '#afaf87',
    \ '145': '#afafaf', '146': '#afafdf', '147': '#afafff', '148': '#afdf00', '149': '#afdf5f',
    \ '150': '#afdf87', '151': '#afdfaf', '152': '#afdfdf', '153': '#afdfff', '154': '#afff00',
    \ '155': '#afff5f', '156': '#afff87', '157': '#afffaf', '158': '#afffdf', '159': '#afffff',
    \ '160': '#df0000', '161': '#df005f', '162': '#df0087', '163': '#df00af', '164': '#df00df',
    \ '165': '#df00ff', '166': '#df5f00', '167': '#df5f5f', '168': '#df5f87', '169': '#df5faf',
    \ '170': '#df5fdf', '171': '#df5fff', '172': '#df8700', '173': '#df875f', '174': '#df8787',
    \ '175': '#df87af', '176': '#df87df', '177': '#df87ff', '178': '#dfaf00', '179': '#dfaf5f',
    \ '180': '#dfaf87', '181': '#dfafaf', '182': '#dfafdf', '183': '#dfafff', '184': '#dfdf00',
    \ '185': '#dfdf5f', '186': '#dfdf87', '187': '#dfdfaf', '188': '#dfdfdf', '189': '#dfdfff',
    \ '190': '#dfff00', '191': '#dfff5f', '192': '#dfff87', '193': '#dfffaf', '194': '#dfffdf',
    \ '195': '#dfffff', '196': '#ff0000', '197': '#ff005f', '198': '#ff0087', '199': '#ff00af',
    \ '200': '#ff00df', '201': '#ff00ff', '202': '#ff5f00', '203': '#ff5f5f', '204': '#ff5f87',
    \ '205': '#ff5faf', '206': '#ff5fdf', '207': '#ff5fff', '208': '#ff8700', '209': '#ff875f',
    \ '210': '#ff8787', '211': '#ff87af', '212': '#ff87df', '213': '#ff87ff', '214': '#ffaf00',
    \ '215': '#ffaf5f', '216': '#ffaf87', '217': '#ffafaf', '218': '#ffafdf', '219': '#ffafff',
    \ '220': '#ffdf00', '221': '#ffdf5f', '222': '#ffdf87', '223': '#ffdfaf', '224': '#ffdfdf',
    \ '225': '#ffdfff', '226': '#ffff00', '227': '#ffff5f', '228': '#ffff87', '229': '#ffffaf',
    \ '230': '#ffffdf', '231': '#ffffff', '232': '#080808', '233': '#121212', '234': '#1c1c1c',
    \ '235': '#262626', '236': '#303030', '237': '#3a3a3a', '238': '#444444', '239': '#4e4e4e',
    \ '240': '#585858', '241': '#606060', '242': '#666666', '243': '#767676', '244': '#808080',
    \ '245': '#8a8a8a', '246': '#949494', '247': '#9e9e9e', '248': '#a8a8a8', '249': '#b2b2b2',
    \ '250': '#bcbcbc', '251': '#c6c6c6', '252': '#d0d0d0', '253': '#dadada', '254': '#e4e4e4',
    \ '255': '#eeeeee', 'fg': 'fg', 'bg': 'bg', 'NONE': 'NONE',
	\ 'white': 'white', 'black': 'black',
	\ 'gray': 'gray', 'darkgray': 'darkgray', 'lightgray': 'lightgray',
	\ 'red': 'red', 'darkred': 'darkred', 'lightred': 'lightred',
	\ 'green': 'green', 'darkgreen': 'darkgreen', 'lightgreen': 'lightgreen',
	\ 'blue': 'blue', 'darkblue': 'darkblue', 'lightblue': 'lightblue',
	\ 'cyan': 'cyan', 'darkcyan': 'darkcyan', 'lightcyan': 'lightcyan',
	\ 'magenta': 'magenta', 'darkmagenta': 'darkmagenta', 'lightmagenta': 'lightmagenta',
	\ 'yellow': 'yellow', 'darkyellow': 'darkyellow', 'lightyellow': 'lightyellow',
	\ }

function! s:colorNameToGui(name)
	let lname = tolower(a:name)
	if has_key(s:xterm_colors, lname)
		return s:xterm_colors[lname]
	endif
	return 'gray'
endfunction

let white = '230'
let black = '233'
let white = 'white'
let black = 'black'

let fg = white
let bg = black

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

let lightestgray = '254'
let lightgray = 'Gray'
let gray = 'Gray'
let darkgray = 'DarkGray'
let darkestgray = '235'

execute ':highlight Normal				ctermfg=' . fg . ' guifg=' . s:colorNameToGui(fg) . ' ctermbg=' . bg . ' guibg=' . s:colorNameToGui(bg)

execute ':highlight Comment				ctermfg=' . red . ' guifg=' . s:colorNameToGui(red)
execute ':highlight Constant			ctermfg=' . darkgray . ' guifg=' . s:colorNameToGui(darkgray)
execute ':highlight CursorLine			cterm=bold ctermbg=' . darkgray . ' guibg=' . s:colorNameToGui(darkgray)
execute ':highlight Delimiter			ctermfg=' . gray . ' guifg=' . s:colorNameToGui(gray)
execute ':highlight DiffAdded			ctermfg=' . green . ' guifg=' . s:colorNameToGui(green)
execute ':highlight DiffChanged			ctermfg=' . blue . ' guifg=' . s:colorNameToGui(blue)
execute ':highlight DiffFile			ctermfg=' . magenta . ' guifg=' . s:colorNameToGui(magenta)
execute ':highlight DiffLine			ctermfg=' . blue . ' guifg=' . s:colorNameToGui(blue)
execute ':highlight DiffRemoved			ctermfg=' . red . ' guifg=' . s:colorNameToGui(red)
execute ':highlight DiffText			cterm=bold ctermbg=' . gray . ' guibg=' . s:colorNameToGui(gray)
execute ':highlight Directory			ctermfg=' . magenta . ' guifg=' . s:colorNameToGui(magenta)
execute ':highlight Error				ctermfg=' . white . ' guifg=' . s:colorNameToGui(white)
execute ':highlight ErrorMsg			ctermfg=' . white . ' guifg=' . s:colorNameToGui(white) . ' ctermbg=' . darkred . ' guibg=' . s:colorNameToGui(darkred)
execute ':highlight FoldColumn			ctermfg=' . magenta . ' guifg=' . s:colorNameToGui(magenta) . ' ctermbg=' . bg . ' guibg=' . s:colorNameToGui(bg)
execute ':highlight Folded				ctermfg=' . magenta . ' guifg=' . s:colorNameToGui(magenta) . ' ctermbg=' . bg . ' guibg=' . s:colorNameToGui(bg)
execute ':highlight GitGutterAdd		ctermfg=' . green . ' guifg=' . s:colorNameToGui(green) . ' ctermbg=' . bg . ' guibg=' . s:colorNameToGui(bg)
execute ':highlight GitGutterAddLine	ctermbg=' . darkestgray . ' guibg=' . s:colorNameToGui(darkestgray)
execute ':highlight GitGutterChange		ctermfg=' . darkblue . ' guifg=' . s:colorNameToGui(darkblue) . ' ctermbg=' . bg . ' guibg=' . s:colorNameToGui(bg)
execute ':highlight GitGutterChangeLine	ctermbg=' . darkestblue . ' guibg=' . s:colorNameToGui(darkestblue)
execute ':highlight GitGutterDelete		ctermfg=' . red . ' guifg=' . s:colorNameToGui(red) . ' ctermbg=' . bg . ' guibg=' . s:colorNameToGui(bg)
execute ':highlight GitGutterDeleteLine	ctermbg=' . darkestred . ' guibg=' . s:colorNameToGui(darkestred)
execute ':highlight Identifier			ctermfg=' . blue . ' guifg=' . s:colorNameToGui(blue)
execute ':highlight Ignore				ctermfg=' . gray . ' guifg=' . s:colorNameToGui(gray)
execute ':highlight IncSearch			cterm=reverse'
execute ':highlight LineNr				ctermfg=' . darkgray . ' guifg=' . s:colorNameToGui(darkgray) . ' ctermbg=' . bg . ' guibg=' . s:colorNameToGui(bg)
execute ':highlight ModeMsg				ctermfg=' . white . ' guifg=' . s:colorNameToGui(white) . ' ctermbg=' . darkred . ' guibg=' . s:colorNameToGui(darkred)
execute ':highlight MoreMsg				ctermfg=' . white . ' guifg=' . s:colorNameToGui(white) . ' ctermbg=' . darkred . ' guibg=' . s:colorNameToGui(darkred)
execute ':highlight NonText				ctermfg=' . green . ' guifg=' . s:colorNameToGui(green)
execute ':highlight PreProc				ctermfg=' . yellow . ' guifg=' . s:colorNameToGui(yellow)
execute ':highlight Question			ctermfg=' . red . ' guifg=' . s:colorNameToGui(red)
execute ':highlight Search				ctermfg=' . white . ' guifg=' . s:colorNameToGui(white) . ' ctermbg=' . darkmagenta . ' guibg=' . s:colorNameToGui(darkmagenta)
execute ':highlight SignColumn			ctermfg=' . white . ' guifg=' . s:colorNameToGui(white) . ' ctermbg=' . bg . ' guibg=' . s:colorNameToGui(bg)
execute ':highlight Special				ctermfg=' . lightyellow . ' guifg=' . s:colorNameToGui(lightyellow)
execute ':highlight SpecialKey			cterm=bold ctermfg=' . blue . ' guifg=' . s:colorNameToGui(blue) . ' ctermbg=' . bg . ' guibg=' . s:colorNameToGui(bg)
execute ':highlight Statement			ctermfg=' . lightgreen . ' guifg=' . s:colorNameToGui(lightgreen)
execute ':highlight StatusLine			ctermfg=' . darkgray . ' guifg=' . s:colorNameToGui(darkgray) . ' ctermbg=' . white . ' guibg=' . s:colorNameToGui(white)
execute ':highlight StatusLineNC		ctermfg=' . darkmagenta . ' guifg=' . s:colorNameToGui(darkmagenta) . ' ctermbg=' . white . ' guibg=' . s:colorNameToGui(white)
execute ':highlight TabLine				ctermbg=' . darkmagenta . ' guibg=' . s:colorNameToGui(darkmagenta) . ' ctermfg=' . darkmagenta . ' guifg=' . s:colorNameToGui(darkmagenta)
execute ':highlight TabLineFill			ctermbg=' . darkgray . ' guibg=' . s:colorNameToGui(darkgray) . ' ctermfg=' . white . ' guifg=' . s:colorNameToGui(white)
execute ':highlight TabLineSel			ctermbg=' . gray . ' guibg=' . s:colorNameToGui(gray) . ' ctermfg=' . white . ' guifg=' . s:colorNameToGui(white)
execute ':highlight TagbarHighlight		ctermfg=' . white . ' guifg=' . s:colorNameToGui(white) . ' ctermbg=' . darkestred . ' guibg=' . s:colorNameToGui(darkestred)
execute ':highlight Title				ctermfg=' . red . ' guifg=' . s:colorNameToGui(red)
execute ':highlight Todo				ctermfg=' . yellow . ' guifg=' . s:colorNameToGui(yellow) . ' ctermbg=' . bg . ' guibg=' . s:colorNameToGui(bg)
execute ':highlight Type				ctermfg=' . magenta . ' guifg=' . s:colorNameToGui(magenta)
execute ':highlight Underlined			cterm=underline ctermfg=' . gray . ' guifg=' . s:colorNameToGui(gray)
execute ':highlight VertSplit			ctermfg=' . darkmagenta . ' guifg=' . s:colorNameToGui(darkmagenta) . ' ctermbg=' . darkmagenta . ' guibg=' . s:colorNameToGui(darkmagenta)
execute ':highlight Visual				cterm=reverse ctermfg=' . fg . ' guifg=' . s:colorNameToGui(fg) . ' ctermbg=' . bg . ' guibg=' . s:colorNameToGui(bg)
execute ':highlight VisualNOS			cterm=bold'
execute ':highlight WarningMsg			ctermfg=' . red . ' guifg=' . s:colorNameToGui(red)
execute ':highlight Whitespace			ctermbg=' . darkred . ' guibg=' . s:colorNameToGui(darkred)
execute ':highlight WildMenu			ctermfg=' . black . ' guifg=' . s:colorNameToGui(black) . ' ctermbg=' . magenta . ' guibg=' . s:colorNameToGui(magenta)

" Update lightline configuration... this is used in .vimrc in the
" LightlineColorScheme() routine
let g:lightline_colorscheme = 'powerline'

" Need both the autocmd and normal highlight. The autocmd is needed for
" opening the file, and the normal command is needed when switching
" colorscheme after file has been opened
if &filetype ==# 'diff'
	execute ':highlight Folded ctermfg=' . darkgray . ' guifg=' . s:colorNameToGui(darkgray) . ' ctermbg=' . bg . ' guibg=' . s:colorNameToGui(bg)
endif
autocmd FileType diff execute ':highlight Folded ctermfg=' . darkgray . ' guifg=' . s:colorNameToGui(darkgray) . ' ctermbg=' bg
