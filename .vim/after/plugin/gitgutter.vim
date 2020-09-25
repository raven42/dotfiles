
" Disable the cursor move autocmd as it seems to be causing issues with
" cursor movement delays
if g:have_gitgutter
	autocmd! gitgutter CursorMoved
endif
