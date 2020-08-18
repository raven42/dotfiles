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
highlight GitGutterAdd			ctermfg=Green
highlight GitGutterAddLine		ctermbg=235
highlight GitGutterChange		ctermfg=Blue
highlight GitGutterChangeLine	ctermbg=17
highlight GitGutterDelete		ctermfg=Red
highlight GitGutterDeleteLine	ctermbg=52
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

" --- GNU Coding Standards
" setlocal cindent
" setlocal cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1
" setlocal shiftwidth=2
" setlocal softtabstop=2
" setlocal textwidth=79
" setlocal fo-=ro fo+=cql

set nocompatible			" ---- Use Vim defaults (much better!)
set bs=indent,eol,start		" ---- allow backspacing over everything in insert mode
" set viminfo=%,<800,'10,/50,:100,h,f0,n~/.vim/cache/.viminfo
" "           | |    |   |   |    | |  + viminfo file path
" "           | |    |   |   |    | + file marks 0-9,A-Z 0=NOT stored
" "           | |    |   |   |    + disable 'hlsearch' loading viminfo
" "           | |    |   |   + command-line history saved
" "           | |    |   + search history saved
" "           | |    + files marks saved
" "           | + lines saved each register (old name for <, vi6.2)
" "           + save/restore buffer list
set viminfo='50,\"1000,:100,n~/.viminfo
set history=50				" ---- keep 50 lines of command line history
set ruler					" ---- show the cursor position all the time
set confirm					" ---- Ask to continue when necessary
set noinsertmode			" ---- don't don't out in insert mode
set backspace=2				" ---- allow us to backspace before an insert
set tabstop=4				" ---- set tabs to 4 spaces
set shiftwidth=4			" ---- set shift width to 4 spaces
set softtabstop=4			" ---- set tabs to 4 spaces when using softtabs
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
set autoread				" ---- Autoread file when change is detected
set shortmess=aIt
set textwidth=140			" ---- Set default character width before autowrap
set tags=${TAGFILES}

filetype plugin on
filetype indent on

" ---- :help cinoptions-values
" NOTE: additional formatting options specified in .vim/after/ftplugin.vim
autocmd FileType c,cpp setlocal cinoptions=>4,t0,#0,:0,l1,p2,+2s,c0,(0,m1,)50,J1,#N
"                                          |  |  |  |  |  |  |   |  |  |  |   |  + Recognize shell/perl script comment style
"                                          |  |  |  |  |  |  |   |  |  |  |   + Don't confuse object declarations with labels
"                                          |  |  |  |  |  |  |   |  |  |  + Look for unclosed paranthesis 50 lines away
"                                          |  |  |  |  |  |  |   |  |  + Line up close paren on new line with open paren
"                                          |  |  |  |  |  |  |   |  + Line up arguments under unclosed parens
"                                          |  |  |  |  |  |  |   + Align lines after comment opener
"                                          |  |  |  |  |  |  + Indent continuation line by 2 shift-width
"                                          |  |  |  |  |  + indent parameter declarations after function but before open bracket
"                                          |  |  |  |  + align with case label instead of statement after it
"                                          |  |  |  + case labels align with switch instead of shift-width in
"                                          |  |  + preprocessor directives should be left aligned
"                                          |  + function return type left justified intead of shift-width
"                                          + normal indentation after start of a block
autocmd FileType python,sh setlocal cinoptions=>4,t0,#s
autocmd BufWinEnter *.c,*.cpp,*.h,*.py match Whitespace /\s\+$/
autocmd InsertEnter *.c,*.cpp,*.h,*.py match Whitespace /\s\+\%#\@<!$/
autocmd InsertLeave *.c,*.cpp,*.h,*.py match Whitespace /\s\+$/
autocmd BufWinEnter *.py 2match Whitespace /^\t\+/
autocmd BufWinEnter *.py set fileformat=unix
autocmd BufWinLeave * call clearmatches()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" PLUGIN Configuration

if version >= 600

	" Here are a couple unicode characters used for any formatted output
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

	"----- Lightline Plugin Configuration
	let g:lightline = {
				\ 'active': {
				\	'left': [['mode', 'paste', 'modified'], ['readonly', 'filename'], ['functionName']],
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
				\	'branch': 'LightlineBranchInfo',
				\	'fileencoding': 'LightlineFileEncoding',
				\	'fileformat': 'LightlineFileFormat',
				\	'filename': 'LightlineFilename',
				\	'filetype': 'LightlineFileType',
				\	'hunksummary': 'LightlineGitgutterHunks',
				\	'mode' : 'LightlineMode',
				\	'modified' : 'LightlineModified',
				\   'readonly': 'LightlineReadonly',
				\	'functionName': 'LightlineFunctionName',
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

	let g:lightline#bufferline#composed_number_map = {
				\ 1:  "\u3010" . '1' . "\u3011",  2:  "\u3010" . '2' . "\u3011",
				\ 3:  "\u3010" . '3' . "\u3011",  4:  "\u3010" . '4' . "\u3011",
				\ 5:  "\u3010" . '5' . "\u3011",  6:  "\u3010" . '6' . "\u3011",
				\ 7:  "\u3010" . '7' . "\u3011",  8:  "\u3010" . '8' . "\u3011",
				\ 9:  "\u3010" . '9' . "\u3011",  10: "\u3010" . '10' . "\u3011",
				\ 11: "\u3010" . '11' . "\u3011", 12: "\u3010" . '12' . "\u3011",
				\ 13: "\u3010" . '13' . "\u3011", 14: "\u3010" . '14' . "\u3011",
				\ 15: "\u3010" . '15' . "\u3011", 16: "\u3010" . '16' . "\u3011",
				\ 17: "\u3010" . '17' . "\u3011", 18: "\u3010" . '18' . "\u3011",
				\ 19: "\u3010" . '19' . "\u3011", 20: "\u3010" . '20' . "\u3011",
				\ }

	let g:lightline#bufferline#composed_number_map = {
				\ 1:  "\u2776", 2:  "\u2777", 3:  "\u2778", 4:  "\u2779",
				\ 5:  "\u277a", 6:  "\u277b", 7:  "\u277c", 8:  "\u277d",
				\ 9:  "\u277e", 10: "\u277f", 11: "\u2780", 12: "\u2781",
				\ 13: "\u2782", 14: "\u2783", 15: "\u2784", 16: "\u2785",
				\ 17: "\u2786", 18: "\u2787", 19: "\u2788", 20: "\u2789",
				\ }

	" --- Lightline#Bufferline Configuration
	let g:lightline#bufferline#show_number = 2
	let g:lightline#bufferline#unicode_symbols = 1
	let g:lightline#bufferline#filename_modifier = ':t'
	let g:lightline#bufferline#unnamed = 'No Name'
	let g:lightline#bufferline#number_separator = ' '

	" --- NERDTree Configuration
	let NERDTreeMouseMode = 2			" --- Open/Close dirs on single mouse click
	let NERDTreeNaturalSort = 1			" --- Sort order of files more natural
	let NERDTreeShowHidden = 1			" --- Show hidden files/folders by default
	let NERDTreeIgnore = [
				\ '\.o$', '\.d$', '\~$', '\.pyc$',
				\ '\.swp$', '\.swo$', '\.swn$',
				\ '\.swm$', '\.swl$', '\.swk$', ]
	if $GIT_ROOT !=# ''
		let BookmarksFile = $GIT_ROOT . '/.rc/NERDTreeBookmarks'
		if filereadable(BookmarksFile)
			let NERDTreeBookmarksFile = BookmarksFile
			let NERDTreeShowBookmarks = 1		" --- Show bookmarks on startup
		elseif filereadable('~/.NERDTreeBookmarks')
			let NERDTreeShowBookmarks = 1		" --- Show bookmarks on startup
		endif
	endif

	" --- NERDCommenter Configuration
	let g:NERDCustomDelimiters = { 'c': { 'left': '/***','right': '***/' } }
	let g:NERDSpaceDelims = 1				" --- add space after delimiter
	let g:NERDCompactSexyComs = 1			" --- use compact syntax for multi-line
	let g:NERDDefaultAlign = 'left'			" --- align line-wise comments to left
	let g:NERDAltDelims_java = 1			" --- set language to use alternate delims
	let g:NERDCommentEmptyLines = 1			" --- allow empty lines to be commented
	let g:NERDTrimTrailingWhitespace = 1	" --- trim whitespace when uncommenting
	let g:NERDToggleCheckAllLines = 1		" --- check all lines for comment or not
	let g:NERDCommentWholeLinesInVMode = 1	" --- Comment entire line in visual
	let g:NERDCreateDefaultMappings = 0		" --- Don't use default mappings

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

	" --- GitGutter Configuration
	let g:gitgutter_highlight_lines = 1
	let g:gitgutter_sign_added = "\ue0b0"
	let g:gitgutter_sign_modified = "\ue0b2\ue0b0"
	let g:gitgutter_sign_removed = "\ue0b8"
	let g:gitgutter_sign_removed_first_line = "\ue0bc"
	let g:gitgutter_sign_remove_above_and_below = "\ue0b0\ue0b2"
	let g:gitgutter_sign_modified_removed = "\ue0b0\ue0b2"

	" --- Tagbar Configuration
	let g:tagbar_position = 'bottom'
	let g:tagbar_height = winheight(0) / 2
	let g:tagbar_width = winwidth(0) > 150 ? 50 : winwidth(0) / 3
	let g:tagbar_previewwin_pos = 'botright'
	let g:tagbar_no_status_line = 1

	" --- Syntastic Configuration
	let g:syntastic_always_populate_loc_list = 1
	let g:syntastic_auto_loc_list = 1
	let g:syntastic_check_on_open = 1
	let g:syntastic_check_on_wq = 0

	" --- AnyFold Configuration
	let g:anyfold_fold_comments=1
	let g:anyfold_fold_display=1

	" --- Flake8 Configuration
	let g:flake8_show_quickfix = 1
	let g:flake8_show_in_gutter = 1
	let g:flake8_show_in_file = 0
	let g:flake8_quickfix_height = 10
	let g:flake8_always_visible = 1

	" --- Auto-pairs Configuration
	let g:AutoPairsShortcutToggle = ''
	let g:AutoPairsShortcutFastWrap = '<Leader>)'

	" --- Generic definitions used by functions for plugins
	let g:ignored_windows = '\v(help|nerdtree|tagbar|qf)'
	let g:branch_icon = "\ue0a0"

	packloadall

	" --- https://github.com/majutsushi/tagbar
	let g:have_tagbar = &runtimepath =~# 'tagbar' ? 1 : 0
	" --- https://github.com/preservim/nerdtree
	let g:have_nerdtree = &runtimepath =~# 'nerdtree' ? 1 : 0
	" --- https://github.com/tpope/vim-fugitive
	let g:have_fugitive = &runtimepath =~# 'fugitive' ? 1 : 0
	" --- https://github.com/airblade/vim-gitgutter
	let g:have_gitgutter = &runtimepath =~# 'gitgutter' ? 1 : 0
	" --- https://github.com/arecarn/vim-fold-cycle
	let g:have_foldcycle = &runtimepath =~# 'foldcycle' ? 1 : 0
	" --- https://github.com/Chiel92/vim-autoformat
	let g:have_autoformat = &runtimepath =~# 'autoformat' ? 1 : 0
	" --- https://github.com/pseewald/vim-anyfold
	let g:have_anyfold = &runtimepath =~# 'anyfold' ? 1 : 0
	" --- https://github.com/itchyny/lightline.vim
	let g:have_lightline = &runtimepath =~# 'lightline' ? 1 : 0
	" --- https://github.com/nvie/vim-flake8
	let g:have_flake8 = &runtimepath =~# 'flake8' ? 1 : 0
	" --- https://github.com/preservim/nerdcommenter.git
	let g:have_nerdcommenter = &runtimepath =~# 'nerdcommenter' ? 1 : 0
	" --- https://github.com/raven42/devpanel-vim.git
	let g:have_devpanel = &runtimepath =~# 'devpanel' ? 1 : 0

	function! LightlineFileEncoding()
		return &filetype =~# g:ignored_windows ? '' :
					\ &fenc !=# '' ? &fenc : &enc
	endfunction

	function! LightlineFileFormat()
		return winwidth(0) < 90 ? '' :
					\ &filetype =~# g:ignored_windows ? '' :
					\ &fileformat
	endfunction

	function! LightlineFilename()
		return &filetype =~# g:ignored_windows ? '' :
					\ expand('%:t') !=# '' ? expand('%:t') : '[No Name]'
	endfunction

	function! LightlineFileType()
		return &filetype !~# g:ignored_windows ? &filetype : ''
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
					\ &filetype !~# g:ignored_windows ? "\u270e" :
					\ ''
	endfunction

	function! LightlineReadonly()
		return &readonly &&
					\ &filetype !~# g:ignored_windows ? "\ue0a2" :
					\ ''
	endfunction

	function! LightlineBranchInfo()
		if !g:have_fugitive || &filetype =~# g:ignored_windows
			return ''
		endif
		let branch = fugitive#head()
		return branch !=# '' ? ' '. g:branch_icon . branch : ''
	endfunction

	function! LightlineFunctionName()
		if !g:have_tagbar || &filetype =~# g:ignored_windows
			return ''
		endif
		return tagbar#currenttag("%s", "", 'f')
	endfunction

	function! LightlineCloseBuffer()
		echom 'Closing buffer ' . % . '...'
	endfunction

	function! LastOpenFileName() abort
		if !exists('t:lastfilename')
			let t:lastfilename = fnamemodify(bufname('%'), ':p')
		endif
		if &filetype !~# g:ignored_windows
			let bufname = fnamemodify(bufname('%'), ':p')
			if bufname == ''
				let bufname = 'No Name'
			endif
			let t:lastfilename = bufname
		endif
		return t:lastfilename
	endfunction

	function! UpdateTitle()
		let &titlestring = 'VIM - ' . expand("%:t")
		let branch_info = ''
		if g:have_fugitive
			let branch = fugitive#head()
			if branch !=# ''
				let branch_info = ' '. g:branch_icon . ' (' . branch . ') '
			endif
		endif
		let file_info = LastOpenFileName()
		let file_info = substitute(file_info, '\/work\/dh404494', '', '')
		let file_info = substitute(file_info, 'vobs\/projects\/springboard', '..', '')
		let file_info = substitute(file_info, '\/home\/dh404494', '~', '')
		let &titlestring = 'VIM ' . branch_info . file_info
	endfunction

	function! FilterBuffer(i)
		return bufexists(a:i) && buflisted(a:i) && !(getbufvar(a:i, '&filetype') =~# g:ignored_windows)
	endfunction

	function! FilteredBuffers()
		let l:buffers = filter(range(1, bufnr('$')), 'FilterBuffer(v:val)')
		return l:buffers
	endfunction

	function! BufActivateNth(bufnr) abort
		while &filetype =~# g:ignored_windows
			execute 'wincmd w'
		endwhile
		let l:buffers = FilteredBuffers()
		if a:bufnr < len(l:buffers)
			execute 'buffer ' . l:buffers[a:bufnr]
		endif
	endfunction

	function! BufCloseNth(bufnr) abort
		let l:buffers = FilteredBuffers()
		if a:bufnr < len(l:buffers)
			execute 'bdelete ' . l:buffers[a:bufnr]
		endif
	endfunction

	function! BufClose() abort
		" If only one buffer open and listed (ignoring hidden buffers) don't close
		let l:buffers = FilteredBuffers()
		if len(l:buffers) <= 1
			echo '...No more buffers to close'
			return
		endif
		let bufnr = bufnr("%")
		bprevious
		execute 'bdelete ' . bufnr
	endfunction

	" --- Key Mappings for all plugins
	nmap <Leader>cc <plug>NERDCommenterToggle
	vmap <Leader>cc <plug>NERDCommenterToggle
	nmap <Leader>cm <plug>NERDCommenterMinimal
	vmap <Leader>cm <plug>NERDCommenterMinimal
	nmap <Leader>ci <plug>NERDCommenterInvert
	vmap <Leader>ci <plug>NERDCommenterInvert
	nmap <Leader>cy <plug>NERDCommenterYank
	vmap <Leader>cy <plug>NERDCommenterYank

	" nmap <Leader>1 <Plug>lightline#bufferline#go(1)
	" nmap <Leader>2 <Plug>lightline#bufferline#go(2)
	" nmap <Leader>3 <Plug>lightline#bufferline#go(3)
	" nmap <Leader>4 <Plug>lightline#bufferline#go(4)
	" nmap <Leader>5 <Plug>lightline#bufferline#go(5)
	" nmap <Leader>6 <Plug>lightline#bufferline#go(6)
	" nmap <Leader>7 <Plug>lightline#bufferline#go(7)
	" nmap <Leader>8 <Plug>lightline#bufferline#go(8)
	" nmap <Leader>9 <Plug>lightline#bufferline#go(9)
	" nmap <Leader>0 <Plug>lightline#bufferline#go(10)
	nmap <Leader>1 :call BufActivateNth(0)<CR>
	nmap <Leader>2 :call BufActivateNth(1)<CR>
	nmap <Leader>3 :call BufActivateNth(2)<CR>
	nmap <Leader>4 :call BufActivateNth(3)<CR>
	nmap <Leader>5 :call BufActivateNth(4)<CR>
	nmap <Leader>6 :call BufActivateNth(5)<CR>
	nmap <Leader>7 :call BufActivateNth(6)<CR>
	nmap <Leader>8 :call BufActivateNth(7)<CR>
	nmap <Leader>9 :call BufActivateNth(8)<CR>
	nmap <Leader>0 :call BufActivateNth(9)<CR>

	nnoremap <Leader>x :NERDTreeToggle <CR>
	nnoremap <Leader>t :TagbarToggle <CR>
	nnoremap <Leader>d :DevPanelToggle<CR>
	nnoremap <silent> <Leader>q :call BufClose()<CR>

	" --- Autocmds for all plugins
	autocmd BufNewFile,BufReadPost *.txt let b:tagbar_ignore = 1
	autocmd VimEnter *.c,*.cpp,*.h,*.py,*.vim DevPanel
	autocmd BufEnter * call UpdateTitle()
	"autocmd Filetype c,cpp,python AnyFoldActivate
	autocmd BufWritePost *.py call flake8#Flake8()

	augroup quickfixclose
		autocmd!
		autocmd WinEnter * if winnr('$') == 1 && &buftype == "quickfix"|q|endif
	augroup END

endif

" End PLUGIN Configurations
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

nmap <silent> <Leader>= :resize +5<CR>
nmap <silent> <Leader>- :resize -5<CR>
nmap <silent> <Leader>_ :vertical resize +5<CR>
nmap <silent> <Leader>+ :vertical resize -5<CR>

set foldlevel=10

" Decrease / Increase fold level
nmap z, zm
nmap z. zr
nmap z,, :set foldlevel=0 <CR>
nmap z.. :set foldlevel=99 <CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Folding utilities

let g:LogLevelFoldMap = {
			\ '\[EMERG\]'	: 1,
			\ '\[ALERT\]'	: 2,
			\ '\[CRIT\]'	: 3,
			\ '\[ERR\]'		: 4,
			\ '\[WARN\]'	: 5,
			\ '\[NOTICE\]'	: 6,
			\ '\[INFO\]'	: 7,
			\ '\[DEBUG\]'	: 8,
			\ '\[VERBOSE\]'	: 9
			\ }

function! FoldLogLevel(lnum)
	let line = getline(a:lnum)
	for [level, foldlevel] in items(g:LogLevelFoldMap)
		if line =~? level
			return foldlevel
		endif
	endfor
	return '0'
endfunction

function! FoldTextFunction() " {{{2
	if g:have_tagbar
		let text = tagbar#GetNearbyTag(v:foldend, '%s', 'p')
	else
		let suba = getline(v:foldstart)
		let foldmarkerpat = join(map(split(&l:foldmarker,','), "v:val.'\\d\\='"), '\|')
		let suba = substitute(suba, foldmarkerpat, '', 'g')
		let suba = substitute(suba, '\s*$', '', '')
		let text = suba
	endif
	let lines = v:foldend - v:foldstart + 1
	let fillchar = matchstr(&fillchars, 'fold:\zs.')
	if strlen(fillchar) == 0
		let fillchar = '-'
	endif
	let lines = repeat(fillchar, 4).' ' . lines . ' lines '.repeat(fillchar, 3)
	if has('float')
		let nuw = max([float2nr(log10(line('$')))+3, &numberwidth])
	else
		let nuw = &numberwidth
	endif
	let n = winwidth(winnr()) - &foldcolumn - nuw - strlen(lines)
	let text = text[:min([strlen(text), n])]
	if text[-1:] != ' '
		if strlen(text) < n
			let text .= ' '
		else
			let text = substitute(text, '\s*.$', '', '')
		endif
	endif
	let text .= repeat(fillchar, n - strlen(text))
	let text .= lines
	return text
endfunction

function! ToggleLogFold()
	if exists('g:toggle_fold')
		set foldlevel=99
		unlet g:toggle_fold
		return
	endif
	set foldmethod=expr
	set foldexpr=FoldLogLevel(v:lnum)
	set foldlevel=5
	let g:toggle_fold = 1
endfunction

function! ToggleGitFold()
	if !g:have_gitgutter
		echo '...GitGutter plugin not installed'
		return
	endif
	if exists('t:toggle_fold')
		set foldlevel=99
		unlet g:toggle_fold
		return
	endif
	GitGutterFold
	if g:have_tagbar
		set foldtext=FoldTextFunction()
	else
		set foldtext=gitgutter#fold#foldtext()
	endif
	set foldlevel=1
	let g:toggle_fold = 1
endfunction

function! ToggleSearchWord()
	if exists('g:toggle_fold')
		set foldlevel=99
		let @/ = ''					" --- Clear the search pattern
		unlet g:toggle_fold
		return
	endif
	let @/ = expand('<cword>')		" --- Set search pattern to current word
	call SearchFold(0)				" --- Call SearchFold() for normal mode
	set foldlevel=2					" --- Set to show a few lines of context
	set foldtext=FoldTextFunction()
	let g:toggle_fold = 1
endfunction

nnoremap <silent> <C-z> :call ToggleSearchWord()<CR>
nnoremap <silent> <C-l> :call ToggleLogFold()<CR>
nnoremap <silent> <Leader>g :call ToggleGitFold()<CR>

nnoremap ; :

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
