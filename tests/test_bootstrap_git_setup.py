"""Real Git configuration in temporary homes; Proxmox calls are recorded only."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
BOOTSTRAP = ROOT / 'sbin/bootstrap'
GLOG = "log --graph --all --pretty=format:'%C(yellow)%h%Creset %C(red)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'"


class GitSetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='git-bootstrap-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.home = self.base / 'admin home'
        self.home.mkdir()
        self.commands = self.base / 'commands'
        self.commands.mkdir()
        for name, body in {
            'id': 'if [ "$1" = -un ]; then echo admin; fi\n',
            'getent': 'printf "admin:x:1000:1000::%s:/bin/bash\\n" "$TEST_USER_HOME"\n',
        }.items():
            path = self.commands / name
            path.write_text('#!/bin/sh\nset -eu\n' + body)
            path.chmod(0o755)
        self.env = dict(os.environ, ADMIN_USER='admin', TEST_USER_HOME=str(self.home),
                        XDG_CONFIG_HOME=str(self.home / '.config'),
                        GIT_CONFIG_NOSYSTEM='1',
                        PATH=str(self.commands) + os.pathsep + os.environ['PATH'])
        for key in list(self.env):
            if key.startswith('GIT_SETUP_') or key.startswith('GIT_CONFIG_') and key != 'GIT_CONFIG_NOSYSTEM':
                self.env.pop(key)

    def run_setup(self, *args, success=True):
        result = subprocess.run(['bash', str(BOOTSTRAP / 'setup/git-setup.sh'), *args],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def config(self, *args):
        env = dict(self.env, HOME=str(self.home))
        return subprocess.check_output(['git', 'config', '--global', *args], env=env, text=True).strip()

    def test_defaults_alias_and_repeat_preserve_unrelated_settings(self):
        (self.home / '.gitconfig').write_text('[core]\n\teditor = nano\n')
        self.run_setup()
        self.assertEqual(self.config('--get', 'user.username'), 'raven42')
        self.assertEqual(self.config('--get', 'user.name'), 'David Hegland')
        self.assertEqual(self.config('--get', 'user.email'), 'darth.gerbil@gmail.com')
        self.assertEqual(self.config('--get', 'alias.glog'), GLOG)
        first = (self.home / '.gitconfig').read_bytes()
        self.run_setup()
        self.assertEqual((self.home / '.gitconfig').read_bytes(), first)
        self.assertEqual(self.config('--get', 'core.editor'), 'nano')
        # Exercise Git's alias parser against a real commit, without any network.
        repo = self.base / 'repository'
        repo.mkdir()
        env = dict(self.env, HOME=str(self.home))
        for args in [('init',), ('commit', '--allow-empty', '-m', 'alias test'), ('glog', '-1')]:
            result = subprocess.run(['git', *args], cwd=repo, env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('alias test', result.stdout)
        self.assertIn('David Hegland', result.stdout)

    def test_overrides_are_data_and_do_not_change_target_account(self):
        name = 'A Person $(touch should-not-exist)'
        self.run_setup('--user', 'different-user', '--name', name, '--email', 'person@example.invalid')
        self.assertEqual(self.config('--get', 'user.username'), 'different-user')
        self.assertEqual(self.config('--get', 'user.name'), name)
        self.assertEqual(self.config('--get', 'user.email'), 'person@example.invalid')
        self.assertFalse((ROOT / 'should-not-exist').exists())

    def test_missing_options_fail_before_configuration(self):
        for option in ('--user', '--name', '--email'):
            self.assertIn('requires a value', self.run_setup(option, success=False).stderr)
        self.assertFalse((self.home / '.gitconfig').exists())

    def test_create_and_apply_forward_identity_as_separate_arguments(self):
        bootstrap = self.base / 'bootstrap'
        shutil.copytree(BOOTSTRAP, bootstrap)
        common = bootstrap / 'lib/proxmox-lxc-common.sh'
        source = common.read_text()
        guard = '[[ "${EUID}" -eq 0 ]]'
        self.assertEqual(source.count(guard), 1)
        common.write_text(source.replace(guard, 'true'))
        calls = self.base / 'pct-calls.jsonl'
        pct = self.commands / 'pct'
        pct.write_text('#!' + shutil.which('python3') + '\n' + '''import json, os, sys
with open(os.environ['TEST_PCT_CALLS'], 'a') as stream:
    stream.write(json.dumps(sys.argv[1:]) + '\\n')
if sys.argv[1] == 'status':
    if os.environ['TEST_SUBCOMMAND'] == 'create':
        sys.exit(1)
    print('status: running')
''')
        pct.chmod(0o755)
        key = self.base / 'key.pub'
        key.write_text('fixture public key')
        name = 'Name With Spaces'
        for command in ('create', 'apply'):
            calls.write_text('')
            env = dict(self.env, TEST_PCT_CALLS=str(calls), TEST_SUBCOMMAND=command)
            args = ['bash', str(bootstrap / 'lib/commands' / (command + '.sh')),
                    '--vmid', '123', '--user', 'admin', '--ssh-key', str(key),
                    '--setup', 'git-setup', '--setup', 'nut', '--git-user', 'git-user',
                    '--git-name', name, '--git-email', 'name@example.invalid']
            if command == 'create':
                args += ['--hostname', 'test.invalid', '--template', 'local:vztmpl/fixture']
            result = subprocess.run(args, env=env, input='fixture-password\nfixture-password\n',
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            invocations = [json.loads(line) for line in calls.read_text().splitlines()]
            expected = ['exec', '123', '--', 'env', 'ADMIN_USER=admin',
                        '/root/setup-git-setup.sh', '--user', 'git-user', '--name', name,
                        '--email', 'name@example.invalid']
            self.assertIn(expected, invocations)
            self.assertIn(['exec', '123', '--', 'env', 'ADMIN_USER=admin',
                           '/root/setup-nut.sh'], invocations)


if __name__ == '__main__':
    unittest.main()
