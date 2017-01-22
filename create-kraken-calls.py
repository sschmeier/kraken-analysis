#!/usr/bin/env python
"""
NAME: create-kraken-calls.py
=========

DESCRIPTION
===========

INSTALLATION
============

USAGE
=====

VERSION HISTORY
===============

v0.1   2017/01/23    Initial version.

LICENCE
=======
2017, copyright Sebastian Schmeier (s.schmeier@gmail.com), http://sschmeier.com

template version: 1.6 (2016/11/09)
"""

from signal import signal, SIGPIPE, SIG_DFL
import sys
import os
import os.path
import argparse
import glob

# When piping stdout into head python raises an exception
# Ignore SIG_PIPE and don't throw exceptions on it...
# (http://docs.python.org/library/signal.html)
signal(SIGPIPE, SIG_DFL)

__version__ = 'v0.1'
__date__ = '2017/01/23'
__email__ = 's.schmeier@gmail.com'
__author__ = 'Sebastian Schmeier'


def parse_cmdline():
    """ Parse command-line args. """
    ## parse cmd-line -----------------------------------------------------------
    description = 'Read delimited file.'
    version = 'version %s, date %s' % (__version__, __date__)
    epilog = 'Copyright %s (%s)' % (__author__, __email__)

    parser = argparse.ArgumentParser(description=description, epilog=epilog)

    parser.add_argument('--version',
                        action='version',
                        version='%s' % (version))

    parser.add_argument(
        'str_db',
        metavar='DB-PATH',
        help=
        'Path to kraken db dir.')
    parser.add_argument(
        'str_dir',
        metavar='DIR',
        help=
        'Directory with files.')
    parser.add_argument(
        'str_dirout',
        metavar='OUTDIR',
        help=
        'Directory to place new files.')

    # if no arguments supplied print help
    if len(sys.argv)==1:
        parser.print_help()
        sys.exit(1)
    
    args = parser.parse_args()
    return args, parser


def main():
    """ The main funtion. """
    args, parser = parse_cmdline()

    files = glob.glob(os.path.join(args.str_dir,'*.gz'))
    #assert len(files) == 38
    sys.stderr.write('%i files found to process.\n'%len(files))

    db = args.str_db
    
    for f in files:
        s1 = 'kraken --threads 4 --gzip-compressed -db %s %s 2> %s.err > %s.kraken\n'%(db,
                                                                                       f,
                                                                                       os.path.join(args.str_dirout, os.path.basename(f).split('.')[0]),
                                                                                       os.path.join(args.str_dirout, os.path.basename(f).split('.')[0]))
        sys.stdout.write(s1)

    return


if __name__ == '__main__':
    sys.exit(main())

