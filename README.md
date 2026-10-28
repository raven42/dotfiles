
# .dotfiles

[![Vint](https://github.com/raven42/dotfiles/workflows/vint/badge.svg)](https://github.com/raven42/dotfiles/actions?workflow=vint)
[![Check](https://github.com/raven42/dotfiles/workflows/flake8/badge.svg)](https://github.com/raven42/dotfiles/actions?workflow=flake8)
[![Check](https://github.com/raven42/dotfiles/workflows/reviewdog/badge.svg)](https://github.com/raven42/dotfiles/actions?workflow=reviewdog)
[![Check](https://github.com/raven42/dotfiles/workflows/submodules/badge.svg)](https://github.com/raven42/dotfiles/actions?workflow=submodules)

Linux dotfiles, scripts, and configurations, tracked in a standard Git checkout
and deployed into the home directory with symlinks.

## Contents

- [.dotfiles](#dotfiles)
  - [Contents](#contents)
  - [Installation](#installation)
    - [Migrating an existing bare HOME repository](#migrating-an-existing-bare-home-repository)
    - [Tools stay in the checkout](#tools-stay-in-the-checkout)
    - [Optional binfiles and profiles](#optional-binfiles-and-profiles)
    - [Additional private profiles](#additional-private-profiles)
    - [Migrating from the bare repository](#migrating-from-the-bare-repository)
    - [Finding and cleaning stale symlinks](#finding-and-cleaning-stale-symlinks)
  - [Bash Configuration](#bash-configuration)
  - [Environment Variables](#environment-variables)
    - [GIT REPO Setup](#git-repo-setup)
    - [Build Target](#build-target)
  - [VIM Usage / Setup](#vim-usage--setup)
    - [VIM Usage](#vim-usage)
    - [VIM Clipboard Setup](#vim-clipboard-setup)
  - [Unicode Character Support](#unicode-character-support)
  - [Universal CTAGS](#universal-ctags)
  - [Environment Modules](#environment-modules)
  - [Further Reading](#further-reading)

## Installation

Use a standard checkout. `setup.sh` links configuration into your home directory;
Git tracks files in the checkout, not the entire home directory.

```bash
git clone --recurse-submodules git@github.com:raven42/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./setup.sh --dry-run
./setup.sh
```

Requires Bash and Python 3. Source paths are resolved from the script location,
so the checkout may live elsewhere. No downloads, Git updates, or global Git
configuration changes happen during setup.

For existing dotfiles, preview and explicitly back up conflicts:

```bash
./setup.sh --backup --dry-run
./setup.sh --backup
```

Backups go to a unique `~/.dotfiles-backups/<timestamp>/` directory, preserving
relative paths. Real files, directories, and conflicting symlinks are moved there
before linking. Correct links are left alone. Setup preflights all destinations
and rolls back its links/moves if a later operation fails. Shared parent directories
(`.rc`, `.config`, `.ctags.d`) must be real directories, not symlinks.
Unrelated entries in those directories remain untouched.

Deployment is discovered by scanning the checkout, including newly added/untracked
files. There is no hardcoded list of dotfiles or public tiers. Add a config file or
`.rc/NN-tier/` directory and rerun setup; it will appear in the deployment plan.

The repository's `.deploy.json` defines the small policy exception list:

- `exclude`: checkout-relative glob patterns for repository-only entries such as
  `.git`, `.github`, `.gitmodules`, documentation, tests, and installer files.
- `merge_directories`: directories to retain as real containers in HOME and scan
  for child links. Defaults are `.rc`, `.config`, and `.ctags.d`.

All other entries are linked as files or whole directories. Exclusions apply to
entries visited by the scan; a linked directory's contents remain intact. To exclude
individual descendants, make their containing directories merge directories too.
Git metadata named `.git` is always excluded when encountered by the scan.
Private profile links are still selected by `--profile`; collisions with discovered
public targets fail before writes. Unrelated HOME entries are untouched.

`.vim` remains a whole-directory link: initialize submodules before switching and
migrate local Vim additions from the backup. Review `--dry-run` when adding new
checkout content, since untracked files are eligible too. Remove or extend exclusion
patterns in `.deploy.json` if you want normally omitted repository content deployed.

### Migrating an existing bare HOME repository

Use [`scripts/migrate.py`](scripts/migrate.py) for a backed-up v3.0 to v4.0
migration with a private override tier. Read the [migration guide](doc/migration-v4.md)
for preparation, required shell-customization review, apply, and recovery.

### Tools stay in the checkout

`sbin/`, `doc/`, and `img/` are repository-only content. Core shell setup appends
`$DOTFILES_ROOT/sbin` to PATH, preserving native command precedence. New tools
are available without rerunning setup. Documentation is read in the checkout.
Conventional configuration links and the `~/.rc` profile composition remain.
Private binfiles continues to use the active `~/bin` checkout.

For an existing installation, preview and migrate old `~/sbin` links:

```bash
./setup.sh --migrate-sbin --dry-run
./setup.sh --migrate-sbin
```

Setup normally reports these legacy links without removing them. Migration backs
up live or broken links targeting this checkout's `sbin/`, including an old whole
`~/sbin` link. It preserves real files and unrelated links, never follows directory
links, and leaves real directories in place. Other checkout locations are not
considered owned. Use `--backup` too if configuration deployment has conflicts.
Open a fresh shell after updating. Cron, services, and sudo should use explicit
checkout command paths or their own PATH settings; they cannot rely on `.bashrc`.
The Proxmox host command and completion links remain separate system integration.

### Optional binfiles and profiles

Keeping the existing `~/bin` checkout is supported and needs no second clone:

```bash
./setup.sh --binfiles "$HOME/bin" --profile home --backup --dry-run
./setup.sh --binfiles "$HOME/bin" --profile home --backup
```

This keeps `~/bin` in place and selects the private profile links. `--profile work`
adds the team tier. Without `--profile`, existing private profile links are untouched.
To use a separate binfiles checkout, pass `--binfiles "$HOME/Projects/binfiles"`;
setup links it at `~/bin`, backing up an existing destination only with `--backup`.
Never delete a checkout that deployed symlinks still reference.

### Additional private profiles

`--profile` also accepts names defined by `binfiles/.rc/profiles/<name>/profile.json`.
For example, `org` extends `work` and adds a `45-org` tier for extra settings:

```bash
./setup.sh --binfiles "$HOME/bin" --profile org --backup --dry-run
./setup.sh --binfiles "$HOME/bin" --profile org --backup
```

Definitions use `{"extends": "work", "links": {"45-org": "profiles/org"}}`.
Targets are relative to the private `.rc` directory. Both installers use binfiles'
`profile_config.py`; old binfiles checkouts still support built-in home/work.
See `~/bin/.rc/profiles/README.md` for inheritance, validation, and extension files.

### Migrating from the bare repository

1. Check old changes with `git --git-dir="$HOME/.cfg" --work-tree="$HOME" status
   --untracked-files=all -- .rc/` and compare any local files you want to retain.
2. Commit/transfer desired edits into the new checkout. Initialize its submodules
   with `git submodule update --init --recursive`.
3. Run the dry run above, review conflicts, then run the same command without
   `--dry-run` to save the old files and create links.
4. Open a fresh shell. `githome` now runs `git -C "$DOTFILES_ROOT"`; untracked
   files are shown normally in the checkout. Keep `~/.cfg` for recovery until
   satisfied; setup never modifies or removes it.

Do not use the old bare repository's `checkout` after migration: its work tree is
still HOME. The new deployment does not change an existing global `core.excludesfile`
setting; inspect it separately if global ignores are hiding files.

Updating is ordinary Git workflow: inspect changes, `git pull --ff-only` in the
checkout, update submodules, and rerun setup when deployment targets change.
Removing a tracked target does not automatically remove old deployed links.

Run installer tests with `python3 tests/test_setup.py`.

For Proxmox/LXC provisioning, see [the bootstrap guide](sbin/bootstrap/README.md).
Its dotfiles module uses this same installer as the administrative user;
fresh containers clone the published repository rather than copying the host's
working tree. Bootstrap regression checks run with
`python3 tests/test_bootstrap_dotfiles.py` using temporary homes and local Git
fixtures, without provisioning a real container.

### Finding and cleaning stale symlinks

Setup reports broken links into this dotfiles checkout under known deployment
directories, even when the source file has been deleted. For example, deleting
`.ctags.d/new-config` is detected on the next run.

```bash
./setup.sh                         # report only; stale links are retained
./setup.sh --clean-stale --dry-run  # preview cleanup alongside deployment
./setup.sh --clean-stale            # back up and remove stale links
```

Cleanup saves the symlinks themselves in the normal dated backup directory; it
never removes their targets. `--backup` is still required for unrelated deployment
conflicts. All preflight checks must pass before deployment or cleanup writes.

The scan is restricted to real HOME directories corresponding to non-excluded
root directories in the checkout, plus configured merge-directory roots (even if
the source merge directory was removed). It recurses through real directories,
never through symlinked directories, and never scans top-level HOME entries.
`Library`, `Documents`, `Downloads`, `.git`, and `.dotfiles-backups` are excluded
at any depth, as is the source checkout itself. Other repositories' broken links,
live links, and regular files are left alone. Paths must target inside this exact
checkout; prefix matches such as `dotfiles-other` do not count.

Optional `cleanup_exclude` patterns in `.deploy.json` add checkout-relative-style
paths under HOME to exclude from cleanup, e.g. `[".ctags.d/local", ".config/private"]`.
Excluded real directories are pruned with all their descendants. Cleanup can find
relative targets too. It does not recover links for a completely removed top-level
directory unless that directory remains listed in `merge_directories`.

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
remotes, or company-specific shortcuts. If you also have a private/team config repo of your own, you add it as
one or more numbered tiers **symlinked** into `.rc/`, e.g. `.rc/30-team -> ~/some-private-repo/rc/30-team`.
Because the loader only cares about the `NN-*` naming convention and whether an entry is a file or
directory — not where it physically lives — a symlinked tier loads exactly like `00-core`/`20-vendor` do, no
changes needed here.

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

There is a script at `sbin/git-repo` which can be used to setup a new sub-shell environment to set repository specific environment variables and other such parameters. This script will set a few env variables and enter a new sub-shell with these variables defined and change directories to the root level of that repository. This script will use the `$WORKSPACES` environment variable to scan for valid git repositories matching the given name, or if no repository is specified, it will list all repositories.

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

#### Example Usage

```bash
dev-server ~$ echo $WORKSPACES
/home/$USER/.vim/pack/plugins/start:/home/$USER/projects
dev-server ~$ echo $WORKSPACE_SEARCH_DEPTH
1
dev-server ~$ git-repo
Multiple repositories found. Please specify which repository.

/home/$USER/.vim/pack/plugins/start/nerdtree
/home/$USER/.vim/pack/plugins/start/tagbar
/home/$USER/.vim/pack/plugins/start/devpanel-vim
/home/$USER/projects/dotfiles
/home/$USER/projects/vim-src
/home/$USER/projects/ctags

Please entry repository path: dotfiles
Entering main repository .. [/home/$USER/projects/dotfiles dotfiles@$USER/dotfiles]
dotfiles (master) dotfiles$ git status
On branch master
Your branch is up to date with 'origin/master'.

nothing to commit, working tree clean
dotfiles (master) dotfiles$ exit
exit
dev-server ~$ git-repo dotfiles
Entering main repository .. [/home/$USER/projects/dotfiles dotfiles@$USER/dotfiles]
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
is implemented once, in `$USER/binfiles`' `bld_target_resolve.bash`, and shared by `mk`/`mkesm`/`bld-target`
— see that repo for details.)

View or set it with the `bld-target` script (or `mk -d <target>`):

```bash
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

See the [.vim/](.vim/) file for more information on the VIM setup and configuration including shortcuts and further personalization options.

:information\_source: For full list of plugins, see the [.vim](.vim/) readme or the [.vim/pack/plugins/start](https://github.com/$USER/dotfiles/tree/master/.vim/pack/plugins/start) directory.

### VIM Clipboard Setup

By default VIM uses its own clipboard. The [.vimrc](.vimrc) file does override this and uses the system clipboard for autoselect as well as copy/paste functionality. If you wish to enabled this for use across SSH connections, then X11 forwarding must be enabled on the SSH session. This can be done in one of two ways.

Enable X11 forwarding per ssh session: This will enable X11 forwarding only for this specific session.

```bash
ssh -XY <hostname>
```

Enable X11 forwarding in the `.ssh/config` file: This will enable it for SSH connections as defined in the config file.

```ini
Host *.<trusted-network>
    ForwardX11 yes
    ForwardX11Trusted yes
```

> :warning: **Caution:** Only enable this for trusted hosts. Otherwise this will forward X11 parameters to all hosts.
>
> :warning: **Note:** Also special handling is needed when using visual mode selection. This is set to automatically copy to the system clipboard. If you select something using the mouse, and then while it is still selected use the scroll wheel to move the window down, additional content will be put in the clipboard other than just what was selected.

## Unicode Character Support

While not strictly needed, the vim configuration can make use of unicode characters to make things look a little nicer. This is controlled by the `USE_UNICODE` environment variable, set (and defaulted to `1`) in [.rc/00-core/00-vars.sh](.rc/00-core/00-vars.sh) — override it to `0` in a later-loading tier if you'd rather not use them. You must also make sure to have a font installed that has unicode characters. All the examples in the vim usage and configuration are shown with unicode characters enabled.

To get unicode character support on different distributions, the powerline package may need to be installed. It may also be advantageous to install the additional font packages listed here:

> [powerline](https://packages.debian.org/stretch/powerline)
> [ttf-ancient-fonts](https://packages.debian.org/buster/ttf-ancient-fonts)
> [fonts-noto](https://packages.debian.org/buster/fonts-noto)

---

## Universal CTAGS

These plugins also work better with Universal CTAGS instead of Exuberant CTAGS. This can also be compiled and installed from the source if the distribution does not already include universal ctags.

```bash
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

> - <https://www.atlassian.com/git/tutorials/dotfiles>
> - <https://www.atlassian.com/git/tutorials/git-submodule>
> - <https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh>
> - <https://docs.github.com/en/github/writing-on-github>
> - <https://www.rapidtables.com/code/text/unicode-characters.html>
> - <https://modules.readthedocs.io/en/latest/index.html>

Credit:
> <darth.gerbil@gmail.com>
