#!/usr/bin/env python
"""
NAME: create-domain-overview.py
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
import csv
import collections
import gzip
import bz2
import zipfile
import time
import re

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
        'list_files',
        metavar='FILE',
        nargs='+',
        help=
        'kraken-report output file.')
    parser.add_argument('-o',
                        '--out',
                        metavar='STRING',
                        dest='outfile_name',
                        default=None,
                        help='Out-file. [default: "stdout"]')

    # if no arguments supplied print help
    if len(sys.argv)==1:
        parser.print_help()
        sys.exit(1)
    
    args = parser.parse_args()
    return args, parser


def load_file(filename):
    """ LOAD FILE """
    if filename.split('.')[-1] == 'gz':
        filehandle = gzip.open(filename, 'rt')
    else:
        filehandle = open(filename, 'rt')
    return filehandle


def parse_krakenreport(filename):
    fileobj = load_file(filename)
    d = collections.OrderedDict()
    reader = csv.reader(fileobj, delimiter = '\t')
    for a in reader:
        if a[5] == 'unclassified':
            d['unclassified'] = int(a[1])
        if a[3] == 'D':
            d[a[5].strip()] = int(a[1])
    return d


def main():
    """ The main funtion. """
    args, parser = parse_cmdline()

    # create outfile object
    if not args.outfile_name:
        outfileobj = sys.stdout
    elif args.outfile_name in ['-', 'stdout']:
        outfileobj = sys.stdout
    elif args.outfile_name.split('.')[-1] == 'gz':
        outfileobj = gzip.open(args.outfile_name, 'wb')
    else:
        outfileobj = open(args.outfile_name, 'w')

    domains = ['Bacteria', 'Archaea' , 'Viruses', 'unclassified']
    outfileobj.write('File\t%s\t%s\n' %('\t'.join(domains),'\t'.join(['%s(pct)'%s for s in domains]) ))
    for fn in args.list_files:
        res = parse_krakenreport(fn)
        name = os.path.basename(fn)

        a = [name]
        num_all = sum(res.values())
        for d in domains:
            if d not in res:
                a.append('0')
                continue
            try:
                a.append(str(res[d]))
            except KeyError:
                a.append('0')
                
        for d in domains:
            if d not in res:
                a.append('0')
                continue
            if num_all > 0:
                a.append(str(res[d]*100.0/num_all))
            else:
                a.append('0.0')
        outfileobj.write('%s\n'%('\t'.join(a)))
        
    # ------------------------------------------------------
    outfileobj.close()
    return


if __name__ == '__main__':
    sys.exit(main())

