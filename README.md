
# .dotfiles

[![Vint](https://github.com/raven42/dotfiles/workflows/vint/badge.svg)](https://github.com/raven42/dotfiles/actions?workflow=vint)
[![Check](https://github.com/raven42/dotfiles/workflows/flake8/badge.svg)](https://github.com/raven42/dotfiles/actions?workflow=flake8)
[![Check](https://github.com/raven42/dotfiles/workflows/reviewdog/badge.svg)](https://github.com/raven42/dotfiles/actions?workflow=reviewdog)
[![Check](https://github.com/raven42/dotfiles/workflows/submodules/badge.svg)](https://github.com/raven42/dotfiles/actions?workflow=submodules)

Linux .dotfiles, scripts, and configurations. This setup uses a bare repository to track linux .dotfiles and configuration files.

### Contents:
- [Installation](#installation)
- [Bash Configuration](#bash-configuration)
  - [Environment Variables](#environment-variables)
  - [GIT REPO Setup](#git-repo-setup)
  - [Build Target](#build-target)
- [Vim Usage / Setup](#vim-usage--setup)
  - [VIM Usage](#vim-usage)
  - [VIM Compilation](#vim-compilation)
  - [VIM Clipboard Setup](#vim-clipboard-setup)
  - [Unicode Character Support](#unicode-character-support)
- [Univeral CTAGS](#univeral-ctags)
- [Further Reading](#further-reading)

## Installation

:information\_source: **Personal Copy:** If you wish to modify any of the base scripts, it is recommended to fork your own copy of this repo so you can make your own changes. There are plenty of options to override the default behavior, but if further customization is needed, then forking your own repo would be best.

:warning: **Warning:** This process may overwrite existing scripts and resource files such as `~/.bashrc` and `~/.vimrc` as well as others if they are the same as what you already have. It is a good idea to backup any existing scripts you have before doing this process.

To setup on a new system, use the following commands. This creates an alias called `githome` which is used in place of the regular `git` program. This is done to allow automatically setting the git directory for a bare repository. A bare repsitory is used to avoid having a git path in your home directory which could lead toward accidental `git` commands run from your home directory. This new bare repository will be located at `$HOME/.cfg`. After cloning the repo, because this is a bare repository, a `checkout` is needed to update everything to the latest and then you must also set the upstream branch to track the origin:
```
git clone --bare git@github.com:raven42/dotfiles.git $HOME/.cfg
alias githome='git --git-dir=$HOME/.cfg --work-tree=$HOME'
echo ".cfg" >> .gitignore
githome config --local --add remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
githome fetch
githome branch --set-upstream-to origin/master
githome checkout
```


Setup git to not show untracked files in the status output. You can also setup the username and email associated with this git repository if different than your normal username / email if desired.
```
githome config --local status.showUntrackedFiles no
```

Once cloned, it may be necessary to initialize / update any submodules for any git repositories that are embedded in the environment.
```
githome submodule init
githome submodule update
```

To update submodules if they are updated:
```
githome submodule update
```

:information\_source: **Further Reading:** For more info on bare repository setup, see the further reading section below.

:information\_source: **SSH Keys:** If you wish to configure SSH keys to use with github as a different account, see the guide at [doc/ssh\_config.md](doc/ssh\_config.md).

---

## Bash Configuration
[.bashrc](.bashrc) is a small, generic loader. It defines a `source` wrapper (so every sourced file is
tracked, for tooling that wants to answer "where did this come from"), a recursive loader that walks
[.rc/](.rc/) in a fixed, numbered order, and the prompt-update machinery. All the actual environment setup —
exports, aliases, functions — lives under `.rc/`, not in `.bashrc` itself.

See [.rc/README.md](.rc/README.md) for the full description: how the loader orders things, the `xx-*` prefix
that disables an entry without deleting it, and the layout this repo ships:

| Path | Contents |
| --- | --- |
| `.rc/00-core/` | Generic bash environment: exports, path helpers, a `cd` replacement, generic aliases. |
| `.rc/20-vendor/` | Vendored third-party scripts (git prompt/completion, a VS Code IPC helper). |
| `.rc/templates/` | Reference-only starter files for building your own site-specific tier. Never loaded. |

This repo intentionally ships only generic, site-agnostic content — no proprietary server names, internal git
remotes, or company-specific shortcuts. If you also have a private/team config repo of your own (this
author's is `raven42/binfiles` — see its README for the install steps), you add it as one or more numbered
tiers **symlinked** into `.rc/`, e.g. `.rc/30-team -> ~/some-private-repo/rc/30-team`. Because the loader only
cares about the `NN-*` naming convention and whether an entry is a file or directory — not where it physically
lives — a symlinked tier loads exactly like `00-core`/`20-vendor` do, no changes needed here.

## Environment Variables
The generic variables and toggles this repo defines live in [.rc/00-core/00-vars.sh](.rc/00-core/00-vars.sh)
— things like:

- `USE_UNICODE` — enable unicode characters in the bash prompt/window title and in VIM's status/buffer lines.
- `AUTOSAVE` — autosave setting for VIM.
- `SHOW_TARGET_IN_PROMPT` — show the current `$BLD_TARGET` in the prompt (see **Build Target** below). When
  set, the prompt looks like `$BLD_TARGET $GIT_REPO (<git-branch>) <directory>$`; when unset, just
  `$GIT_REPO (<git-branch>) <directory>$`.
- `SRC_PATH_PREFIX` — used by `.vimrc` to shorten path names in the window title, and by the `retag` script
  when generating ctags for a repository. E.g. `SRC_PATH_PREFIX="common/path/to/src"` turns
  `/<repo>/common/path/to/src/lib/` into `/<repo>/../lib/` in the title.
- `UNIFIED_HISTORY` — when set, `history` is backed by a file shared across every session into a host instead
  of each session's own in-memory history.

Core supplies safe workspace/repository defaults. The selected `10-profile` tier
can override them before `20-vendor` and `30-team` load; `40-user` holds shared
personal settings. Use `~/bin/.rc/setup-rc home` or `work` when binfiles is installed.
See [.rc/README.md](.rc/README.md) for the numbered file convention, cache defaults,
nearest `.venv` activation, and variable refresh behavior.

### GIT REPO Setup
There is a script at `sbin/git-repo` which can be used to setup a new sub-shell environment to set repository specific environment variables and other such parameters. This script will set a few env variables and enter a new sub-shell with these variables defined and change directories to the root level of that repository. This script will use the `$WORKSPACES` environment variable to scan for valid git repositories matching the given name, or if no repository is specified, it will list all respositories.

The `git-repo` script can also be used to clone a new repository if needed. To use this script properly, there are a few key environment variables which should be set in whatever private tier you've added (see **Environment Variables** above) — this repo doesn't define them itself. These variables are as follows:
```bash
# WORKSPACES - This is a `:` delimited list of paths to search for repositories in. When used with the git-repo script, these paths
# will be searched for any repo name specified on the command line
export WORKSPACES=${HOME}/projects:/public/${USER}/projects

# WORKSPACE_SEARCH_DEPTH - This variable defines the search depth in the available WORKSPACES paths in which
# to look for valid git repositories. This means the script will search for valid git repositories a maximum
# of WORKSPACE_SEARCH_DEPTH directories deep from each workspace. If not set, this will default to a search
# depth of 5. The larger the value, the more time it will take to actually search for repositories.
# Example:
export WORKSPACE_SEARCH_DEPTH=5

# DEFAULT_GIT_SERVER - This is used to set a URL to a git server from which to clone
export DEFAULT_GIT_SERVER=git@github.com

# DEFAULT_GIT_REPO - This is used to specify a default repository to clone from the server
export DEFAULT_GIT_REPO=raven42/dotfiles.git
```

##### Example Usage:
```
dev-server ~$ echo $WORKSPACES
/home/raven42/.vim/pack/plugins/start:/home/raven42/projects
dev-server ~$ echo $WORKSPACE_SEARCH_DEPTH
1
dev-server ~$ git-repo
Multiple repositories found. Please specify which repository.

/home/raven42/.vim/pack/plugins/start/nerdtree
/home/raven42/.vim/pack/plugins/start/tagbar
/home/raven42/.vim/pack/plugins/start/devpanel-vim
/home/raven42/projects/dotfiles
/home/raven42/projects/vim-src
/home/raven42/projects/ctags

Please entry repository path: dotfiles
Entering main repository .. [/home/raven42/projects/dotfiles dotfiles@raven42/dotfiles]
dotfiles (master) dotfiles$ git status
On branch master
Your branch is up to date with 'origin/master'.

nothing to commit, working tree clean
dotfiles (master) dotfiles$ exit
exit
dev-server ~$ git-repo dotfiles
Entering main repository .. [/home/raven42/projects/dotfiles dotfiles@raven42/dotfiles]
dotfiles (master) dotfiles$ exit
exit
dev-server ~$
```

`Entering main repository ..` (and the matching `Leaving repository ..` on the way back out) come from
[.rc/20-vendor/scripts/git-environment.sh](.rc/20-vendor/scripts/git-environment.sh), which also sets `$GIT_ROOT`/`$GIT_REPO`/
`$GIT_PATH`/`$GIT_REMOTE` on every directory change, not just from `git-repo`. Set `$GIT_ENVIRONMENT_SILENT=1`
to suppress these messages.

### Build Target
`$BLD_TARGET` is a per-shell "current build target" value, shown in the prompt when `$SHOW_TARGET_IN_PROMPT=1`
(see **Environment Variables** above) and available for aliases/scripts to key off of, e.g.
`alias cp-img='cp ${GIT_ROOT}/<build-path>/${BLD_TARGET}/<path-to-image> <dest-path>'`.

It's read from a small resource file, sourced automatically on every prompt, whose location resolves in a
tiered fallback: a per-repo `${GIT_ROOT}/.rc/bld_target.sh` override takes priority if present; otherwise a
personal, non-per-repo file is used, checked in this order so the same tooling works whether or not a given
machine has migrated to this `~/.rc/` layout: `~/.rc/prompt.d/bld_target.sh`, then the older
`~/.private/bld_target.sh`, then the older still `~/bin/prompt_command/bld_target.sh`. (This fallback chain
is implemented once, in `raven42/binfiles`' `bld_target_resolve.bash`, and shared by `mk`/`mkesm`/`bld-target`
— see that repo for details.)

View or set it with the `bld-target` script (or `mk -d <target>`):

```
some_target <git-repo> (master) proj$ bld-target
Current build bld_target is BLD_TARGET=some_target
some_target <git-repo> (master) proj$ bld-target another_target
Set new default BLD_TARGET=another_target in [~/.rc/prompt.d/bld_target.sh]
another_target <git-repo> (master) proj$
```

This file should contain as little as possible — ideally just exporting the `$BLD_TARGET` environment variable:
```bash
export BLD_TARGET=<build-target>
```

---

## VIM Usage / Setup

### VIM Usage
See the [.vim/](.vim/) file for more information on the VIM setup and configuration including shortcuts and further personalization options. Documentation for plugins which are used and can be customized can be found here:
- https://github.com/raven42/devpanel-vim
- https://github.com/preservim/nerdtree
- https://github.com/preservim/tagbar
- https://github.com/tpope/vim-fugitive
- https://github.com/airblade/vim-gitgutter

:information\_source: For full list of plugins, see the [.vim](.vim/) readme or the [.vim/pack/plugins/start](https://github.com/raven42/dotfiles/tree/master/.vim/pack/plugins/start) directory.

### VIM Compilation
The VIM plugins and resource files all require VIM 8 installed. This can be compiled and installed from the source if the default version is not VIM 8 or higher.

##### Install for single user
1. Clone the git repository:
```
git clone https://github.com/vim/vim
cd vim
```
2. If you have previously cloned and built vim in your local vim repository, do the following to return it to a porcelain state. Otherwise you can skip to step 3.
```
git clean -dxf
git pull
```
3. Now you can configure, build, and install vim
```
./configure --with-features=huge \
    --enable-multibyte \
    --enable-rubyinterp=yes \
    --enable-python3interp=yes \
    --with-python3-command=$PYTHON_VER \
    --with-python3-config-dir=$(python3-config --configdir) \
    --enable-perlinterp=yes \
    --enable-gui=gtk2 \
    --enable-cscope \
    --enable-fontset \
    --prefix=${HOME}/bin/vim-9.0
make
make install
```

##### Install for all users
To install for all users, additional packages may be needed in order to compile. In this example we will use a Debian distribution, so subsitute with the package manager of your choice if required.
```
sudo apt-get build-deps vim
sudo apt remove vim vim-runtime gvim
cd ~
get clone https://github.com/vim/vim
cd vim
./configure --prefix=/usr/local --enable-python3interp --enable-perlinterp --enable-gnome-check --enable-gui=auto --enable-gtk2-check --with-x --enable-fontset --enable-gtk2-check
make VIMRUNTIMEDIR=/usr/local/share/vim/vim82
```

> :warning: **Note:** For some linux distribution installs (like Debian currently), even though VIM 8 is installed on the system, it may not have the required compilation flags for full usage of this environment setup (like `--enable-python3interp`). So manual compilation may still be needed. See [here](https://github.com/ycm-core/YouCompleteMe/wiki/Building-Vim-from-source) for more details.

### VIM Clipboard Setup
By default VIM uses its own clipboard. The [.vimrc](.vimrc) file does override this and uses the system clipboard for autoselect as well as copy/paste funcitonality. If you wish to enabled this for use across SSH connections, then X11 forwarding must be enabled on the SSH session. This can be done in one of two ways.

Enable X11 forwarding per ssh session: This will enable X11 forwarding only for this specific session.
```
ssh -XY <hostname>
```

Enable X11 forwarding in the `.ssh/config` file: This will enable it for SSH connections as defined in the config file.
```
Host *.<trusted-network>
    ForwardX11 yes
    ForwardX11Trusted yes
```

> :warning: **Caution:** Only enable this for trusted hosts. Otherwise this will forward X11 parameters to all hosts.
>
> :warning: **Note:** Also special handling is needed when using visual mode selection. This is set to automatically copy to the system clipboard. If you select something using the mouse, and then while it is still selected use the scroll wheel to move the window down, additional content will be put in the clipboard other than just what was selected.

## Unicode Character Support
While not strictly needed, the vim configuration can make use of unicode characters to make things look a little nicer. This is controlled by the `USE_UNICODE` environment variable, set (and defaulted to `1`) in [.rc/00-core/00-vars.sh](.rc/00-core/00-vars.sh) — override it to `0` in a later-loading tier if you'd rather not use them. You must also make sure to have a font installed that has unicode characters. All the examples in the vim usage and configuration are shown with unicode characters enabled.

To get unicode character support on different disrtibutions, the powerline package may need to be installed. It may also be advantagous to install the additional font packages listed here:

> [powerline](https://packages.debian.org/stretch/powerline)

> [ttf-ancient-fonts](https://packages.debian.org/buster/ttf-ancient-fonts)

> [fonts-noto](https://packages.debian.org/buster/fonts-noto)

---

## Univeral CTAGS
These plugins also work better with Universal CTAGS instead of Exuberant CTAGS. This can also be compiled and installed from the source if the distribution does not already include universal ctags.
```
git clone https://github.com/universal-ctags/ctags
cd ctags
./autogen.sh
./configure --prefix=${HOME}
make
make install
```

---

## Environment Modules
It is also possible to integrate environment modules into these resource files. Environment modules allows for easy setting of your `$PATH` / `$LD_LIBRARY_PATH` / `$MANPATH` and other similar environment variables. It also allows you to `load` a module at will, and to `unload` a module at will. This makes swapping toolsets or such an easy task. For more info, see the `modules` link in the further reading section.

---

## Further Reading
For more reading, see the following:
> * <https://www.atlassian.com/git/tutorials/dotfiles>
> * <https://www.atlassian.com/git/tutorials/git-submodule>
> * <https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh>
> * <https://docs.github.com/en/github/writing-on-github>
> * <https://www.webfx.com/tools/emoji-cheat-sheet/>
> * <https://www.rapidtables.com/code/text/unicode-characters.html>
> * <https://modules.readthedocs.io/en/latest/index.html>

Credit:
> <darth.gerbil@gmail.com>
