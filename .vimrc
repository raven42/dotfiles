"----- David Hegland's .vimrc file
"----- designed for vim 8.2
"----- 2020

"---- Default /etc/vimrc contents
if v:lang =~ "utf8$" || v:lang =~ "UTF-8$"
	set fileencodings=utf-8
endif

if has("multi_byte")
	 if &termencoding == ""
		  let &termencoding = &encoding
	 endif
	 set encoding=utf-8
	 setglobal fileencoding=utf-8
	 "setglobal bomb
	 set fileencodings=ucs-bom,utf-8,latin1
endif

" Only do this part when compiled with support for autocommands
if has("autocmd")
  augroup redhat
    " In text files, always limit the width of text to 78 characters
"    autocmd BufRead *.txt set tw=78
    " When editing a file, always jump to the last cursor position
    autocmd BufReadPost *
    \ if line("'\"") > 0 && line ("'\"") <= line("$") |
    \   exe "normal! g'\"" |
    \ endif
  augroup END
endif

if has("cscope") && filereadable("/usr/bin/cscope")
   set csprg=/usr/bin/cscope
   set csto=0
   set cst
   set nocsverb
   " add any database in current directory
   if filereadable("cscope.out")
      cs add cscope.out
   " else add database pointed to by environment
   elseif $CSCOPE_DB != ""
      cs add $CSCOPE_DB
   endif
   set csverb
endif

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif

if &term=="xterm"
     set t_Co=8
     set t_Sb=^[[4%dm
     set t_Sf=^[[3%dm
endif
"----- END Default /etc/vimrc contents

"----- set up the stuff for color highlighing in an xterm
if &term =~ "xterm"
 if has("terminfo")
  set t_Co=16
  set t_Sf=[3%p1%dm
  set t_Sb=[4%p1%dm
  set t_vb=
  set t_kh=[7%p1%dm
  set t_@7=[4%p1%dm
 else
  set t_Co=16
  set t_Sf=[3%dm
  set t_Sb=[4%dm
  set t_vb=
  set t_kh=[7%dm
  set t_@7=[4%dm
 endif
endif

" ---- Syntax Highlighting Defintions
" ---- For more colors, see 256 color pallet in ~/.vim/sample-256.colors

"colorscheme desert
syntax on					" ---- turn on syntax highlighting
set background=dark

highlight Comment		ctermfg=Red guifg=Red
highlight Constant		ctermfg=Gray guifg=Gray
highlight Cursor		guifg=bg guibg=fg
highlight CursorLine	cterm=bold ctermbg=DarkGray
highlight Delimiter		ctermfg=Gray guifg=Gray
highlight DiffAdd		ctermbg=4 guibg=DarkBlue
highlight DiffChange	ctermbg=5 guibg=DarkMagenta
highlight DiffDelete	ctermfg=12 ctermbg=6 gui=bold guifg=Blue guibg=DarkCyan
highlight DiffText		cterm=bold ctermbg=12 gui=bold guibg=Red
highlight Directory		ctermfg=Yellow guifg=Yellow
highlight Error			ctermfg=White guifg=White ctermbg=Red guibg=Red
highlight ErrorMsg		ctermfg=Yellow guifg=Yellow
highlight FoldColumn	ctermfg=Magenta ctermbg=Black guifg=Magenta guibg=Black
highlight Folded		ctermfg=Magenta ctermbg=Black guifg=Magenta guibg=Black
highlight Identifier	ctermfg=DarkBlue guifg=DarkBlue
highlight Ignore		ctermfg=Gray guifg=bg
highlight IncSearch		cterm=reverse gui=reverse
highlight LineNr		ctermfg=Gray guifg=Gray
highlight ModeMsg		ctermfg=White guifg=White ctermbg=DarkRed guibg=DarkRed
highlight MoreMsg		ctermfg=White guifg=White ctermbg=DarkRed guibg=DarkRed
highlight NonText		ctermfg=LightGreen guifg=LightGreen
highlight Normal		ctermfg=White guifg=White guibg=Black
highlight PreProc		ctermfg=Yellow guifg=Yellow
highlight Question		ctermfg=Red guifg=Red
highlight Search		ctermfg=White guifg=White ctermbg=DarkBlue guibg=DarkBlue
highlight SignColumn	ctermfg=White ctermbg=Black guifg=Magenta guibg=Grey
highlight Special		ctermfg=Yellow guifg=Yellow
highlight SpecialKey	cterm=bold
highlight Statement		ctermfg=Green guifg=Green
highlight StatusLine	ctermfg=DarkGray guifg=DarkGray ctermbg=White guibg=White
highlight StatusLineNC	ctermfg=DarkMagenta guifg=DarkMagenta ctermbg=White guibg=Black
highlight TabLine		ctermbg=DarkMagenta ctermfg=DarkMagenta
highlight TabLineFill	ctermbg=DarkGray ctermfg=White
highlight TabLineSel	ctermbg=LightGray ctermfg=White
highlight Title			ctermfg=Red guifg=Red
highlight Todo			ctermfg=Yellow guifg=Yellow ctermbg=Black guibg=Black
highlight Type			ctermfg=Magenta guifg=Magenta
highlight Underlined	cterm=underline ctermfg=12 gui=underline guifg=#80a0ff
highlight VertSplit		ctermfg=DarkMagenta ctermbg=DarkMagenta
highlight Visual		cterm=reverse gui=reverse
highlight VisualNOS		cterm=bold gui=bold
highlight WarningMsg	ctermfg=Red guifg=Red
highlight Whitespace	ctermbg=DarkRed guibg=DarkRed
highlight WildMenu		ctermfg=Black ctermbg=Yellow guifg=Black guibg=Yellow
highlight lCursor		guifg=bg guibg=fg

"GNU Coding Standards
"setlocal cindent
"setlocal cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1
"setlocal shiftwidth=2
"setlocal softtabstop=2
"setlocal textwidth=79
"setlocal fo-=ro fo+=cql

set nocompatible			" ---- Use Vim defaults (much better!)
set bs=indent,eol,start		" ---- allow backspacing over everything in insert mode
set viminfo='20,\"50		" ---- read/write a .viminfo file, don't store more
							" ---- than 50 lines of registers
set history=50				" ---- keep 50 lines of command line history
set ruler					" ---- show the cursor position all the time
set confirm
set noinsertmode			" ---- don't don't out in insert mode
set backspace=2				" ---- allow us to backspace before an insert
set tabstop=4
set shiftwidth=4
set softtabstop=4
set noexpandtab				" ---- use real tab characters
set ttymouse=xterm2			" ---- turn on the mouse in the xterm
set mouse=a					" ---- enable mouse for all VIM options
set iskeyword+="-."
set showcmd					" ---- show the command in the status line
set noerrorbells			" ---- STOP BEEPING!
set showmatch				" ---- show matching brackets
set ttyfast					" ---- smoother output
set laststatus=2			" ---- Always show the status line
set showtabline=2			" ---- Always show tabline, even if only one file open
set updatetime=100			" ---- Default updatetime=4000 to slow
set hidden					" ---- Don't close buffers when switching
set splitbelow				" ---- Open all new splits below current window
set cindent					" ---- Enabled C indenting
set autoindent				" ---- autoindenting is good
set smartindent				" ---- Recognize syntax for formatting

filetype plugin on
filetype indent on

" ---- :help cinoptions-values
"autocmd FileType *.c,*.cpp,*.h
autocmd FileType c,cpp setlocal cinoptions=>4,t0,#0,:0,l1,t0,p2,+2s,c0,(0,m1,)50,J1,#N
autocmd FileType python,sh setlocal cinoptions=>4,t0,#s

match Whitespace /\s\+$/
autocmd BufWinEnter * match Whitespace /\s\+$/
autocmd InsertEnter * match Whitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match Whitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()
autocmd BufWinEnter *.py 2match Whitespace /^\t\+/
autocmd BufWinEnter *.py set fileformat=unix

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugin Configurations

" Note on powerline fonts: The fonts must be installed separately. The .vimrc
" will only use the unicode characters for the various fonts. It is not
" actually a plugin for vim like the others. Enter as double-quoted string
" in the format "\uXXXX"
"
" Here are a couple unicode characters
" E0A0	Branch
" E0A1	Line number
" E0A2	Padlock (read-only)
" E0A3	Column number
" E0B0	Right angle solid
" E0B1	Right angle line
" E0B2	Left angle solid
" E0B3	Left angle line
" E0B8	Bottom-left angle solid
" E0B9	Bottom-left angle line
" E0BA	Bottom-right angle solid
" E0BB	Bottom-right angle line
" E0BC	Top-left angle solid
" E0BD	Top-left angle line
" E0BE	Top-right angle solid
" E0BF	Top-right angle line

" --- https://github.com/majutsushi/tagbar
" --- https://github.com/preservim/nerdtree
" --- https://github.com/tpope/vim-fugitive
" --- https://github.com/airblade/vim-gitgutter
" --- https://github.com/arecarn/vim-fold-cycle
" --- https://github.com/Chiel92/vim-autoformat
" --- https://github.com/pseewald/vim-anyfold
" --- https://github.com/itchyny/lightline.vim
" --- https://github.com/vim-airline/vim-airline
" --- https://github.com/nvie/vim-flake8
" --- https://github.com/preservim/nerdcommenter.git
" --- https://github.com/raven42/devpanel-vim.git

"----- Lightline Plugin Configuration
let g:lightline = {
			\ 'active': {
			\	'left': [['mode', 'paste', 'modified'], ['readonly', 'filename'], ['tagbar']],
			\	'right': [['lineinfo'], ['percent'], ['fileformat', 'fileencoding', 'filetype']]
			\   },
			\ 'inactive': {
			\   'left': [['mode'], ['filename', 'modified']],
			\   'right': [['lineinfo'], ['percent']]
			\ },
			\ 'tabline': {
			\	'left': [ ['buffers'] ],
			\	'right': [ ['hunksummary'], ['branch'] ]
			\ },
			\ 'tab': {
			\	'active': ['filename', 'modified'],
			\	'inactive': ['filename', 'modified'],
			\ },
			\ 'component': {
			\	'lineinfo': "\ue0a3" . '%3l:%-2v',
			\ },
			\ 'component_expand': {
			\	'buffers': 'lightline#bufferline#buffers'
			\ },
			\ 'component_type': {
			\	'buffers': 'tabsel'
			\ },
			\ 'component_function': {
			\	'branch': 'LightlineFugitive',
			\	'fileencoding': 'LightlineFileEncoding',
			\	'fileformat': 'LightlineFileFormat',
			\	'filename': 'LightlineFilename',
			\	'filetype': 'LightlineFileType',
			\	'hunksummary': 'LightlineGitgutterHunks',
			\	'mode' : 'LightlineMode',
			\	'modified' : 'LightlineModified',
			\   'readonly': 'LightlineReadonly',
			\	'tagbar': 'LightlineTagbar',
			\ },
			\ 'tab_component_function': {
			\	'filename': 'LightlineTabname',
			\	'closebuffer': 'LightlineCloseBuffer',
			\ },
			\ 'separator': { 'left': "\ue0b0", 'right': "\ue0b2" },
			\ 'subseparator': { 'left': "\ue0b1", 'right': "\ue0b3" }
			\ }

let g:short_mode_map = {
			\ 'n': 'NORM',
			\ 'i' : 'INS',
			\ 'R' : 'REPL',
			\ 'v' : 'VIS',
			\ 'V' : 'VISL',
			\ "\<C-v>": 'VB',
			\ 'c' : 'CMD',
			\ 's' : 'S',
			\ 'S' : 'SL',
			\ "\<C-s>": 'SB',
			\ 't': 'T',
			\ }

function! LightlineFileEncoding()
	return &filetype ==# 'nerdtree' ? '' :
				\ &filetype ==# 'tagbar' ? '' :
				\ &fenc !=# '' ? &fenc : &enc
endfunction

function! LightlineFileFormat()
	return winwidth(0) < 90 ? '' :
				\ &filetype ==# 'nerdtree' ? '' :
				\ &filetype ==# 'tagbar' ? '' :
				\ &fileformat
endfunction

function! LightlineFilename()
	return &filetype ==# 'nerdtree' ? '' :
				\ &filetype ==# 'tagbar' ? '' :
				\ &filetype ==# 'qf' ? '' :
				\ expand('%:t') !=# '' ? expand('%:t') : '[No Name]'
endfunction

function! LightlineFileType()
	return &filetype !~# '\v(help|nerdtree|tagbar)' ? &filetype : ''
endfunction

function! LightlineGitgutterHunks()
	let [a, m, r] = GitGutterGetHunkSummary()
	return printf('+%d ~%d -%d', a, m, r)
endfunction

function! LightlineMode()
	return &filetype ==# 'nerdtree' ? 'File Explorer' :
				\ &filetype ==# 'tagbar' ? 'Tags' :
				\ exists('w:flake8_window') ? 'Python Errors/Warnings' :
				\ winwidth(0) < 90 ? get(g:short_mode_map, mode(), '') :
				\ lightline#mode()
endfunction

function! LightlineModified()
	return &modified &&
				\ &filetype !~# '\v(help|nerdtree|tagbar)' ? '+' :
				\ ''
endfunction

function! LightlineReadonly()
	return &readonly &&
				\ &filetype !~# '\v(help|nerdtree|tagbar)' ? "\ue0a2" :
				\ ''
endfunction

function! LightlineTabname(n) abort
	let s = ''
	let winnr = tabpagewinnr(a:n)
	let buflist = tabpagebuflist(a:n)
	let bufignore = ['nerdtree', 'tagbar', 'help']
	for b in buflist
		let buftype = getbufvar(b, "&filetype")
		if index(bufignore, buftype)==-1 "index returns -1 if the item is not contained in the list
			let bufnr = b
			break
		elseif b==buflist[-1]
			let bufnr = b
		endif
	endfor
	let bufname = bufname(bufnr)
	let s = (bufname != '' ? bufname : 'No Name')

	return s
endfunction

function! LightlineFugitive()
	if &ft !~? 'vimfiler' && exists('*FugitiveHead')
		if &filetype =~# '\v(help|tagbar|nerdtree)'
			return ''
		endif
		let branch = fugitive#head()
		let branch_icon = "\ue0a0"
		return branch !=# '' ? ' '. branch_icon . branch : ''
	endif
	return ''
endfunction

function! LightlineTagbar()
	" This isn't working right.... it is causing odd characters to show up
	" on the screen. For now, just return an empty string.
	if exists('*tagbar#currenttag')
		return &filetype !~# '\v(help|tagbar|nerdtree)' ? tagbar#currenttag("%s", "", 'p') : ''
	endif
	return ''
endfunction

function! LightlineCloseBuffer()
	echom 'Closing buffer ' . % . '...'
endfunction

function! UpdateTitle()
	let &titlestring = 'VIM - ' . expand("%:t")
	if exists('fugitive#head()')
		let branch = fugitive#head()
	else
		let branch = ''
	endif
	if branch !=# ''
		let icon = "\ue0a0"
		let &titlestring = 'VIM - ' . icon . branch . ' - ' . expand("%:t")
	endif
endfunction

"let NERDTreeCreatePrefix='silent keepalt keepjumps'
let NERDTreeMouseMode = 2		" --- Open/Close directories on single mouse click
let NERDTreeNaturalSort = 1		" --- Sort order of numbered files more natural

"let g:tablineclosebutton = 1
let g:tagbar_position = 'bottom'
let g:tagbar_height = winheight(0) / 2
let g:tagbar_width = winwidth(0) > 150 ? 50 : winwidth(0) / 3
let g:tagbar_previewwin_pos = 'botright'
"let g:tagbar_left = 1			" --- old deprecated value
"let g:tagbar_vertical = 30		" --- old deprecated value

autocmd BufNewFile,BufReadPost *.txt let b:tagbar_ignore = 1

" If we have lightline, don't use the tagbar status line
let g:tagbar_no_status_line = 1

nmap <Leader>1 <Plug>lightline#bufferline#go(1)
nmap <Leader>2 <Plug>lightline#bufferline#go(2)
nmap <Leader>3 <Plug>lightline#bufferline#go(3)
nmap <Leader>4 <Plug>lightline#bufferline#go(4)
nmap <Leader>5 <Plug>lightline#bufferline#go(5)
nmap <Leader>6 <Plug>lightline#bufferline#go(6)
nmap <Leader>7 <Plug>lightline#bufferline#go(7)
nmap <Leader>8 <Plug>lightline#bufferline#go(8)
nmap <Leader>9 <Plug>lightline#bufferline#go(9)
nmap <Leader>0 <Plug>lightline#bufferline#go(10)

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

let g:gitgutter_highlight_lines = 1
let g:gitgutter_sign_added = "\ue0b0\ue0b0"
let g:gitgutter_sign_modified = "\ue0b2\ue0b0"
let g:gitgutter_sign_modified = "\ue0b2\ue0b0"
let g:gitgutter_sign_removed = "\ue0b2\ue0b2"

highlight GitGutterAdd			ctermfg=Green
highlight GitGutterAddLine		ctermbg=17
highlight GitGutterChange		ctermfg=Blue
highlight GitGutterChangeLine	ctermbg=235
highlight GitGutterDelete		ctermfg=Red
highlight GitGutterDeleteLine	ctermbg=52

function! CurrentFunction()
	let name = getline(search("^[^ \t#/]\\{2}.*[^:]\s*$", 'bW'))
	let lines = v:foldend - v:foldstart + 1
	let lines_fmt = lines . ' lines'
	let separator = repeat('-', winwidth(0) - strdisplaywidth(name) - strdisplaywidth(lines_fmt) - 5)

	return name . ' ' . separator . lines_fmt
endfunction

function! GitGutterFoldToggle()
	if !exists('t:gitgutter_fold')
		let t:gitgutter_fold = 0
	endif
	if t:gitgutter_fold == 0
		GitGutterFold
		let t:gitgutter_fold = 1
		set foldtext=gitgutter#fold#foldtext()
		"set foldtext=CurrentFunction()
		set foldlevel=1
	else
		GitGutterFold
		let t:gitgutter_fold = 0
		set foldlevel=99
	endif
endfunction
nmap <Leader>g :call GitGutterFoldToggle()<CR>

" Automatically open / close NERDTree when vim starts / exits
"autocmd vimenter * NERDTree
"autocmd bufenter * if (winnr("$") == 2 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | q | endif

" AnyFold Configuration
if exists('AnyFoldActivate')
	autocmd Filetype c,cpp,python AnyFoldActivate
endif
let g:anyfold_fold_comments=1
let g:anyfold_fold_display=1
"hi Folded term=underline cterm=underline

let g:flake8_show_quickfix = 1
let g:flake8_show_in_gutter = 1
let g:flake8_show_in_file = 0
let g:flake8_quickfix_height = 10
let g:flake8_always_visible = 1

if exists('flake8#Flake8()')
	autocmd BufWritePost *.py call flake8#Flake8()
endif

let g:NERDSpaceDelims = 1			" --- add space after delimiter
let g:NERDCompactSexyComs = 1		" --- use compact syntax for multi-line
let g:NERDDefaultAlign = 'left'		" --- align line-wise comments to left
let g:NERDAltDelims_java = 1		" --- set language to use alternate delims
let g:NERDCommentEmptyLines = 1		" --- allow empty lines to be commented
let g:NERDTrimTrailingWhitespace = 1	" --- trim whitespace when uncommenting
let g:NERDToggleCheckAllLines = 1	" --- check all lines for comment or not
let g:NERDCommentWholeLinesInVMode = 1	" --- Comment entire line in visual

" Override the default '<Leader>cc' mapping to toggle instead of comment
let g:NERDCreateDefaultMappings = 0
nmap <Leader>cc <plug>NERDCommenterToggle
vmap <Leader>cc <plug>NERDCommenterToggle
nmap <Leader>cm <plug>NERDCommenterMinimal
vmap <Leader>cm <plug>NERDCommenterMinimal
nmap <Leader>ci <plug>NERDCommenterInvert
vmap <Leader>ci <plug>NERDCommenterInvert
nmap <Leader>cy <plug>NERDCommenterYank
vmap <Leader>cy <plug>NERDCommenterYank

" Add your own custom formats or override the defaults
let g:NERDCustomDelimiters = { 'c': { 'left': '/***','right': '***/' } }

autocmd VimEnter *.c,*.cpp,*.h,*.py DevPanel
nnoremap <leader>d DevPanelToggle

autocmd BufEnter * call UpdateTitle()

nnoremap <leader>x :NERDTreeToggle <CR>
nnoremap <leader>t :TagbarToggle <CR>

augroup quickfixclose
	autocmd!
	autocmd WinEnter * if winnr('$') == 1 && &buftype == "quickfix"|q|endif
augroup END

" End Plugin Configurations
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" <CTRL-UP> - Switch to window above
nmap <silent> [1;5A :wincmd k<CR>
tmap <silent> [1;5A <c-w>:wincmd k<CR>
" <CTRL-DOWN> - Switch to window below
nmap <silent> [1;5B :wincmd j<CR>
tmap <silent> [1;5B <c-w>:wincmd j<CR>
" <CTRL-LEFT> - Switch to window to the left
nmap <silent> [1;5D :wincmd h<CR>
tmap <silent> [1;5D <c-w>:wincmd h<CR>
" <CTRL-RIGHT> - Switch to window to the right
nmap <silent> [1;5C :wincmd l<CR>
tmap <silent> [1;5C <c-w>:wincmd l<CR>

nmap <silent> = :resize +5<CR>
nmap <silent> - :resize -5<CR>
nmap <silent> _ :vertical resize +5<CR>
nmap <silent> + :vertical resize -5<CR>

nnoremap ; :

"----- Set cursor movement to more natural behavior of moving a row at a time
"----- for wrapped lines, and to home/end of current row instead of full line
"nnoremap <up> g<up>
"nnoremap <down> g<down>
"nnoremap <home> g<home>
"nnoremap <end> g<end>

"----- Let's try the following settings for C/C++
autocmd FileType c,cpp
\	set formatoptions=croql
\	cindent
\	comments=sr:/*,mb:*,ex:*/,://

"----- We need real tabs for Makefiles.
autocmd FileType make set noexpandtab
autocmd FileType make set nosmarttab

"----- have java highlight our functions
"let java_highlight_functions=1

"----- have php3 highlight SQL, and keep in better sync.
let php3_sql_query = 1
let php3_minlines = 3000
let php3_baselib = 1

if has("gui_running")
	 set guifont=Monospace\ 8
	 set mouse=a
	 set ttymouse=sgr
endif

"show only lines containing word under cursor
if version >= 600

set fml=0
set foldtext=FoldText()

function! FoldText()
	 let nl = v:foldend - v:foldstart + 1
	 let txt = '+-- ' . nl . ' lines '
	 return txt
endfunction

function! ToggleFold()
	if !exists('t:folded')
		let t:folded = 0
	endif
	if (t:folded == 0)
		set foldnestmax=1
		set foldlevel=10
		let t:folded = 1
	else
		exec "normal! zR"
		set foldmethod=manual
		let t:folded = 0
	endif
endfunction

" Returns either the contents of a fold or spelling suggestions.
if (v:version >= 700) && has('balloon_eval')
	 function! BalloonExpr()
		let foldStart = foldclosed(v:beval_lnum )
		let foldEnd = foldclosedend(v:beval_lnum)
		let lines = []
		if foldStart < 0
		  " We're not in a fold.
		  " If 'spell' is on and the word pointed to is incorrectly spelled,
		  " the tool tip will contain a few suggestions.
		  let lines = spellsuggest( spellbadword( v:beval_text )[ 0 ], 5, 0 )
		else
		  let numLines = foldEnd - foldStart + 1
		  " Up to 31 lines get shown okay; beyond that, only 30 lines are shown with
		  " ellipsis in between to indicate too much. The reason why 31 get shown ok
		  " is that 30 lines plus one of ellipsis is 31 anyway.
		  if ( numLines > 31 )
			 let lines = getline( foldStart, foldStart + 14 )
			 let lines += [ '-- Snipped ' . ( numLines - 30 ) . ' lines --' ]
			 let lines += getline( foldEnd - 14, foldEnd )
		  else
			 let lines = getline( foldStart, foldEnd )
		  endif
		endif
		return join( lines, has( "balloon_multiline" ) ? "\n" : " " )
	 endfunction
	 set ballooneval
	 set balloondelay=10
	 set balloonexpr=BalloonExpr()
endif

set omnifunc=syntaxcomplete#Complete

function! FoldCursor(lnum)
	"set foldlevel=0
	let word = expand('<cword>')
	if getline(a:lnum) =~? word
		return '0'
	endif
	if getline(a:lnum+foldlevel) =~? word
		return foldlevel
	endif
	if getline(a:lnum-foldlevel) =~? word
		return foldlevel
	endif
	return '99'
endfunction

" Alt-Z - Fold text in search buffer
"map <silent> z :set foldmethod=expr foldexpr=(getline(v:lnum)=~@/)?0:(getline(v:lnum-1)=~@/)\\|\\|(getline(v:lnum+1)=~@/)?1:(getline(v:lnum-2)=~@/)\\|\\|(getline(v:lnum+2)=~@/)?2:(getline(v:lnum-3)=~@/)\\|\\|(getline(v:lnum+3)=~@/)?3:(getline(v:lnum-4)=~@/)\\|\\|(getline(v:lnum+4)=~@/)?4:(getline(v:lnum-5)=~@/)\\|\\|(getline(v:lnum+5)=~@/)?5:(getline(v:lnum-6)=~@/)\\|\\|(getline(v:lnum+6)=~@/)?6:(getline(v:lnum-7)=~@/)\\|\\|(getline(v:lnum+7)=~@/)?7:(getline(v:lnum-8)=~@/)\\|\\|(getline(v:lnum+8)=~@/)?8:(getline(v:lnum-9)=~@/)\\|\\|(getline(v:lnum+9)=~@/)?9:(getline(v:lnum-10)=~@/)\\|\\|(getline(v:lnum+10)=~@/)?10:11 \| call ToggleFold()<CR>
" Ctrl-Z - Fold text under cursor
"map <c-z> :set foldmethod=expr foldexpr=FoldCursor(v:lnum)<CR>
"map <silent> <c-z> :set foldmethod=expr foldexpr=(getline(v:lnum)=~'<c-r>=expand("<cword>")<cr>')?0:(getline(v:lnum-1)=~'<c-r>=expand("<cword>")<cr>')\\|\\|(getline(v:lnum+1)=~'<c-r>=expand("<cword>")<cr>')?1:(getline(v:lnum-2)=~'<c-r>=expand("<cword>")<cr>')\\|\\|(getline(v:lnum+2)=~'<c-r>=expand("<cword>")<cr>')?2:(getline(v:lnum-3)=~'<c-r>=expand("<cword>")<cr>')\\|\\|(getline(v:lnum+3)=~'<c-r>=expand("<cword>")<cr>')?3:(getline(v:lnum-4)=~'<c-r>=expand("<cword>")<cr>')\\|\\|(getline(v:lnum+4)=~'<c-r>=expand("<cword>")<cr>')?4:(getline(v:lnum-5)=~'<c-r>=expand("<cword>")<cr>')\\|\\|(getline(v:lnum+5)=~'<c-r>=expand("<cword>")<cr>')?5:(getline(v:lnum-6)=~'<c-r>=expand("<cword>")<cr>')\\|\\|(getline(v:lnum+6)=~'<c-r>=expand("<cword>")<cr>')?6:(getline(v:lnum-7)=~'<c-r>=expand("<cword>")<cr>')\\|\\|(getline(v:lnum+7)=~'<c-r>=expand("<cword>")<cr>')?7:(getline(v:lnum-8)=~'<c-r>=expand("<cword>")<cr>')\\|\\|(getline(v:lnum+8)=~'<c-r>=expand("<cword>")<cr>')?8:(getline(v:lnum-9)=~'<c-r>=expand("<cword>")<cr>')\\|\\|(getline(v:lnum+9)=~'<c-r>=expand("<cword>")<cr>')?9:(getline(v:lnum-10)=~'<c-r>=expand("<cword>")<cr>')\\|\\|(getline(v:lnum+10)=~'<c-r>=expand("<cword>")<cr>')?10:11 \| call ToggleFold()<CR>
" Shift-Z - Fold functions
"map <silent> Z :set foldmethod=indent \| call ToggleFold()<CR>
set foldlevel=10

" Decrease / Increase fold level
map z, zm
map z. zr

endif

"handy formatting commands for cstyle
"<Ctrl-F2> - replace whitespace at end of line
map <silent> O1;5Q :1,$s/[ \t]*$//<CR>:let @/ = ""<CR>
"<Ctrl-F3> - retab file to remove 'spaces instead of tabs'
map <silent> O1;5R :%retab!<CR>
"<Ctrl-F4> - fix keyword / parenthesis spacing
map <silent> O1;5S :1,$s/\(if\\|for\\|while\\|return\\|sizeof\)(/\1 (/<CR>
"<Ctrl-F5> - fix keyword / parenthesis spacing
map <silent> [15;5~ :1,$s/\(printf\) (/\1(/<CR>
"<Ctrl-F6> - fix parenthesis / bracket
map <silent> [17;5~ :1,$s/){/) {/<CR>
"<Ctrl-F7> - fix cast spacing
map <silent> [18;5~ :1,$s/(\(char\\|char \*\\|char \*\*\\|int\\|int \*\)) /(\1)/<CR>


let w:hexmode = 0
function! ToggleHex()
	 if (w:hexmode == 0)
		  let w:hexmode = 1
		  %!xxd -g 4
	 else
		  let w:hexmode = 0
		  %!xxd -r
	 endif
endfunction
"<Ctrl-H> - convert file to hex
map <silent>  :call ToggleHex()<CR>

function! GenerateUnicode(first, last)
	 let i = a:first
	 while i <= a:last
		  if (i%256 == 0)
				$put ='----------------------------------------------------'
				$put ='     0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F '
				$put ='----------------------------------------------------'
		  endif
		  let c = printf('%04X ', i)
		  for j in range(16)
				let c = c . nr2char(i) . ' '
				let i += 1
		  endfor
		  $put =c
	 endwhile
endfunction

"set tw and unset it
map ,w :set tw=76<CR>
map ,W :set tw=0<CR>

"handy tscope binding
map tt <SPACE>byw:!tscope -i ' f <C-R>"'<CR>

"ctrl-f - tag to filename under cursor
map  :tag <c-r>=expand("<cfile>")<cr><CR>

" fix a few common typo messages
map Qa :qa
map qq :qa
map QQ :qa
map Wq :wq
map WQ :wq

set tags=${TAGFILES}
set viminfo='50,\"1000,:100,n~/.viminfo
map ,t :'a,'b!tf<CR>
set shortmess=aIt

set autoread
