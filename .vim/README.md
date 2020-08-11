# .vim/
VIM resource and configuration directory.

This directory sets up and configures vim using various plugins. It integrates them all together.

# Basic usage
Basic usage and navigation uses the standard vim movement keys and also uses the mouse to move between windows, select text in visual mode, and move the cursor. There are also some useful key mappings to move between windows.
| Key Sequence | Description |
| --- | --- |
| `<Ctrl-Up>` | Move to the window above the current one. |
| `<Ctrl-Down>` | Move to the window below the current one. |
| `<Ctrl-Left>` | Move to the window to the left of the current one. |
| `<Ctrl-Right>` | Move to the window to the right of the current one. |
| `<Leader><#>` | Move to the open buffer as signified by `#`. (Example: `\2`) |
| `<Leader>cc` | Toggle a comment block around the currently selected code in visual mode. |
| `<Leader>cm` | Comment a block of code using minimal comments |
| `<Leader>ci` | Invert selected code: Comment any uncommented code, and uncomment any commented code |
| `<Leader>cy` | Yank selected code into clipboard and then comment out |
| `<Leader>d` | Toggle the File Explorer (NERDTree) and Tag (Tagbar) windows |
| `<Leader>-` | Resize the current window making it 5 characters less in height |
| `<Leader>=` | Resize the current window making it 5 characters more in height |
| `<Leader>\_` | Resize the current window making it 5 character less in width |
| `<Leader>+` | Resize the current window making it 5 character more in width |
| `<Leader>q` | Close the current buffer :construction: (Not yet fully funcitonal) |
| `<Leader>g` | Activate the GitGutter fold method to fold all text around the current changes in the open file. |
| `z,` | Decrease current foldlevel by one reducing the amount of context around a fold |
| `z.` | Increase current foldlevel by one increasing the amount of context around a fold |
| `z,,` | Set foldlevel to 0 (close all folds) |
| `z..` | Set foldlevel to 99 (open all folds to level 99) |
| `za` | Toggle a fold open / closed |
| `<Ctrl-h>` | Toggle Hex mode. |

> :information\_source: **Leader:** All these `<Leader>` commands are done using the `\` key by default. Example `\1` will jump to the first open buffer. This can be changed in your .vimrc if you wish to use a different `<Leader>` character by adding a `:let mapleader = "<character>"`.
  
> :warning: **Folding:** Activating some foldmethods might take a while to activate.

---

## DevPanel
The DevPanel plugin will automatically open the NERDTree and Tagbar plugin windows and arrange them accordingly.
![devpanel vim example](../img/devpanel\_example.png?raw=true "DevPanel Example:")

---

## NERDTree
The NERDTree plugin provides a file browser for any files. `<double-click>` or hit `<enter>` on any file to open it in a new buffer. `<single-click>` or hit `<enter>` on any directory to expand / collapse it. When a file is opened, it will open in a new buffer. The tabline will be updated to list that file name as well. Use `<Leader><#>` or `:n` / `:p` to move between opened buffers.

If you do a `<middle-click>` on a file, then the current edit window will be split horizontally and the new file will be opened in the split.

> :construction: **Example:** coming soon...

### Bookmarks
The NERDTree plugin provides a bookmark feature which can provide a quick access to directories of your choice. One downside of this though is it cannot resolve any environment variables in the path name. To help facilitate this, a per-repository specific bookmark file can be generated using a defaults file. This functionality has been added to automatically generate the bookmarks file on sourcing the `[.bashrc](../.bashrc)` script. This is done by using the `[bin/gen\_nerdtree\_bookmarks.py](../bin/gen\_nerdtree\_bookmarks.py)` script along with a defaults file located at `${HOME}/.default/NERDTreeDefaultBookmarks` file.

To add bookmarks, modify the `.default/NERDTreeDefaultBookmarks` file to include any bookmarks you want to add. The format should be the name of your bookmark (cannot include spaces), then a single space followed by the path to the file. If an environment variable is needed, you can add that in with a `${<env-var>}` type syntax. The path should be an absolute path.

Example:
```
source-directory /home/<user>/project/source
build-directory ${HOME}/build
projects ${GIT\_ROOT}/projects
```

This will generate a file at `${GIT\_ROOT}/.rc/NERDTreeBookmarks` which will contain the following:
```
source-directory /home/<user>/project/source
build-directory /home/<user>/build
projects /work/<user>/<repo>/projects
```

---

## Tagbar
The Tagbar plugin will use ctags to populate a window with any tags from the current file. `<double-click>` or hit `<enter>` on any tag to jump to it. `<single-click>` or move the cursor over any function and the full prototype will be listed below the statusline. When the cursor is over a particular tag, you can open it in a preview window by hitting the `P` (`<shift>p`) key.

### Shortcuts
The following shortcuts all work in the Tagbar window.
| Tagbar Shortcuts | Description |
| --- | --- |
| `<enter>` | Go to tag under cursor |
| `<double-click>` | Go to tag under cursor |
| `s` | Toggle tag sorting method between file order and name order |
| `x` | Toggle zoom mode (increase the Tagbar window to full screen width or to normal size). |
| `P` | Open the selected tag in the preview window. |
> :construction: **Example:** coming soon...

---

## Lightbar
The Lightbar plugin will display useful information about the currently opened file. It will display the file, the current function the cursor is located in (in the bottome status line), a list of the open buffers (on the left side of the tabline), and the current working GIT branch (on the right side of the tabline) if available.
> :construction: **Example:** coming soon...

---

## GitGutter
The GitGutter plugin will display information about the added / modified / removed git hunks in the current file.

Lines that have been added will be highlighted on the left side of the file window with two green left arrows.
> :construction: **Example:** coming soon...

Lines that have been modified will be highlighted on the left side of the file window with a blue left then right arrow.
> :construction: **Example:** coming soon...

Lines that have been deleted will be highlighted on the left side of the file window with two red right arrows (note: the highlight will occur on the line prior to the deletion).
> :construction: **Example:** coming soon...

---

## NERDCommenter
The NERDCommenter plugin allows for quickly commenting / uncommenting a block of code or lines of code. This is most easily done in `Visual` mode by selecting text with the mouse (with `set mouse=a` in your .vimrc), or by hitting the `v` key and using the cursor to select the desired text. The following key sequences will have various modes of commenting the code.
| Key Sequence | Command | Description | Example |
| --- | --- | --- | --- |
| `<Leader>cc` | Comment Toggle | This will toggle a comment block. Either inserting the normal comments if not currently commented, or uncomment the block if it is already commented | :construction: coming soon... |
| `<Leader>cm` | Minimal Comment | This will add a single comment start / end at the beginning / end of the selected block. | :construction: coming soon... |
| `<Leader>ci` | Comment Invert | This will invert the commented code. The commented code selected will be uncommented, the uncommented code will be commented. | :construction: coming soon... |
| `<Leader>cy` | Yank Comment | This will yank the selected code putting a copy of that code into the clipboard, and then comment out the selected code. | :construction: coming soon... |

## Additional Plugins
To add any additional plugins, you can automatically add / load them by doing the following:

```
cd ~/.vim/pack/plugins/start
githome submodule add <plugin-url>
githome commit -m "Added plugin <plugin>"
```
> :warning: **User Config:** After cloning the remote repo, you may want to set a specific username/email for that repository if using a different github server or account.
```
cd <plugin>
git config --local user.name '<user>'
git config --local user.email '<email>'
```

---

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
