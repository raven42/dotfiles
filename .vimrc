" --- David Hegland's .vimrc file
" --- designed for vim 8.2
" --- 2020

" --- Initialization {{{1
" --- Envinroment varaiables information {{{2

" The following envinronment variables are used in this resource script
" $CSCOPE_DB		: looks for a cscope database
" $TAGDIR			: Defines the VIM tag directory to look for ctags
" $HOME				: Used to define 'makeprg' for make tasks
" $USE_UNICODE		: If set use unicode characters for some plugin definitions
" $USE_DEVPANEL		: Use the devpanel by default
" $GIT_ROOT			: Used for repo specific bookmark file
" $USER				: Used to filter file names for title formatting
" $SRC_PATH_PREFIX	: Used to filter file names for title formatting
" $AUTOSAVE			: Set to 0|1 to Disable|Enable autosave for all files

" --- End Envonrment Variables

" --- Default /etc/vimrc contents {{{2
if v:lang =~# 'utf8$' || v:lang =~# 'UTF-8$'
	set fileencodings=utf-8
endif

" --- Encoding Setup {{{2
if has('multi_byte')
	if &termencoding ==# ''
		let &termencoding = &encoding
	endif
	set encoding=utf-8
	setglobal fileencoding=utf-8
	" setglobal bomb
	set fileencodings=ucs-bom,utf-8,latin1
	scriptencoding utf-8
endif

" --- Setup textwidth for text files {{{2
if has('autocmd')
	augroup redhat
		" In text files, always limit the width of text to 78 characters
		"    autocmd BufRead *.txt set tw=78
		" When editing a file, always jump to the last cursor position
		autocmd BufReadPost *
					\ if line("'\"") > 0 && line ("'\"") <= line('$') |
					\   exe "normal! g'\"" |
					\ endif
	augroup END
endif

" --- Setup cscope {{{2
if has('cscope') && filereadable('/usr/bin/cscope')
	set csprg=/usr/bin/cscope
	set csto=0
	set cst
	set nocsverb
	" add any database in current directory
	if filereadable('cscope.out')
		cs add cscope.out
		" else add database pointed to by environment
	elseif $CSCOPE_DB !=# ''
		cs add $CSCOPE_DB
	endif
	set csverb
endif

" --- Setup GUI parameters {{{2
if has('gui_running')
	set guifont=Monospace\ 8
	set mouse=a
	set ttymouse=sgr
	set termguicolors
endif

" --- setup xterm parameters {{{2
if &term =~# 'xterm'
	if has('terminfo')
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
	" Handle terminal raw mode correctly
	" FIXME: This should be temporary until a better fix is found
	" This limits vim from recognizing <C-a> and <C-S-a> as separate
	" key sequences. For more info see :help modifyOtherKeys
	set t_TI=
	set t_TE=
endif

" --- Syntax Highlighting Defintions {{{2

" --- For more colors, see 256 color pallet in ~/.vim/sample-256.colors
"	  Primary color highlighting moved into ~/.vim/colors/  and will use
"	  the colorscheme command to load a <colorscheme>.vim file.
syntax on					" ---- turn on syntax highlighting
set background=dark
set hlsearch
colorscheme xterm

" --- Setup VIM defaults {{{2
" --- GNU Coding Standards
" setlocal cindent
" setlocal cinoptions=>4,n-2,{2,^-2,:2,=2,g0,h2,p5,t0,+2,(0,u0,w1,m1
" setlocal shiftwidth=2
" setlocal softtabstop=2
" setlocal textwidth=79
" setlocal fo-=ro fo+=cql

let $TMPDIR=$HOME . '/tmp'

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
set viminfo='50,<1000,:100,n~/.viminfo
set history=50				" ---- keep 50 lines of command line history
set ruler					" ---- show the cursor position all the time
set confirm					" ---- Ask to continue when necessary
set noinsertmode			" ---- don't don't out in insert mode
set backspace=2				" ---- allow us to backspace before an insert
set tabstop=4				" ---- set tabs to 4 spaces
set shiftwidth=4			" ---- set shift width to 4 spaces
set softtabstop=4			" ---- set tabs to 4 spaces when using softtabs
set noexpandtab				" ---- use real tab characters
set ttymouse=sgr			" ---- turn on the mouse in the xterm
set mouse=a					" ---- enable mouse for all VIM options
set mousetime=1000			" ---- increase the mouse double click time to 1 second
set iskeyword=@,48-57,_,192-255,.,-
set showcmd					" ---- show the command in the status line
set noerrorbells			" ---- STOP BEEPING!
set showmatch				" ---- show matching brackets
set ttyfast					" ---- smoother output
set laststatus=2			" ---- Always show the status line
set showtabline=2			" ---- Always show tabline, even if only one file open
set updatetime=1000			" ---- Default updatetime=4000 to slow
set hidden					" ---- Don't close buffers when switching
set splitbelow				" ---- Open all new splits below current window
set cindent					" ---- Enabled C indenting
set autoindent				" ---- autoindenting is good
set smartindent				" ---- Recognize syntax for formatting
set autoread				" ---- Autoread file when change is detected
" set shortmess=aIt
set textwidth=0				" ---- Set default character width before autowrap
set foldlevel=10
set makeprg=$HOME/bin/cmk
set clipboard=unnamed,autoselect,exclude:cons\|linux
set number

if v:version >= 800
	set modelineexpr
	set modeline
endif

let tagfiles = ''
for tagfile in split(globpath($TAGDIR, '*'), '\n')
	if tagfiles ==# ''
		let tagfiles=tagfile
	else
		let tagfiles .= ',' . tagfile
	endif
endfor
execute 'set tags=' . tagfiles

filetype plugin on
filetype indent on

" --- have java highlight our functions
"let java_highlight_functions=1

" --- have php3 highlight SQL, and keep in better sync.
let php3_sql_query = 1
let php3_minlines = 3000
let php3_baselib = 1

nnoremap ; :

" .vimrc autocmds
augroup vimrc
	"----- Let's try the following settings for C/C++
	autocmd FileType c,cpp
				\	setlocal formatoptions=croql
				\	cindent
				\	comments=sr:/*,mb:*,ex:*/,://

	" --- We need real tabs for Makefiles.
	autocmd FileType make setlocal noexpandtab
	autocmd FileType make setlocal nosmarttab

	" --- :help cinoptions-values
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
	" autocmd BufWinEnter *.py set fileformat=unix
	autocmd BufWinLeave * call clearmatches()
augroup END

" Hit // to search for visually selected text
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>

" --- Powerline setup {{{2
" Powerline Configuration
python3 from powerline.vim import setup as powerline_setup
python3 powerline_setup()
python3 del powerline_setup

set laststatus=2

" }}}1

" --- PLUGIN Configurations {{{1
" ---- Only load plugins if VIM version 8 or higher {{{2

if v:version >= 800

    " ---- Character Map {{{2
	" Here are a couple unicode characters used for any formatted output
	" E0A0  Branch						25E2 ◢
	" E0A1  Line number				25E3 ◣
	" E0A2  Padlock (read-only)		25E4 ◤
	" E0A3  Column number				25E5 ◥
	" E0B0  Right angle solid			21B2 ↲ Enter
	" E0B1  Right angle line			26A0 ⚠ Warning
	" E0B2  Left angle solid			26A1 ⚡Lightning
	" E0B3  Left angle line			2714 ✔ Checkmark
	" E0B8 							2716 ✖ X-Mark
	" E0B9 							2718 ✘ X-Mark
	" E0BA 							271A ✚ Plus-Mark
	" E0BB 							2260 ≠ Not Equals
	" E0BC 							2264 ≤ Less-than or equal
	" E0BD 							2265 ≥ Greater-than or equal
	" E0BE 							00A9 © Copyright
	" E0BF 							00AE ® Rights-Reserved
	" 25BC ▼ Arrow Down					23F3 ⏳Timer
	" 25B2 ▲ Arrow Up					23F0 ⏰Alarm Clock
	" 25B6 ▶ Arrow Right
	" 25C0 ◀ Arrow Left
	"  NOTE: To enter unicode ctrl-v then u for 2 byte or U for 4 byte unicode
	"  Ex: <Ctrl-V>u2714  for \u2714 (checkmark)

	" Flags to disable some plugins
	let g:loaded_nerdtree_git_status = 1
	"let g:loaded_tagbar = 1
	"let g:loaded_devpanel = 1

	if $USE_UNICODE !=# ''
		let g:use_unicode = $USE_UNICODE
	else
		let g:use_unicode = 1
	endif

	let g:charmap_unicode = {
				\ 'branch'					: '',
				\ 'line-num'				: '',
				\ 'lock'					: '',
				\ 'write'					: '✎',
				\ 'column-num'				: '',
				\ 'left-separator'			: '',
				\ 'right-separator'			: '',
				\ 'left-subseparator'		: '',
				\ 'right-subseparator'		: '',
				\ 'arrow-up'				: '⯅',
				\ 'arrow-down'				: '⯆',
				\ 'arrow-left'				: '⯇',
				\ 'arrow-right'				: '⯈',
				\ 'line-added'				: '',
				\ 'line-modified'			: '',
				\ 'line-modified-removed'	: '',
				\ 'line-removed-above'		: '◤',
				\ 'line-removed'			: '◣',
				\ 'modified'				: '✚',
                \ 'staged'					: '✔',
                \ 'untracked'				: '✭',
                \ 'renamed'					: '➜',
                \ 'unmerged'				: '═',
                \ 'deleted'					: '✖',
                \ 'dirty'					: '✗',
                \ 'ignored'					: '!',
                \ 'clean'					: ' ',
                \ 'unknown'					: '?',
				\ 'fold-fillchar'			: '═',
				\ 'fold-leftchar'			: '╣',
				\ 'fold-rightchar'			: '╠'
				\ }

	let g:charmap_normal = {
				\ 'branch'					: '',
				\ 'line-num'				: '',
				\ 'lock'					: 'r',
				\ 'write'					: '+',
				\ 'column-num'				: '',
				\ 'left-separator'			: '',
				\ 'right-separator'			: '',
				\ 'left-subseparator'		: '|',
				\ 'right-subseparator'		: '|',
				\ 'arrow-up'				: '^',
				\ 'arrow-down'				: '-',
				\ 'arrow-left'				: '<',
				\ 'arrow-right'				: '>',
				\ 'line-added'				: '+',
				\ 'line-modified'			: '~',
				\ 'line-modified-removed'	: '~',
				\ 'line-removed-above'		: '-',
				\ 'line-removed'			: '-',
				\ 'modified'				: '+',
                \ 'staged'					: '*',
                \ 'untracked'				: 'u',
                \ 'renamed'					: 'r',
                \ 'unmerged'				: '=',
                \ 'deleted'					: '-',
                \ 'dirty'					: 'x',
                \ 'ignored'					: '!',
                \ 'clean'					: ' ',
                \ 'unknown'					: '?',
				\ 'fold-fillchar'			: '-',
				\ 'fold-leftchar'			: '|',
				\ 'fold-rightchar'			: '|'
				\ }	

	let g:nummap_unicode = {
				\ 1:  '❶',  2: '❷', 3:  '❸',  4: '❹', 5:  '❺',
				\ 6:  '❻',  7: '❼', 8:  '❽',  9: '❾', 10: '❿',
				\ 11: '⓫', 12: '⓬', 13: '⓭', 14: '⓮', 15: '⓯',
				\ 16: '⓰', 17: '⓱', 18: '⓲', 19: '⓳', 20: '⓴',
				\ }

	let g:nummap_normal = {
				\ 1:  '1.',  2:  '2.',  3:  '3.',  4:  '4.',  5:  '5.',
				\ 6:  '6.',  7:  '7.',  8:  '8.',  9:  '9.',  10: '10.',
				\ 11: '11.', 12: '12.', 13: '13.', 14: '14.', 15: '15.',
				\ 16: '16.', 17: '17.', 18: '18.', 19: '19.', 20: '20.',
				\ }

	" ---- SetUnicode() {{{2
	if g:use_unicode
		let g:charmap = g:charmap_unicode
		let g:nummap = g:nummap_unicode
	else
		let g:charmap = g:charmap_normal
		let g:nummap = g:nummap_normal
	endif

	" ---- Lightline Plugin Configuration {{{2
	let g:lightline = {
				\ 'active': {
				\	'left': [['mode', 'paste', 'modified'], ['readonly', 'filename'], ['functionName']],
				\	'right': [['lineinfo'], ['percent'], ['fileformat', 'fileencoding', 'filetype']]
				\ },
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
				\	'lineinfo': g:charmap['line-num'] . '%3l:%-2v',
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
				\ 'separator': {
				\	'left': g:charmap['left-separator'],
				\	'right': g:charmap['right-separator'],
				\ },
				\ 'subseparator': {
				\	'left': g:charmap['left-subseparator'],
				\	'right': g:charmap['right-subseparator']
				\ }
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

	" ---- Lightline#Bufferline Configuration {{{2
	let g:lightline#bufferline#composed_number_map = g:nummap
	let g:lightline#bufferline#show_number = 2
	let g:lightline#bufferline#unicode_symbols = 1
	let g:lightline#bufferline#filename_modifier = ':t'
	let g:lightline#bufferline#unnamed = 'No Name'
	let g:lightline#bufferline#number_separator = ' '

	" ---- NERDTree Configuration {{{2
	let NERDTreeMouseMode = 2			" --- Open/Close dirs on single mouse click
	let NERDTreeNaturalSort = 1			" --- Sort order of files more natural
	let NERDTreeShowHidden = 1			" --- Show hidden files/folders by default
	let NERDTreeIgnore = [
				\ '\.o$', '\.d$', '\~$', '\.pyc$',
				\ '\.swp$', '\.swo$', '\.swn$',
				\ '\.swm$', '\.swl$', '\.swk$', ]
	let g:NERDTreeDirArrowExpandable = g:charmap['arrow-right']
	let g:NERDTreeDirArrowCollapsible = g:charmap['arrow-down']
	if $GIT_ROOT !=# ''
		let BookmarksFile = $GIT_ROOT . '/.rc/NERDTreeBookmarks'
		if filereadable(BookmarksFile)
			let NERDTreeBookmarksFile = BookmarksFile
			let NERDTreeShowBookmarks = 1		" --- Show bookmarks on startup
		elseif filereadable('~/.NERDTreeBookmarks')
			let NERDTreeShowBookmarks = 1		" --- Show bookmarks on startup
		endif
	endif

	" ---- NERDTree Git Configuration {{{2
	let g:NERDTreeGitStatusShowClean = 0
	let g:NERDTreeGitStatusConcealBrackets = 1
	let g:NERDTreeStatusUpdateOnCursorHold = 0
	let g:NERDTreeGitStatusIndicatorMapCustom = {
				\ 'Modified'  : g:charmap['modified'],
				\ 'Staged'    : g:charmap['staged'],
				\ 'Untracked' : g:charmap['untracked'],
				\ 'Renamed'   : g:charmap['renamed'],
				\ 'Unmerged'  : g:charmap['unmerged'],
				\ 'Deleted'   : g:charmap['deleted'],
				\ 'Dirty'     : g:charmap['dirty'],
				\ 'Ignored'   : g:charmap['ignored'],
				\ 'Clean'     : g:charmap['clean'],
				\ 'Unknown'   : g:charmap['unknown']
				\ }

	" ---- NERDCommenter Configuration {{{2
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

	" ---- GitGutter Configuration {{{2
	let g:gitgutter_highlight_lines = 1
	let g:gitgutter_preview_win_location = 'rightbelow'
	let g:gitgutter_sign_added = g:charmap['line-added']
	let g:gitgutter_sign_modified = g:charmap['line-modified']
	let g:gitgutter_sign_removed = g:charmap['line-removed']
	let g:gitgutter_sign_removed_first_line = g:charmap['line-removed-above']
	let g:gitgutter_sign_remove_above_and_below = g:charmap['line-modified-removed']
	let g:gitgutter_sign_modified_removed = g:charmap['line-modified-removed']

	" ---- Tagbar Configuration {{{2
	let g:tagbar_no_status_line = 1
	let g:tagbar_iconchars = [ g:charmap['arrow-right'], g:charmap['arrow-down'] ]
	let g:tagbar_file_size_limit = 1000000
	let g:tagbar_jump_offset = winheight(0) / 4
	let g:tagbar_show_data_type = 1
	let g:tagbar_show_tag_count = 1
	let g:tagbar_case_insensitive = 1
	let g:tagbar_highlight_method = 'scoped-stl'
	let g:tagbar_autoclose = 0
	let g:tagbar_autoclose_netrw = 1

	" let g:no_status_line = 1
	" let g:tagbar_autofocus = 0
	" let g:tagbar_autopreview = 0
	" let g:tagbar_autoshowtag = 1
	" let g:tagbar_compact = 1
	" let g:tagbar_indent = 1
	" let g:tagbar_jump_offset = winheight(0)/4
	" let g:tagbar_left = 1
	" let g:tagbar_silent = 1
	" let g:tagbar_sort = 0
	" let g:tagbar_width = max([40, winwidth(0) / 6])
	" let g:tagbar_wrap = 1

	" let g:tagbar_long_help = 1
	" let g:tagbar_compact = 1
	" let g:tagbar_autoshowtag = 0

	" Override 'c' type that doesn't include unions to avoid issues with
	" unions inside of functions messing up with display and scoping issues.
	let g:tagbar_type_c = {
				\ 'ctagstype'	: 'c',
				\ 'regex'	: [
					\ '/(TODO).*//T,ToDo,ToDo Messages/{_anonymous=todo_}',
					\ '/(FIXME).*//Q,FixMe,FixMe Messages/{_anonymous=fixme_}',
				\ ],
				\ 'kinds'		: [
					\ 'h:header files:1:0',
					\ 'd:macros:1:0',
					\ 'p:prototypes:1:0',
					\ 'g:enums:0:1',
					\ 'e:enumerators:0:0',
					\ 't:typedefs:0:0',
					\ 's:structs:0:1',
					\ 'm:members:1:0',
					\ 'v:variables:0:0',
					\ 'f:functions:0:1:{:}',
					\ 'T:todo:0:0',
					\ 'Q:fixme:0:0',
				\ ],
				\ 'sro'			: '::',
				\ 'kind2scope'	: {
					\ 'g' : 'enum',
					\ 's' : 'struct',
				\ },
				\ 'scope2kind'	: {
					\ 'enum'   : 'g',
					\ 'struct' : 's',
				\ }
			\ }

	let g:tagbar_type_cheatsheet = {
				\ 'ctagstype'	: 'cheatsheet',
				\ 'kinds'		: [
					\ 'h:header:0:1',
					\ 's:section:0:1',
					\ 'u:unused:0:1',
				\ ],
				\ 'sro'			: '::',
				\ 'kind2scope'	: {
					\ 'h' : 'header',
				\ },
				\ 'scope2kind'	: {
					\ 'header' : 'h',
				\ },
			\ }

	let g:tagbar_type_javascript = {
				\ 'ctagstype'	: 'javascript',
				\ 'regex'		: [
					\ '/async[ \t]+(.*)[ \t]*\(.*\)/\1/f/func/function/',
				\ ],
				\ 'kinds'		: [
					\ 'v:global variables:0:0',
					\ 'C:constants:0:0',
					\ 'c:classes:0:1',
					\ 'g:generators:0:0',
					\ 'p:properties:0:0',
					\ 'm:methods:0:1',
					\ 'f:functions:0:0',
				\ ],
				\ 'sro'			: '.',
				\ 'kind2scope'	: {
					\ 'c' : 'class',
					\ 'f' : 'function',
					\ 'm' : 'method',
					\ 'p' : 'property',
				\ },
				\ 'scope2kind'	: {
					\ 'class' : 'c',
					\ 'function' : 'f',
				\ },
			\ }

	" let g:tagbar_type_perl = {
	"             \ 'kinds' : [
	"                 \ 'c:constants:0:0',
	"                 \ 'f:formats:0:0',
	"                 \ 'l:labels:0:1',
	"                 \ 'p:packages:1:0',
	"                 \ 's:subroutines:0:1',
	"                 \ 'd:subroutineDeclaration:0:0',
	"                 \ 'M:modules:0:0',
	"             \ ],
	"             \ 'deffile' : '~/projects/tagbar-test-files/perl.ctags',
	"         \ }

	" let g:tagbar_type_asciidoc2 = {
	"             \ 'ctagstype': 'asciidoc2',
	"             \ 'deffile': '/home/dh404494/.vim/vim-asciidoc/ctags/asciidoc.cnf',
	"             \ 'sort': 0,
	"             \ 'kinds': [
	"                 \ 's:Table of Contents',
	"                 \ 'i:Included Files',
	"                 \ 'I:Images',
	"                 \ 'v:Videos',
	"                 \ 'a:Set Attributes',
	"                 \ 'A:Unset Attributes'
	"             \ ]
	"         \}

	" Tagbar Debug Options:
	" Note: when using the logfile, don't VI the file or it will overwrite what is there
	" let g:tagbar_ctags_bin = '/usr/bin/ctags' " XXX: To test with exhuberant ctags
	" let g:tagbar_logfile = $HOME . '/tagbar.log'
	" let g:tagbar_no_autocmds = 1
	" let g:tagbar_ignore_anonymous = 1
	" let g:tagbar_width = max([25, winwidth(0) / 5])
	" let g:tagbar_wrap = 2

	" ---- Syntastic Configuration {{{2
	let g:syntastic_always_populate_loc_list = 1
	let g:syntastic_auto_loc_list = 1
	let g:syntastic_check_on_open = 1
	let g:syntastic_check_on_wq = 0

	" ---- AnyFold Configuration {{{2
	let g:anyfold_fold_comments=1
	let g:anyfold_fold_display=1

	" ---- Flake8 Configuration {{{2
	let g:flake8_show_quickfix = 1
	let g:flake8_show_in_gutter = 1
	let g:flake8_show_in_file = 0
	let g:flake8_quickfix_height = 10
	let g:flake8_always_visible = 1
	let g:flake8_auto_update = 0

	" ---- Auto-pairs Configuration {{{2
	let g:AutoPairsShortcutToggle = ''
	let g:AutoPairsShortcutFastWrap = '<Leader>)'

	" ---- UndoTree Configuration {{{2
	let g:undotree_WindowLayout = 3
	let g:undotree_SplitWidth = 30
	let g:undotree_DiffpanelHeight = 20
	let g:undotree_HighlightChangedText = 0
	let g:undotree_HighlightChangedWithSign = 0
	let g:undotree_DiffAutoOpen = 0

	" ---- AutoSave Configuration {{{2
	let g:auto_save = $AUTOSAVE

	" ---- Minimap Configuration {{{2
	let g:minimap_block_filetypes = ['fugitive', 'nerdtree', 'tagbar', 'qf', 'preview', 'diff']

	" ---- DevPanel Configuration {{{2
	if $USE_DEVPANEL !=# ''
		let g:use_devpanel = $USE_DEVPANEL
	else
		let g:use_devpanel = 1
	endif
	if g:use_devpanel
		let g:devpanel_auto_open_files = '*.c,*.cpp,*.h,*.py,*.vim,Makefile,*.make,.vimrc,.bashrc,*.sh'
	else
		let g:devpanel_auto_open_files = 'no_files'
	endif
	let g:devpanel_panel_min = 40
	let g:devpanel_panel_max = 45
	let g:devpanel_open_min_width = 120
	let g:devpanel_use_nerdtree = 1
	let g:devpanel_use_tagbar = 1
	let g:devpanel_use_minimap = 0
	let g:devpanel_use_flake8 = 1

	" ---- Generic definitions used by functions for plugins {{{2
	let g:ignored_filetypes = '\v(nerdtree|tagbar|undotree|qf)'
	let g:ignored_files = '\v(hunk-preview)'

    " ---- Load Plugins {{{2
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
	" --- https://github.com/dkprice/vim-easygrep.git
	let g:have_easygrep = &runtimepath =~# 'easygrep' ? 1 : 0
	" --- https://github.com/mbbill/undotree.git
	let g:have_undotree = &runtimepath =~# 'undotree' ? 1 : 0
	" --- https://github.com/vim-scripts/searchfold.vim.git
	let g:have_searchfold = &runtimepath =~# 'searchfold' ? 1 : 0
	" --- https://github.com/wfxr/minimap.vim
	let g:have_minimap = &runtimepath =~# 'minimap' ? 1 : 0

	if g:have_tagbar && exists('g:tagbar_logfile')
		execute 'TagbarDebug ' . g:tagbar_logfile
	endif

    " ---- LightlineFileEncoding() {{{2
	function! LightlineFileEncoding()
		return &filetype =~# g:ignored_filetypes ? '' :
					\ &fenc !=# '' ? &fenc : &enc
	endfunction

    " ---- LightlineFileFormat() {{{2
	function! LightlineFileFormat()
		return winwidth(0) < 90 ? '' :
					\ &filetype =~# g:ignored_filetypes ? '' :
					\ &fileformat
	endfunction

    " ---- LightlineFilename() {{{2
	function! LightlineFilename()
		return &filetype =~# g:ignored_filetypes ? '' :
					\ expand('%:t') !=# '' ? expand('%:t') : '[No Name]'
	endfunction

    " ---- LightlineFileType() {{{2
	function! LightlineFileType()
		return &filetype !~# g:ignored_filetypes ? &filetype : ''
	endfunction

    " ---- LightlineGitgutterHunks() {{{2
	function! LightlineGitgutterHunks()
		let [a, m, r] = GitGutterGetHunkSummary()
		return printf('+%d ~%d -%d', a, m, r)
	endfunction

    " ---- LightlineMode() {{{2
	function! LightlineMode()
		return &filetype ==# 'nerdtree' ? 'File Explorer' :
					\ &filetype ==# 'tagbar' ? 'Tags' :
					\ &filetype ==# 'undotree' ? 'History' :
					\ &filetype ==# 'diff' ? 'Diffs' :
					\ exists('w:flake8_window') ? 'Python Errors/Warnings' :
					\ winwidth(0) < 90 ? get(g:short_mode_map, mode(), '') :
					\ lightline#mode()
	endfunction

    " ---- LightlineModified() {{{2
	function! LightlineModified()
		return !&modified ? '' :
					\ &filetype =~# g:ignored_filetypes ? '' :
					\ g:charmap['write']
	endfunction

    " ---- LightlineReadonly() {{{2
	function! LightlineReadonly()
		return !&readonly ? '' :
					\ &filetype =~# g:ignored_filetypes ? '' :
					\ g:charmap['lock']
	endfunction

    " ---- LightlineBranchInfo() {{{2
	function! LightlineBranchInfo()
		if !g:have_fugitive || &filetype =~# g:ignored_filetypes
			return ''
		endif
		let branch = FugitiveHead()
		return branch !=# '' ? ' '. g:charmap['branch'] . branch : ''
	endfunction

    " ---- LightlineFunctionName() {{{2
	function! LightlineFunctionName()
		if !g:have_tagbar || &filetype =~# g:ignored_filetypes
			return ''
		endif
		return tagbar#currenttag('%s', '', 'f', 'nearest-stl')
	endfunction

	let g:lineline_colorscheme = 'powerline'
	function! LightlineColorScheme(...) abort
		if !exists('g:loaded_lightline')
			return
		endif
		let color_name = a:0 > 0 ? a:1 : g:lightline_colorscheme
		try
			if color_name =~# 'powerline\|wombat\|solarized\|landscape\|jellybeans\|seoul256\|Tomorrow'
				let g:lightline.colorscheme =
							\ substitute(substitute(color_name, '-', '_', 'g'), '256.*', '', '')
				call lightline#init()
				call lightline#colorscheme()
				call lightline#update()
			endif
		catch
		endtry
	endfunction

	function! s:set_lightline_colorscheme(name) abort
		let g:lightline.colorscheme = a:name
		call lightline#init()
		call lightline#colorscheme()
		call lightline#update()
	endfunction

	function! s:lightline_colorschemes(...) abort
		return join(map(
					\ globpath(&rtp, 'autoload/lightline/colorscheme/*.vim',1,1),
					\ 'fnamemodify(v:val,":t:r")'),
					\ '\n')
	endfunction
	command! -nargs=1 -complete=custom,s:lightline_colorschemes LightlineColorscheme
				\ call s:set_lightline_colorscheme(<q-args>)


    " ---- LastOpenFileNmae() {{{2
	function! LastOpenFileName() abort
		if !exists('t:lastfilename')
			let t:lastfilename = fnamemodify(bufname('%'), ':p')
		endif
		if &filetype !~# g:ignored_filetypes
			let bufname = fnamemodify(bufname('%'), ':p')
			if bufname ==# ''
				let bufname = 'No Name'
			endif
			let t:lastfilename = bufname
		endif
		return t:lastfilename
	endfunction

	" ---- Flake8Update() {{{2
	function! Flake8Update() abort
		" The flake8 when calling the flake8 plugin via an autocmd, it appears
		" to be changing the window focus so the lightline and tagbar info
		" doesn't match what it should. So record the winnr() and switch to it
		" again when we are done, then call some update routines and redraw
		let l:win = winnr()
		call flake8#Flake8()
		execute l:win 'wincmd w'
		call lightline#update()
		call tagbar#Update()
		redraw!
	endfunction

    " ---- UpdateTitle() {{{2
	function! UpdateTitle()
		let &titlestring = 'VIM - ' . expand('%:t')
		let branch_info = ''
		if g:have_fugitive
			let branch = FugitiveHead()
			if branch !=# ''
				let branch_info = ' '. g:charmap['branch'] . ' (' . branch . ') '
			endif
		endif
		let file_info = LastOpenFileName()
		let file_info = substitute(file_info, '\/work\/' . $USER, '', '')
		let file_info = substitute(file_info, '\/home\/' . $USER, '~', '')
		let file_info = substitute(file_info, $SRC_PATH_PREFIX, '..', '')
		let &titlestring = 'VIM ' . branch_info . file_info
		set title
	endfunction

    " ---- FilterBuffer() {{{2
	function! FilterBuffer(i)
		return bufexists(a:i) && buflisted(a:i) && !(getbufvar(a:i, '&filetype') =~# g:ignored_filetypes) && !(bufname('%') =~# g:ignored_files)
	endfunction

    " ---- FilteredBuffers() {{{2
	function! FilteredBuffers()
		let l:buffers = filter(range(1, bufnr('$')), 'FilterBuffer(v:val)')
		return l:buffers
	endfunction

    " ---- BufActivateNth() {{{2
	function! BufActivateNth(bufnr) abort
		if winnr('#') > 1
			" Find the main window... don't switch to another buffer while
			" in a devpanel window
			while &readonly && &filetype =~# g:ignored_filetypes && bufname('%') =~# g:ignored_files
				execute 'wincmd w'
			endwhile
		endif
		let l:buffers = FilteredBuffers()
		if a:bufnr < len(l:buffers)
			execute 'buffer ' . l:buffers[a:bufnr]
		endif
	endfunction

    " ---- BufCloseNth() {{{2
	function! BufCloseNth(bufnr) abort
		let l:buffers = FilteredBuffers()
		if a:bufnr < len(l:buffers)
			execute 'bdelete ' . l:buffers[a:bufnr]
		endif
	endfunction

    " ---- BufClose() {{{2
	function! BufClose() abort
		" If only one buffer open and listed (ignoring hidden buffers) don't close
		let l:buffers = FilteredBuffers()
		if len(l:buffers) <= 1
			echo '...No more buffers to close'
			return
		endif
		let bufnr = bufnr('%')
		bprevious
		execute 'bdelete ' . bufnr
	endfunction

    " ---- ToggleGitHunkPreview() {{{2
	function! ToggleGitHunkPreview() abort
		for winnr in range(1, winnr('#'))
			if getwinvar(winnr, '&filetype') ==# 'diff'
				execute winnr . 'wincmd w'
				quit
				return
			endif
		endfor
		GitGutterPreviewHunk
	endfunction

    " ---- ToggleGitQuickFix() {{{2
	function! ToggleGitQuickFix() abort
		if exists('g:quickfix_window')
			unlet g:quickfix_window
			cclose
			return
		endif
		GitGutterQuickFix
		copen
		let g:quickfix_window = 1
	endfunction

    " ---- CheckForDotFiles() {{{2
	function! CheckForDotFiles() abort
		let file = expand('%:t')
		let path = expand('%:p:h')
		let githome_repo = [
					\ $HOME,
					\ $HOME . '/sbin',
					\ $HOME . '/doc',
				\ ]
		if index(githome_repo, path) !=# -1
			" let g:gitgutter_git_args = '--git-dir=' . $HOME . '/.cfg/'
			let g:gitgutter_git_args = '--git-dir=' . $HOME . '/.cfg/ --work-tree=' . $HOME
			let g:gitgutter_diff_args = '--no-index'
		else
			let g:gitgutter_git_args = ''
			let g:gitgutter_diff_args = ''
		endif
	endfunction

	" ---- Key Mappings for all plugins {{{2
	nmap <Leader>cc <plug>NERDCommenterToggle
	vmap <Leader>cc <plug>NERDCommenterToggle
	nmap <Leader>cm <plug>NERDCommenterMinimal
	vmap <Leader>cm <plug>NERDCommenterMinimal
	nmap <Leader>ci <plug>NERDCommenterInvert
	vmap <Leader>ci <plug>NERDCommenterInvert
	nmap <Leader>cy <plug>NERDCommenterYank
	vmap <Leader>cy <plug>NERDCommenterYank

	nmap <silent> <Leader>1 :call BufActivateNth(0)<CR>
	nmap <silent> <Leader>2 :call BufActivateNth(1)<CR>
	nmap <silent> <Leader>3 :call BufActivateNth(2)<CR>
	nmap <silent> <Leader>4 :call BufActivateNth(3)<CR>
	nmap <silent> <Leader>5 :call BufActivateNth(4)<CR>
	nmap <silent> <Leader>6 :call BufActivateNth(5)<CR>
	nmap <silent> <Leader>7 :call BufActivateNth(6)<CR>
	nmap <silent> <Leader>8 :call BufActivateNth(7)<CR>
	nmap <silent> <Leader>9 :call BufActivateNth(8)<CR>
	nmap <silent> <Leader>0 :call BufActivateNth(9)<CR>
	nmap <silent> <Leader>n :bn<CR>
	nmap <silent> <Leader>p :bp<CR>

	nnoremap <silent> <Leader>x :NERDTreeToggle <CR>
	nnoremap <silent> <Leader>t :TagbarToggle <CR>
	nnoremap <silent> <Leader>d :DevPanelToggle<CR>
	nnoremap <silent> <Leader>q :call BufClose()<CR>
	nnoremap <silent> <Leader>u :UndotreeToggle<CR>
	nnoremap <silent> <Leader>m :MinimapToggle<CR>

	nnoremap g] :GitGutterNextHunk<CR>
	nnoremap g. :GitGutterNextHunk<CR>:GitGutterPreviewHunk<CR>
	nnoremap g[ :GitGutterPrevHunk<CR>
	nnoremap g, :GitGutterPrevHunk<CR>:GitGutterPreviewHunk<CR>
	nnoremap gs :GitGutterStageHunk<CR>
	nnoremap gu :GitGutterUndoHunk<CR>
	nnoremap <silent> gp :call ToggleGitHunkPreview()<CR>
	nnoremap <silent> gq :call ToggleGitQuickFix()<CR>

	nnoremap <silent> t[ :TagbarJumpPrev<CR>
	nnoremap <silent> t] :TagbarJumpNext<CR>
	" nnoremap <silent> t[ :call tagbar#jumpToNearbyTag(-1, 'nearest')<CR>
	" nnoremap <silent> t] :call tagbar#jumpToNearbyTag(1, 'nearest')<CR>

	" <CTRL-UP> - Switch to window above
	" <CTRL-DOWN> - Switch to window below
	" <CTRL-LEFT> - Switch to window to the left
	" <CTRL-RIGHT> - Switch to window to the right
	nmap <silent> [1;5A :wincmd k<CR>
	nmap <silent> [1;5B :wincmd j<CR>
	nmap <silent> [1;5D :wincmd h<CR>
	nmap <silent> [1;5C :wincmd l<CR>

	if has('terminal')
		tmap <silent> [1;5A <c-w>:wincmd k<CR>
		tmap <silent> [1;5B <c-w>:wincmd j<CR>
		tmap <silent> [1;5D <c-w>:wincmd h<CR>
		tmap <silent> [1;5C <c-w>:wincmd l<CR>
	endif

	nmap <silent> <Leader>= :resize +5<CR>
	nmap <silent> <Leader>- :resize -5<CR>
	nmap <silent> <Leader>+ :vertical resize +5<CR>
	nmap <silent> <Leader>_ :vertical resize -5<CR>

	" ---- Autocmds for all plugins {{{2
	augroup vimplugins
		autocmd!

		autocmd FileType cheatsheet let g:tagbar_show_data_type = 0
		autocmd FileType cheatsheet let g:tagbar_sort = 0

		" autocmd FileType tagbar setlocal nolinebreak
		autocmd BufNewFile,BufReadPost *.txt let b:tagbar_ignore = 1

		if g:have_gitgutter
			autocmd VimEnter * call gitgutter#all(0)
		endif

		autocmd ColorScheme * call LightlineColorScheme()

		autocmd BufEnter * call UpdateTitle()
		autocmd BufWritePost *.py call Flake8Update()
		autocmd BufEnter * call CheckForDotFiles()
	augroup END

	augroup quickfixclose
		autocmd!
		autocmd WinEnter * if winnr('$') ==# 1 && &buftype ==# "quickfix"|q|endif
	augroup END

endif

" }}}1

" --- Folding utilities {{{1
" --- Folding Information {{{2
"		foldexpr return		behavior
"		0					No fold at this line
"		1, 2, ..			line set to this fold level
"		-1					use fold level of prev/next line (lowest)
"		'='					line set to fold level of previous line
"		'a1', 'a2', ..		add one, two, .. to fold level of prev line
"		's1', 's2', ..		subtrack one, two, .. to fold level of prev line
"		'<1', '<2', ..		a fold with this level ends at this line
"		'>1', '>2', ..		a fold with this level starts at this line
"
" --- LogLevelFolding Setup {{{2
let g:LogLevelFoldMap = [
			\ [ '###',			0 ],
			\ [ '\[EMERG\]',	1 ],
			\ [ '\[ALERT\]',	2 ],
			\ [ '\[CRIT\]',		3 ],
			\ [ '\[ERR\]',		4 ],
			\ [ '\[WARN\]',		5 ],
			\ [ '\[NOTICE\]',	6 ],
			\ [ '\[INFO\]',		7 ],
			\ [ '\[DEBUG\]',	8 ],
			\ [ '\[VERBOSE\]',	9 ],
			\ ]

" --- FoldLevelLog() {{{2
function! FoldLevelLog(lnum)
	let line = getline(a:lnum)
	for [level, foldlevel] in g:LogLevelFoldMap
		if line =~? level
			return foldlevel
		endif
	endfor
	return len(g:LogLevelFoldMap)
endfunction

" --- FoldLevelDiff() {{{2
function! FoldLevelDiff(lnum)
	let line = getline(a:lnum)
	if line =~# '^\(diff\) '
		return 0
	elseif line =~# '^\(---\|+++\|index\|@@\) '
		return 1
	else
		return 2
	endif
endfunction

" --- FoldLevelNewDiff() {{{2
function! FoldLevelNewDiff(lnum)
	let line = getline(a:lnum)
	if line =~# '^\(diff\)'
		return '>1'
	elseif line =~# '^index'
		return '>3'
	elseif line =~# '^@@'
		return '>2'
	else
		return '='
	endif
endfunction

" --- FoldLevelSS() {{{2
function! FoldLevelSS(lnum)
	let line = getline(a:lnum)
	if line =~# '\v(SWITCHCMD|CHASSISCMD)'
		return '>1'
	else
		return '='
	endif
endfunction

" --- FoldLevelCheatshzaeet() {{{2
function! FoldLevelCheatsheet(lnum)
	let line = getline(a:lnum)
	let nextline = a:lnum < line('$') ? getline(a:lnum + 1) : ''
	let lvl = '='
	if line =~# '^#####'
		let lvl = '>1'
	elseif line =~# '^###'
		let lvl = '>2'
	elseif line =~# '^---'
		let lvl = '>3'
	elseif nextline =~# '^#####'
		let lvl = '<1'
	elseif nextline =~# '^###'
		let lvl = '<2'
	elseif nextline =~# '^---'
		let lvl = '<2'
	endif
	" echom 'line ' . a:lnum . ' [' . line . '] lvl [' . lvl . ']'
	return lvl
endfunction

" --- FoldLevelDefine() {{{2
function! FoldLevelDefine(lnum)
	let line = getline(a:lnum)
	let lvl = '='
	if line =~# '^#if'
		let lvl = 'a1'
	elseif line =~# '^#endif'
		let lvl = 's1'
	endif
	return lvl
endfunction

" --- FoldLevelInvertSearch() {{{2
function! FoldLevelInvertSearch(lnum)
	let line = getline(a:lnum)
	let lvl = '0'
	let srch_pattern = @/

	" For empty lines, use -1
	if line =~# '^\s*$'
		let lvl = -1
	elseif line =~# srch_pattern
		let lvl = 1
	endif

	return lvl
endfunction

" --- FoldTextFmt() {{{2
function! FoldTextFmt(fmt)
	if a:fmt ==# 'tag' && g:have_tagbar						" TAG fold text
		let text = tagbar#GetTagNearLine(v:foldend, '%s', 'f')
	elseif a:fmt ==# 'null'									" NULL fold text
		let text = ''
	elseif a:fmt ==# 'log'									" LOG fold text
		for [level, foldlevel] in g:LogLevelFoldMap
			if foldlevel ==# &foldlevel
				let disp_level = level
				break
			endif
		endfor
		let text = substitute(disp_level, '[\[\]\\]', '', 'g')
	elseif a:fmt ==# 'search'								" SEARCH fold text
		let text = 'search:' . @/		" Read contents of search register into text
	elseif a:fmt ==# 'invert-search'						" INVERT-SEARCH fold text
		let text = 'invert-search:' . @/
	elseif a:fmt ==# 'block'								" BLOCK fold text
		let suba = getline(v:foldstart)
		let foldmarkerpat = join(map(split(&l:foldmarker,','), "v:val.'\\d\\='"), '\|')
		let suba = substitute(suba, foldmarkerpat, '', 'g')
		let suba = trim(substitute(suba, '\s*$', '', ''))
		let text = repeat(' ', indent(v:foldstart) - 4) . suba
		if text =~# '{$'
			let text .= ' ... }'
		endif
	else													" DEFAULT fold text
		let suba = getline(v:foldstart)
		let foldmarkerpat = join(map(split(&l:foldmarker,','), "v:val.'\\d\\='"), '\|')
		let suba = substitute(suba, foldmarkerpat, '', 'g')
		let suba = trim(substitute(suba, '\s*$', '', ''))
		let text = suba
	endif

	if strchars(text) > 0
		let text = repeat(g:charmap['fold-fillchar'], 2)
					\ . g:charmap['fold-leftchar']
					\ . ' ' . text . ' '
					\ . g:charmap['fold-rightchar']
					\ . repeat(g:charmap['fold-fillchar'], 2)
	endif
	let lines = v:foldend - v:foldstart + 1
	let lines = ' ' . lines . ' lines '
	let lines = repeat(g:charmap['fold-fillchar'], 2)
				\ . g:charmap['fold-leftchar']
				\ . lines
				\ . g:charmap['fold-rightchar']
				\ . repeat(g:charmap['fold-fillchar'], 2)
	let set_number = &number
	if set_number ==# 0
		let nuw = 0
	elseif has('float')
		let nuw = max([float2nr(log10(line('$')))+2, &numberwidth])
	else
		let nuw = &numberwidth
	endif
	let n = winwidth(winnr()) - &foldcolumn - nuw - strchars(lines)
	if strchars(text) > n
		let text = text[:n]
	endif
	let text .= repeat(g:charmap['fold-fillchar'], n - strchars(text))
	let text .= lines
	return text
endfunction

" --- SetFoldMethod() {{{2
function! SetFoldMethod(fold_method, set_level)
	let current_foldlevel = &foldlevel
	let new_foldlevel = current_foldlevel
	let new_foldmethod = a:fold_method

	if new_foldmethod ==# 'log'					" --- LOG fold method
		set foldmethod=expr
		set foldexpr=FoldLevelLog(v:lnum)
		let new_foldlevel = a:set_level ? 5 : current_foldlevel
		set foldtext=FoldTextFmt('log')
		for [level, loglevel] in g:LogLevelFoldMap
			if loglevel ==# new_foldlevel
				let disp_level = level
				break
			endif
		endfor
		echo 'Folding log-level - showing all logs ' . substitute(disp_level, '\', '', 'g') . ' (' . new_foldlevel . ') or higher...'
	elseif new_foldmethod ==# 'git'				" --- GIT fold method
		if !g:have_gitgutter
			echo 'GitGutter plugin not installed...'
			return
		endif
		let [a,m,r] = GitGutterGetHunkSummary()
		echo 'GIT fold... +' . a . ' ~' . m . ' -' . r
					\ . ' (may take a while depending on size of changes)'
		call gitgutter#fold#enable()
		if g:have_tagbar
			set foldtext=FoldTextFmt('tag')
		else
			set foldtext=gitgutter#fold#foldtext()
		endif
		let new_foldlevel = 1
		redraw | echo 'GIT fold... +' . a . ' ~' . m . ' -' . r
	elseif new_foldmethod ==# 'invert-search'	" --- INVERT-SEARCH fold method
		let new_foldlevel=0
		set foldmethod=expr
		set foldexpr=FoldLevelInvertSearch(v:lnum)
		set foldtext=FoldTextFmt('invert-search')
		echo 'Invert-Search fold...'
	elseif new_foldmethod ==# 'search'			" --- SEARCH fold method
		if !g:have_searchfold
			echo 'SearchFold plugin not installed...'
			return
		endif
		call SearchFold(0) " Call SearchFold() for normal mode
		let new_foldlevel=2
		if &filetype ==# 'log'
			set foldtext=FoldTextFmt('search')
		else
			set foldtext=FoldTextFmt('tag')
		endif
	elseif new_foldmethod ==# 'search-word'		" --- SEARCH-WORD fold method
		if !g:have_searchfold
			echo 'SearchFold plugin not installed...'
			return
		endif
		let @/ = expand('<cword>')	" Set search pattern to current word
		call SearchFold(0)			" Call SearchFold() for normal mode
		let new_foldlevel=2
		let new_foldmethod='search'	" 'search-word' is really the same as 'search'
		if &filetype ==# 'log'
			set foldtext=FoldTextFmt('search')
		else
			set foldtext=FoldTextFmt('tag')
		endif
	elseif new_foldmethod ==# 'indent'			" --- INTEND fold method
		set foldmethod=indent
		set foldtext=FoldTextFmt('null')
		let new_foldlevel=0
		echo 'Indent fold...'
	elseif new_foldmethod ==# 'diff'			" --- DIFF fold method
		set foldmethod=expr
		set foldexpr=FoldLevelDiff(v:lnum)
		set foldtext=FoldTextFmt('null')
		let new_foldlevel=1
	elseif new_foldmethod ==# 'newdiff'			" --- NEWDIFF fold method
		set foldmethod=expr
		set foldexpr=FoldLevelNewDiff(v:lnum)
		set foldtext=FoldTextFmt('')
		let new_foldlevel=1
	elseif new_foldmethod ==# 'syntax'			" --- SYNTAX fold method
		set foldmethod=syntax
		set foldtext=FoldTextFmt('block')
		let new_foldlevel=0
		echo 'Syntax fold...'
	elseif new_foldmethod ==# 'cheatsheet'		" --- CHEATSHEET fold method
		set foldmethod=expr
		set foldexpr=FoldLevelCheatsheet(v:lnum)
		set foldtext=FoldTextFmt('')
		let new_foldlevel=1
		echo 'Cheatsheet fold...'
	elseif new_foldmethod ==# 'define'			" --- DEFINE fold method
		set foldmethod=expr
		set foldexpr=FoldLevelDefine(v:lnum)
		set foldtext=FoldTextFmt('')
		let new_foldlevel=0
		echo 'Define fold...'
	elseif new_foldmethod ==# 'manual'			" --- MANUAL fold method
		set foldmethod=manual
		set foldtext=FoldTextFmt('')
		let new_foldlevel=0
		echo 'Manual fold...'
	elseif new_foldmethod ==# 'marker'			" --- MARKER fold method
		set foldmethod=marker
		set foldtext=FoldTextFmt('')
		let new_foldlevel=1
		echo 'Marker fold...'
	elseif new_foldmethod ==# 'ssave'			" --- SSAVE fold method
		set foldmethod=expr
		set foldexpr=FoldLevelSS(v:lnum)
		set foldtext=FoldTextFmt('')
		let new_foldlevel=0
		echo 'SSave fold...'
	elseif new_foldmethod ==# 'default'			" --- DEFAULT fold method
		set foldmethod=manual
		set foldtext=FoldTextFmt('')
		let new_foldlevel=0
	endif

	if a:set_level
		execute 'set foldlevel=' . new_foldlevel
	else
		execute 'set foldlevel=' . current_foldlevel
	endif

	let b:fold_method = new_foldmethod
endfunction

" --- ToggleFold() {{{2
function! ToggleFold(fold_method)
	if exists('b:fold_method') && b:fold_method ==# a:fold_method
		set foldlevel=99
		unlet b:fold_method
		echo 'All folds disabled'
		return
	endif

	call SetFoldMethod(a:fold_method, 1)
endfunction

" --- FoldUsage() {{{2
function! FoldUsage()
	if !exists('g:mapleader')
		let leader = '\'
	elseif g:mapleader ==? '\<Space>'
		let leader = '<Space>'
	elseif g:mapleader ==? '\<Tab>'
		let leader = '<Tab>'
	else
		let leader = g:mapleader
	endif

	echo 'Folding Usage:'
	echo '  ' . leader . 'zw   - Set [SEARCH] pattern to word under cursor and toggle search fold method'
	echo '  ' . leader . 'zs   - Toggle [SEARCH] fold method to fold based on the current search pattern which matches the current search pattern'
	echo '  ' . leader . 'zis  - Toggle [INVERT-SEARCH] fold method to fold based on the current search pattern which matches anything except the current search pattern'
	echo '  ' . leader . 'zl   - Toggle [LOG-LEVEL] fold method. Sets fold levels for `[VERBOSE]` / `[DEBUG]` / etc. Default fold level is `[WARN]` and higher'
	echo '  ' . leader . 'zg   - Activate the [GIT] method to fold all text around the current changes in the open file'
	echo '  ' . leader . 'zy   - Toggle [SYNTAX] fold method. Useful for showing only function names or other block level folds. Better folding for matching blocks than indent.'
	echo '  ' . leader . 'zi   - Toggle [INDENT] fold method. Useful for showing only function names.'
	echo '  ' . leader . 'zd   - Toggle [DIFF] fold method. Use this when examining output of `diff <file1> <file2> > diff-file` command output.'
	echo '  ' . leader . 'zD   - Toggle [DEFINE] fold method. This will set fold markers based on the `#if` / `#endif` statements in a file. This will work with both `#if SOMETHING` or `#ifdef SOMETHING` syntax'
	echo '  ' . leader . 'zC   - Toggle [CHEATSHEET] fold method. See .vim/syntax/cheatsheet.vim for syntax details.'
	echo '  ' . leader . 'zm   - Toggle [MANUAL] fold method. This can be used with `zf` to create manual folds.'
	echo '  ' . leader . 'zM   - Toggle [MARKER] fold method.'
	echo '  ' . leader . 'zz   - Recompute current fold method. Does not change fold level, but updates current fold method to recompute for any changes.'
	echo '  z,    - Decrease current foldlevel by one reducing the amount of context around a fold'
	echo '  z.    - Increase current foldlevel by one increasing the amount of context around a fold'
	echo '  z,,   - Set foldlevel to 0 (close all folds)'
	echo '  z..   - Set foldlevel to 99 (open all folds to level 99)'
	echo '  za    - Toggle a fold open / closed under the cursor'
	echo '  zA    - Toggle all folds open / closed under the cursor'
	echo '  z<#>  - Set the foldlevel to `<#>`. Ex: `z3` will set the fold level to 3'
	echo '  zf    - Create a fold around the selected text (MANUAL only)'
	echo '  zd    - Delete the fold under the cursor (MANUAL only)'
	echo '  zE    - Deletes all folds (MANUAL only)'
endfunction

" --- Folding keymaps and other fold init {{{2
nnoremap <silent> <Leader>zw :call ToggleFold('search-word')<CR>
nnoremap <silent> <Leader>zs :call ToggleFold('search')<CR>
nnoremap <silent> <Leader>zy :call ToggleFold('syntax')<CR>
nnoremap <silent> <Leader>zl :call ToggleFold('log')<CR>
nnoremap <silent> <Leader>zg :call ToggleFold('git')<CR>
nnoremap <silent> <Leader>zi :call ToggleFold('indent')<CR>
nnoremap <silent> <Leader>zis :call ToggleFold('invert-search')<CR>
nnoremap <silent> <Leader>zd :call ToggleFold('diff')<CR>
nnoremap <silent> <Leader>zdd :call ToggleFold('newdiff')<CR>
nnoremap <silent> <Leader>zD :call ToggleFold('define')<CR>
nnoremap <silent> <Leader>zC :call ToggleFold('cheatsheet')<CR>
nnoremap <silent> <Leader>zm :call ToggleFold('manual')<CR>
nnoremap <silent> <Leader>zM :call ToggleFold('marker')<CR>
nnoremap <silent> <Leader>zS :call ToggleFold('ssave')<CR>
nnoremap <silent> <Leader>zz :call SetFoldMethod(exists('b:fold_method') ? b:fold_method : 'default', 0)<CR>

nnoremap <Leader>z? :call FoldUsage()<CR>
nnoremap z? :call FoldUsage()<CR>

" Decrease / Increase fold level
nmap z, zm \| :echo 'set foldlevel=' . &foldlevel <CR>
nmap z. zr \| :echo 'set foldlevel=' . &foldlevel <CR>
nmap z,, :set foldlevel=0  \| echo 'set foldlevel=' . &foldlevel <CR>
nmap z.. :set foldlevel=99 \| echo 'set foldlevel=' . &foldlevel <CR>
nmap z0 :set foldlevel=0 \| echo 'set foldlevel=' . &foldlevel <CR>
nmap z1 :set foldlevel=1 \| echo 'set foldlevel=' . &foldlevel <CR>
nmap z2 :set foldlevel=2 \| echo 'set foldlevel=' . &foldlevel <CR>
nmap z3 :set foldlevel=3 \| echo 'set foldlevel=' . &foldlevel <CR>
nmap z4 :set foldlevel=4 \| echo 'set foldlevel=' . &foldlevel <CR>
nmap z5 :set foldlevel=5 \| echo 'set foldlevel=' . &foldlevel <CR>
nmap z6 :set foldlevel=6 \| echo 'set foldlevel=' . &foldlevel <CR>
nmap z7 :set foldlevel=7 \| echo 'set foldlevel=' . &foldlevel <CR>
nmap z8 :set foldlevel=8 \| echo 'set foldlevel=' . &foldlevel <CR>
nmap z9 :set foldlevel=9 \| echo 'set foldlevel=' . &foldlevel <CR>

let c_no_comment_fold = 1
call SetFoldMethod('default', 1)		" Default to manual folding

augroup folding
	autocmd FileType cheatsheet setlocal foldmethod=expr foldexpr=FoldLevelCheatsheet(v\:lnum) foldlevel=2
augroup END
" }}}1

" --- Utility Functions {{{1
" --- ToggleHex Setup {{{2

"<Ctrl-H> - convert file to hex
map <silent>  :call ToggleHex()<CR>
" ex command for toggling hex mode - define mapping if desired
command -bar ToggleHex call ToggleHex()

" helper function to toggle hex mode
function ToggleHex()
  " hex mode should be considered a read-only operation
  " save values for modified and read-only for restoration later,
  " and clear the read-only flag for now
  let l:modified=&mod
  let l:oldreadonly=&readonly
  let &readonly=0
  let l:oldmodifiable=&modifiable
  let &modifiable=1
  if !exists('b:editHex') || !b:editHex
    " save old options
    let b:oldft=&ft
    let b:oldbin=&bin
    " set new options
    setlocal binary " make sure it overrides any textwidth, etc.
    silent :e " this will reload the file without trickeries 
              "(DOS line endings will be shown entirely )
    let &ft='xxd'
    " set status
    let b:editHex=1
    " switch to hex editor
    %!xxd -g 4
  else
    " restore old options
    let &ft=b:oldft
    if !b:oldbin
      setlocal nobinary
    endif
    " set status
    let b:editHex=0
    " return to normal editing
    %!xxd -r
  endif
  " restore values for modified and read only state
  let &mod=l:modified
  let &readonly=l:oldreadonly
  let &modifiable=l:oldmodifiable
endfunction

" --- GenerateUnicode() {{{2
function! GenerateUnicode(first, last)
	let i = a:first
	while i <= a:last
		if (i%256 ==# 0)
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

" --- Toggle Unicode {{{2
"  This function can be used to toggle the character maps to set them to
"  unicode or normal. This can be useful if doing a copy/paste of folded text
"  so the unicode characters don't end up getting copied.
function! ToggleUnicode()
	if g:use_unicode
		let g:charmap = g:charmap_normal
		let g:nummap = g:nummap_normal
		let g:use_unicode = 0
	else
		let g:charmap = g:charmap_unicode
		let g:nummap = g:nummap_unicode
		let g:use_unicode = 1
	endif
	redraw!
endfunction
command! -nargs=0 ToggleUnicode call ToggleUnicode()
command! -nargs=0 UnicodeToggle call ToggleUnicode()

" --- CleanWhiteSpace {{{2
"  This function can be used to clear whitespace at the end of the line.
function! CleanWhiteSpace()
	silent! execute '%s/\s\+$//e'
endfunction
command! -nargs=0 CleanWhiteSpace call CleanWhiteSpace()

" --- CleanFile {{{2
"  This function can be used to run a series of cleanup routines on
"  the file to ensure proper formatting.
function! CleanFile()
	call CleanWhiteSpace()
	if g:have_autoformat
        if !has('python') && !has('python3')
            echohl WarningMsg |
                \ echomsg 'WARNING: vim has no support for python, but it is required to run the formatter!' |
                \ echohl None
            return 1
        endif
		silent! execute ':Autoformat'
	endif
endfunction
command! -nargs=0 CleanFile call CleanFile()

" --- Search and fold {{{2
"  This function will search for a pattern, then set the fold method to
"  search-fold for all buffers
function! SearchAndFold(pattern)
	let @/ = a:pattern	" Set search pattern to passed in pattern
	execute 'bufdo execute ":call SetFoldMethod(''search'', 1)"'
	call BufActivateNth(0)
endfunction
command! -nargs=+ SearchAndFold call SearchAndFold(<q-args>)
" }}}1

" --- Modeline {{{1
" vim: foldenable foldmethod=marker foldlevel=1
