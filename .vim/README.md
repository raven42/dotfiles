# .vim/
VIM resource and configuration directory.

This directory sets up and configures vim using various plugins. It integrates them all together.

# Basic usage
Basic usage and navigation uses the standard vim movement keys and also uses the mouse to move between windows, select text in visual mode, and move the cursor. There are also some useful key mappings to move between windows.
> <Ctrl-Up> - Move to the window above the current one.
> <Ctrl-Down> - Move to the window below the current one.
> <Ctrl-Left> - Move to the window to the left of the current one.
> <Ctrl-Right> - Move to the window to the right of the current one.
> <Leader># - Move to the open buffer as signified by `#`.
> <Leader>g - Activate the GitGutter fold method to fold all text around the current changes in the open file.
> <Leader>cc - Toggle a comment block around the currently selected code in visual mode.
>> Note: All these <Leader> commands are done using the `\` key. Example `\1` will jump to the first open buffer.

## NERDTree
The NERDTree plugin provides a file browser for any files. Double-click on any file to open it in a new buffer. Single-click on any directory to expand / collapse it.

## Tagbar
The Tagbar plugin will use ctags to populate a window with any tags from the current file. Double-click on any tag to jump to it.

## DevPanel
The DevPanel plugin will automatically open the NERDTree and Tagbar plugin windows and arrange them accordingly.

## Lightbar
The Lightbar plugin will display useful information about the currently opened file. It will display the file, the current function the cursor is located in (in the bottome status line), a list of the open buffers (on the left side of the tabline), and the current working GIT branch (on the right side of the tabline) if available.

## GitGutter
The GitGutter plugin will display information about the added / modified / removed git hunks in the current file.

Lines that have been added will be highlighted on the left side of the file window with two green left arrows.

Lines that have been modified will be highlighted on the left side of the file window with a blue left then right arrow.

Lines that have been deleted will be highlighted on the left side of the file window with two red right arrows (note: the highlight will occur on the line prior to the deletion).

The following plugins are included in this configuration:
> <https://github.com/raven42/devpanel-vim>  
> <https://github.com/raven42/indentpython.vim>  
> <https://github.com/itchyny/lightline.vim>  
> <https://github.com/mengelbrecht/lightline-bufferline>  
> <https://github.com/preservim/nerdtree>  
> <https://github.com/preservim/nerdcommenter>  
> <https://github.com/raven42/tagbar>  
> <https://github.com/vim-scripts/searchfold.vim>  
> <https://github.com/nvie/vim-flake8>  
> <https://github.com/tpope/vim-fugitive>  
> <https://github.com/airblade/vim-gitgutter>  
> <https://github.com/roxma/vim-paste-easy>  
> <https://github.com/Chiel92/vim-autoformat>  
