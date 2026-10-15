#!/usr/bin/env python3
"""Discover and deploy home links, preserving unrelated files and optional backups."""
import argparse
import fnmatch
import os
import datetime
from pathlib import Path
import shutil
import sys
import json
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
def discover_links(root, home):
    """Scan checkout entries; policy controls exclusions and shared containers."""
    config = json.loads((root / '.deploy.json').read_text())
    if (not isinstance(config, dict)
            or not {'merge_directories', 'exclude'} <= set(config)
            or set(config) - {'merge_directories', 'exclude', 'cleanup_exclude'}):
        raise ValueError('.deploy.json must define merge_directories and exclude')
    for key in config:
        if not isinstance(config[key], list) or not all(
                isinstance(value, str) and value for value in config[key]):
            raise ValueError(key + ' must be a list of nonempty strings')
    merged = set(config['merge_directories'])
    for name in merged:
        path = Path(name)
        if name == '.' or path.is_absolute() or '..' in path.parts or path.as_posix() != name:
            raise ValueError('Invalid merge directory: ' + name)
    links = []

    def scan(directory):
        for source in sorted(directory.iterdir()):
            relative = source.relative_to(root)
            name = relative.as_posix()
            # Git internals are never deployment targets, even with custom policy.
            if source.name == '.git':
                continue
            if any(fnmatch.fnmatchcase(name, pattern)
                   for pattern in config['exclude']):
                continue
            if name in merged or any(item.startswith(name + '/') for item in merged):
                if source.is_symlink() or not source.is_dir():
                    raise ValueError('Merge source must be a real directory: ' + name)
                scan(source)
            else:
                links.append((home / relative, source))

    scan(root)
    return links


# Never descend into personal-data folders or Git/internal backup trees by default.
CLEANUP_EXCLUDE = {'Library', 'Documents', 'Downloads', '.git', '.dotfiles-backups'}


def find_stale_links(root, home):
    """Find broken checkout-owned links under known real home directories only."""
    config = json.loads((root / '.deploy.json').read_text())
    excluded = config['exclude']
    cleanup_excluded = config.get('cleanup_exclude', [])
    # Include merge roots even if their source was deleted, so old children can
    # still be found. Never walk HOME itself or follow directory symlinks.
    names = {name.split('/')[0] for name in config['merge_directories']}
    names.update(p.name for p in root.iterdir() if p.is_dir() and not p.is_symlink())

    def skip(path):
        relative = path.relative_to(home)
        return (any(part in CLEANUP_EXCLUDE for part in relative.parts)
                or any(fnmatch.fnmatchcase(relative.as_posix(), pattern)
                       for pattern in cleanup_excluded)
                or path.resolve() == root)

    def owned_and_dead(path):
        if not path.is_symlink() or path.exists():
            return False
        target = Path(os.readlink(path))
        if not target.is_absolute():
            target = path.parent / target
        target = Path(os.path.abspath(target))
        # Check path components, not string prefixes (dotfiles-other is unrelated).
        if root not in target.parents:
            return False
        try:
            return root in target.resolve().parents
        except (OSError, RuntimeError):
            return False

    found = []
    for name in sorted(names):
        if any(fnmatch.fnmatchcase(name, pattern) for pattern in excluded):
            continue
        directory = home / name
        if directory == home or directory.is_symlink() or not directory.is_dir():
            continue
        if skip(directory):
            continue

        def walk_error(error):
            raise error

        for current, dirs, files in os.walk(directory, followlinks=False,
                                            onerror=walk_error):
            current = Path(current)
            for entry in sorted(dirs + files):
                path = current / entry
                if path.is_symlink():
                    # Do not resolve a directory symlink just to decide traversal.
                    if not any(part in CLEANUP_EXCLUDE
                               for part in path.relative_to(home).parts):
                        relative = path.relative_to(home).as_posix()
                        if not any(fnmatch.fnmatchcase(relative, pattern)
                                   for pattern in cleanup_excluded):
                            if owned_and_dead(path):
                                found.append(path)
            dirs[:] = [entry for entry in dirs
                       if not (current / entry).is_symlink()
                       and not skip(current / entry)]
    return sorted(set(found))


def find_legacy_sbin_links(root, home):
    """Find checkout-owned legacy tool links without following directory links."""
    source = root / 'sbin'
    directory = home / 'sbin'

    def owned(path):
        target = Path(os.readlink(path))
        if not target.is_absolute():
            target = path.parent / target
        target = Path(os.path.abspath(target))
        try:
            resolved = target.resolve()
        except (OSError, RuntimeError):
            return False
        return ((target == source or source in target.parents)
                and (resolved == source or source in resolved.parents))

    if directory.is_symlink():
        return [directory] if owned(directory) else []
    if not directory.is_dir():
        return []
    found = []

    def walk_error(error):
        raise error

    for current, dirs, files in os.walk(directory, followlinks=False,
                                        onerror=walk_error):
        current = Path(current)
        for name in sorted(dirs + files):
            path = current / name
            if name not in CLEANUP_EXCLUDE and path.is_symlink() and owned(path):
                found.append(path)
        dirs[:] = [name for name in dirs
                   if not (current / name).is_symlink()
                   and name not in CLEANUP_EXCLUDE]
    return sorted(found)


def present(path):
    return path.exists() or path.is_symlink()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--home', type=Path, default=Path.home(),
                        help='destination home (default: current home)')
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--clean-stale', action='store_true',
                        help='back up and remove broken checkout-owned links in known directories')
    parser.add_argument('--migrate-sbin', action='store_true',
                        help='back up old HOME/sbin links into this checkout')
    parser.add_argument('--backup', action='store_true',
                        help='move conflicting entries into a dated backup')
    parser.add_argument('--binfiles', type=Path,
                        help='optional binfiles checkout; linked at HOME/bin')
    parser.add_argument('--profile',
                        help='home, work, or a profile from binfiles/.rc/profiles/')
    args = parser.parse_args()
    home = args.home.expanduser().resolve()
    if home == ROOT or ROOT in home.parents:
        parser.error('destination home must not be inside the source checkout')
    if args.profile and not args.binfiles:
        parser.error('--profile requires --binfiles')
    try:
        links = discover_links(ROOT, home)
    except (OSError, ValueError) as error:
        parser.error(str(error))
    obsolete = []
    if args.binfiles:
        binfiles = args.binfiles.expanduser().resolve()
        if not (binfiles / '.rc/setup-rc').is_file():
            parser.error('binfiles checkout must contain .rc/setup-rc')
        # An existing checkout at ~/bin needs no replacement/link.
        if binfiles != (home / 'bin').resolve():
            links.append((home / 'bin', binfiles))
        if args.profile:
            resolver = binfiles / '.rc/profile_config.py'
            if resolver.is_file():
                result = subprocess.run(
                    [sys.executable, str(resolver), args.profile],
                    capture_output=True, text=True,
                )
                if result.returncode:
                    parser.error(result.stderr.strip())
                config = json.loads(result.stdout)
                targets = config['links']
                managed = config['managed']
            else:
                # Older binfiles checkouts still support the original profiles.
                if args.profile not in ('home', 'work'):
                    parser.error('Custom profiles require binfiles/.rc/profile_config.py')
                targets = {
                    '10-profile': '11-home' if args.profile == 'home' else '12-work',
                    '40-user': '40-user', 'prompt.d': 'prompt.' + args.profile,
                }
                if args.profile == 'work':
                    targets['30-team'] = '30-team'
                managed = ['10-profile', '40-user', '30-team', 'prompt.d',
                           '20-team', '30-user', '30-work', '31-home', '32-work']
            links += [(home / '.rc' / dest, binfiles / '.rc' / src)
                      for dest, src in targets.items()]
            obsolete += [home / '.rc' / name for name in managed if name not in targets]

    actions = []
    errors = []
    destinations = set()
    for dest, src in links:
        if dest in destinations:
            errors.append('Multiple deployment sources for: ' + str(dest))
        destinations.add(dest)
    for dest in destinations:
        if any(parent in destinations for parent in dest.parents):
            errors.append('Overlapping deployment destinations: ' + str(dest))
    for dest, src in links:
        if not src.exists():
            errors.append('Missing source: ' + str(src))
            continue
        # Shared parent directories must not redirect writes into other checkouts.
        parent = dest.parent
        while parent != home:
            if parent.is_symlink() or (parent.exists() and not parent.is_dir()):
                errors.append('Parent must be a real directory: ' + str(parent))
                break
            parent = parent.parent
        if dest.is_symlink() and dest.resolve() == src.resolve():
            continue
        if dest.is_dir() and (src == dest or dest in src.parents):
            errors.append('Cannot move a destination containing its source: ' + str(dest))
            continue
        if present(dest) and not args.backup:
            errors.append('Conflict (use --backup): ' + str(dest))
        actions.append((dest, src))
    for dest in obsolete:
        if dest in destinations:
            errors.append('Profile cleanup conflicts with discovered source: ' + str(dest))
            continue
        if not present(dest):
            continue
        if not dest.is_symlink():
            errors.append('Legacy profile path is not a symlink: ' + str(dest))
        elif not args.backup:
            errors.append('Obsolete link (use --backup): ' + str(dest))
        else:
            actions.append((dest, None))
    try:
        stale = find_stale_links(ROOT, home)
    except (OSError, ValueError) as error:
        parser.error('Unable to scan stale links: ' + str(error))
    try:
        legacy = find_legacy_sbin_links(ROOT, home)
    except (OSError, ValueError) as error:
        parser.error('Unable to scan legacy sbin links: ' + str(error))
    for path in legacy:
        print('LEGACY {} -> {}'.format(path, os.readlink(path)))
    if legacy:
        if args.migrate_sbin:
            for path in legacy:
                if any(path == dest or path in dest.parents or dest in path.parents
                       for dest in destinations):
                    errors.append('Migration conflicts with deployment: ' + str(path))
                else:
                    actions.append((path, None))
        else:
            print('Run with --migrate-sbin to back up and remove these links.')
    handled = {dest for dest, _ in actions} | destinations
    stale = [path for path in stale
             if path not in handled and not any(parent in handled for parent in path.parents)]
    for path in stale:
        print('STALE {} -> {}'.format(path, os.readlink(path)))
    if stale:
        if args.clean_stale:
            # Reuse the transactional backup path; cleanup never deletes targets.
            actions.extend((path, None) for path in stale)
        else:
            print('Run with --clean-stale to back up and remove these links.')
    for dest, src in actions:
        verb = 'BACKUP + LINK' if present(dest) else 'LINK'
        print('{} {}{}'.format(verb if src else 'BACKUP', dest,
                               ' -> ' + str(src) if src else ''))
    if errors:
        for error in errors:
            print(error, file=sys.stderr)
        return 1
    if args.dry_run:
        print('Dry run: no changes made.')
        return 0
    if not actions:
        print('Deployment links are current; reported links left unchanged.' if stale or legacy
              else 'Already deployed; no changes needed.')
        return 0

    backup = None
    # Store backups outside any destination being moved, with a unique name.
    if any(present(dest) for dest, _ in actions):
        base = home / '.dotfiles-backups'
        if base.is_symlink():
            print('Backup directory must not be a symlink: ' + str(base), file=sys.stderr)
            return 1
        base.mkdir(parents=True, exist_ok=True)
        stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S-')
        backup = Path(tempfile.mkdtemp(prefix=stamp, dir=str(base)))
    completed = []
    try:
        for dest, src in actions:
            saved = None
            if present(dest):
                saved = backup / dest.relative_to(home)
                saved.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(dest), str(saved))
            completed.append((dest, saved, src))
            if src:
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.symlink_to(src)
    except Exception:
        # Undo this run's links/moves if installation fails partway through.
        for dest, saved, src in reversed(completed):
            if src and dest.is_symlink():
                dest.unlink()
            if saved and present(saved):
                shutil.move(str(saved), str(dest))
        raise
    if backup:
        print('Previous entries saved in: ' + str(backup))
    print('Deployment complete. Open a fresh shell. The old ~/.cfg is untouched.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
