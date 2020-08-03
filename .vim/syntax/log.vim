" Vim syntax file
" Language:		Log
" Maintainer:	David Hegland <dhegland@brocade.com>
" Last Change:	2013 Nov 22

" Quit when a (custom) syntax file was already loaded
if exists("b:current_syntax")
	finish
endif

" Define the various log levels
syn	match		logEmerg		display ".*EMERG.*"
syn match		logAlert		display ".*ALERT.*"
syn match		logCrit			display ".*CRIT.*"
syn match		logError		display ".*ERR.*"
syn match		logWarn			display ".*WARN.*"
syn match		logNotice		display ".*NOTICE.*"
syn match		logInfo			display	".*INFO.*"
syn match		logDebug		display ".*DEBUG.*"
syn match		logVerbose		display ".*VERBOSE.*"

" Other syntax
syn match		logComment		"^#.*$"

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

highlight		logComment		ctermfg=Magenta

let b:current_sytax = "log"
