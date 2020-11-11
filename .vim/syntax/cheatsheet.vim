" Vim syntax file
" Language:		Cheatsheed
" Maintainer:	David Hegland <dhegland@brocade.com>
" Last Change:	2020 Nov 10
"
" Basic syntax is as follows:
"	Line starts with '##### some string'	This is a header line - fold level 1
"	Line starts with '### some string'		This is a section line - fold level 2
"	Line starts with '--- some string'		This is an unused section line - fold level 3
"	Line contains '# some string'			This is a comment except where previously defined
"
" See FoldLevelCheatsheet() for determining fold levels.

" Quit when a (custom) syntax file was already loaded
if exists("b:current_syntax")
	finish
endif

let valid_title = "[a-zA-Z0-9 \t\\-]\+"
" Define the various log levels
syntax	match	CHEATSHEET_HEADER			"^##### .*"						contains=CHEATSHEET_HEADER_TITLE containedin=CHEATSHEET_COMMENT
syntax	match	CHEATSHEET_HEADER_TITLE		"[a-zA-Z0-9 \t\\/\(\).,:;]\+"	contained
syntax	match	CHEATSHEET_SECTION			"^### .*"						contains=CHEATSHEET_SECTION_TITLE containedin=CHEATSHEET_COMMENT
syntax	match	CHEATSHEET_SECTION_TITLE	"[a-zA-Z0-9 \t\\/\(\).,;:]\+"	contained
syntax	match	CHEATSHEET_UNUSED			"^--- .*"						contains=CHEATSHEET_UNUSED_TITLE containedin=CHEATSHEET_COMMENT
syntax	match	CHEATSHEET_UNUSED_TITLE		"[a-zA-Z0-9 \t\\/\(\).,;:]\+"	contained
syntax	match	CHEATSHEET_COMMENT			"#.*$"
syntax	match	CHEATSHEET_COMMENT			"^-.*$"

highlight		CHEATSHEET_HEADER			ctermfg=Red
highlight		CHEATSHEET_HEADER_TITLE		ctermfg=Yellow
highlight		CHEATSHEET_SECTION			ctermfg=Red
highlight		CHEATSHEET_SECTION_TITLE	ctermfg=DarkYellow
highlight		CHEATSHEET_UNUSED			ctermfg=DarkRed
highlight		CHEATSHEET_UNUSED_TITLE		ctermfg=Grey
highlight		CHEATSHEET_COMMENT			ctermfg=202

let b:current_sytax = "cheatsheet"
