#!/usr/bin/python

import os
import logging as log
import argparse
import re

HOME = os.environ.get('HOME')

parser = argparse.ArgumentParser(description='This script will generate a set of bookmarks for the VIM '
                                 'NERDTree plugin.')
parser.add_argument('-i', '--input', help='Specify the input filename to use to generate the bookmarks',
                    default='%s/.default/NERDTreeDefaultBookmarks' % HOME)
parser.add_argument('-o', '--output', help='Specify the output filename to store the bookmarks.',
                    default='%s/.NERDTreeBookmarks' % HOME)
parser.add_argument('-v', '--verbose', help='Enable verbose logging', default=0, action='store_true')
parser.add_argument('-q', '--quiet', help='Disable logging, only showing errors', default=0, action='store_true')
args = parser.parse_args()

log.basicConfig(format='%(asctime)s - [%(levelname)s]: %(message)s', datefmt='%m/%d/%Y %I:%M:%S %p',
                level=log.INFO)


def main():
    global args

    logger = log.getLogger()
    if args.verbose:
        logger.setLevel(log.DEBUG)
    elif args.quiet:
        logger.setLevel(log.ERROR)

    log.debug('Input file [%s]' % args.input)
    log.debug('Output file [%s]' % args.output)

    if not os.path.isfile(args.input):
        log.error('Input file [%s] does not exist' % args.input)
        return

    if os.path.isfile(args.output):
        log.info('Overwriting [%s]...' % args.output)
    else:
        log.info('Creating [%s]...' % args.output)

    f_in = open(args.input, 'r')
    f_out = open(args.output, 'w')

    for line in f_in:
        line = line.rstrip()
        log.debug('parsing line [%s]' % line)
        if line == '':
            break

        match = re.search(r'(?P<bookmark>[a-zA-Z0-9_/]*) (?P<path>.*)', line)
        bookmark = match.group('bookmark')
        path = match.group('path')
        log.debug('  bookmark [%s] path [%s]' % (bookmark, path))
        env_match = re.search(r'\${(?P<env_var>[a-zA-Z0-9_]*)}', path)
        if env_match:
            env_var = os.environ.get(env_match.group(1))
            log.debug('  found env variable [%s] value [%s]' % (env_match.group('env_var'), env_var))
            if not env_var:
                log.error('Bookmark [%s] has environment variable [%s] which is undefined'
                          % (bookmark, env_match.group('env_var')))
                log.error('  Path [%s]' % path)
                log.error('  Skipping this bookmark')
                continue

            path = path.replace(env_match.group(0), env_var)

        log.info('Generating bookmark [%s] path [%s]' % (bookmark, path))
        f_out.write('%s %s\n' % (bookmark, path))

    f_in.close()
    f_out.close()


if __name__ == '__main__':
    main()
