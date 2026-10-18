"""Migration integration tests: isolated fake homes and local repositories only."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class MigrationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.home = self.base / 'home with spaces'
        self.home.mkdir()
        self.old = self.home / '.cfg'
        self.git('init', '--bare', str(self.old))
        self.legacy = ['--git-dir', str(self.old), '--work-tree', str(self.home)]
        for name, text in {'.bashrc': '# old startup\n', '.bash_profile': '. ~/.bashrc\n',
                           '.tmux.conf': 'stock\n', 'sbin/tool': 'stock tool\n',
                           'sbin/custom': 'original tool\n'}.items():
            p = self.home / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(text)
        self.git(*self.legacy, 'add', '.bashrc', '.bash_profile', '.tmux.conf', 'sbin')
        self.git(*self.legacy, 'commit', '-m', 'baseline')
        self.git(*self.legacy, 'tag', 'v3.0')
        (self.home / 'sbin/custom').write_text('committed user tool\n')
        self.git(*self.legacy, 'add', 'sbin/custom')
        self.git(*self.legacy, 'commit', '-m', 'user customizations')
        (self.home / '.bashrc').write_text('# old startup\nalias mine="echo mine"\n')
        (self.home / '.tmux.conf').write_text('local settings\n')
        (self.home / 'sbin/untracked').write_text('personal tool\n')
        self.target = self.base / 'target clone'
        self.target.mkdir()
        shutil.copytree(ROOT / 'scripts', self.target / 'scripts',
                        ignore=shutil.ignore_patterns('__pycache__'))
        shutil.copy(ROOT / '.deploy.json', self.target / '.deploy.json')
        (self.target / '.bashrc').write_text(
            '__rc_load() { for f in "$1"/*.sh; do . "$f"; done; }\n'
            'path_prepend() { :; }\nexport NEW_LAYOUT=yes\n'
            'rc_on() { callback=$2; }\n'
            'if [ -d "$HOME/.rc/99-local" ]; then\n'
            '  __rc_load "$HOME/.rc/99-local"; "$callback"; fi\n')
        (self.target / '.bash_profile').write_text('. ~/.bashrc\n')
        (self.target / '.tmux.conf').write_text('new settings\n')
        (self.target / '.rc/00-core').mkdir(parents=True)
        (self.target / '.rc/00-core/00-vars.sh').write_text('# fixture\n')
        self.git('init', str(self.target))
        self.git('-C', str(self.target), 'add', '.')
        self.git('-C', str(self.target), 'commit', '-m', 'new')
        self.git('-C', str(self.target), 'tag', 'v4.0')

    def git(self, *args):
        return subprocess.run(['git', '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
                               *args], capture_output=True, check=True).stdout

    def run_migration(self, *args, ok=True):
        result = subprocess.run(['python3', str(ROOT / 'scripts/migrate.py'), *map(str, args)],
                                capture_output=True, text=True,
                                env={**os.environ, 'PYTHONDONTWRITEBYTECODE': '1'})
        self.assertEqual(result.returncode == 0, ok, result.stdout + result.stderr)
        return result

    def prepare(self):
        self.run_migration('--home', self.home, '--target', self.target)
        return next((self.home / '.dotfiles-migration').iterdir())

    def test_preservation_and_apply(self):
        session = self.prepare()
        self.assertFalse((self.home / '.bashrc').is_symlink())
        self.assertEqual((session / 'backup/home/sbin/untracked').read_text(), 'personal tool\n')
        self.assertTrue((session / 'backup/bare-repo/HEAD').is_file())
        self.assertIn('alias mine', (session / 'bashrc.patch').read_text())
        self.run_migration('--apply', session, ok=False)
        self.assertIn('alias mine', (session / 'local/99-local/90-post.sh').read_text())
        self.run_migration('--apply', session, '--accept-review')
        self.assertEqual((self.home / '.tmux.conf').read_text(), 'local settings\n')
        self.assertEqual((self.home / 'sbin/custom').read_text(), 'committed user tool\n')
        self.assertFalse((self.home / 'sbin/tool').exists())
        self.assertTrue((self.home / 'sbin/untracked').exists())
        result = subprocess.run(['bash', '--noprofile', '--norc', '-c',
                                 '. "$HOME/.bashrc"; alias mine; test "$NEW_LAYOUT" = yes'],
                                env={**os.environ, 'HOME': str(self.home)}, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(b'echo mine', result.stdout)
        self.run_migration('--apply', session, '--accept-review', ok=False)

    def test_changes_after_prepare_block_apply(self):
        session = self.prepare()
        (self.home / 'sbin/untracked').write_text('changed')
        result = self.run_migration('--apply', session, '--accept-review', ok=False)
        self.assertIn('HOME changed', result.stderr)
        self.assertFalse((self.home / '.bashrc').is_symlink())

    def test_failed_installer_restores_home(self):
        # Installer will refuse a symlinked shared parent before doing any writes.
        external = self.base / 'external'
        external.mkdir()
        (self.home / '.rc').symlink_to(external)
        session = self.prepare()
        self.run_migration('--apply', session, '--accept-review', ok=False)
        self.assertEqual((self.home / '.bashrc').read_text(), '# old startup\nalias mine="echo mine"\n')
        self.assertTrue((self.home / '.rc').is_symlink())
        self.assertEqual(list(external.iterdir()), [])

    def test_nested_config_preserved_without_changing_target(self):
        (self.target / '.config/app').mkdir(parents=True)
        (self.target / '.config/app/new').write_text('new default')
        self.git('-C', str(self.target), 'add', '.')
        self.git('-C', str(self.target), 'commit', '-m', 'config')
        self.git('-C', str(self.target), 'tag', '-f', 'v4.0')
        (self.home / '.config/app').mkdir(parents=True)
        (self.home / '.config/app/user').write_bytes(b'personal\x00binary')
        session = self.prepare()
        self.run_migration('--apply', session, '--accept-review')
        self.assertEqual((self.home / '.config/app/user').read_bytes(), b'personal\x00binary')
        self.assertEqual((self.home / '.config/app/new').read_text(), 'new default')
        self.assertFalse((self.target / '.config/app/user').exists())

    def test_wrong_target_ref_rejected(self):
        self.git('-C', str(self.target), 'tag', '-d', 'v4.0')
        self.run_migration('--home', self.home, '--target', self.target, ok=False)
        self.assertFalse((self.home / '.dotfiles-migration').exists())


if __name__ == '__main__':
    unittest.main()
