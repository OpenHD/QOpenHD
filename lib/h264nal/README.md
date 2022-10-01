# h264nal: A Library and Tool to parse H264 NAL units

By [Chema Gonzalez](https://github.com/chemag), 2021-07-21


# 1. Rationale
This document describes h264nal, a simpler H264 (aka AVC aka h.264 aka ISO/IEC 14496-10 - MPEG-4 Part 10, Advanced Video Coding) NAL (network abstraction layer) unit parser.

Final goal it to create a binary that accepts a file in h264 Annex B format
(.264) and dumps the contents of the parsed NALs.

[h265nal](https://github.com/chemag/h265nal) is a similar project to parse
H265 NAL units.


# 2. Install Instructions

Get the git repo, and then build using cmake.

```
$ git clone https://github.com/chemag/h264nal
$ cd h264nal
$ mkdir build
$ cd build
$ cmake ..  # also cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
$ make
```

Feel free to test all the unittests:

```
$ make test
Running tests...
Test project /home/chemag/proj/h264nal/build
      Start  1: h264_common_unittest
 1/16 Test  #1: h264_common_unittest .........................................   Passed    0.00 sec
      Start  2: h264_hrd_parameters_parser_unittest
 2/16 Test  #2: h264_hrd_parameters_parser_unittest ..........................   Passed    0.00 sec
      Start  3: h264_vui_parameters_parser_unittest
 3/16 Test  #3: h264_vui_parameters_parser_unittest ..........................   Passed    0.00 sec
      Start  4: h264_sps_parser_unittest
 4/16 Test  #4: h264_sps_parser_unittest .....................................   Passed    0.00 sec
      Start  5: h264_pps_parser_unittest
 5/16 Test  #5: h264_pps_parser_unittest .....................................   Passed    0.00 sec
      Start  6: h264_ref_pic_list_modification_parser_unittest
 6/16 Test  #6: h264_ref_pic_list_modification_parser_unittest ...............   Passed    0.00 sec
      Start  7: h264_pred_weight_table_parser_unittest
 7/16 Test  #7: h264_pred_weight_table_parser_unittest .......................   Passed    0.00 sec
      Start  8: h264_dec_ref_pic_marking_parser_unittest
 8/16 Test  #8: h264_dec_ref_pic_marking_parser_unittest .....................   Passed    0.00 sec
      Start  9: h264_rtp_single_parser_unittest
 9/16 Test  #9: h264_rtp_single_parser_unittest ..............................   Passed    0.00 sec
      Start 10: h264_rtp_stapa_parser_unittest
10/16 Test #10: h264_rtp_stapa_parser_unittest ...............................   Passed    0.00 sec
      Start 11: h264_rtp_fua_parser_unittest
11/16 Test #11: h264_rtp_fua_parser_unittest .................................   Passed    0.00 sec
      Start 12: h264_rtp_parser_unittest
12/16 Test #12: h264_rtp_parser_unittest .....................................   Passed    0.00 sec
      Start 13: h264_slice_header_parser_unittest
13/16 Test #13: h264_slice_header_parser_unittest ............................   Passed    0.00 sec
      Start 14: h264_slice_layer_without_partitioning_rbsp_parser_unittest
14/16 Test #14: h264_slice_layer_without_partitioning_rbsp_parser_unittest ...   Passed    0.00 sec
      Start 15: h264_bitstream_parser_unittest
15/16 Test #15: h264_bitstream_parser_unittest ...............................   Passed    0.00 sec
      Start 16: h264_nal_unit_parser_unittest
16/16 Test #16: h264_nal_unit_parser_unittest ................................   Passed    0.00 sec

100% tests passed, 0 tests failed out of 16

Total Test time (real) =   0.07 sec
```

Or to test any of the unittests:

```
$ ./test/h264_bitstream_parser_unittest
Running main() from /builddir/build/BUILD/googletest-release-1.10.0/googletest/src/gtest_main.cc
[==========] Running 2 tests from 1 test suite.
[----------] Global test environment set-up.
[----------] 2 tests from H264BitstreamParserTest
[ RUN      ] H264BitstreamParserTest.TestSampleBitstream601
[       OK ] H264BitstreamParserTest.TestSampleBitstream601 (0 ms)
[ RUN      ] H264BitstreamParserTest.TestSampleBitstream601Alt
[       OK ] H264BitstreamParserTest.TestSampleBitstream601Alt (0 ms)
[----------] 2 tests from H264BitstreamParserTest (0 ms total)

[----------] Global test environment tear-down
[==========] 2 tests from 1 test suite ran. (0 ms total)
[  PASSED  ] 2 tests.
```

Check the included vector file:

```
$ ./tools/h264nal --add-offset --add-length --add-parsed-length ../media/601.264
h264nal: original version
nal_unit { offset: 0x00000004 length: 24 parsed_length: 0x00000016 nal_unit_header { forbidden_zero_bit: 0 nal_ref_idc: 3 nal_unit_type: 7 } nal_unit_payload { sps { profile_idc: 66 constraint_set0_flag: 1 constraint_set1_flag: 1 constraint_set2_flag: 0 constraint_set3_flag: 0 constraint_set4_flag: 0 constraint_set5_flag: 0 reserved_zero_2bits: 0 level_idc: 22 seq_parameter_set_id: 0 log2_max_frame_num_minus4: 1 pic_order_cnt_type: 2 max_num_ref_frames: 16 gaps_in_frame_num_value_allowed_flag: 0 pic_width_in_mbs_minus1: 19 pic_height_in_map_units_minus1: 14 frame_mbs_only_flag: 1 direct_8x8_inference_flag: 1 frame_cropping_flag: 0 vui_parameters_present_flag: 1 vui_parameters { aspect_ratio_info_present_flag: 0 overscan_info_present_flag: 0 video_signal_type_present_flag: 1 video_format: 5 video_full_range_flag: 1 colour_description_present_flag: 0 chroma_loc_info_present_flag: 0 timing_info_present_flag: 1 num_units_in_tick: 1 time_scale: 50 fixed_frame_rate_flag: 0 nal_hrd_parameters_present_flag: 0 vcl_hrd_parameters_present_flag: 0 pic_struct_present_flag: 0 bitstream_restriction_flag: 1 motion_vectors_over_pic_boundaries_flag: 1 max_bytes_per_pic_denom: 0 max_bits_per_mb_denom: 0 log2_max_mv_length_horizontal: 10 log2_max_mv_length_vertical: 10 max_num_reorder_frames: 0 max_dec_frame_buffering: 16 } } } }
nal_unit { offset: 0x00000020 length: 6 parsed_length: 0x00000006 nal_unit_header { forbidden_zero_bit: 0 nal_ref_idc: 3 nal_unit_type: 8 } nal_unit_payload { pps { pic_parameter_set_id: 0 seq_parameter_set_id: 0 entropy_coding_mode_flag: 0 bottom_field_pic_order_in_frame_present_flag: 0 num_slice_groups_minus1: 0 num_ref_idx_l0_active_minus1: 15 num_ref_idx_l1_active_minus1: 0 weighted_pred_flag: 0 weighted_bipred_idc: 0 pic_init_qp_minus26: -8 pic_init_qs_minus26: 0 chroma_qp_index_offset: -2 deblocking_filter_control_present_flag: 1 constrained_intra_pred_flag: 0 redundant_pic_cnt_present_flag: 0 transform_8x8_mode_flag: 0 pic_scaling_matrix_present_flag: 0 pic_scaling_list_present_flag { } second_chroma_qp_index_offset: 0 } } }
nal_unit { offset: 0x00000029 length: 628 parsed_length: 0x00000001 nal_unit_header { forbidden_zero_bit: 0 nal_ref_idc: 0 nal_unit_type: 6 } nal_unit_payload {  } }
nal_unit { offset: 0x000002a0 length: 244 parsed_length: 0x00000005 nal_unit_header { forbidden_zero_bit: 0 nal_ref_idc: 3 nal_unit_type: 5 } nal_unit_payload { slice_layer_without_partitioning_rbsp { slice_header { first_mb_in_slice: 0 slice_type: 7 pic_parameter_set_id: 0 frame_num: 0 idr_pic_id: 0 ref_pic_list_modification { ref_pic_list_modification_flag_l0: 0 ref_pic_list_modification_flag_l1: 0 } dec_ref_pic_marking { no_output_of_prior_pics_flag: 0 long_term_reference_flag: 0 } slice_qp_delta: -12 disable_deblocking_filter_idc: 0 slice_alpha_c0_offset_div2: 0 slice_beta_offset_div2: 0 } } } }
...
```


# 3. CLI Binary Operation

Parse all the NAL units of an Annex B (`.264` extension) file.

```
$ ./tools/h264nal file.264 --noas-one-line --add-length --add-offset --add-parsed-length
h264nal: original version
nal_unit {
  offset: 0x00000004
  length: 24
  parsed_length: 0x00000016
  nal_unit_header {
    forbidden_zero_bit: 0
    nal_ref_idc: 3
    nal_unit_type: 7
  }
  nal_unit_payload {
    sps {
      profile_idc: 66
      constraint_set0_flag: 1
      constraint_set1_flag: 1
      constraint_set2_flag: 0
      constraint_set3_flag: 0
      constraint_set4_flag: 0
      constraint_set5_flag: 0
      reserved_zero_2bits: 0
      level_idc: 22
      seq_parameter_set_id: 0
      log2_max_frame_num_minus4: 1
      pic_order_cnt_type: 2
      ...
```


# 4. Programmatic Integration Operation

There are 3 ways to integrate the parser in your C++ parser:

## 4.1. Annex B H264, Full-File Parsing
If you just have a binary blob with the full contents of a file in Annex B
format, use the `H264BitstreamParser::ParseBitstream()` method. This case
is useful, for example, when you have an Annex B format file (a file with
`.264` or `.h264` extension). You read the whole file in memory, and then
convert the read blob into a set of parsed NAL units.

The following code has been copied from `tools/h264nal.cc`:

```
// read your .264 file into the vector `buffer`
std::vector<uint8_t> buffer(size);

// create bitstream parser from the file
std::unique_ptr<h264nal::H264BitstreamParser::BitstreamState> bitstream =
          h264nal::H264BitstreamParser::ParseBitstream(
          buffer.data(), buffer.size(), options->add_offset,
          options->add_length, options->add_parsed_length);
```

The `H264BitstreamParser::ParseBitstream()` function receives a generic
binary string (`data` and `length`) that you read from the file, plus
some options (whether to add options, length, and parsed length to each
NAL units).

It then:

* (1) splits the input string into a vector of NAL units, and
* (2) parses the NAL units, and add them to the vector


## 4.2. NAL-Unit Parsing
If you have a series of binary blobs with NAL units, use the
`H264NalUnitParser::ParseNalUnit()` method. This case is useful for example
if you have a producer of NAL units (e.g. an encoder), and you want to
parse them as soon as they are produced.

The following code has been copied from `H264BitstreamParser::ParseBitstream()`
in `src/h264_bitstream_parser.cc`:

```
// keep a bitstream parser state (to keep the PPS/SPS NALUs)
h264nal::H264BitstreamParserState bitstream_parser_state;

// create bitstream parser
std::unique_ptr<h264nal::H264BitstreamParser::BitstreamState> bitstream;

while (1) {
  const uint8_t* data = ...;  // get pointer to the NAL start
	size_t length = ...;  // get NAL size

  auto nal_unit = H264NalUnitParser::ParseNalUnit(
      data, length, bitstream_parser_state);

  // check whether the parser was successful
	if (nal_unit == nullptr) {
    // cannot parse the NalUnit
    continue;
  }

  // check the parser offset
  auto offset = nalu_index.payload_start_offset;
  auto length = nalu_index.payload_size;
}
```

The `H264NalUnitParser::ParseNalUnit()` function receives a generic
binary string (`data` and `length`) that contains a NAL unit, plus
a `H264BitstreamParserState` object that keeps all the SPS/PPS it
ever sees. It then parses the NAL unit, and returns it (including the
parsing offsets).

It will also update the input `H264BitstreamParserState` object if it
sees any PPS/SPS. This is important if the parsed NAL unit has state
that needs to be used to parse other NAL units (SPS, PPS): In that
case it will be stored into the `BitstreamParserState` object that is
passed around.

Note that `H264NalUnitParser::ParseNalUnit()` will only parse 1 NAL unit.
There are some producers that will instead produce multiple NAL units
in the output buffer. For example, an h264 encoder producing a key frame
may return 3 NAL units (PPS, SPS, and slice header).


## 4.3. RTP Packet Parsing
If you want to just pass consecutive RTP packets (rfc6184 format), and get
information on their contents, use the `H264RtpParser::ParseRtp` method.

The following code is inspired from `test/h264_rtp_parser_unittest.cc`.

```
// keep a bitstream parser state (to keep the PPS/SPS NALUs)
H264BitstreamParserState bitstream_parser_state;

// parse packet(s)
std::unique_ptr<H264RtpParser::RtpState> rtp = H264RtpParser::ParseRtp(
    buffer, arraysize(buffer),
    &bitstream_parser_state);

// packets will return the actual contents into `rtp`, and update the
// bitstream parser state if the RTP packet contains a SPS/PPS.

// check the main packet contents
if (rtp->nal_unit_header->nal_unit_type <= 23) {
  // a packet containing a single NAL Unit
  // header := rtp->rtp_single.nal_unit_header
  // payload := rtp->rtp_single.nal_unit_payload

} else if (rtp->nal_unit_header->nal_unit_type == RTP_STAPA_NUT) {
  // a STAP-A (Aggregation Packet) packet contains 2+ NAL Units
  // number_of_packets := rtp->rtp_ap.nal_unit_payloads.size()
  // packet_i := rtp->rtp_ap.nal_unit_payloads[i]

} else if (rtp->nal_unit_header->nal_unit_type == RTP_FUA_NUT) {
  // an FU-A (Fragmentation Unit) packet contains a piece of a NAL unit
  // has_start_of_packet := rtp->rtp_fu.s_bit
  // internal_type := rtp->rtp_fu.fu_type
  // packet := rtp->rtp_fu.nal_unit_payload
}

// access to the SPS/PPS map
// e.g. bitstream_parser_state.sps[sps_id].pic_width_in_luma_samples
```


# 5. Requirements
Requires gtests, gmock.

The [`webrtc`](webrtc) directory contains an RBSP parser copied from webrtc.


# 6. Other
The [media](media/README.md) directory contains information on testing the
parser using media files.

The [fuzz](fuzz/README.md) directory contains information on fuzzing the
parser.


# 7. TODO

List of tasks:
* add lacking parsers (e.g. SEI)
* remove TODO entries from the code
* move headers to separate `include/` file to allow easier programmatic
  integration
* add a set of Annex B files for testing


# 8. Limitations

* no support for STAP-B, MTAP16, MTAP24, or FU-B RTP packetization.


# 9. License

h264nal is BSD licensed, as found in the [LICENSE](LICENSE) file.


# Appendix 1: MacOS Preparation Notes

1. install gtests (see [here](https://stackoverflow.com/questions/15852631/how-to-install-gtest-on-mac-os-x-with-homebrew))

```
$ git clone https://github.com/google/googletest
$ cd googletest
$ mkdir build
$ cd build
$ cmake ..
$ make
$ sudo make install
```

2. install llvm (see [here](https://stackoverflow.com/questions/53111082/how-to-install-clang-tidy-on-macos))

```
$ brew install llvm
$ ln -s "$(brew --prefix llvm)/bin/clang-format" "/usr/local/bin/clang-format"
$ ln -s "$(brew --prefix llvm)/bin/clang-tidy" "/usr/local/bin/clang-tidy"
$ ln -s "$(brew --prefix llvm)/bin/clang-apply-replacements" "/usr/local/bin/clang-apply-replacements"
```
