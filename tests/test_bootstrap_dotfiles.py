"""Exercise the copied LXC module with local Git fixtures and fake user commands.

No Proxmox calls, package changes, network access, or real HOME writes. Only the
root guard is replaced in the test copy; sudo/install/id/getent are test shims.
The Git clone, submodules, symlink installer, and backup operations are real.
"""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


def git(*args, cwd):
    result = subprocess.run(['git', *args], cwd=cwd, capture_output=True, text=True)
    if result.returncode:
        raise RuntimeError(result.stderr)
    return result.stdout.strip()


class BootstrapDotfilesTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='bootstrap-dotfiles-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.home = self.base / 'user home'
        self.home.mkdir()
        self.upstream = self.base / 'upstream'
        self.upstream.mkdir()
        shutil.copy(ROOT / 'setup.sh', self.upstream)
        shutil.copy(ROOT / '.deploy.json', self.upstream)
        shutil.copytree(ROOT / 'scripts', self.upstream / 'scripts',
                        ignore=shutil.ignore_patterns('__pycache__'))
        (self.upstream / '.bashrc').write_text('new shell\n')
        (self.upstream / '.rc/00-core').mkdir(parents=True)
        (self.upstream / '.rc/00-core/vars.sh').write_text('new variables\n')
        git('init', cwd=self.upstream)
        git('add', '.', cwd=self.upstream)
        git('-c', 'user.name=Bootstrap Test', '-c', 'user.email=test@example.invalid',
            'commit', '-m', 'fixture', cwd=self.upstream)
        submodule = self.base / 'vim fixture'
        submodule.mkdir()
        (submodule / 'fixture').write_text('vim fixture\n')
        git('init', cwd=submodule)
        git('add', '.', cwd=submodule)
        git('-c', 'user.name=Bootstrap Test', '-c', 'user.email=test@example.invalid',
            'commit', '-m', 'fixture', cwd=submodule)
        git('-c', 'protocol.file.allow=always', 'submodule', 'add', str(submodule),
            '.vim', cwd=self.upstream)
        git('-c', 'user.name=Bootstrap Test', '-c', 'user.email=test@example.invalid',
            'commit', '-am', 'submodule', cwd=self.upstream)
        self.shims = self.base / 'commands'
        self.shims.mkdir()
        shims = {
            'id': 'if [ "$1" = -gn ]; then echo bootstrap-test; fi\n',
            'getent': 'printf "bootstrap-test:x:1000:1000::%s:/bin/bash\\n" "$TEST_USER_HOME"\n',
            'sudo': '[ "$1" = -u ] || exit 90\nshift 2\nexec env "$@"\n',
            'install': '[ "$1" = -d ] || exit 91\nshift\n'
                       'while [ "$#" -gt 0 ]; do\n'
                       'case "$1" in -o|-g) shift 2;; *) mkdir -p "$1"; shift;; esac\ndone\n',
        }
        for name, body in shims.items():
            path = self.shims / name
            path.write_text('#!/bin/sh\nset -eu\n' + body)
            path.chmod(0o755)
        source = (ROOT / 'sbin/bootstrap/setup/dotfiles.sh').read_text()
        guard = '[[ "${EUID}" -eq 0 ]]'
        assert source.count(guard) == 1
        self.script = self.base / 'setup-dotfiles.sh'
        self.script.write_text(source.replace(guard, 'true'))
        self.env = dict(os.environ, TEST_USER_HOME=str(self.home),
                        DOTFILES_REPO=str(self.upstream), ADMIN_USER='bootstrap-test',
                        GIT_ALLOW_PROTOCOL='file', GIT_CONFIG_NOSYSTEM='1',
                        GIT_CONFIG_GLOBAL=os.devnull,
                        PATH=str(self.shims) + os.pathsep + os.environ['PATH'])
        self.checkout = self.home / 'Projects/dotfiles'

    def run_module(self, *args, success=True):
        result = subprocess.run(['bash', str(self.script), *args], env=self.env,
                                capture_output=True, text=True, cwd=self.base)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def test_fresh_clone_migrates_legacy_home_and_repeat_preserves_edits(self):
        (self.home / '.cfg').mkdir()
        (self.home / '.cfg/legacy').write_text('keep repository')
        (self.home / '.bashrc').write_text('old shell')
        (self.home / '.gitconfig').write_text('[core]\n\texcludesfile = ~/.gitignore_global\n')
        (self.home / '.gitignore_global').write_text('.cfg\n')
        (self.home / '.rc/00-core').mkdir(parents=True)
        (self.home / '.rc/00-core/vars.sh').write_text('old variables')
        (self.home / '.rc/private').mkdir()
        self.run_module()
        self.assertEqual((self.home / '.bashrc').resolve(), self.checkout / '.bashrc')
        self.assertTrue((self.home / '.vim/fixture').is_file())
        self.assertFalse((self.home / '.rc').is_symlink())
        self.assertTrue((self.home / '.rc/private').is_dir())
        self.assertEqual((self.home / '.cfg/legacy').read_text(), 'keep repository')
        self.assertIn('excludesfile', (self.home / '.gitconfig').read_text())
        self.assertEqual((self.home / '.gitignore_global').read_text(), '.cfg\n')
        backups = list((self.home / '.dotfiles-backups').iterdir())
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / '.bashrc').read_text(), 'old shell')
        self.assertEqual((backups[0] / '.rc/00-core/vars.sh').read_text(), 'old variables')
        (self.checkout / '.bashrc').write_text('local edits')
        (self.checkout / '.vim/fixture').write_text('local submodule edits')
        self.run_module()
        self.assertEqual((self.home / '.bashrc').read_text(), 'local edits')
        self.assertEqual((self.home / '.vim/fixture').read_text(), 'local submodule edits')
        self.assertEqual(list((self.home / '.dotfiles-backups').iterdir()), backups)

    def test_unrelated_directory_is_not_executed(self):
        self.checkout.mkdir(parents=True)
        (self.checkout / 'setup.sh').write_text('touch "' + str(self.home / 'unexpected') + '"')
        self.run_module(success=False)
        self.assertFalse((self.home / 'unexpected').exists())

    def test_old_checkout_without_installer_fails_before_home_changes(self):
        self.run_module()
        (self.checkout / 'scripts/setup.py').unlink()
        result = self.run_module(success=False)
        self.assertIn('missing scripts/setup.py', result.stderr)

    def test_existing_checkout_requires_initialized_submodules(self):
        self.checkout.parent.mkdir(parents=True)
        git('clone', str(self.upstream), str(self.checkout), cwd=self.base)
        result = self.run_module(success=False)
        self.assertIn('Uninitialized submodules', result.stderr)
        self.assertFalse((self.home / '.bashrc').exists())

    def test_broken_checkout_link_fails_without_cloning_over_it(self):
        self.checkout.parent.mkdir(parents=True)
        self.checkout.symlink_to(self.base / 'missing')
        result = self.run_module(success=False)
        self.assertIn('Not a checkout directory', result.stderr)
        self.assertTrue(self.checkout.is_symlink())

    def test_missing_user_argument_has_clear_error(self):
        self.assertIn('--user requires a username',
                      self.run_module('--user', success=False).stderr)


if __name__ == '__main__':
    unittest.main()
