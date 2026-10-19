"""Installer regression checks. All writes use temporary fake homes/checkouts."""
import importlib.util
import os
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

SOURCE = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('setup', SOURCE / 'scripts/setup.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

with tempfile.TemporaryDirectory(prefix='dotfiles-setup-') as tmp:
    base = Path(tmp).resolve()
    repo = base / 'clone with spaces'
    repo.mkdir()
    shutil.copytree(SOURCE / 'scripts', repo / 'scripts')
    shutil.copy(SOURCE / 'setup.sh', repo / 'setup.sh')
    shutil.copy(SOURCE / '.deploy.json', repo / '.deploy.json')
    fixtures = [
        '.bashrc', '.vimrc', '.vim', '.config/flake8', '.rc/00-core',
        '.rc/20-vendor', '.rc/templates',
    ]
    for name in fixtures:
        path = repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        if name in ['.vim', '.rc/00-core', '.rc/20-vendor', '.rc/templates']:
            path.mkdir()
        else:
            path.write_text('fixture\n')
    (repo / '.ctags.d').mkdir()
    (repo / '.ctags.d/tool').write_text('fixture\n')
    (repo / 'README.md').write_text('not deployed')
    (repo / '.github').mkdir()
    (repo / '.git').mkdir()
    (repo / '.gitmodules').write_text('not deployed')
    home = base / 'home with spaces'
    home.mkdir()

    def run(*args, success=True):
        result = subprocess.run(
            [sys.executable, str(repo / 'scripts/setup.py'), '--home', str(home), *args],
            capture_output=True, text=True,
        )
        assert (result.returncode == 0) == success, result.stdout + result.stderr
        return result

    run('--dry-run')
    assert not list(home.iterdir())
    (home / '.bashrc').write_text('native startup\n')
    run(success=False)
    assert not (home / '.vimrc').exists()
    run('--backup', '--dry-run')
    assert (home / '.bashrc').read_text() == 'native startup\n'
    assert not (home / '.dotfiles-backups').exists()
    (home / '.config').mkdir()
    (home / '.config/unrelated').write_text('keep')
    run('--backup')
    assert (home / '.bashrc').resolve() == repo / '.bashrc'
    assert (home / '.config/unrelated').read_text() == 'keep'
    backups = list((home / '.dotfiles-backups').iterdir())
    assert len(backups) == 1
    assert (backups[0] / '.bashrc').read_text() == 'native startup\n'
    run()
    assert list((home / '.dotfiles-backups').iterdir()) == backups
    # New files and whole tiers are discovered without modifying installer code.
    (repo / '.new-tool').write_text('new dotfile')
    (repo / '.rc/60-extra').mkdir()
    (repo / '.rc/60-extra/00-vars.sh').write_text('export EXTRA=1\n')
    (repo / '.config/new-app').mkdir()
    (repo / '.config/new-app/settings').write_text('setting')
    (repo / '.ctags.d/new-tool').write_text('tool')
    run('--dry-run')
    assert not (home / '.new-tool').exists()
    run()
    for name in ['.new-tool', '.rc/60-extra', '.config/new-app', '.ctags.d/new-tool']:
        assert (home / name).is_symlink()
        assert (home / name).resolve() == repo / name
    assert not (home / '.rc').is_symlink()
    for name in ['README.md', '.github', '.git', '.gitmodules', '.deploy.json',
                 'setup.sh', 'scripts', 'tests']:
        assert not (home / name).exists()
    # Checkout tools are excluded; migration only backs up owned links.
    (repo / 'sbin').mkdir()
    (repo / 'sbin/tool').write_text('tool')
    run()
    assert not (home / 'sbin').exists()
    (home / 'sbin/nested').mkdir(parents=True)
    live = home / 'sbin/tool'
    live.symlink_to(repo / 'sbin/tool')
    dead = home / 'sbin/nested/dead'
    dead.symlink_to(os.path.relpath(repo / 'sbin/missing', dead.parent))
    unrelated = home / 'sbin/unrelated'
    unrelated.symlink_to(base / 'other/sbin/missing')
    local = home / 'sbin/local'
    local.write_text('keep')
    external = base / 'external-tools'
    external.mkdir()
    (external / 'keep').symlink_to(repo / 'sbin/tool')
    (home / 'sbin/external').symlink_to(external)
    assert '--migrate-sbin' in run().stdout
    run('--migrate-sbin', '--dry-run')
    assert live.is_symlink() and dead.is_symlink()
    # A deployment conflict must prevent migration, too.
    (home / '.vimrc').unlink()
    (home / '.vimrc').write_text('conflict')
    run('--migrate-sbin', success=False)
    assert live.is_symlink()
    run('--migrate-sbin', '--backup')
    assert not live.is_symlink() and not dead.is_symlink()
    for path in [live, dead]:
        # Path.glob() skips dangling symlinks before Python 3.12, so test each backup directory directly.
        copies = [session / path.relative_to(home) for session in (home / '.dotfiles-backups').iterdir()]
        assert any(copy.is_symlink() for copy in copies)
    assert unrelated.is_symlink() and local.read_text() == 'keep'
    assert (external / 'keep').is_symlink()
    assert 'LEGACY' not in run('--migrate-sbin').stdout
    shutil.rmtree(home / 'sbin')
    (home / 'sbin').symlink_to(repo / 'sbin')
    run('--migrate-sbin')
    assert not (home / 'sbin').is_symlink()
    assert (repo / 'sbin/tool').read_text() == 'tool'
    # Broken destination links are conflicts, and are backed up as links.
    (home / '.vimrc').unlink()
    (home / '.vimrc').symlink_to('/does/not/exist')
    run(success=False)
    run('--backup')
    assert (home / '.vimrc').resolve() == repo / '.vimrc'
    # Existing ~/bin checkout stays a directory; private tiers are selected.
    binfiles = home / 'bin'
    for name in ['11-home', '12-work', '40-user', '30-team', 'prompt.home', 'prompt.work']:
        (binfiles / '.rc' / name).mkdir(parents=True)
    (binfiles / '.rc/setup-rc').write_text('# fixture\n')
    run('--binfiles', str(binfiles), '--profile', 'work')
    assert not binfiles.is_symlink()
    assert (home / '.rc/30-team').is_symlink()
    run('--binfiles', str(binfiles), '--profile', 'home', '--backup')
    assert not (home / '.rc/30-team').exists()
    assert (home / '.rc/10-profile').resolve() == binfiles / '.rc/11-home'
    (repo / '.rc/10-profile').mkdir()
    result = run('--binfiles', str(binfiles), '--profile', 'home',
                 '--backup', success=False)
    assert 'Multiple deployment sources' in result.stderr
    assert (home / '.rc/10-profile').resolve() == binfiles / '.rc/11-home'
    (repo / '.rc/10-profile').rmdir()
    # A deleted source is reported without mutation, then explicitly cleaned.
    (repo / '.ctags.d/new-tool').unlink()
    stale = home / '.ctags.d/new-tool'
    (home / '.ctags.d/nested').mkdir()
    relative = home / '.ctags.d/nested/relative'
    relative.symlink_to(os.path.relpath(repo / '.ctags.d/deleted', relative.parent))
    deleted_dir = home / '.rc/deleted-tier'
    deleted_dir.symlink_to(repo / '.rc/no-longer-present')
    # Protect top-level links, unrelated targets, live links, and private trees.
    protected = []
    for name, target in [
        ('root-dead', repo / 'missing'),
        ('.ctags.d/other-repo', base / 'clone with spaces-other/missing'),
        ('.ctags.d/outside', base / 'missing'),
    ]:
        p = home / name
        p.symlink_to(target)
        protected.append(p)
    for name in ['Library', 'Documents', 'Downloads', 'unmanaged']:
        (home / name).mkdir()
        if name != 'unmanaged':
            (repo / name).mkdir()  # still never scan these known roots
        p = home / name / 'dead'
        p.symlink_to(repo / 'missing')
        protected.append(p)
    # Excluded directories would otherwise become deployment conflicts; exclude
    # their public entries too while independently checking cleanup exclusions.
    config_path = repo / '.deploy.json'
    config = json.loads(config_path.read_text())
    config['exclude'] += ['Library', 'Documents', 'Downloads']
    config['cleanup_exclude'] = ['.ctags.d/keep']
    config_path.write_text(json.dumps(config))
    (home / '.ctags.d/keep').mkdir()
    p = home / '.ctags.d/keep/dead'
    p.symlink_to(repo / 'missing')
    protected.append(p)
    (home / '.ctags.d/Library').mkdir()
    p = home / '.ctags.d/Library/dead'
    p.symlink_to(repo / 'missing')
    protected.append(p)
    # Do not traverse symlinked directories, even into this checkout.
    (repo / '.rc/00-core/source-dead').symlink_to(repo / 'missing')
    protected.append(repo / '.rc/00-core/source-dead')
    p = home / '.ctags.d/external-tree'
    p.symlink_to(base)
    regular = home / '.ctags.d/regular'
    regular.write_text('untouched')
    result = run()
    assert 'STALE ' + str(stale) in result.stdout
    assert '--clean-stale' in result.stdout
    assert stale.is_symlink() and relative.is_symlink()
    result = run('--clean-stale', '--dry-run')
    assert stale.is_symlink() and deleted_dir.is_symlink()
    # Deployment conflicts must prevent cleanup as well.
    (home / '.vimrc').unlink()
    (home / '.vimrc').write_text('conflict')
    run('--clean-stale', success=False)
    assert stale.is_symlink()
    run('--backup', '--clean-stale')
    for p in [stale, relative, deleted_dir]:
        assert not p.is_symlink()
        copies = [session / p.relative_to(home) for session in (home / '.dotfiles-backups').iterdir()]
        assert any(copy.is_symlink() for copy in copies)
    assert all(p.is_symlink() for p in protected)
    assert regular.read_text() == 'untouched'
    assert 'STALE ' not in run('--clean-stale').stdout
    # Restore the intentionally dangling source so discovery tests remain valid.
    (repo / '.rc/00-core/source-dead').unlink()
    # Never deploy through a parent link into another directory.
    shutil.rmtree(home / '.config')
    external = base / 'external'
    external.mkdir()
    (home / '.config').symlink_to(external)
    run('--backup', success=False)
    assert not list(external.iterdir())
print('PASS installer dry-run, conflicts, backups, repeat setup, private profiles, parent protection')
