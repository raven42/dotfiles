# Shell configuration

`.bashrc` loads numbered tier directories under `~/.rc` in order. The standard
layout is `00-core`, `10-profile`, `20-vendor`, `30-team`, `40-user`.
The private tiers are optional symlinks selected by `~/bin/.rc/setup-rc home|work`.
Core defaults support loading without a profile; team settings load only at work.

Each tier uses:

| File | Responsibility |
| --- | --- |
| `00-vars.sh` | Re-sourceable defaults and derived/exported variables |
| `10-func.sh` | Helper function definitions |
| `20-env.sh` | PATH changes and one-time initialization |
| `50-aliases.sh` | Aliases/command-like functions, with local `$CD` detection |
| `90-post.sh` | Final startup overrides |

Within a directory, numbered `00`–`89` entries load first, unnumbered shell files
next, and `90`–`99` entries last. Numbered directories recurse; unnumbered directories
(such as `scripts`, `templates`, `tests`, and `prompt.d`) are not auto-loaded.
Entries beginning with `xx-` are disabled. Vendor files retain their names under
`20-vendor/scripts`, explicitly sourced from numbered wrappers.

`source` tracks unique files in `__sourced_files`. Set `SILENT_SOURCING=0` after
startup to trace subsequent includes. The wrapper quotes filenames and preserves
source arguments/status.

## Repository and virtualenv updates

After all tiers load, Git state and the nearest `.venv` are initialized.
`change_dir` repeats these checks after successful directory changes. Git context
changes re-source every active `00-vars.sh`, using the same tier order and disabled
entry rules as startup. No tool initialization files run during refresh. An optional
`rc_update_repo_paths` hook updates derived paths after variable refresh.

The nearest `.venv/bin/activate` wins. An automatically activated environment is
not repeatedly sourced within the same tree and is deactivated on leaving it.
Manually activated/inherited environments are preserved. Set `RC_AUTO_VENV=0` to
opt out. Keep PATH mutations and function definitions out of `00-vars.sh`.

## Profile and prompt links

`10-profile` points at private `11-home` or `12-work`; `40-user` is shared.
`30-team` is linked only for work. `prompt.d` points at `prompt.home` or
`prompt.work`. The prompt loader reads that single directory and skips `xx-*` files.
See `~/bin/.rc/README.md` for setup and cache details.

Home defaults to `XDG_CACHE_HOME=$HOME/.cache`. The work profile selects a work-local
cache. Cache directories never belong in executable PATH.

Use a fresh shell after switching profiles; re-sourcing does not remove definitions
from the previous profile. Both repositories need the corresponding migration.

## Event callbacks

Register a defined function from a tier's `20-env.sh`:

```bash
function my_directory_update() {
    local previous_dir=$1 current_dir=$2
    # Update the current shell here.
}
rc_on change_dir my_directory_update
rc_off change_dir my_directory_update  # optional removal
```

Define helpers in `10-func.sh`. `change_dir` emits `change_dir OLD NEW` after
successful changes (including `cd .`), but not after failures or `cd --` listings.
`rc_emit shell_ready "$PWD"` runs once at the end of each `.bashrc` load, after all
tiers and prompt helpers exist. Git and virtualenv integrations register for both.

Callbacks run in registration order in the current shell. Duplicate registrations
are ignored, so re-sourcing is safe. Removal is idempotent; removing and registering
again places a callback last. Each emission snapshots the registry, so registration
changes inside callbacks affect the next emission. Arguments are forwarded without
word splitting or eval. Event and callback names use letters, digits and underscores
and cannot start with a digit. Functions must exist when registered.

`rc_emit` continues after missing/failing callbacks, reports them to stderr, and
returns 1 if any failed (otherwise 0). A successful `cd` still returns 0. Emit custom
events with `rc_emit event_name ...`; an event without listeners is a no-op.
Avoid emitting the same event recursively from its own callback.

`change_dir` is defined once in `00-core/11-change-dir.sh` along with it's alias.
Git registers `update_git_environment` for `change_dir` and
`shell_ready`. When Git context changes it emits `git_environment_changed OLD_ROOT
NEW_ROOT` (an empty root means outside a repository). Core registers
`__rc_refresh_vars` for this event; additional listeners can inspect the updated
`GIT_*` variables. Moving within the same repository does not emit this Git event.
