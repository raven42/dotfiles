# .vim/
VIM resource and configuration directory.

This directory sets up and configures vim using various plugins. It integrates them all together.

# Basic usage
Basic usage and navigation uses the standard vim movement keys and also uses the mouse to move between windows, select text in visual mode, and move the cursor. There are also some useful key mappings to move between windows. This vim configuration is optimized for 175 character wide screens or more using the DevPanel plugin will yield about 120 characters in the active edit window.

### Key Shortcuts
```
<Ctrl-Up>    - Move to the window above the current one.
<Ctrl-Down>  - Move to the window below the current one.
<Ctrl-Left>  - Move to the window to the left of the current one.
<Ctrl-Right> - Move to the window to the right of the current one.
<Leader><#>  - Move to the open buffer as signified by `#`. (Example: `\2`)
<Leader>n    - Move to the next buffer
<Leader>p    - Move to the previous buffer
<Leader>cc   - Toggle a comment block around the currently selected code in visual mode.
<Leader>cm   - Comment a block of code using minimal comments
<Leader>ci   - Invert selected code: Comment any uncommented code, and uncomment any commented code
<Leader>cy   - Yank selected code into clipboard and then comment out
<Leader>-    - Resize the current window making it 5 characters less in height
<Leader>=    - Resize the current window making it 5 characters more in height
<Leader>_    - Resize the current window making it 5 character less in width
<Leader>+    - Resize the current window making it 5 character more in width
<Leader>q    - Close the current buffer
<Leader>d    - Toggle the DevPanel showing the File Explorer, Tag, and if needed the Python Syntax Checker panels
<Leader>x    - Toggle the File Explorer panel
<Leader>t    - Toggle the Tag panel
<Leader>u    - Toggle the undo history panel
<Leader>vv   - Grep for the word under the cursor, match all occurences
<Leader>va   - Like vv, but add to existing list
<Leader>vr   - Perform a global search on the word under the cursor and prompt for a pattern with which to replace it.
```

### Folding Shortcuts
```
<Leader>zw   - Set [SEARCH] pattern to word under cursor and toggle search fold method
<Leader>zs   - Toggle [SEARCH] fold method to fold based on the current search pattern
<Leader>zl   - Toggle [LOG-LEVEL] fold method. Sets fold levels for `[VERBOSE]` / `[DEBUG]` / etc. Default fold level is `[WARN]` and higher
<Leader>zg   - Activate the [GIT] method to fold all text around the current changes in the open file
<Leader>zy   - Toggle [SYNTAX] fold method. Useful for showing only function names or other block level folds. Better folding for matching blocks than indent.
<Leader>zi   - Toggle [INDENT] fold method. Useful for showing only function names.
<Leader>zd   - Toggle [DIFF] fold method. Use this when examining output of `diff <file1> <file2> > diff-file` command output.
<Leader>zm   - Toggle [MANUAL] fold method. This can be used with `zf` to create manual folds.
<Leader>zz   - Recompute current fold method. Does not change fold level, but updates current fold method to recompute for any changes.
z,   - Decrease current foldlevel by one reducing the amount of context around a fold
z.   - Increase current foldlevel by one increasing the amount of context around a fold
z,,  - Set foldlevel to 0 (close all folds)
z..  - Set foldlevel to 99 (open all folds to level 99)
za   - Toggle a fold open / closed under the cursor
zA   - Toggle all folds open / closed under the cursor
z<#> - Set the foldlevel to `<#>`. Ex: `z3` will set the fold level to 3
zf   - Create a fold around the selected text (MANUAL only)
zd   - Delete the fold under the cursor (MANUAL only)
zE   - Deletes all folds (MANUAL only)

```

### Git Shortcuts
```
g] - Move to next hunk
g[ - Move to previous hunk
gs - Stage the hunk under the cursor
gu - Undo the hunk under the cursor, reverting it to the unmodified state
gp - Toggle the preview window and populate with the hunk under the cursor
gq - Toggle the quickfix window and populate with all hunks
```
:information\_source: **More Info:** See the [GitGutter](https://github.com/airblade/vim-gitgutter.git) plugin for more details

### Other Shortcuts
```
<Ctrl-h> - Toggle Hex mode.
```

### Commands
```
:Autoformat                     - Attempt to fix any formatting errors
:Grep <args>                    - Search for the specified patter from the current directory
:GrepAdd <arg>                  - Add the search pattern to the grep list
:Replace <target> <replacement> - Perform a global search and replace using the same files as the `:Grep` command. Opens dialog to confirm
:ReplaceUndo                    - Undo the last `:Replace` operation
:GrepOptions                    - Open a window to set grep options.
:GrepRoot [+arg]                - Configure the location easygrep searches from
:Git                            - Show summary window similar to git status
:Git blame                      - Open the current files git blame history in a split window
:Git diff                       - Open the git diff output in a split window
:Git log                        - Open the git log output in a split window
:Git <cmd>                      - Run git <cmd> and display the output in a split window
:ToggleUnicode                  - This will toggle the `g:use_unicode` flag on/off and update the character map in VIM accordinly. This will
                                  only affect the text loaded in the edit window, not the plugin character mappings
```

:information\_source: **Leader:** All these `<Leader>` commands are done using the `\` key by default. Example `\1` will jump to the first open buffer. This can be changed in your .vimrc if you wish to use a different `<Leader>` character by adding a `:let mapleader = "<character>"`.
  
:warning: **Folding:** Activating some foldmethods might take a while to activate.

### More Info
For more information, see the documentation for list of plugins at the bottom. The complete list of integrated plugins can be found in the vim [plugins](.vim/pack/plugins/start/) directory

---

## DevPanel
The DevPanel plugin will automatically open the NERDTree and Tagbar plugin windows and arrange them accordingly.
![devpanel vim example](../img/devpanel\_example.png?raw=true "DevPanel Example:")

---

## NERDTree (File Browser)
The NERDTree plugin provides a file browser for any files. `<double-click>` or hit `<enter>` on any file to open it in a new buffer. `<single-click>` or hit `<enter>` on any directory to expand / collapse it. When a file is opened, it will open in a new buffer. The tabline will be updated to list that file name as well. Use `<Leader><#>` or `:n` / `:p` to move between opened buffers.

If you do a `<middle-click>` on a file, then the current edit window will be split horizontally and the new file will be opened in the split.

### Bookmarks
The NERDTree plugin provides a bookmark feature which can provide a quick access to directories of your choice. One downside of this though is it cannot resolve any environment variables in the path name. To help facilitate this, a per-repository specific bookmark file can be generated using a defaults file. This functionality has been added to automatically generate the bookmarks file on sourcing the [`.bashrc`](../.bashrc) script. This is done by using the [`bin/gen_nerdtree_bookmarks.py`](../bin/gen_nerdtree_bookmarks.py) script along with a defaults file located at `${HOME}/.default/NERDTreeDefaultBookmarks` file.

To add bookmarks, modify the `.default/NERDTreeDefaultBookmarks` file to include any bookmarks you want to add. The format should be the name of your bookmark (cannot include spaces), then a single space followed by the path to the file. If an environment variable is needed, you can add that in with a `${<env-var>}` type syntax. The path should be an absolute path.

Example:
```
source-directory /home/<user>/project/source
build-directory ${HOME}/build
projects ${GIT_ROOT}/projects
```

This will generate a file at `${GIT_ROOT}/.rc/NERDTreeBookmarks` which will contain the following (assuming your `$GIT_ROOT` is located at `/work/<user>/<repo>`):
```
source-directory /home/<user>/project/source
build-directory /home/<user>/build
projects /work/<user>/<repo>/projects
```

---

## Tagbar (CTag Viewer)
The Tagbar plugin will use ctags to populate a window with any tags from the current file. `<double-click>` or hit `<enter>` on any tag to jump to it. `<single-click>` or move the cursor over any function and the full prototype will be listed below the statusline. When the cursor is over a particular tag, you can open it in a preview window by hitting the `P` (`<shift>p`) key.

### Tagbar Shortcuts
The following shortcuts all work in the Tagbar window.
```
<enter>        - Jump to tag under cursor in the active window
<double-click> - Jump to tag under cursor in the active window
s              - Toggle tag sorting method between file order and name order
x              - Toggle zoom mode (increase the Tagbar window to full screen width or to normal size).
P              - Open the selected tag in the preview window.
```

---

## Lightbar
The Lightbar plugin will display useful information about the currently opened file. It will display the file, the current function the cursor is located in (in the bottome status line), a list of the open buffers (on the left side of the tabline), and the current working GIT branch (on the right side of the tabline) if available.

---

## GitGutter / Fugitive
The GitGutter and Fugitive plugins integrate with git to display information about the added / modified / removed git hunks in the current file, as well as provide utilities to perform git operations from within VIM.
* Lines that have been added will be highlighted on the left side of the file window with a green left arrow.
* Lines that have been modified will be highlighted on the left side of the file window with a blue left then right arrow.
* Lines that have been deleted will be highlighted on the left side of the file window with a red right arrow (note: the highlight will occur on the line prior to the deletion).
* The git hunk information is available in the top-right of the VIM window to show the added / modified / removed lines of code for the unstaged changes in the active file.
* The git branch will be visible at the top-right of the VIM window next to the hunk information.
* `:Git blame` can be used to view the `git blame <file>` for the active file in a new buffer next to the opened file. This allows for easy viewing of the blame history of the file. You can `<double-click>` the commit hash to jump to the commit log that introduced that change. Use `:q` to close the blame window if needed.
* The `\gu` (`<Leader>gu`) shortcut can be used to undo the changes in the hunk under the cursor.
* The `\gs` (`<Leader>gs`) shortcut can be used to stage the hunk under the cursor. This can be useful to stage only a subset of changes in a file instead of doing a `git add` for the entire file.
* The `\zg` (`<Leader>zg`) shortcut can be used to fold away all code that is not part of the currently modified hunks. This is useful to view all unstaged changes in a given file.

Example: In this example you can see the added / modified / deleted lines as well as the branch information and the git-folding method.

![git_fold example](../img/git\_fold\_example.png?raw=true "GitFold Example:")

Example: In this example, you can see the output from the `:Gblame` command to view the `git blame` history of the file.

![git_blame example](../img/git\_blame\_example.png?raw=true "GitBlame Example:")

---

## NERDCommenter
The NERDCommenter plugin allows for quickly commenting / uncommenting a block of code or lines of code. This is most easily done in `Visual` mode by selecting text with the mouse (with `set mouse=a` in your .vimrc), or by hitting the `v` key and using the cursor to select the desired text. The following key sequences will have various modes of commenting the code.

| Key Sequence | Command | Description |
| --- | --- | --- |
| <Leader>cc | Comment Toggle | This will toggle a comment block. Either inserting the normal comments if not currently commented, or uncomment the block if it is already commented |
| <Leader>cm | Minimal Comment | This will add a single comment start / end at the beginning / end of the selected block. |
| <Leader>ci | Comment Invert | This will invert the commented code. The commented code selected will be uncommented, the uncommented code will be commented. |
| <Leader>cy | Yank Comment | This will yank the selected code putting a copy of that code into the clipboard, and then comment out the selected code. |

## Additional Plugins
To add any additional plugins, you can automatically add / load them by doing the following:

```
cd ~/.vim/pack/plugins/start
githome submodule add <plugin-url>
githome commit -m "Added plugin <plugin>"
```
:warning: **User Config:** After cloning the remote repo, you may want to set a specific username/email for that repository if using a different github server or account.
```
cd <plugin>
git config --local user.name '<user>'
git config --local user.email '<email>'
```

---

## Plugin Integrations
* [NERDTree](https://github.com/preservim/nerdtree) - File Browser
* [NERDCommenter](https://github.com/preservim/nerdcommenter) - Easy commenting
* [Tagbar](https://github.com/preservim/tagbar) - Tag Browser
* [GitGutter](https://github.com/airblade/vim-gitgutter) - Git Integration
* [Fugitive](https://github.com/tpope/vim-fugitive) - Git Integration
* [EasyGrep](https://github.com/dkprice/vim-easygrep) - Grep functionality
* [Autoformat](https://github.com/Chiel92/vim-autoformat) - Syntax formatting
* [Flake8](https://github.com/nvie/vim-flake8) - Python syntax checker
* [IndentPython](https://github.com/vim-scripts/indentpython.vim) - Python indentation syntax formatter
* [DevPanel](https://github.com/raven42/devpanel-vim) - IDE Window Manager
* [Lightline](https://github.com/itchyny/lightline.vim) - Status line information
* [Lightline-Bufferline](https://github.com/mengelbrecht/lightline-bufferline) - Adds buffer line to top of Vim window
* [SeachFold](https://github.com/vim-scripts/searchfold.vim) - Folding based on search patterns
* [UndoTree](https://github.com/mbbill/undotree) - Undo / Redo history tree browser
* [PasteEasy](https://github.com/roxma/vim-paste-easy) - Better pasting while in insert mode
