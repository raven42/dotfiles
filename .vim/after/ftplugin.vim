"----- ftplugin file
"----- Execute after VIM loads all plugins

" --- Reset python tabs to 4
augroup python
	" --- ftype/python.vim overwrites this
	autocmd FileType python setlocal ts=4 sts=4 sw=4 expandtab formatoptions=crnqjo
augroup end

augroup markdown
	autocmd FileType markdown setlocal ts=4 sts=4 sw=4 expandtab
augroup end
