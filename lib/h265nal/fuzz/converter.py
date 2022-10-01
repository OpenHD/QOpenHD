#!/usr/bin/env python3

# Copyright (c) Facebook, Inc. and its affiliates.

"""converter.py module description."""

import argparse
import os.path
import pathlib
import re
import string
import sys

default_values = {
    'debug': 0,
    'infile': None,
    'outdir': './',
}


CODE_TEMPLATE = """\
/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

// This file was auto-generated using fuzz/converter.py from
// $infile.
// Do not edit directly.

$include

// libfuzzer infra to test the fuzz target
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
$code
  return 0;
}
"""

DATA_REGEXP = r'0x[0-9a-f][0-9a-f]'


def do_something(options):
    # read and parse the input file
    lines = read_input(options.infile, options.debug)
    output = parse_input(lines, options.debug)
    # get the output file name
    if options.infile == sys.stdin:
        fout_code = sys.stdout
        outfile_data_dir = None
        outfile_data_template = None
    else:
        outfile_code = os.path.basename(options.infile)
        outfile_code = outfile_code.replace('unittest', 'fuzzer')
        outfile_code = os.path.join(options.outdir, outfile_code)
        fout_code = open(outfile_code, 'w')
        outfile_data_dir = os.path.basename(options.infile)
        outfile_data_dir = outfile_data_dir.replace('unittest', 'fuzzer')
        outfile_data_dir = outfile_data_dir.replace('.cc', '')
        outfile_data_dir = os.path.join(options.outdir, 'corpus',
                                        outfile_data_dir)
        outfile_data_template = os.path.join(outfile_data_dir,
                                             'unittest.%02i.bin')

    # compose the output file
    infile = os.path.basename(options.infile)
    output['infile'] = infile
    code_template = string.Template(CODE_TEMPLATE)
    code = code_template.substitute(output)
    fout_code.write(code)
    fout_code.close()
    if options.debug > 0:
        print('outfile_code: %s' % outfile_code)

    # compose the data files
    for i, data_bytes in enumerate(output['data']):
        outfile_data = outfile_data_template % i
        if outfile_data_dir is None:
            continue
        pathlib.Path(outfile_data_dir).mkdir(parents=True, exist_ok=True)
        fout_data = open(outfile_data, 'wb')
        fout_data.write(data_bytes)
        fout_data.close()
        if options.debug > 0:
            print('outfile_data: %s' % outfile_data)


def read_input(infile, debug):
    # open infile
    if infile != sys.stdin:
        try:
            fin = open(infile, 'r+')
        except IOError:
            print('Error: cannot open file "%s":', infile)
    else:
        fin = sys.stdin.buffer

    # process infile
    lines = fin.readlines()
    fin.close()
    return lines


def parse_input(lines, debug):
    lines_include = []
    lines_data = []
    lines_code = []
    output = {}

    # extract the includes, data, and code
    data_mode = False
    code_mode = False
    for line in lines:
        # skip blank lines/comments
        if len(line.strip()) == 0:
            continue
        # need include lines, buffers, code lines
        if line.startswith("#include "):
            lines_include.append(line)
        elif 'fuzzer::conv: data' in line:
            # data mode
            data_mode = True
            lines_data.append([])
            continue
        elif line == '};\n':
            data_mode = False
        elif 'fuzzer::conv: begin' in line:
            # begin code mode
            data_mode = False
            code_mode = True
            lines_code.append('  {\n')
            continue
        elif 'fuzzer::conv: end' in line:
            # end code mode
            code_mode = False
            lines_code.append('  }\n')
            continue
        if data_mode:
            lines_data[-1].append(line)
        if code_mode:
            lines_code.append(line)

    # clean the includes
    output['include'] = ''
    for line in lines_include:
        # remove gmock and gtest lines
        if 'gmock' in line or 'gtest' in line:
            continue
        output['include'] += line

    # clean the data
    output['data'] = []
    for ll in lines_data:
        data_bytes = re.findall(DATA_REGEXP, ''.join(ll))
        output['data'].append(bytes.fromhex(''.join(b[2:] for b in
                                            data_bytes)))

    # clean the code
    output['code'] = ''
    for line in lines_code:
        # add h265nal namespace if needed
        if 'H265' in line:
            line = line.replace('H265', 'h265nal::H265')
        if 'NalUnitType::' in line:
            line = line.replace('NalUnitType::', 'h265nal::NalUnitType::')
        line = line.replace('buffer, arraysize(buffer)', 'data, size')
        output['code'] += line
    output['code'].strip('\n')
    output['code'] = output['code'].strip('\n')

    return output


def get_options(argv):
    """Generic option parser.

    Args:
        argv: list containing arguments

    Returns:
        Namespace - An argparse.ArgumentParser-generated option object
    """
    # init parser
    # usage = 'usage: %prog [options] arg1 arg2'
    # parser = argparse.OptionParser(usage=usage)
    # parser.print_help() to get argparse.usage (large help)
    # parser.print_usage() to get argparse.usage (just usage line)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
            '-d', '--debug', action='count',
            dest='debug', default=default_values['debug'],
            help='Increase verbosity (use multiple times for more)',)
    parser.add_argument(
            '--quiet', action='store_const',
            dest='debug', const=-1,
            help='Zero verbosity',)
    parser.add_argument(
            'infile', type=str,
            default=default_values['infile'],
            metavar='input-file',
            help='input file',)
    parser.add_argument(
            'outdir', type=str,
            default=default_values['outdir'],
            metavar='output-file',
            help='output file',)
    # do the parsing
    options = parser.parse_args(argv[1:])
    return options


def main(argv):
    # parse options
    options = get_options(argv)
    # get infile/outdir
    if options.infile == '-':
        options.infile = sys.stdin
    # print results
    if options.debug > 0:
        print(options)
    # do something
    do_something(options)


if __name__ == '__main__':
    # at least the CLI program name: (CLI) execution
    main(sys.argv)
