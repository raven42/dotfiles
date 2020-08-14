#!/usr/bin/python

import re
import argparse
import telnetlib
import logging as log
import os
import time
from datetime import datetime

HOST = ''
USER = 'root'
PASS = 'fibranne'

verbose = False
pretend = False
no_filter = True
no_file = False

def_login = 'root'
def_password = 'fibranne'
def_local_path = os.path.expanduser('~')
def_iterations = 10
def_delay = 5
def_path = ''
def_timeout = 5

login_timeout = 15

prompt = '> '

parser = argparse.ArgumentParser(description='This script will collect a set '
                                 'of statistics counters from a switch for '
                                 'perfomance analysis. The stats will be '
                                 'collected in a file at '
                                 './<timestamp>_SW<hostname>_STATS_<iteration>')
parser.add_argument('hostname', help='Add <hostname> to host list', nargs='+')
parser.add_argument('-v', '--verbose', help='Enable verbose logging', default=0, action='store_true')
parser.add_argument('-i', '--iteration', help='Set the number of test iterations to run (default=%d).'
                    % def_iterations, default=def_iterations, type=int)
parser.add_argument('-d', '--delay', help='Set the delay in seconds between collections (default=%d)'
                    % def_delay, default=def_delay, type=int)
parser.add_argument('-p', '--path', help='Set the output directory where all stats files will be located '
                    '(default=%s' % def_path, default=def_path)
parser.add_argument('--login', help='Set the login name', default=def_login)
parser.add_argument('--password', help='Set the password', default=def_password)
parser.add_argument('--pretend', help='Don\'t actually run anything. Only show steps.',
                    default=False, action='store_true')
parser.add_argument('--no-filter', help='Turn off escape code filtering on all output',
                    default=False, action='store_true')
parser.add_argument('--no-file', help='Disable logging stats output to a file.',
                    default=False, action='store_true')

log.basicConfig(format='%(asctime)s - [%(levelname)s]: %(message)s', datefmt='%m/%d/%Y %I:%M:%S %p',
                level=log.INFO)

# Setup list of escape sequence characters to filter out of output as a regex
esc_seq = re.compile(r'(\x9B|\x1B\[)[0-?]*[ -\/]*[@-~]|[\x00-\x09\x0B-\x1F\x7F-\xFF]')


def runcmd(session, command, prompt='> '):
    global verbose, pretend, def_timeout

    # log.debug(command)
    if pretend:
        log.debug('{%s}: %s' % (session[1], command))
        return ''

    session[0].write(command + '\n')
    output = session[0].read_until(prompt, def_timeout)
    if not no_filter:
        output = output.replace('\r\n', '\n')
        output = esc_seq.sub('', output)
        log.debug('{%s}: %s' % (session[1], output))

    return output


def connect(hostname, username, password):
    global verbose, pretend, prompt

    log.info('Connecting to host:' + hostname)
    if pretend:
        return (0, hostname)

    try:
        session = (telnetlib.Telnet(hostname, port=23, timeout=5), hostname)

        log.debug('Connected.... logging into switch')
        log.debug(session[0].read_until('login: '))

        runcmd(session, username, 'Password: ')
        output = runcmd(session, password)
        if prompt not in output:
            log.info('Failed to connect to %s. Invalid login.' % hostname)
            return (0, hostname)

        log.debug('Connected to %s, adding to session list' % hostname)

        return session
    except IOError:
        log.error('Failed to connect to host:%s' % hostname)


def main():
    global verbose, pretend, no_filter

    session_list = []
    hostlist = []

    args = parser.parse_args()

    verbose = args.verbose
    hostnames = args.hostname
    username = args.login
    password = args.password
    pretend = args.pretend
    max_iterations = args.iteration
    delay = args.delay
    path = args.path
    no_filter = args.no_filter
    no_file = args.no_file

    iteration = 1

    command_list = []
    command_list.append('top -n 2 -d 0.5')
    command_list.append('date')
    command_list.append('iostat -x')
    command_list.append('cat /proc/meminfo')
    command_list.append('cat /proc/stat')
    command_list.append('esmcmd thread info')
    command_list.append('date')

    logger = log.getLogger()
    if verbose:
        logger.setLevel(log.DEBUG)

    log.debug('hostnames:[%s]' % ', '.join(map(str, hostnames)))
    log.debug('username:' + username)
    log.debug('password:' + password)

    if len(path):
        full_path = os.path.join(os.getcwd(), path)
        if not os.path.exists(full_path):
            log.info('Path %s does not exist' % full_path)
            return
        if not os.path.isdir(full_path):
            log.info('Path %s is not a directory' % full_path)
            return

    hostlist = hostnames

    if len(hostlist) == 0:
        log.info('Hostlist empty. Nothing more to do.')
        return

    for hostname in hostlist:
        session = connect(hostname, username, password)
        if session[0] or pretend:
            session_list.append(session)

    if len(session_list) == 0:
        log.info('Session list empty. No switches to gather stats from')
        return

    for iteration in range(1, max_iterations + 1):
        if iteration > 1:
            log.debug('Sleeping for %d seconds' % delay)

        if not pretend:
            time.sleep(delay)
            log.info('Starting iteration %d / %d' % (iteration, max_iterations))

        for session in session_list:
            if not pretend and not no_file:
                now = datetime.now()
                timestamp = now.strftime('%Y%m%d_%H%M%S')
                filename = '%s_SW%s_STATS_%d' % (timestamp, session[1], iteration)
                if len(path) and not path.endswith('/'):
                    path = path + '/'
                    filename = path + filename

                log.debug('filename:%s' % filename)

                # Open in binary mode so we control the line breaks
                f = open(filename, 'wb')
                f.write('#############################################\n')
                f.write('# Iteration %d / %d\n' % (iteration, max_iterations))

            output = runcmd(session, 'echo Iteration %d' % iteration)
            for command in command_list:
                output = runcmd(session, command)
                if not pretend and not no_file:
                    f.write(output + '\n')

            if not pretend and not no_file:
                f.close()
                log.info('Done with iteration %d / %d' % (iteration, max_iterations))

    log.info('Closing connections...')
    for session in session_list:
        if session[0]:
            session[0].close()
            # ...


if __name__ == '__main__':
    main()
