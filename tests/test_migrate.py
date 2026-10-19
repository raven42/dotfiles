"""Migration integration tests: isolated fake homes and local repositories only."""
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
        self.output = self.base / 'migration output'
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
        self.run_migration('--home', self.home, '--output', self.output, '--target', self.target)
        return next(self.output.iterdir())

    def test_preservation_and_apply(self):
        session = self.prepare()
        self.assertFalse((self.home / '.bashrc').is_symlink())
        self.assertEqual((session / 'backup/home/sbin/untracked').read_text(), 'personal tool\n')
        self.assertTrue((session / 'backup/bare-repo/HEAD').is_file())
        self.assertIn('alias mine', (session / 'bashrc.patch').read_text())
        self.run_migration('--apply', session, ok=False)
        self.assertIn('alias mine', (session / 'local/99-local/50-aliases.sh').read_text())
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

    def test_target_after_ref_accepted(self):
        (self.target / 'later').write_text('later')
        self.git('-C', str(self.target), 'add', '.')
        self.git('-C', str(self.target), 'commit', '-m', 'later')
        session = self.prepare()
        self.run_migration('--apply', session, '--accept-review')

    def test_target_before_ref_rejected(self):
        (self.target / 'later').write_text('later')
        self.git('-C', str(self.target), 'add', '.')
        self.git('-C', str(self.target), 'commit', '-m', 'later')
        self.git('-C', str(self.target), 'tag', '-f', 'v4.0')
        self.git('-C', str(self.target), 'checkout', '-q', 'HEAD~1')
        self.run_migration('--home', self.home, '--output', self.output, '--target', self.target, ok=False)
        self.assertFalse(self.output.exists())

    def test_appended_bashrc_routed_with_provenance(self):
        with (self.home / '.bashrc').open('a') as stream:
            stream.write('export MYVAR="a b"\n'
                         'if true; then\n  export NESTED=1\n  alias nested=true\nfi\n'
                         'export CHAINED=1; echo hi\n'
                         'export PATH="$PATH:/opt/x"\n'
                         'greet() {\n  echo hi\n}\n')
        tier = self.prepare() / 'local/99-local'
        marker = '# ---- Source: ~/.bashrc line'
        vars_sh, aliases, post = [(tier / n).read_text() for n in ('00-vars.sh', '50-aliases.sh', '90-post.sh')]
        self.assertIn(marker, vars_sh)
        self.assertIn('export MYVAR="a b"', vars_sh)
        self.assertIn('alias mine', aliases)
        for text in ('export NESTED=1', 'alias nested=true', 'export CHAINED=1; echo hi', 'greet()'):
            self.assertIn(text, post)
            self.assertNotIn(text, vars_sh + aliases)
        self.assertNotIn('RC_PATH', vars_sh)
        self.assertIn('export PATH="$PATH:/opt/x"', post)
        for name in ('00-vars.sh', '10-func.sh', '20-env.sh', '50-aliases.sh', '90-post.sh'):
            subprocess.run(['bash', '-n', str(tier / name)], check=True)

    def test_legacy_default_private_dirs_migrated_to_tier(self):
        for directory in ('.default', '.private'):
            (self.home / directory).mkdir()
        (self.home / '.default/common_rc.sh').write_text(
            'export FROM_COMMON=1\nexport LEGACY_DATA=$DEFAULT_RC_PATH/data.txt\n')
        (self.home / '.default/data.txt').write_text('data')
        (self.home / '.private/private_rc.sh').write_text(
            'PRIVATE_RC_PATH=${HOME}/.private\nsource "$PRIVATE_RC_PATH/extra.sh"\n')
        (self.home / '.private/extra.sh').write_text('export FROM_EXTRA=1\n')
        (self.home / '.private/post_rc.sh').write_text('export FROM_POST="$HOME/.private/post"\n')
        with (self.home / '.bashrc').open('a') as stream:
            stream.write('export APPENDED_REF="$PRIVATE_RC_PATH/x"\n')
        session = self.prepare()
        tier = session / 'local/99-local'
        self.assertIn('FROM_COMMON', (tier / '15-default-common_rc.sh').read_text())
        self.assertIn('FROM_POST', (tier / '95-private-post_rc.sh').read_text())
        self.assertEqual((tier / 'data/private/extra.sh').read_text(), 'export FROM_EXTRA=1\n')
        self.assertTrue((tier / 'data/default/data.txt').is_file())
        everything = ''.join(p.read_text() for p in tier.rglob('*') if p.is_file())
        self.assertNotIn('$DEFAULT_RC_PATH', everything)
        self.assertNotIn('$PRIVATE_RC_PATH', everything)
        self.assertNotIn('"$HOME/.private/post"', everything)
        self.assertIn('$HOME/.rc/99-local/data/private/x', (tier / '00-vars.sh').read_text())
        self.run_migration('--apply', session, '--accept-review')
        script = ('. "$HOME/.bashrc"; "$callback"; echo "$FROM_COMMON|$FROM_EXTRA|$LEGACY_DATA|$FROM_POST"')
        result = subprocess.run(['bash', '--noprofile', '--norc', '-c', script],
                                env={**os.environ, 'HOME': str(self.home)}, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout.strip().split('|'), [
                '1', '1', str(self.home) + '/.rc/99-local/data/default/data.txt',
                str(self.home) + '/.rc/99-local/data/private/post'
            ]
        )

    def test_legacy_prompt_hooks_and_completions_migrated(self):
        for directory in ('bin/prompt_command', 'bin/completions'):
            (self.home / directory).mkdir(parents=True)
        (self.home / 'bin/prompt_command/10-x.sh').write_text('export HOOK_RAN=1\n')
        (self.home / 'bin/prompt_command/notes.txt').write_text('not a hook\n')
        (self.home / 'bin/completions/x.bash').write_text('export COMPLETION_LOADED=1\n')
        session = self.prepare()
        tier = session / 'local/99-local'
        self.assertEqual((tier / 'prompt.d/10-x.sh').read_text(), 'export HOOK_RAN=1\n')
        self.assertFalse((tier / 'prompt.d/notes.txt').exists())
        everything = ''.join(p.read_text() for p in tier.glob('*.sh'))
        self.assertNotIn('PROMPT_COMMAND_PATH', everything)
        self.assertIn('bin/completions', (tier / '90-post.sh').read_text())
        self.assertIn('does not read ~/.rc/99-local/prompt.d', (session / 'REVIEW.md').read_text())
        self.run_migration('--apply', session, '--accept-review')
        self.assertEqual((self.home / '.rc/99-local/prompt.d/10-x.sh').read_text(), 'export HOOK_RAN=1\n')

    def test_home_is_read_only_during_prepare(self):
        def snapshot():
            return sorted((str(p.relative_to(self.home)), p.lstat().st_mtime_ns, p.lstat().st_size)
                          for p in self.home.rglob('*'))
        before = snapshot()
        self.prepare()
        self.assertEqual(snapshot(), before)
        self.assertFalse((self.home / '.dotfiles-migration').exists())

    def test_default_output_is_dot_dotfiles_migration_in_invoking_home(self):
        invoking = self.base / 'invoking home'
        invoking.mkdir()
        subprocess.run(['python3', str(ROOT / 'scripts/migrate.py'), '--home', str(self.home),
                        '--target', str(self.target)], check=True, capture_output=True,
                       env={**os.environ, 'HOME': str(invoking), 'PYTHONDONTWRITEBYTECODE': '1'})
        self.assertEqual(len(list((invoking / '.dotfiles-migration').iterdir())), 1)
        self.assertFalse((self.home / '.dotfiles-migration').exists())

    def test_output_overlapping_managed_path_rejected(self):
        for output in (self.home / 'sbin/out', self.home / '.cfg/out', self.target / 'out'):
            result = self.run_migration('--home', self.home, '--output', output, '--target', self.target, ok=False)
            self.assertIn('overlaps', result.stderr)

    def test_baseline_autodetected_from_nearest_tag(self):
        self.git(*self.legacy, 'tag', 'v3.1')
        result = self.run_migration('--home', self.home, '--output', self.output, '--target', self.target)
        self.assertIn('Using baseline v3.1', result.stdout)
        self.assertRegex(next(self.output.iterdir()).name,
                         r'^v3\.1-[0-9a-f]{10}-to-v4\.0-[0-9a-f]{10}-.+')

    def test_missing_baseline_tags_require_explicit_baseline(self):
        self.git(*self.legacy, 'tag', '-d', 'v3.0')
        result = self.run_migration('--home', self.home, '--output', self.output, '--target', self.target, ok=False)
        self.assertIn('--baseline', result.stderr)
        self.assertFalse(self.output.exists())

    def test_wrong_target_ref_rejected(self):
        self.git('-C', str(self.target), 'tag', '-d', 'v4.0')
        self.run_migration('--home', self.home, '--output', self.output, '--target', self.target, ok=False)
        self.assertFalse(self.output.exists())


if __name__ == '__main__':
    unittest.main()
