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

augroup quickfix
	autocmd!
    autocmd FileType qf setlocal nobuflisted
augroup end

augroup yang
	autocmd FileType yang setlocal ts=2 sts=2 sw=2 expandtab
augroup end
