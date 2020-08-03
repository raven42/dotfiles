call NERDTreeAddKeyMap({
		\ 'key': '<CR>',
		\ 'scope': "Node",
		\ 'callback': 'OpenDirInNewTab',
		\ 'quickhelpText': 'open node' })
call NERDTreeAddKeyMap({
		\ 'key': '<2-LeftMouse>',
		\ 'scope' : 'FileNode',
		\ 'callback' : 'OpenFileInNewTab',
		\ 'quickhelpText' : 'open file in new tab',
		\ 'override' : 1 })

" FUNCTION: s:openDirInNewTab(target) {{{1
function! OpenDirInNewTab(node)
	if a:node.path.isDirectory
		call a:node.activate()
	else
		call a:node.activate({'where': 't'})
		call g:NERDTreeCreator.CreateMirror()
		wincmd l
	endif
endfunction

" FUNCTION: s:openDirInNewTab(target) {{{1
function! OpenFileInNewTab(target)
	let l:opener = g:NERDTreeOpener.New(a:target.path, {'where': 't'})
    call l:opener.open(a:target)
endfunction
