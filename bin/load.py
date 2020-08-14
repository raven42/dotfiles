#!/usr/bin/python

import sys
import argparse
import telnetlib
import logging as log
import pexpect
import os
import time

HOST = ''
USER = 'root'
PASS = 'fibranne'

verbose = False
pretend = False

def_login = 'root'
def_password = 'fibranne'
def_local_path = os.path.expanduser('~')
def_remote_path = '/tftpboot'
def_image_file = 'esmmod.tar'
def_backup_file = 'esmbak.tar'

load_timeout = 180
login_timeout = 15

prompt = '$ '

parser = argparse.ArgumentParser(description='This script will load %s from your default '
        '/home path onto all switches in the host list. It will then load the binaries on '
        'the switch and can optionally reboot/hareboot the switches. If no backkup exists, '
        'then a backup of existing image files will be created on the switch. Use the '
        'following command to restore original images: cd / && tar -xvf %s/%s'
        % (def_image_file, def_remote_path, def_backup_file))
parser.add_argument('hostname', help='Add <hostname> to host list',
        nargs='+')
parser.add_argument('-v', '--verbose', help='Enable verbose logging',
        default=0, action='store_true')
parser.add_argument('-b', '--backup', help='Force creation of backup images',
        default=False, action='store_true')
parser.add_argument('-r', '--reboot', help='Reset the switch after loading code',
        default=False, action='store_true')
parser.add_argument('--hareboot', help='Reset the switch using hareboot',
        default=False, action='store_true')
parser.add_argument('--login', help='Set the login name',
        default=def_login)
parser.add_argument('--password', help='Set the password',
        default=def_password)
parser.add_argument('--image', help='Set the image file to load',
        default=def_image_file)
parser.add_argument('--orig-image', help='Set the filename to store the original imagee file as',
        default=def_backup_file)
parser.add_argument('--local-path', help='Set the local-path used to find the image file',
        default=def_local_path)
parser.add_argument('--remote-path', help='Set the remote-path used to place the image file',
        default=def_remote_path)
parser.add_argument('--pretend', help='Don\'t actually run anything. Only show steps.',
        default=False, action='store_true')

log.basicConfig(format='%(asctime)s - [%(levelname)s]: %(message)s', datefmt='%m/%d/%Y %I:%M:%S %p',
        level=log.INFO)


def loadcode(hostname, username, password, image_file, local_path, remote_path):
    global verbose, pretend
    rc = 0

    log.debug('Copying %s/%s to %s@%s:%s/%s...'
              % (local_path, image_file, username, hostname, remote_path, image_file))
    cmd = 'scp %s/%s %s@%s:%s/%s' % (local_path, image_file, username, hostname, remote_path, image_file)
    log.debug(cmd)

    if pretend:
        return rc

    # Run SCP command in new bash shell instance. This will allow us
    # to search for a prompt at completion instead of running SCP
    # directly. Running directly can result in timeouts or EOF due to
    # the escape codes that SCP uses to control terminal output.
    child = pexpect.spawn(cmd)
    child.logfile_read = sys.stdout

    if verbose:
        child.logfile_write = sys.stdout

    # child.sendline(cmd)

    try:
        rc = child.expect(['(?i)password:', r'yes/no', pexpect.EOF], timeout=login_timeout)
        if rc == 0:
            child.sendline(password)
            rc = 0
            child.expect(pexpect.EOF, timeout=load_timeout)

        elif rc == 1:
            child.sendline('yes')
            child.expect(['(?i)password:', pexpect.EOF], timeout=login_timeout)
            if rc == 0:
                child.sendline(password)
                rc = 0
                child.expect(pexpect.EOF, timeout=load_timeout)
            elif rc == 1:
                log.error('{%s} - Unexpected EOF. Unable to connect to switch' % hostname)
                rc = 1

        elif rc == 2:
            log.error('{%s} - Unexpected EOF. Unable to connect to switch' % hostname)
            rc = 1

    except pexpect.TIMEOUT:
        log.debug('{%s} - TIMEOUT detected' % hostname)
        rc = 1

    child.close()
    log.debug('{%s} - exit_code:%d' % (hostname, child.exitstatus))
    return rc


def runcmd(session, command, prompt='> '):
    global verbose, pretend

    # log.debug(command)
    if pretend:
        log.debug('{%s}: %s' % (session[1], command))
        return

    session[0].write(command + '\n')
    output = session[0].read_until(prompt)
    log.debug('{%s}: %s' % (session[1], output))

    return output


def connect(hostname, username, password):
    global verbose, pretend

    log.info('Connecting to host:' + hostname)
    if pretend:
        return (0, hostname)

    try:
        session = (telnetlib.Telnet(hostname, port=23, timeout=5), hostname)

        log.debug('Connected.... logging into switch')
        log.debug(session[0].read_until('login: '))

        runcmd(session, username, 'Password: ')
        runcmd(session, password)
        runcmd(session, 'cd /')

        log.debug('Connected to %s, adding to session list' % hostname)

        return session

    except IOError:
        log.error('Failed to connect to host:%s' % hostname)


def main():
    global verbose, pretend

    session_list = []
    hostlist = []

    args = parser.parse_args()

    verbose = args.verbose
    hostnames = args.hostname
    username = args.login
    password = args.password
    local_path = args.local_path
    remote_path = args.remote_path
    image_file = args.image
    backup_file = args.orig_image
    reboot = args.reboot
    hareboot = args.hareboot
    backup = args.backup
    pretend = args.pretend

    logger = log.getLogger()
    if verbose:
        logger.setLevel(log.DEBUG)

    log.debug('hostnames:[%s]' % ', '.join(map(str, hostnames)))
    log.debug('username:' + username)
    log.debug('password:' + password)
    log.debug('local_path:' + local_path)
    log.debug('remote_path:' + remote_path)
    log.debug('image_file:' + image_file)
    log.debug('backup_file:' + backup_file)
    log.debug('reboot:%r' % reboot)
    log.debug('hareboot:%r' % hareboot)
    log.debug('backup:%r' % backup)

    log.info('Copying image files to switch...')
    for hostname in hostnames:
        rc = loadcode(hostname, username, password, image_file, local_path, remote_path)
        if rc != 0:
            log.warning('{%s}: code load failed' % (hostname))
        else:
            hostlist.append(hostname)

    if len(hostlist) == 0:
        log.info('Hostlist empty. Nothing more to do.')
        return

    for hostname in hostlist:
        session = connect(hostname, username, password)
        if session[0] or pretend:
            session_list.append(session)

    for session in session_list:
        # Look for module load file
        output = runcmd(session, 'ls %s/%s' % (remote_path, image_file))
        if 'No such file' in output:
            log.warning('No image file')
            continue

        else:
            # ...
            log.debug('Image file found')

    if len(session_list) == 0:
        log.info('Session list empty. Nothing more to do.')
        return

    log.info('Looking for backup images...')
    for session in session_list:
        session_backup = backup

        # Look for backup load file
        output = runcmd(session, 'ls %s/%s' % (remote_path, backup_file))
        if 'No such file' in output:
            log.debug('{%s}: Backup file not found' % session[1])
            session_backup = True

        else:
            # ...
            log.debug('{%s}: Backup file found' % session[1])

        # Create backup if needed
        if session_backup:
            log.info('{%s}: Creating backup file...' % session[1])
            runcmd(session, 'tar -cvf %s/%s `tar -tf %s/%s`' % (remote_path, backup_file, remote_path, image_file))

    if len(session_list) == 0:
        log.info('Session list empty. Nothing more to do.')
        return

    log.info('Loading image files...')
    for session in session_list:
        has_sync = False
        # Run sync command to ensure images are written to drive
        if '/fabos/link_rbin/sync' in runcmd(session, 'which sync'):
            has_sync = True

        if has_sync:
            log.info('  {%s} Sync file system before load...' % session[1])
            runcmd(session, 'sync; sync')

        # Load the images
        log.info('  {%s} Loading file images...' % session[1])
        runcmd(session, 'tar -xvf %s/%s' % (remote_path, image_file))

        # Run sync command to ensure images are written to drive
        if has_sync:
            log.info('  {%s} Sync file system after load...' % session[1])
            runcmd(session, 'sync; sync')

    if reboot:
        if len(session_list) == 0:
            log.info('Session list empty. Nothing more to do.')
            return

        log.info('Rebooting switches...')
        for session in session_list:
            log.info('   Rebooting %s...' % session[1])
            runcmd(session, 'echo y | reboot')

    if hareboot:
        if len(session_list) == 0:
            log.info('Session list empty. Nothing more to do.')
            return

        log.info('Harebooting switches...')
        for session in session_list:
            log.info('   HA Rebooting %s...' % session[1])
            runcmd(session, 'echo y | hareboot')

    # sleep for a bit to allow reboot to take before session terminated
    sleep_time = 5
    log.debug('Sleeping for %d seconds...' % sleep_time)
    time.sleep(sleep_time)

    log.debug('Closing connections...')
    for session in session_list:
        if session[0]:
            session[0].close()

    # ...


if __name__ == '__main__':
    main()
