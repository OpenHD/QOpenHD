/*
 *  Copyright (c) Facebook, Inc. and its affiliates.
 */

#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>

#include <climits>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#include "config.h"
#include "h265_bitstream_parser.h"
#include "h265_common.h"
#include "rtc_base/bit_buffer.h"

extern int optind;

typedef struct arg_options {
  int debug;
  bool as_one_line;
  bool add_offset;
  bool add_length;
  bool add_parsed_length;
  bool add_checksum;
  bool add_contents;
  char *infile;
  char *outfile;
} arg_options;

// default option values
arg_options DEFAULTS{
    .debug = 0,
    .as_one_line = true,
    .add_offset = false,
    .add_length = false,
    .add_parsed_length = false,
    .add_checksum = false,
    .add_contents = false,
    .infile = nullptr,
    .outfile = nullptr,
};

void usage(char *name) {
  fprintf(stderr, "usage: %s [options]\n", name);
  fprintf(stderr, "where options are:\n");
  fprintf(stderr, "\t-d:\t\tIncrease debug verbosity [default: %i]\n",
          DEFAULTS.debug);
  fprintf(stderr, "\t-q:\t\tZero debug verbosity\n");
  fprintf(stderr, "\t--as-one-line:\tSet as_one_line flag%s\n",
          DEFAULTS.as_one_line ? " [default]" : "");
  fprintf(stderr, "\t--noas-one-line:\tReset as_one_line flag%s\n",
          !DEFAULTS.as_one_line ? " [default]" : "");
  fprintf(stderr, "\t--add-offset:\tSet add_offset flag%s\n",
          DEFAULTS.add_offset ? " [default]" : "");
  fprintf(stderr, "\t--noadd-offset:\tReset add_offset flag%s\n",
          !DEFAULTS.add_offset ? " [default]" : "");
  fprintf(stderr, "\t--add-length:\tSet add_length flag%s\n",
          DEFAULTS.add_length ? " [default]" : "");
  fprintf(stderr, "\t--noadd-length:\tReset add_length flag%s\n",
          !DEFAULTS.add_length ? " [default]" : "");
  fprintf(stderr, "\t--add-parsed-length:\tSet add_parsed_length flag%s\n",
          DEFAULTS.add_parsed_length ? " [default]" : "");
  fprintf(stderr, "\t--noadd-parsed-length:\tReset add_parsed_length flag%s\n",
          !DEFAULTS.add_parsed_length ? " [default]" : "");
  fprintf(stderr, "\t--add-checksum:\tSet add_checksum flag%s\n",
          DEFAULTS.add_checksum ? " [default]" : "");
  fprintf(stderr, "\t--noadd-checksum:\tReset add_checksum flag%s\n",
          !DEFAULTS.add_checksum ? " [default]" : "");
  fprintf(stderr, "\t--add-contents:\tSet add_contents flag%s\n",
          DEFAULTS.add_contents ? " [default]" : "");
  fprintf(stderr, "\t--noadd-contents:\tReset add_contents flag%s\n",
          !DEFAULTS.add_contents ? " [default]" : "");
  fprintf(stderr, "\t--version:\t\tDump version number\n");
  fprintf(stderr, "\t-h:\t\tHelp\n");
  exit(-1);
}

// long options with no equivalent short option
enum {
  QUIET_OPTION = CHAR_MAX + 1,
  AS_ONE_LINE_FLAG_OPTION,
  NO_AS_ONE_LINE_FLAG_OPTION,
  ADD_OFFSET_FLAG_OPTION,
  NO_ADD_OFFSET_FLAG_OPTION,
  ADD_LENGTH_FLAG_OPTION,
  NO_ADD_LENGTH_FLAG_OPTION,
  ADD_PARSED_LENGTH_FLAG_OPTION,
  NO_ADD_PARSED_LENGTH_FLAG_OPTION,
  ADD_CHECKSUM_FLAG_OPTION,
  NO_ADD_CHECKSUM_FLAG_OPTION,
  ADD_CONTENTS_FLAG_OPTION,
  NO_ADD_CONTENTS_FLAG_OPTION,
  VERSION_OPTION,
  HELP_OPTION
};

arg_options *parse_args(int argc, char **argv) {
  int c;
  static arg_options options;

  // set default options
  options = DEFAULTS;

  // getopt_long stores the option index here
  int optindex = 0;

  // long options
  static struct option longopts[] = {
      // matching options to short options
      {"debug", no_argument, NULL, 'd'},
      // options without a short option
      {"quiet", no_argument, NULL, QUIET_OPTION},
      {"as-one-line", no_argument, NULL, AS_ONE_LINE_FLAG_OPTION},
      {"noas-one-line", no_argument, NULL, NO_AS_ONE_LINE_FLAG_OPTION},
      {"add-offset", no_argument, NULL, ADD_OFFSET_FLAG_OPTION},
      {"noadd-offset", no_argument, NULL, NO_ADD_OFFSET_FLAG_OPTION},
      {"add-length", no_argument, NULL, ADD_LENGTH_FLAG_OPTION},
      {"noadd-length", no_argument, NULL, NO_ADD_LENGTH_FLAG_OPTION},
      {"add-parsed-length", no_argument, NULL, ADD_PARSED_LENGTH_FLAG_OPTION},
      {"noadd-parsed-length", no_argument, NULL,
       NO_ADD_PARSED_LENGTH_FLAG_OPTION},
      {"add-checksum", no_argument, NULL, ADD_CHECKSUM_FLAG_OPTION},
      {"noadd-checksum", no_argument, NULL, NO_ADD_CHECKSUM_FLAG_OPTION},
      {"add-contents", no_argument, NULL, ADD_CONTENTS_FLAG_OPTION},
      {"noadd-contents", no_argument, NULL, NO_ADD_CONTENTS_FLAG_OPTION},
      {"version", no_argument, NULL, VERSION_OPTION},
      {"help", no_argument, NULL, HELP_OPTION},
      {NULL, 0, NULL, 0}};

  // parse arguments
  while ((c = getopt_long(argc, argv, "dh", longopts, &optindex)) != -1) {
    switch (c) {
      case 0:
        // long options that define flag
        // if this option set a flag, do nothing else now
        if (longopts[optindex].flag != NULL) {
          break;
        }
        printf("option %s", longopts[optindex].name);
        if (optarg) {
          printf(" with arg %s", optarg);
        }
        break;

      case 'd':
        options.debug += 1;
        break;

      case QUIET_OPTION:
        options.debug = 0;
        break;

      case AS_ONE_LINE_FLAG_OPTION:
        options.as_one_line = true;
        break;

      case NO_AS_ONE_LINE_FLAG_OPTION:
        options.as_one_line = false;
        break;

      case ADD_OFFSET_FLAG_OPTION:
        options.add_offset = true;
        break;

      case NO_ADD_OFFSET_FLAG_OPTION:
        options.add_offset = false;
        break;

      case ADD_LENGTH_FLAG_OPTION:
        options.add_length = true;
        break;

      case NO_ADD_LENGTH_FLAG_OPTION:
        options.add_length = false;
        break;

      case ADD_PARSED_LENGTH_FLAG_OPTION:
        options.add_parsed_length = true;
        break;

      case NO_ADD_PARSED_LENGTH_FLAG_OPTION:
        options.add_parsed_length = false;
        break;

      case ADD_CHECKSUM_FLAG_OPTION:
        options.add_checksum = true;
        break;

      case NO_ADD_CHECKSUM_FLAG_OPTION:
        options.add_checksum = false;
        break;

      case ADD_CONTENTS_FLAG_OPTION:
        options.add_contents = true;
        break;

      case NO_ADD_CONTENTS_FLAG_OPTION:
        options.add_contents = false;
        break;

      case VERSION_OPTION:
        printf("version: %s\n", PROJECT_VER);
        exit(0);
        break;

      case HELP_OPTION:
      case 'h':
        usage(argv[0]);

      default:
        printf("Unsupported option: %c\n", c);
        usage(argv[0]);
    }
  }

  // require 2 extra parameters
  if ((argc - optind != 1) && (argc - optind != 2)) {
    fprintf(stderr, "need infile (outfile is optional)\n");
    usage(argv[0]);
    return nullptr;
  }

  options.infile = argv[optind];
  if (argc - optind == 2) {
    options.outfile = argv[optind + 1];
  }
  return &options;
}

int main(int argc, char **argv) {
  arg_options *options;

#ifdef SMALL_FOOTPRINT
  printf("h265nal: small footprint version\n");
#else
  printf("h265nal: original version\n");
#endif
  // parse args
  options = parse_args(argc, argv);
  if (options == nullptr) {
    usage(argv[0]);
    exit(-1);
  }

  // print args
  if (options->debug > 1) {
    printf("options->debug = %i\n", options->debug);
    printf("options->infile = %s\n",
           (options->infile == NULL) ? "null" : options->infile);
    printf("options->outfile = %s\n",
           (options->outfile == NULL) ? "null" : options->outfile);
  }

  // add_contents requires add_length and add_offset
  if (options->add_contents) {
    options->add_offset = true;
    options->add_length = true;
  }

  // read infile
  // TODO(chemag): read the infile incrementally
  FILE *infp = fopen(options->infile, "rb");
  if (infp == nullptr) {
    // did not work
    fprintf(stderr, "Could not open input file: \"%s\"\n", options->infile);
    return -1;
  }
  fseek(infp, 0, SEEK_END);
  int64_t size = ftell(infp);
  fseek(infp, 0, SEEK_SET);
  // read file into buffer
  std::vector<uint8_t> buffer(size);
  fread(reinterpret_cast<char *>(buffer.data()), 1, size, infp);

  // parse bitstream
  std::unique_ptr<h265nal::H265BitstreamParser::BitstreamState> bitstream =
      h265nal::H265BitstreamParser::ParseBitstream(
          buffer.data(), buffer.size(), options->add_offset,
          options->add_length, options->add_parsed_length,
          options->add_checksum);

#ifdef FDUMP_DEFINE
  // get outfile file descriptor
  FILE *outfp;
  if (options->outfile == nullptr ||
      (strlen(options->outfile) == 1 && options->outfile[0] == '-')) {
    // use stdout
    outfp = stdout;
  } else {
    outfp = fopen(options->outfile, "wb");
    if (outfp == nullptr) {
      // did not work
      fprintf(stderr, "Could not open output file: \"%s\"\n", options->outfile);
      return -1;
    }
  }

  int indent_level = (options->as_one_line) ? -1 : 0;
  for (auto &nal_unit : bitstream->nal_units) {
    nal_unit->fdump(outfp, indent_level, options->add_offset,
                    options->add_length, options->add_parsed_length,
                    options->add_checksum);
    if (options->add_contents) {
      fprintf(outfp, " contents {");
      for (size_t i = 0; i < nal_unit->length; i++) {
        fprintf(outfp, " 0x%02x,", buffer[nal_unit->offset + i]);
        if ((i + 1) % 16 == 0) {
          fprintf(outfp, " ");
        }
      }
      fprintf(outfp, " }");
    }
    fprintf(outfp, "\n");
  }
#endif  // FDUMP_DEFINE

  return 0;
}
