# .dotfiles
Linux .dotfiles, scripts, and configurations

This setup uses a bare repository to track linux .dotfiles and configuration files.

> :information_source: **Personal Copy:** If you wish to modify any of the base scripts, it is recommended to fork your own copy of this repo so you can make your own changes.

## Setup
To setup on a new system, use the following commands. This creates an alias called `githome` which is used in place of the regular `git` program. This is done to allow automatically setting the git directory for a bare repository. A bare repsitory is used to avoid having a git path in your home directory which could lead toward accidental `git` commands run from your home directory. This new bare repository will be located at `$HOME/.cfg`:
```
alias githome='/usr/bin/git' --git-dir=$HOME/.cfg --work-tree=$HOME'
echo ".cfg" >> .gitignore
git clone --bare <dotfiles-repo.git> $HOME/.cfg
```


Setup git to not show untracked files in the status output
```
githome config --local status.showUntrackedFiles no
```

Once cloned, it may be necessary to initialize / update any submodules for any git repositories that are embedded in the environment.
```
githome clone <dotfiles-repo.git>
githome submodule init
githome submodule update
```

To update submodules if they are updated:
```
githome submodule update
```

> :warning: **Note:** You may need to remove any existing conflicting files (such as .bashrc) if there is any default file on the system. Either remove or backup these files.

> :information_source: **Further Reading:** For more info on bare repository setup, see the further reading section below.


---

## Bash Configuration
The [.bashrc](.bashrc) file is a generic resource file which defines some basics which should be compatible for any user. This script will reference the following user specific files.
| File | Purpose |
| --- | --- |
| .default/common_rc | This file is included prior to any repository specific resource files. Use this for common aliases and environment setup. |
| ${GIT_ROOT}/.rc/rc | If the `${GIT_ROOT}` envinroment variable is set, this will look for and source any resource file located in this path. This can be used to specify repository specific aliases and environment setup. |
| ${GIT_ROOT}/.rc/swbd | This file is used to define a specific platform to set for the current command shell. See SWBD platform discussion below |
| .default/post_rc | This file is included at the very end of the `.bashrc` file for any thing to be done at the end of the environment setup. |

### SWBD Platform
The `${GIT_ROOT}/.rc/swbd` file is sourced after every command as part of the PROMPT_COMMAND function call. This can be used to set a current `$SWBD` environment variable which can be used for all future commands. This variable is also displayed on the bash prompt. This can be used to create common aliases / scripts using this environement variable.

This file should contain as little as possible. Ideally only exporting the $SWBD environment variable.
```
export SWBD=swbd165
```

Example:
`alias cp-img='cp ${GIT_ROOT}/<build-path>/${SWBD}/<path-to-image> <dest-path>'`

---

## VIM Configuration
See the [.vim/README.md](.vim/README.md) file for more information on the VIM setup and configuration.

---

## VIM Compilation
The VIM plugins and resource files all require VIM 8 installed. This can be compiled and installed from the source.
```
git clone https://github.com/vim/vim
cd vim
./configure --prefix=${HOME} --enable-python3interp --enable-perlinterp --enable-gnome-check --enable-gui=auto --enable-gtk2-check --with-x --enable-fontset --enable-gtk2-check
make
make install
```

---

## Univeral CTAGS
These plugins also work better with Universal CTAGS instead of Exuberant CTAGS. This can also be compiled and installed from the source.
```
git clone https://github.com/universal-ctags/ctags
cd ctags
./autogen.sh
./configure --prefix=${HOME}
make
make install
```

---

## Further Reading
For more reading, see the following:
> * <https://www.atlassian.com/git/tutorials/dotfiles>
> * <https://www.atlassian.com/git/tutorials/git-submodule>
> * <https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh>
> * <https://docs.github.com/en/github/writing-on-github>
> * <https://www.webfx.com/tools/emoji-cheat-sheet/>


Credit:
> <darth.gerbil@gmail.com>
