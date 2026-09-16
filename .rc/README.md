# ~/.rc — Shell Environment Layout

`~/.rc/` holds this shell setup's environment configuration, organized into numbered directories ("trust
tiers") that `.bashrc` loads automatically and in a predictable order. This file describes the generic
mechanism that ships in this public repo; see "Site-specific tiers" below for how a team or individual adds
their own configuration without it ever needing to live here.

## Quick Start

This environment loads resource files in a tiered approach following this rough load order.

```text
. .bashrc
  .rc/00-core/
      . 00-vars.sh
      . 05-path-func.sh
      . 10-env.sh
      . 20-aliases.sh
      . 50-change-dir.sh
  .rc/10-vendor/
      . git-completion.bash
      . git-environment.sh
      . git-prompt.sh
      . vscode-ipc.sh
  .rc/20-team/              // if present
      . // load team/site specific resource files
  .rc/30-user/              // if present
      . // load user specific resource files
  .rc/<other-non-tiered-files>
  .rc/90-post/
      . // load any post resource files at the end
```

## How loading works

`.bashrc` calls a small recursive loader (`__rc_load`) once, at shell startup, against `~/.rc` itself. Within
any directory it processes, entries load in this order:

1. Numbered entries `00` through `89`, in numeric order. A numbered entry that's a directory recurses with
   the same rule (so a tier's own files are ordered the same way the tiers themselves are); a numbered entry
   that's a `.sh`/`.bash` file just sources.
2. Unnumbered files, in alphabetical order.
3. Numbered entries `90` through `99`, last — reserved for anything that needs to run after everything else
   (an override/cleanup band).

An **unnumbered directory** is never recursed into or sourced — only unnumbered *files* are. This is what
lets a directory like `templates/` sit at the top level purely as reference material, safe from ever being
loaded by accident.

An entry prefixed with `xx-` is always skipped, regardless of what (if anything) follows it — a way to
disable something without deleting it (e.g. rename `20-something.sh` to `xx-20-something.sh`).

## Layout shipped in this repo

| Path | Contents |
| --- | --- |
| `00-core/` | Generic bash environment: exports, path helpers, a `cd` replacement, generic aliases. Safe for anyone. |
| `10-vendor/` | Vendored third-party scripts, kept under their own upstream names, not the file-kind convention. |
| `templates/` | Reference-only starter files for adding your own site-specific tiers. Never loaded. |

The gaps in the numbering (`05`, `15`, ..., `40`-`89`) are intentional room to insert something later without
renumbering anything else.

## The file-kind convention within a tier (a pattern, not a requirement)

Nothing about the loader enforces this, but the tiers in this repo follow a consistent sub-convention so the
same number means the same kind of thing in any tier: `00` for variable/export declarations, `10` for
functions and one-time setup, `20` for aliases, `90` for an end-of-tier override hook. Adopt it, ignore it, or
invent your own — the loader only cares about the numeric prefix and whether an entry is a file or a
directory.

## Site-specific tiers (not included in this public repo)

This repo intentionally ships only generic, site-agnostic content. Anything specific to your employer, team,
or personal setup — proprietary server names, internal git remotes, company-specific directory shortcuts —
should never be committed here. The recommended pattern is to add your own numbered tiers as **symlinks**
into a separate, private location (a private repo, a different directory outside this one, wherever makes
sense for you):

```text
~/.rc/20-team   -> ~/some-private-repo/rc/20-team   (site- or team-shared config)
~/.rc/30-user   -> ~/some-private-repo/rc/30-user   (fully personal config)
```

Because the loader only cares about the `NN-*` naming convention and whether an entry is a file or a
directory — not where it physically lives — these symlinked tiers load exactly like `00-core`/`10-vendor` do,
in the same numeric position, with no changes needed to `.bashrc` or this repo. See `templates/` for a
starting point for what a site-specific tier's own files might contain.

## Other environment set up here

- `$RC_PATH` — exported by `00-core`, points at `~/.rc`. Anything that needs to reference this layout by name
  (rather than hardcoding `~/.rc` again) should use this.
- `$PROMPT_COMMAND_PATH` — also exported by `00-core`. This is a *separate* mechanism from the boot-time
  loader above: it points at a directory of scripts sourced on *every* prompt (not just once at startup), for
  things that need to stay current as the shell is used. See `.bashrc`'s `set_prompt()`.
- `$__sourced_files` — an array recording every file this session has sourced (populated by `.bashrc`'s
  `source()` wrapper), including anything sourced transitively from a file in one of these tiers. Available
  for tooling that wants to answer "where did this come from" for something defined during shell startup —
  e.g. a site-specific tier could build a smarter `which` on top of it.
- `$SILENT_SOURCING` — set to `0` for a live, indented trace of every file as it's sourced (indentation
  reflects sourcing depth, so a file sourced from a file sourced from a tier is visually nested under it).
  Defaults to `1` (silent).
