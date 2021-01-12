# .dotfiles
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

To setup on a new system, use the following commands. This creates an alias called `githome` which is used in place of the regular `git` program. This is done to allow automatically setting the git directory for a bare repository. A bare repsitory is used to avoid having a git path in your home directory which could lead toward accidental `git` commands run from your home directory. This new bare repository will be located at `$HOME/.cfg`. After cloning the repo, because this is a bare repository, a `checkout` is needed to update everything to the latest:
```
git clone --bare <dotfiles-repo.git> $HOME/.cfg
alias githome='git --git-dir=$HOME/.cfg --work-tree=$HOME'
echo ".cfg" >> .gitignore
githome checkout
```


Setup git to not show untracked files in the status output
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
The [.bashrc](.bashrc) file is a generic resource file which defines some basics which should be compatible for any user. This script will reference the following user specific files.
| File | Purpose |
| --- | --- |
| .default/common_rc.sh | This file is included prior to any repository specific resource files. Use this for common aliases and environment setup. |
| .default/repo_rc.sh | This file is used as a template for any new repositories that use the `${GIT_REPO}` environment setup. This file is copied to `${GIT_REPO}/.rc/rc` for user generated repos |
| ${GIT_ROOT}/.rc/rc | If the `${GIT_ROOT}` envinroment variable is set, this will look for and source any resource file located in this path. This can be used to specify repository specific aliases and environment setup. |
| ${GIT_ROOT}/.rc/bld_target.sh | This file is used to define a specific platform to set for the current command shell. See **Build Target** discussion below |
| .default/post_rc | This file is included at the very end of the `.bashrc` file for any thing to be done at the end of the environment setup. |

## Environment Variables
There are a few environmental configuration options which can be toggled in a user private `.default/common_rc.sh` script.
```bash
#!/bin/bash

# Default resource file
#
# .default/common_rc.sh -	Set user specific environment options. This should include any aliases, environment path
#							variables, and any other user specific environment options.
#
# This file is sourced in the .bashrc script after defaults have been initialized but before any processing of the env
# variables or execution of supporting scripts This allows the user to override some defaults, or setup other parameters
# prior to executing further env setup scripts. This can be used in conjunction with the .default/post_rc.sh script to
# control and override environment default set in the .bashrc script on a per user basis in the event .bashrc is a common
# file.
#
# The general order of loading resource scripts is as follows:
#	.bashrc
#		// setup any bash environment and other variables
#		// initialize any common ENV vars (PATH / LD_RUN_PATH / etc)
#		// determine env specific resource script based on GIT_REPO
#		. .default/common_rc.sh		# load common_rc.sh script to set any user specific env variables
#		. ${GIT_REPO}/.rc/rc		# load env specific resource script
#		// process any ENV variables needed
#		// setup prompt / title routines
#		. .default/post_rc.sh		# load post_rc.sh script to override anything that was done so far

# To disable unicode characters in VIM and bash prompts. There are unicode characters used for the terminal window title,
# and in VIM, unicode characters are used in the status line, buffer line, and window title.
export USE_UNICODE=1

# Set autosave for option vim
export AUTOSAVE=0

# Setting this to 0 will not show the current $BLD_TARGET in the command prompt. By default the prompt will look like this:
#   $BLD_TARGET $GIT_REPO (<git-branch>) <directory>$ 
# Setting this to 0 will result in the following:
#   $GIT_REPO (<git-branch>) <directory>$
export SHOW_TARGET_IN_PROMPT=1

# This env variable is used by the .vimrc to shorten path names for window title
# Example: SRC_PATH_PREFIX="common/path/to/src" will result in truncating that
# portion out of the window path title. So if for example you were in the path
#     /<repo>/common/path/to/src/lib/
# then the window title would show
#     /<repo>/../lib/
# This variable is also used by the retag script to generate ctags for a repository.
export SRC_PATH_PREFIX="projects"

# UNIFIED_HISTORY - This env var is used to determine if a unified history should be used between all sessions into a host.
# This will enable the 'history' command to use a file instead of in memory history so the shell history is updated every
# command across all sessions, not just the current session as is the default
export UNIFIED_HISTORY=0

# Setup source code path prefix based on GIT_ROOT, also setup TAGDIR which is used by VIM to look for any ctags
if [ $GIT_ROOT ]; then
	ROOT_PATH=${GIT_ROOT}
	if [ -d ${GIT_ROOT}/.rc/tags ]; then
		TAGDIR=${GIT_ROOT}/.rc/tags
	else
		TAGDIR=${HOME}/.default/tags
	fi
else
	TAGDIR=${HOME}/.default/tags
fi

# TAG_PATH - The TAG_PATH variable defines a list of paths to parse for the retag script. This is
# a whitespace delimited list of path definitions. Each path definition is a colon delimited list
# consisting of <default>:<tag-file>:<path> with the following definitions:
#     <default> - 0|1  if 0, then only process this path if the retag -a option is given
#     <tag-file> - The filename to use for the output
#     <path> - The path to start a recursive tag search in
# This is all run from the ${GIT_ROOT}/${SRC_PATH_PREFIX} location. All paths should be
# relative from that directory
TAG_PATH="1:tags_src:src"
TAG_PATH="$TAG_PATH 1:tags_inc:inc"
export TAG_PATH

# Set defaults needed for ~/sbin/git-repo script to work with our environment
export WORKSPACES=${HOME}/work:${HOME}/projects
export WORKSPACE_SEARCH_DEPTH=5
export DEFAULT_GIT_SERVER=git@github.com
```

### GIT REPO Setup
There is a script at `sbin/git-repo` which can be used to setup a new sub-shell environment to set repository specific environment variables and other such parameters. This script will set a few env variables and enter a new sub-shell with these variables defined and change directories to the root level of that repository. This script will use the `$WORKSPACES` environment variable to scan for valid git repositories matching the given name, or if no repository is specified, it will list all respositories.

The `git-repo` script can also be used to clone a new repository if needed. To use this script properly, there are a few key environment variables which should be set in `.default/common_rc`. These variables are as follows:
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
Setting up GIT environment variables for dotfiles...
  RC SPEC:/home/raven42/projects/dotfiles/.rc/rc
  TAGDIR:/home/raven42/projects/dotfiles/.rc/tags
dotfiles (master) dotfiles$ git status
On branch master
Your branch is up to date with 'origin/master'.

nothing to commit, working tree clean
dotfiles (master) dotfiles$ exit
exit
dev-server ~$ git-repo dotfiles
Setting up GIT environment variables for dotfiles...
  RC SPEC:/home/raven42/projects/dotfiles/.rc/rc
  TAGDIR:/home/raven42/projects/dotfiles/.rc/tags
dotfiles (master) dotfiles$ exit
exit
dev-server ~$
```

### Build Target
The `${GIT_ROOT}/.rc/bld_target.sh` file is sourced after every command as part of the `PROMPT_COMMAND` function call. This can be used to set a current `$BLD_TARGET` environment variable which can be used for all future commands. This variable is also displayed on the bash prompt. This can be used to create common aliases / scripts using this environement variable. This build target can be modified using the following script.
```
some_target <git-repo> (master) proj$ bld-target
Current build target is BLD_TARGET=some_target
some_target <git-repo> (master) proj$ bld-target another_target
Set new default BLD_TARGET=another_target in [<git-repo>/.rc/bld_target.sh]
another_target <git-repo> (master) proj$
```

This file should contain as little as possible. Ideally only exporting the $BLD_TARGET environment variable.
```bash
export BLD_TARGET=<build-target>
```

Example:
`alias cp-img='cp ${GIT_ROOT}/<build-path>/${BLD_TARGET}/<path-to-image> <dest-path>'`

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
The VIM plugins and resource files all require VIM 8 installed. This can be compiled and installed from the source.

##### Install for single user
```
git clone https://github.com/vim/vim
cd vim
./configure --prefix=${HOME} --enable-python3interp --enable-perlinterp --enable-gnome-check --enable-gui=auto --enable-gtk2-check --with-x --enable-fontset --enable-gtk2-check
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
While not strictly needed, the vim configuration can make use of unicode characters to make things look a little nicer. To make use of this, the `USE_UNICODE` environment variable needs to be set to `1` in your `.default/common_rc` or similar. You must also make sure to have a font installed that has unicode characters. All the examples in the vim usage and configuration are shown with unicode characters enabled.

To get unicode character support on different disrtibutions, the powerline package may need to be installed. It may also be advantagous to install the additional font packages listed here:

> [powerline](https://packages.debian.org/stretch/powerline)

> [ttf-ancient-fonts](https://packages.debian.org/buster/ttf-ancient-fonts)

> [fonts-noto](https://packages.debian.org/buster/fonts-noto)

If your environment does not have any unicode fonts installed, and if you are unable to install any via the normal methods like above, another option is to copy existing fonts from another user in your organization. To manually copy / install these fonts, find another user in your organization that does have unicode fonts installed and copy them to your home path. Once copied, you can use the `fc-cache --force --verbose` to manually update your font cache and then verify that the correct directories were scanned. The paths to look at for fonts in a user profile can be found here:
```
<user>/.fonts
<user>/.local/share/fonts
```

So to copy from another user and update your font cache, it would look something like this:
```
~$ mkdir ~/.fonts
~$ mkdir -p ~/.local/share/fonts
~$ cp -r /home/<another-user>/.fonts ~/.fonts
~$ cp -r /home/<another-user>/.local/share/fonts ~/.local/share/fonts
~$ fc-cache --force --verbose
/usr/share/fonts: caching, new cache contents: 0 fonts, 3 dirs
/usr/share/fonts/bitmap: caching, new cache contents: 15 fonts, 0 dirs
/usr/share/fonts/default: caching, new cache contents: 0 fonts, 2 dirs
/usr/share/fonts/default/Type1: caching, new cache contents: 35 fonts, 0 dirs
/usr/share/fonts/default/ghostscript: caching, new cache contents: 13 fonts, 0 dirs
/usr/share/fonts/liberation: caching, new cache contents: 4 fonts, 0 dirs
/usr/share/X11/fonts/Type1: caching, new cache contents: 13 fonts, 0 dirs
/usr/share/X11/fonts/TTF: skipping, no such directory
/usr/local/share/fonts: skipping, no such directory
/home/<user>/.fonts: caching, new cache contents: 250 fonts, 1 dirs
/home/<user>/.fonts/luculent: caching, new cache contents: 0 fonts, 0 dirs
/var/cache/fontconfig: not cleaning unwritable cache directory
/home/<user>/.fontconfig: cleaning cache directory
fc-cache: succeeded
~$ 
```
> :warning: **Note:** After installing / updating your font cache, it may be required to reboot your system.

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

> :warning: **Note:** Currently Universal-CTAGS does not compile correctly on older systems like CentOS 6.9. To fix this, the following patch can be applied to the ctags source. See https://github.com/universal-ctags/ctags/issues/2776 for more info.

```diff
diff --git a/misc/packcc/packcc.c b/misc/packcc/packcc.c
index f61274d..ffbbc58 100644
--- a/misc/packcc/packcc.c
+++ b/misc/packcc/packcc.c
@@ -411,7 +411,8 @@ static bool unescape_string(char *str, size_t *length) {
                 }
                 {
                     char s[4];
-                    for (int k=0;k<4;k++) {
+                    int k;
+                    for (k=0;k<4;k++) {
                         char c = str[i + k + 1];
                         s[k] = (c >= '0' && c <= '9') ? c - '0' :
                                (c >= 'a' && c <= 'f') ? c - 'a' + 10 :
@@ -423,7 +424,8 @@ static bool unescape_string(char *str, size_t *length) {
                     }
                     else {
                         int ch=s[0];
-                        for (int k=1;k<4;k++) ch = (ch << 4) | s[k];
+                        int k;
+                        for (k=1;k<4;k++) ch = (ch << 4) | s[k];
                         if (ch < 0x80) {
                             str[j++] = (char)ch;
                         } else if (ch < 0x800) {
```

---

## Further Reading
For more reading, see the following:
> * <https://www.atlassian.com/git/tutorials/dotfiles>
> * <https://www.atlassian.com/git/tutorials/git-submodule>
> * <https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh>
> * <https://docs.github.com/en/github/writing-on-github>
> * <https://www.webfx.com/tools/emoji-cheat-sheet/>
> * <https://www.rapidtables.com/code/text/unicode-characters.html>

Credit:
> <darth.gerbil@gmail.com>
