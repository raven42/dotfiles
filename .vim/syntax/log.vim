" Vim syntax file
" Language:		Log
" Maintainer:	David Hegland <dhegland@brocade.com>
" Last Change:	2013 Nov 22

" Quit when a (custom) syntax file was already loaded
if exists('b:current_syntax')
	finish
endif

" Define the various log levels
syn	match		logEmerg		".*EMERG.*"		contains=logComment
syn match		logAlert		".*ALERT.*"		contains=logComment
syn match		logCrit			".*CRIT.*"		contains=logComment
syn match		logError		".*ERR.*"		contains=logComment
syn match		logWarn			".*WARN.*"		contains=logComment
syn match		logNotice		".*NOTICE.*"	contains=logComment
syn match		logInfo			".*INFO.*"		contains=logComment
syn match		logDebug		".*DEBUG.*"		contains=logComment
syn match		logVerbose		".*VERBOSE.*"	contains=logComment

" Other syntax
syn match		logComment		"#.*$"

"hi def link		logDebug		Comment
"hi def link		logVerbose		Ignore

highlight		logEmerg		ctermfg=White ctermbg=Red
highlight		logAlert		ctermfg=White ctermbg=Red
highlight		logCrit			ctermfg=Red
highlight		logError		ctermfg=Red
highlight		logWarn			ctermfg=Yellow
highlight		logNotice		ctermfg=Cyan
highlight		logInfo			ctermfg=White
highlight		logDebug		ctermfg=145
highlight		logVerbose		ctermfg=242

highlight		logComment		ctermfg=202

let b:current_sytax = 'log'
