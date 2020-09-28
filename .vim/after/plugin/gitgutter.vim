
" Disable the cursor move autocmd as it seems to be causing issues with
" cursor movement delays
if &runtimepath =~# 'gitgutter'
	autocmd! gitgutter CursorMoved
endif
