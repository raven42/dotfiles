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


def present(path):
    return path.exists() or path.is_symlink()


def copy(source, dest):
    dest.parent.mkdir(parents=True, exist_ok=True)
    if source.is_symlink():
        dest.symlink_to(os.readlink(source))
    elif source.is_dir():
        shutil.copytree(source, dest, symlinks=True)
    else:
        shutil.copy2(source, dest)


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


def safe_name(name):
    path = Path(name)
    if path.is_absolute() or '..' in path.parts or not path.parts or name == '.':
        raise ValueError('Expected a relative HOME path: ' + name)
    return path


def prepare(args):
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
        if directory.is_dir() and not directory.is_symlink() and folder != '.rc':
            for current, dirs, files in os.walk(directory, followlinks=False):
                for name in dirs + files:
                    path = Path(current) / name
                    if not path.is_dir() or path.is_symlink():
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
    base = home / '.dotfiles-migration'
    if base.is_symlink():
        raise ValueError('Migration directory must not be a symlink')
    before = {n: fingerprint(home / n) for n in sorted(roots)}
    bare_before = fingerprint(bare)
    base.mkdir(mode=0o700, exist_ok=True)
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
                                 'diff', '--binary', *options], capture_output=True, check=True)
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
            if old:
                deleted.append(name)
            continue
        if path.is_dir():
            continue
        previous = git(bare, 'cat-file', 'blob', old[2]) if old else b''
        current = os.fsencode(os.readlink(path)) if path.is_symlink() else path.read_bytes()
        mode = '120000' if path.is_symlink() else ('100755' if path.stat().st_mode & 0o111 else '100644')
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
                appended_shell.append(current[len(previous):].decode())
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
                  and (home / n.split('/')[0]).is_dir()
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
    (override / '00-vars.sh').write_text(
        '# User variable overrides; also reloaded on repository changes.\n'
        'export DEFAULT_RC_PATH="$HOME/.default"\n'
        'export PRIVATE_RC_PATH="$HOME/.private"\n'
        'export GIT_PRIVATE_RC="$HOME/.private/repo_rc.sh"\n'
        'export NERDTREE_DEF_BOOKMARKS="$HOME/.private/NERDTreeDefaultBookmarks"\n')
    (override / '10-func.sh').write_text('# User functions.\n')
    (override / '20-env.sh').write_text('# Preserve user scripts ahead of public tools.\n'
                                        'path_prepend PATH "$HOME/sbin"\npath_prepend PATH "$HOME/bin"\n')
    (override / '50-aliases.sh').write_text('# User aliases and command wrappers.\n')
    post = '# Legacy hooks retained for review; remove obsolete sources before apply.\n'
    for name in ['.default/common_rc.sh', '.default/vscode_env.bash',
                 '.private/private_rc.sh', '.bash_aliases', '.aliases', '.private/post_rc.sh']:
        if (home / name).is_file():
            post += 'source "$HOME/' + name + '"\n'
            review.append('Review generated source of ' + name + ' in 90-post.sh; original remains in HOME and backup')
    if (home / 'bin/completions').is_dir():
        post += ('for __migration_completion in "$HOME"/bin/completions/*.bash; do\n'
                 '    [[ ! -f $__migration_completion ]] || source "$__migration_completion"\n'
                 'done\nunset __migration_completion\n')
        review.append('Review retained bin/completions shell files')
    post += '\n# Custom code appended to the original .bashrc.\n' + '\n'.join(appended_shell)
    (override / '90-post.sh').write_text(post)
    if (home / '.rc').exists():
        review.append('Review existing .rc entries for old loaders or conflicting tier names')
    if (home / 'bin/prompt_command').is_dir():
        with (override / '00-vars.sh').open('a') as stream:
            stream.write('export PROMPT_COMMAND_PATH="$HOME/bin/prompt_command"\n')
        review.append('Review retained bin/prompt_command hooks and PROMPT_COMMAND_PATH')
    if deleted:
        review.append('Review intentionally deleted v3 files listed in manifest; v4 may reintroduce them')
    manifest = dict(home=str(home), bare=str(bare), target=str(target), commit=commit,
                    target_ref=args.target_ref, baseline=args.baseline, roots=sorted(roots), fingerprints=before,
                    bare_fingerprint=bare_before, overrides=sorted(set(overrides)),
                    deleted=deleted, stock_scripts=stock_scripts, review=review, applied=False)
    (session / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    (session / 'REVIEW.md').write_text(
        '# Migration review\n\n' +
        '\n'.join('- [ ] ' + item for item in review) +
        '\n\nEdit local/99-local shell files before applying. Do not source the old .bashrc.\n'
        'Review local/files overrides, which intentionally win over public defaults.\n'
        'Apply requires --accept-review when this list is nonempty.\n'
        'Backup/home and backup/bare-repo are recovery copies; symlinks are preserved as links.\n'
    )
    print('Prepared (HOME configuration unchanged): ' + str(session))
    print('Review ' + str(session / 'REVIEW.md'))
    return session


def apply(args):
    session = args.apply.expanduser().resolve()
    data = json.loads((session / 'manifest.json').read_text())
    if data['applied']:
        raise ValueError('Migration already applied')
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
