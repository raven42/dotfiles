" Vim syntax file
" Language:		Cheatsheed
" Maintainer:	David Hegland <dhegland@brocade.com>
" Last Change:	2020 Nov 10
"
" Basic syntax is as follows:
"	Line starts with '##### some string'	This is a header line
"	Line starts with '### some string'		This is a section line
"	Line starts with '--- some string'		This is an unused section line
"	Line contains '# some string'			This is a comment string except where previously defined

" Quit when a (custom) syntax file was already loaded
if exists("b:current_syntax")
	finish
endif

let valid_title = "[a-zA-Z0-9 \t\\-]\+"
" Define the various log levels
syntax	match	HEADER			"^##### .*"						contains=HEADER_TITLE containedin=COMMENT
syntax	match	HEADER_TITLE	"[a-zA-Z0-9 \t\\/\(\).,:;]\+"	contained
syntax	match	SECTION			"^### .*"						contains=SECTION_TITLE containedin=COMMENT
syntax	match	SECTION_TITLE	"[a-zA-Z0-9 \t\\/\(\).,;:]\+"	contained
syntax	match	UNUSED			"^--- .*"						contains=UNUSED_TITLE containedin=COMMENT
syntax	match	UNUSED_TITLE	"[a-zA-Z0-9 \t\\/\(\).,;:]\+"	contained
syntax	match	COMMENT			"#.*$"

highlight		HEADER			ctermfg=Red
highlight		HEADER_TITLE	ctermfg=Yellow
highlight		SECTION			ctermfg=Red
highlight		SECTION_TITLE	ctermfg=DarkYellow
highlight		UNUSED			ctermfg=DarkRed
highlight		UNUSED_TITLE	ctermfg=Grey
highlight		COMMENT			ctermfg=202

let b:current_sytax = "cheatsheet"
