" custom filetype

if exists("did_load_filetypes")
	finish
endif

augroup	filetypedetect
	au!	BufRead,BufNewFile	*.log				setfiletype	log
	au!	BufRead,BufNewFile	*.log.[0-9]*		setfiletype	log
	au! BufRead,BufNewFile	*.cheat				setfiletype cheatsheet
	au!	BufRead,BufNewFile	*.gdb				setfiletype	gdb
	au! BufRead,BufNewFile	*.colors,*.color	setfiletype 256colors
augroup	END
