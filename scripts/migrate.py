#!/usr/bin/env python3
"""Prepare or apply a backed-up migration from a bare HOME repo to v4.0."""
import argparse
import difflib
import fnmatch
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import tempfile


def git(repo, *args):
    return subprocess.check_output(['git', '--no-optional-locks', '--git-dir', str(repo), *args])


UNREADABLE = {}  # path -> reason; paths that could not be read are reported, never fatal


def note_unreadable(path, error):
    UNREADABLE[str(path)] = error.strerror or str(error)


def present(path):
    """True if the path exists, including dangling symlinks; unreadable paths are noted and reported absent."""
    try:
        path.lstat()
        return True
    except (FileNotFoundError, NotADirectoryError):
        return False
    except PermissionError as error:
        note_unreadable(path, error)
        return False


def isdir(path):
    try:
        return path.is_dir()
    except PermissionError as error:
        note_unreadable(path, error)
        return False


def isfile(path):
    try:
        return path.is_file()
    except PermissionError as error:
        note_unreadable(path, error)
        return False


def walk(path, **kwargs):
    return os.walk(path, onerror=lambda error: note_unreadable(error.filename, error)
                   if isinstance(error, PermissionError) else None, **kwargs)


def copy(source, dest):
    """Copy a file, symlink or tree, skipping (and noting) anything unreadable."""
    dest.parent.mkdir(parents=True, exist_ok=True)
    try:
        if source.is_symlink():
            dest.symlink_to(os.readlink(source))
        elif source.is_dir():
            dest.mkdir(exist_ok=True)
            for child in sorted(os.listdir(source)):
                copy(source / child, dest / child)
            shutil.copystat(source, dest)
        else:
            shutil.copy2(source, dest)
    except PermissionError as error:
        note_unreadable(error.filename or source, error)


def remove(path):
    if path.is_dir() and not path.is_symlink():
        shutil.rmtree(path)
    elif present(path):
        path.unlink()


def fingerprint(path):
    """Detect edits, additions, deletions and mode changes since preparation."""
    digest = hashlib.sha256()

    def visit(p):
        digest.update(str(p.relative_to(path)).encode())
        try:
            if not present(p):
                digest.update(b'missing')
            elif p.is_symlink():
                digest.update(b'link' + os.fsencode(os.readlink(p)))
            elif p.is_dir():
                digest.update(b'dir' + str(p.stat().st_mode).encode())
                for child in sorted(p.iterdir()):
                    visit(child)
            elif p.is_file():
                digest.update(b'file' + str(p.stat().st_mode).encode())
                with p.open('rb') as stream:
                    for chunk in iter(lambda: stream.read(1024 * 1024), b''):
                        digest.update(chunk)
            else:
                raise ValueError('Unsupported special file: ' + str(p))
        except PermissionError as error:
            note_unreadable(p, error)
            digest.update(b'unreadable')
    visit(path)
    return digest.hexdigest()


def tree(repo, ref):
    entries = {}
    for record in git(repo, 'ls-tree', '-rz', ref).split(b'\0'):
        if record:
            meta, name = record.split(b'\t', 1)
            mode, kind, oid = meta.decode().split()
            entries[os.fsdecode(name)] = (mode, kind, oid)
    return entries


def target_check(target, ref):
    head = subprocess.check_output(['git', '-C', str(target), 'rev-parse', 'HEAD']).strip()
    tag = subprocess.check_output(['git', '-C', str(target), 'rev-parse', ref + '^{commit}']).strip()
    # HEAD may equal the ref or be any descendant of it (is-ancestor is true for equal commits).
    ancestor = subprocess.run(['git', '-C', str(target), 'merge-base', '--is-ancestor', tag.decode(), head.decode()])
    if ancestor.returncode == 1:
        raise ValueError('Target checkout must be at or later than ' + ref)
    if ancestor.returncode != 0:
        raise subprocess.CalledProcessError(ancestor.returncode, ancestor.args)
    dirty = subprocess.check_output(['git', '-C', str(target), 'status', '--porcelain', '--untracked-files=all'])
    untracked = subprocess.check_output(
        ['git', '-C', str(target), 'ls-files', '--others', '-z'])
    if dirty or untracked:
        raise ValueError('Target checkout must be clean, including untracked files')
    if not (target / 'scripts/setup.py').is_file():
        raise ValueError('Target must contain the standard-clone installer')
    submodules = subprocess.check_output(['git', '-C', str(target), 'submodule', 'status', '--recursive'])
    if any(line[:1] in (b'-', b'+', b'U') for line in submodules.splitlines()):
        raise ValueError('Initialize target submodules at their recorded commits first')
    return head.decode()


def detect_baseline(repo):
    """Nearest release tag reachable from the legacy HEAD, i.e. the stock version the user started from."""
    try:
        return git(repo, 'describe', '--tags', '--abbrev=0', 'HEAD').decode().strip()
    except subprocess.CalledProcessError:
        raise ValueError('Cannot detect the stock version of the legacy repo; pass --baseline <tag-or-commit>')


def session_prefix(bare, baseline, target_ref, target_commit):
    """<baseline>-<hash>-to-<target-ref>-<hash>- ; mkdtemp appends the random label."""
    def label(name):
        return re.sub(r'[^A-Za-z0-9._]+', '_', name)
    old_hash = git(bare, 'rev-parse', '--short=10', baseline + '^{commit}').decode().strip()
    return '{}-{}-to-{}-{}-'.format(label(baseline), old_hash, label(target_ref), target_commit[:10])


DATA_DIR = '$HOME/.rc/99-local/data'
PROMPT_DIR = '99-local/prompt.d'
LEGACY_DIRS = {'.default': 'default', '.private': 'private'}
# Legacy entry points sourced by the v3 .bashrc, in v3 order: (path, tier file name).
LEGACY_ENTRY = [('.default/common_rc.sh', '15-default-common_rc.sh'),
                ('.default/vscode_env.bash', '16-default-vscode_env.sh'),
                ('.private/private_rc.sh', '17-private-private_rc.sh'),
                ('.private/post_rc.sh', '95-private-post_rc.sh')]
LEGACY_VARS = ('GIT_PRIVATE_RC', 'NERDTREE_DEF_BOOKMARKS')


def rewrite_legacy_paths(text, home):
    """Point v3 DEFAULT_RC_PATH/PRIVATE_RC_PATH and ~/.default, ~/.private references at the 99-local data dir."""
    count = 0

    def sub(pattern, replacement, value, flags=0):
        nonlocal count
        value, n = re.subn(pattern, replacement, value, flags=flags)
        count += n
        return value
    text = sub(r'^([ \t]*)(?:export[ \t]+)?(DEFAULT|PRIVATE)_RC_PATH=.*$',
               r'\1# removed by migration (v4 has no \2_RC_PATH): \g<0>', text, re.M)
    for var, name in (('DEFAULT', 'default'), ('PRIVATE', 'private')):
        text = sub(r'\$\{' + var + r'_RC_PATH[^}]*\}|\$' + var + r'_RC_PATH\b', DATA_DIR + '/' + name, text)
    prefix = r'(?:\$\{HOME\}|\$HOME|~|' + re.escape(str(home)) + ')'
    text = sub(prefix + r'/\.(default|private)\b', lambda m: DATA_DIR + '/' + LEGACY_DIRS['.' + m.group(1)], text)
    return text, count


def legacy_variable_refs(text):
    return [v for v in LEGACY_VARS if re.search(r'\$\{?' + v + r'\b', text)]


def split_appended(text, first_line):
    """Split appended shell code into runs of (kind, first_line, last_line, text).

    Only top-level, single-line `export NAME=value` and `alias name=value` statements are classified
    as 'vars'/'aliases'. Everything inside a block, continuation or heredoc, and anything else, stays
    in order as 'other', so no statement is ever separated from its surrounding control flow.
    """
    runs = []
    depth = 0
    continued = False
    heredoc = False
    for number, line in enumerate(text.splitlines(True), first_line):
        words = line.split()
        first = words[0] if words else ''
        kind = 'other'
        if not continued and not heredoc and depth == 0 and not line[:1].isspace():
            match = re.match(r'(?:export\s+([A-Za-z_][A-Za-z0-9_]*)=|alias\s+[^\s=]+=)', line)
            if match and simple_line(line):
                kind = 'vars' if first == 'export' else 'aliases'
                # 00-vars.sh is re-sourced on repository changes: keep PATH-style and self-referencing
                # exports (which would accumulate) in the one-time startup file.
                name = match.group(1)
                if name and (name.endswith('PATH') or re.search(r'\$\{?' + name + r'\b', line)):
                    kind = 'other'
        if '<<' in line:
            heredoc = True
        if first in ('if', 'for', 'while', 'until', 'case', 'select') or line.rstrip().endswith('{'):
            depth += 1
        elif first in ('fi', 'done', 'esac') or line.strip() == '}':
            depth = max(depth - 1, 0)
        continued = line.rstrip('\n').endswith('\\')
        if kind == 'other' and not line.strip() and runs and runs[-1][0] != 'other':
            kind = runs[-1][0]  # keep blank separators with the run they follow
        if runs and runs[-1][0] == kind:
            runs[-1] = (kind, runs[-1][1], number, runs[-1][3] + line)
        else:
            runs.append((kind, number, number, line))
    return runs


def simple_line(line):
    """True for one self-contained statement: balanced quotes, no chaining, substitution or redirection."""
    if re.search(r'\$\(|`|<|>|\\$', line.rstrip('\n')):
        return False
    lexer = shlex.shlex(line, posix=True, punctuation_chars=True)
    lexer.whitespace_split = False
    lexer.commenters = '#'
    try:
        tokens = list(lexer)
    except ValueError:
        return False
    return not any(t and all(c in lexer.punctuation_chars for c in t) for t in tokens)


def migrate_legacy_dirs(home, stock, override, sections, headers, review):
    """Move v3 ~/.default and ~/.private contents into the 99-local tier, dropping the old layout.

    Entry points the v3 .bashrc sourced become numbered tier files; every other file is copied under
    99-local/data/{default,private}. References to the old locations and variables are rewritten.
    Files identical to the baseline (stock templates) are skipped.
    """
    entries = dict(LEGACY_ENTRY)
    migrated = []
    pending = []
    for legacy, label in LEGACY_DIRS.items():
        root = home / legacy
        if not isdir(root):
            continue
        if root.is_symlink():
            review.append('~/{} is a symlink to {}; its files were copied and the link is unchanged'.format(
                legacy, os.readlink(root)))
        for current, dirs, files in walk(root, followlinks=True):
            dirs.sort()
            for filename in sorted(files):
                path = Path(current) / filename
                rel = path.relative_to(home).as_posix()
                try:
                    content = path.read_bytes()
                except PermissionError as error:
                    note_unreadable(path, error)
                    continue
                if not path.is_file() or stock(rel, content):
                    continue
                shell = path.suffix in ('.sh', '.bash') or content.startswith(b'#!')
                try:
                    text = content.decode()
                except UnicodeDecodeError:
                    shell = False
                count = 0
                if shell:
                    text, count = rewrite_legacy_paths(text, home)
                    for variable in legacy_variable_refs(text):
                        review.append('~/{} uses ${}, which v4 no longer defines'.format(rel, variable))
                if rel in entries:
                    tier = entries[rel]
                    note = 'migrated into the tier' + ('; {} path references rewritten'.format(count) if count else '')
                    sections[tier] = ['\n# ---- Source: ~/{} ({}) ----\n'.format(rel, note)
                                      + (text if text.endswith('\n') else text + '\n')]
                    headers[tier] = '# Migrated from the v3 .default/.private layout.\n'
                    migrated.append(rel)
                else:
                    dest = override / 'data' / label / path.relative_to(root)
                    dest.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(path, dest)
                    if shell:
                        dest.write_text(text)
                    migrated.append(rel)
                    pending.append(rel)
                if count:
                    review.append('Review {} legacy path references rewritten in migrated ~/{}'.format(count, rel))
                if shell:
                    pending_text = text
                    for entry in entries:
                        base = DATA_DIR + '/' + LEGACY_DIRS['.' + entry.split('/')[0].lstrip('.')] + '/'
                        if base + entry.split('/', 1)[1] in pending_text:
                            review.append('~/{} refers to entry file ~/{}, which now lives in the tier, not under '
                                          'data/'.format(rel, entry))
    if pending:
        review.append('Review {} migrated legacy data file(s) under local/99-local/data (path '
                      '$HOME/.rc/99-local/data/...); ~/.default and ~/.private are no longer used'.format(len(pending)))
    elif migrated:
        review.append('~/.default and ~/.private are no longer used by v4; their old files remain in HOME and backup')


def safe_name(name):
    path = Path(name)
    if path.is_absolute() or '..' in path.parts or not path.parts or name == '.':
        raise ValueError('Expected a relative HOME path: ' + name)
    return path


def prepare(args):
    UNREADABLE.clear()
    home = args.home.expanduser().resolve()
    bare = args.bare.expanduser().resolve() if args.bare else home / '.cfg'
    target = args.target.expanduser().resolve()
    commit = target_check(target, args.target_ref)
    # Some HOME repos set core.bare=false; do not require that config flag.
    git(bare, 'rev-parse', '--git-dir')
    if (bare / 'objects/info/alternates').exists():
        raise ValueError('Legacy repo uses external Git objects; make it self-contained before migration')
    args.baseline = args.baseline or detect_baseline(bare)
    print('Using baseline ' + args.baseline)
    baseline = tree(bare, args.baseline)
    tracked = tree(bare, 'HEAD')
    names = set(baseline) | set(tracked)
    names.update(os.fsdecode(n) for n in git(bare, 'ls-files', '-z').split(b'\0') if n)
    target_entries = tree(target / '.git', 'HEAD')
    # Include every potential deployment root so rollback also removes new roots.
    policy = json.loads((target / '.deploy.json').read_text())
    target_roots = {n.split('/')[0] for n in target_entries}
    target_roots = {n for n in target_roots if not any(
        fnmatch.fnmatchcase(n, pattern) for pattern in policy['exclude'])}
    roots = {safe_name(n).parts[0] for n in names} | target_roots
    # Include untracked configuration files inside managed merge containers.
    for folder in policy['merge_directories']:
        directory = home / folder
        if isdir(directory) and not directory.is_symlink() and folder != '.rc':
            for current, dirs, files in walk(directory, followlinks=False):
                for name in dirs + files:
                    path = Path(current) / name
                    if not isdir(path) or path.is_symlink():
                        names.add(path.relative_to(home).as_posix())
    roots.update(['.bashrc', '.bash_profile', '.bash_aliases', '.aliases', '.rc',
                  '.private', '.default', 'sbin', 'bin'])
    roots.update(safe_name(n).parts[0] for n in args.include)
    roots.discard(bare.name if bare.parent == home else '')
    # The backup deliberately covers complete managed top-level directories.
    for name in roots:
        path = home / name
        if path == target or path in target.parents or path == bare or path in bare.parents:
            raise ValueError('Managed path contains a repository: ' + str(path))
        if name in ('.dotfiles-backups', '.dotfiles-migration'):
            raise ValueError('Reserved migration path: ' + name)
    tier = home / '.rc/99-local'
    if present(tier):
        raise ValueError('Existing .rc/99-local must be migrated manually; refusing to replace it')
    # HOME is only read during preparation; everything generated goes under the output directory.
    requested = (args.output or Path.home() / '.dotfiles-migration').expanduser()
    if requested.is_symlink():
        raise ValueError('Migration directory must not be a symlink')
    base = requested.resolve()
    for name in roots:
        path = home / name
        if base == path or base in path.parents or path in base.parents:
            raise ValueError('Output directory overlaps managed path ' + str(path) + '; choose another --output')
    for path in (target, bare):
        if base == path or base in path.parents or path in base.parents:
            raise ValueError('Output directory overlaps ' + str(path) + '; choose another --output')
    before = {n: fingerprint(home / n) for n in sorted(roots)}
    bare_before = fingerprint(bare)
    base.mkdir(mode=0o700, parents=True, exist_ok=True)
    session = Path(tempfile.mkdtemp(prefix=session_prefix(bare, args.baseline, args.target_ref, commit), dir=base))
    os.chmod(session, 0o700)
    backup = session / 'backup'
    backup.mkdir()
    for name in sorted(roots):
        if present(home / name):
            copy(home / name, backup / 'home' / name)
    copy(bare, backup / 'bare-repo')
    if before != {n: fingerprint(home / n) for n in sorted(roots)} or bare_before != fingerprint(bare):
        raise ValueError('Files changed during backup; retry preparation. Partial backup: ' + str(session))
    # Diagnostic diffs include staged and unstaged changes; baseline comparison
    # below also includes customizations committed on a user's branch.
    for label, options in [('unstaged', []), ('staged', ['--cached']), ('baseline', [args.baseline])]:
        result = subprocess.run(['git', '--no-optional-locks', '--git-dir', str(bare), '--work-tree', str(home),
                                 'diff', '--binary', *options], capture_output=True)
        if result.returncode not in (0, 1):
            # Unreadable work-tree files make git warn or fail; keep what it produced and report the rest.
            if b'ermission denied' not in result.stderr:
                raise subprocess.CalledProcessError(result.returncode, result.args, result.stdout, result.stderr)
            UNREADABLE['git diff (' + label + ')'] = 'incomplete: ' + result.stderr.decode(errors='replace').strip()
        (session / (label + '.patch')).write_bytes(result.stdout)
    local = session / 'local'
    override = local / '99-local'
    override.mkdir(parents=True)
    review = []
    overrides = []
    deleted = []
    stock_scripts = []
    appended_shell = []
    shell_names = {'.bashrc', '.bash_profile'}
    for name in sorted(names):
        path = home / name
        old = baseline.get(name)
        if old and old[1] == 'commit':
            continue  # Complete submodule working trees are in the backup.
        if not present(path):
            if old and str(path) not in UNREADABLE:
                deleted.append(name)
            continue
        try:
            if path.is_dir():
                continue
            previous = git(bare, 'cat-file', 'blob', old[2]) if old else b''
            current = os.fsencode(os.readlink(path)) if path.is_symlink() else path.read_bytes()
            mode = '120000' if path.is_symlink() else ('100755' if path.stat().st_mode & 0o111 else '100644')
        except PermissionError as error:
            note_unreadable(path, error)
            continue
        if old and previous == current and old[0] == mode:
            if name.startswith('sbin/'):
                if any(parent.is_symlink() for parent in path.parents if home in parent.parents):
                    review.append('Keep stock script behind directory symlink: ' + name + '; review PATH shadowing')
                else:
                    stock_scripts.append(name)
            continue
        if name in shell_names:
            # Arbitrary diff fragments may split functions/conditionals. Keep
            # them as evidence, never execute them automatically.
            patch = ''.join(difflib.unified_diff(previous.decode(errors='replace').splitlines(True),
                                                 current.decode(errors='replace').splitlines(True),
                                                 fromfile='v3.0/' + name, tofile='HOME/' + name))
            (session / (name.lstrip('.') + '.patch')).write_text(patch)
            if name == '.bashrc' and old and current.startswith(previous):
                appended_shell.append((name, len(previous.splitlines()) + 1, current[len(previous):].decode()))
            review.append('Review/port ' + name + ' changes into local/99-local/*.sh; see '
                          + name.lstrip('.') + '.patch')
        else:
            overrides.append(name)
            if name.startswith('sbin/') and name.endswith(('.sh', '.bash')):
                review.append('Review customized legacy shell library ' + name
                              + '; port needed functions into the tier')
    # Preserve entire user config containers to retain untracked additions and
    # modified/deleted files within whole-directory targets (e.g. Vim plugins).
    policy = json.loads((target / '.deploy.json').read_text())
    merged = policy['merge_directories']
    target_entries = tree(target / '.git', 'HEAD')
    containers = {n.split('/')[0] for n in target_entries if '/' in n
                  and n.split('/')[0] not in merged
                  and isdir(home / n.split('/')[0])
                  and n.startswith('.') and n.split('/')[0] != '.github'}
    for name in sorted(containers):
        overrides = [n for n in overrides if not n.startswith(name + '/')]
        overrides.append(name)
        review.append('Review preserved whole directory ' + name + '; local contents take precedence over v4 defaults')
    # Script directories are preserved in place and exposed before public tools.
    overrides = [n for n in overrides if n.split('/')[0] not in ('sbin', 'bin', '.rc', '.private', '.default')]
    overrides = [n for n in overrides if n not in shell_names]
    for name in overrides:
        copy(home / name, local / 'files' / name)
    generated = 'generated by migrate.py defaults; not copied from your files'
    sections = {'00-vars.sh': [], '10-func.sh': [], '20-env.sh': [], '50-aliases.sh': [], '90-post.sh': []}
    headers = {'00-vars.sh': '# User variable overrides; also reloaded on repository changes.\n',
               '10-func.sh': '# User functions.\n',
               '20-env.sh': '# Preserve user scripts ahead of public tools.\n',
               '50-aliases.sh': '# User aliases and command wrappers.\n',
               '90-post.sh': '# Legacy hooks retained for review; remove obsolete sources before apply.\n'}

    def add(filename, source, body):
        sections[filename].append('\n# ---- Source: ' + source + ' ----\n' + body)

    add('20-env.sh', generated, 'path_prepend PATH "$HOME/sbin"\npath_prepend PATH "$HOME/bin"\n')
    def stock(name, content):
        old = baseline.get(name)
        return bool(old) and old[1] == 'blob' and git(bare, 'cat-file', 'blob', old[2]) == content
    migrate_legacy_dirs(home, stock, override, sections, headers, review)
    for name in ['.bash_aliases', '.aliases']:
        if isfile(home / name):
            add('90-post.sh', 'legacy hook ~/' + name + ' (sourced, not copied)', 'source "$HOME/' + name + '"\n')
            review.append('Review generated source of ' + name + ' in 90-post.sh; original remains in HOME and backup')
    if isdir(home / 'bin/completions'):
        add('90-post.sh', 'retained ~/bin/completions/*.bash (sourced in place, not copied)',
            'for __migration_completion in "$HOME"/bin/completions/*.bash; do\n'
            '    [[ ! -f $__migration_completion ]] || source "$__migration_completion"\n'
            'done\nunset __migration_completion\n')
        review.append('Review retained ~/bin/completions shell files')
    destination = {'vars': '00-vars.sh', 'aliases': '50-aliases.sh', 'other': '90-post.sh'}
    for source, first_line, appended in appended_shell:
        appended, count = rewrite_legacy_paths(appended, home)
        if count:
            review.append('Review {} references to v3 DEFAULT/PRIVATE paths rewritten in appended ~/{} code'.format(
                count, source))
        for kind, first, last, body in split_appended(appended, first_line):
            if body.strip():
                span = 'line {}'.format(first) if first == last else 'lines {}-{}'.format(first, last)
                add(destination[kind], '~/{} {}, appended after {} (diff vs. baseline)'.format(
                    source, span, args.baseline), body if body.endswith('\n') else body + '\n')
    legacy_prompt = home / 'bin/prompt_command'
    if isdir(legacy_prompt):
        hooks = sorted(p for p in legacy_prompt.iterdir() if isfile(p) and p.suffix in ('.sh', '.bash'))
        for hook in hooks:
            (override / 'prompt.d').mkdir(exist_ok=True)
            shutil.copy2(hook, override / 'prompt.d' / hook.name)
        if hooks:
            review.append('Review {} prompt hook(s) copied from ~/bin/prompt_command to local/99-local/prompt.d; '
                          'v4 keeps PROMPT_COMMAND_PATH=~/.rc/prompt.d and also reads ~/.rc/99-local/prompt.d'.format(
                              len(hooks)))
            if PROMPT_DIR not in (target / '.bashrc').read_text():
                review.append('The target .bashrc does not read ~/.rc/99-local/prompt.d; update the dotfiles '
                              'checkout (target-ref or later) or the copied prompt hooks will not run')
    for filename, parts in sections.items():
        (override / filename).write_text(headers.get(filename, '') + ''.join(parts))
    if present(home / '.rc'):
        review.append('Review existing .rc entries for old loaders or conflicting tier names')
    if deleted:
        review.append('Review intentionally deleted v3 files listed in manifest; v4 may reintroduce them')
    for path, reason in sorted(UNREADABLE.items()):
        review.append('Unreadable, so not backed up or analyzed: {} ({})'.format(path, reason))
    manifest = dict(home=str(home), bare=str(bare), target=str(target), commit=commit,
                    target_ref=args.target_ref, baseline=args.baseline, roots=sorted(roots), fingerprints=before,
                    bare_fingerprint=bare_before, overrides=sorted(set(overrides)),
                    deleted=deleted, stock_scripts=stock_scripts, review=review, unreadable=dict(sorted(UNREADABLE.items())),
                    applied=False)
    (session / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    (session / 'REVIEW.md').write_text(
        '# Migration review\n\n' +
        '\n'.join('- [ ] ' + item for item in review) +
        '\n\nEdit local/99-local shell files before applying. Do not source the old .bashrc.\n'
        'Review local/files overrides, which intentionally win over public defaults.\n'
        'Apply requires --accept-review when this list is nonempty.\n'
        'Backup/home and backup/bare-repo are recovery copies; symlinks are preserved as links.\n'
    )
    if UNREADABLE:
        print('Skipped {} unreadable path(s); listed in REVIEW.md'.format(len(UNREADABLE)))
    print('Prepared (HOME configuration unchanged): ' + str(session))
    print('Review ' + str(session / 'REVIEW.md'))
    return session


def apply(args):
    session = args.apply.expanduser().resolve()
    data = json.loads((session / 'manifest.json').read_text())
    if data['applied']:
        raise ValueError('Migration already applied')
    if data.get('unreadable'):
        raise ValueError('Preparation skipped unreadable paths, so the backup is incomplete and recovery would be '
                         'unsafe; fix the permissions and prepare again (see REVIEW.md)')
    if data['review'] and not args.accept_review:
        raise ValueError('Review REVIEW.md and edit overrides, then use --accept-review')
    home, target, bare = map(Path, (data['home'], data['target'], data['bare']))
    if target_check(target, data['target_ref']) != data['commit']:
        raise ValueError('Target changed since preparation')
    if fingerprint(bare) != data['bare_fingerprint']:
        raise ValueError('Bare repository changed since preparation; prepare again')
    for name, digest in data['fingerprints'].items():
        if fingerprint(home / name) != digest:
            raise ValueError('HOME changed since preparation: ' + name + '; prepare again')
    for path in (session / 'local/99-local').glob('*.sh'):
        subprocess.run(['bash', '-n', str(path)], check=True)
    # v4 emits shell_ready after defining its prompt. Load private overrides
    # there so functions/aliases win without replacing the public entry point.
    tier = home / '.rc/99-local'
    staged_tier = session / 'deployed-tier'
    if staged_tier.exists():
        shutil.rmtree(staged_tier)
    staged_tier.mkdir()
    variables = shlex.quote(str(session / 'local/99-local/00-vars.sh'))
    custom = shlex.quote(str(session / 'local/99-local'))
    for linked in ('data', 'prompt.d'):
        if (session / 'local/99-local' / linked).is_dir():
            (staged_tier / linked).symlink_to(session / 'local/99-local' / linked)
    (staged_tier / '00-vars.sh').write_text('source ' + variables + '\n')
    (staged_tier / '90-post.sh').write_text(
        '__migration_load_local() { __rc_load ' + custom + '; }\n'
        'rc_on shell_ready __migration_load_local\n')
    try:
        subprocess.run([sys.executable, str(target / 'scripts/setup.py'),
                        '--home', str(home), '--backup'], check=True)
        tier.symlink_to(staged_tier)
        for name in data['overrides']:
            dest = home / name
            # Never write through a deployed parent symlink into the checkout.
            for parent in reversed(dest.parents):
                if parent == home or home not in parent.parents:
                    continue
                if parent.is_symlink():
                    src = parent.resolve()
                    parent.unlink()
                    shutil.copytree(src, parent, symlinks=True)
            remove(dest)
            dest.symlink_to(session / 'local/files' / name)
        for name in data['stock_scripts']:
            remove(home / name)
    except Exception:
        # Restore complete original managed roots. The private preparation and
        # setup backups remain for diagnosis; original bare repo was never changed.
        for name in data['roots']:
            remove(home / name)
            saved = session / 'backup/home' / name
            if present(saved):
                copy(saved, home / name)
        raise
    data['applied'] = True
    (session / 'manifest.json').write_text(json.dumps(data, indent=2) + '\n')
    print('Migration applied. Open a fresh shell. Keep the migration directory:')
    print(session)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--home', type=Path, default=Path.home())
    parser.add_argument('--bare', type=Path, help='legacy Git directory (default HOME/.cfg)')
    parser.add_argument('--target', type=Path, help='clean standard checkout at or after the target ref')
    parser.add_argument('--output', type=Path,
                        help='directory for the generated migration directory (default: ~/.dotfiles-migration); '
                             '--home is only read')
    parser.add_argument('--baseline', help='stock commit/tag the legacy repo derives from (default: nearest tag below HEAD)')
    parser.add_argument('--target-ref', default='v4.0')
    parser.add_argument('--include', action='append', default=[], help='additional HOME-relative backup path')
    parser.add_argument('--apply', type=Path, help='apply a prepared migration directory')
    parser.add_argument('--accept-review', action='store_true')
    args = parser.parse_args()
    try:
        if args.apply:
            apply(args)
        elif args.target:
            prepare(args)
        else:
            parser.error('--target is required to prepare a migration')
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        print('Migration stopped: ' + str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
