# Migrating a bare HOME repository to v4.0

Run `scripts/migrate.py` using Python 3. It compares the old HOME working tree
against the stock version the bare repository was based on, rather than assuming HEAD
is the upstream version. That baseline is the nearest release tag reachable from the
bare repository's HEAD (any of v1.0 to v4.0); override it with `--baseline`. This includes committed user customizations, staged edits, unstaged edits,
and untracked contents in the managed directories. It never runs legacy shell
code while inspecting it, pulls Git updates, or changes the old bare repository.

## Prepare

First create a separate, clean destination checkout at the existing `v4.0` tag (or any
later commit descended from it), including its submodules. Do not check out that tag through the old bare repo:
that would overwrite HOME before backing it up.

```bash
git clone --branch v4.0 --recurse-submodules \
  https://github.com/raven42/dotfiles.git "$HOME/Projects/dotfiles-v4"
python3 /path/to/migrate.py --target "$HOME/Projects/dotfiles-v4"
```

The migration script can run from a newer checkout or a standalone copy. It does
not need to exist in the tagged destination. `--home`, `--bare`, `--baseline`, and
`--target-ref` support alternative paths/versions; defaults are HOME, HOME/.cfg,
the nearest tag below HEAD and v4.0. The destination must be clean and at the requested commit, with
initialized submodules. Repositories borrowing external objects through Git
alternates must first be made self-contained.

Preparation creates a private `~/.dotfiles-migration/v3-to-v4-*/` directory:

- `backup/home/`: complete managed top-level directories and files, including
  untracked contents. Scope combines legacy tracked/indexed paths, new deployment
  roots, `.bashrc`, `.bash_profile`, `.bash_aliases`, `.aliases`, `.rc`, `.private`,
  `.default`, `bin`, and `sbin`. Use `--include relative/path` to include additional
  top-level HOME directories. This is a layout backup, not an entire HOME backup.
- `backup/bare-repo/`: the old Git metadata, index, refs, objects, and configuration.
- `baseline.patch`, `staged.patch`, `unstaged.patch`: diagnostic Git diffs.
- `local/99-local/`: editable variables, functions, paths, aliases and startup hooks.
- `local/files/`: private copies of customized configuration files.
- `manifest.json` and `REVIEW.md`: inventory, fingerprints and review requirements.

Permissions, executable bits and symlinks are retained. Symlinks are copied as
links: external targets are not recursively backed up. Include external resources
in your normal system backup. ACLs, extended attributes and ownership are not
promised as a filesystem-image backup would be. Keep enough disk space for full
copies of the managed trees (including `~/bin` and Vim submodules).

## Review and apply

Read `REVIEW.md` and edit `local/99-local/` before applying:

- Pure additions at the end of the original `.bashrc` are copied into `90-post.sh`.
  Other `.bashrc` and `.bash_profile` edits are retained as patches and require
  manual porting. Arbitrary removed/added diff lines are not safe shell fragments.
- Existing private/default startup files and alias files get explicit source lines
  in `90-post.sh`; review them for obsolete loader or bare-Git assumptions. The
  original files remain in HOME. Completion and prompt hook locations are retained.
- Modified and new user scripts remain in `~/sbin` and `~/bin`, ahead of public
  tools. Unchanged v3 scripts in `~/sbin` are removed after backup so they cannot
  shadow new commands or reintroduce old shell libraries.
- Customized regular configuration files take priority over public defaults.
  Existing whole-directory configuration, such as `.vim`, is preserved wholesale
  and flagged for review. This retains local plugins and deletions but also retains
  old defaults in that directory; merge new defaults manually where desired.
- Deletions and customized legacy shell libraries are listed for review. Deletions
  are not automatically translated into v4 configuration changes.

```bash
python3 /path/to/migrate.py \
  --apply "$HOME/.dotfiles-migration/v3-to-v4-EXAMPLE" --accept-review
```

`--accept-review` means you have resolved the checklist; it does not automatically
port the remaining patch fragments. Shell files undergo `bash -n` validation.
Changes to HOME, the old Git directory or destination after preparation block apply;
prepare again instead of silently discarding newer edits.

Apply uses the new installer with backups, then installs `~/.rc/99-local` with a
`shell_ready` callback. Custom shell definitions load after the public prompt and
startup functions. `00-vars.sh` also participates in repository variable refresh.
The public `.bashrc` remains the entry point. Open a fresh shell to use the result.

The migration directory contains active override files, not just backups: **keep
it in place**. Later installer runs with `--backup` can replace local config links
with public ones; review their plans and reapply your private config links if
necessary. The local tier is independent of public tiers and remains in place.
Private binfiles profile selection is a separate installer step; `~/bin` is kept.

## Recovery

Apply restores the original managed roots if an installation step fails, while
retaining diagnostics and backups. It refuses to apply a completed migration twice.

For manual recovery, start a shell without startup files (`bash --noprofile --norc`),
save any changes made since migration, and consult `manifest.json` for the root list.
Replace each listed HOME entry with its counterpart under `backup/home/`; entries
absent in the backup were originally absent. Restore directories as whole trees,
not an overlay, to remove new tier links. The original `.cfg` is left untouched;
`backup/bare-repo/` is an additional recovery copy. Do not delete the destination
checkout or migration directory while any active links still reference them.
