# h265nal: A Library and Tool to parse H265 NAL units

By [Chema Gonzalez](https://github.com/chemag), 2020-09-11


# 1. Rationale
This document describes h265nal, a simpler H265 NAL unit parser.

Final goal it to create a binary that accepts a file in h265 Annex B format
(.265) and dumps the contents of the parsed NALs.

[h264nal](https://github.com/chemag/h264nal) is a similar project to parse
H264 NAL units.


# 2. Install Instructions

Get the git repo, and then build using cmake.

```
$ git clone https://github.com/chemag/h265nal
$ cd h265nal
$ mkdir build
$ cd build
$ cmake ..  # also cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo ..
$ make
```

Feel free to test all the unittests:

```
$ make test
Running tests...
Test project h265nal/build
      Start  1: h265_profile_tier_level_parser_unittest
 1/10 Test  #1: h265_profile_tier_level_parser_unittest ...   Passed    0.00 sec
      Start  2: h265_vps_parser_unittest
 2/10 Test  #2: h265_vps_parser_unittest ..................   Passed    0.00 sec
      Start  3: h265_vui_parameters_parser_unittest
 3/10 Test  #3: h265_vui_parameters_parser_unittest .......   Passed    0.00 sec
      Start  4: h265_st_ref_pic_set_parser_unittest
 4/10 Test  #4: h265_st_ref_pic_set_parser_unittest .......   Passed    0.00 sec
      Start  5: h265_sps_parser_unittest
 5/10 Test  #5: h265_sps_parser_unittest ..................   Passed    0.00 sec
      Start  6: h265_pps_parser_unittest
 6/10 Test  #6: h265_pps_parser_unittest ..................   Passed    0.00 sec
      Start  7: h265_aud_parser_unittest
 7/10 Test  #7: h265_aud_parser_unittest ..................   Passed    0.00 sec
      Start  8: h265_slice_parser_unittest
 8/10 Test  #8: h265_slice_parser_unittest ................   Passed    0.00 sec
      Start  9: h265_bitstream_parser_unittest
 9/10 Test  #9: h265_bitstream_parser_unittest ............   Passed    0.00 sec
      Start 10: h265_nal_unit_parser_unittest
10/10 Test #10: h265_nal_unit_parser_unittest .............   Passed    0.00 sec

100% tests passed, 0 tests failed out of 10

Total Test time (real) =   0.04 sec
```

Or to test any of the unittests:

```
$ ./test/h265_profile_tier_level_parser_unittest
Running main() from /builddir/build/BUILD/googletest-release-1.8.1/googletest/src/gtest_main.cc
[==========] Running 1 test from 1 test case.
[----------] Global test environment set-up.
[----------] 1 test from H265ProfileTierLevelParserTest
[ RUN      ] H265ProfileTierLevelParserTest.TestSampleValue
[       OK ] H265ProfileTierLevelParserTest.TestSampleValue (0 ms)
[----------] 1 test from H265ProfileTierLevelParserTest (0 ms total)

[----------] Global test environment tear-down
[==========] 1 test from 1 test case ran. (0 ms total)
[  PASSED  ] 1 test.
```

Check the included vector file:

```
$ ./tools/h265nal ../media/foo.265
h265nal: original version
nal_unit { nal_unit_header { forbidden_zero_bit: 0 nal_unit_type: 39 nuh_layer_id: 0 nuh_temporal_id_plus1: 1 } nal_unit_payload {  } }
...
nal_unit { nal_unit_header { forbidden_zero_bit: 0 nal_unit_type: 0 nuh_layer_id: 0 nuh_temporal_id_plus1: 1 } nal_unit_payload { slice_segment_layer { slice_segment_header { first_slice_segment_in_pic_flag: 1 no_output_of_prior_pics_flag: 0 slice_pic_parameter_set_id: 0 dependent_slice_segment_flag: 0 slice_segment_address: 0 slice_reserved_flag { } slice_type: 0 pic_output_flag: 0 colour_plane_id: 0 slice_pic_order_cnt_lsb: 77 short_term_ref_pic_set_sps_flag: 0 st_ref_pic_set { num_negative_pics: 5 num_positive_pics: 1 delta_poc_s0_minus1 { 2 4 2 2 3 } used_by_curr_pic_s0_flag { 1 1 1 1 1 } delta_poc_s1_minus1 { 0 } used_by_curr_pic_s1_flag { 1 } } slice_temporal_mvp_enabled_flag: 1 slice_sao_luma_flag: 1 slice_sao_chroma_flag: 1 num_ref_idx_active_override_flag: 1 num_ref_idx_l0_active_minus1: 4 num_ref_idx_l1_active_minus1: 0 mvd_l1_zero_flag: 0 collocated_from_l0_flag: 0 five_minus_max_num_merge_cand: 1 slice_qp_delta: 15 slice_loop_filter_across_slices_enabled_flag: 0 num_entry_point_offsets: 12 offset_len_minus1: 5 entry_point_offset_minus1 { 10 2 27 9 2 17 14 24 18 21 16 6 } } } } }
```


# 3. CLI Binary Operation

Parse all the NAL units of an Annex B (`.265` extension) file.

```
$ ./tools/h265nal file.265 --noas-one-line --add-length --add-offset
nal_unit {
  offset: 0x00000004
  length: 23
  nal_unit_header {
    forbidden_zero_bit: 0
    nal_unit_type: 32
    nuh_layer_id: 0
    nuh_temporal_id_plus1: 1
  }
  vps {
    vps_video_parameter_set_id: 0
    vps_base_layer_internal_flag: 1
    vps_base_layer_available_flag: 1
    vps_max_layers_minus1: 0
    ...
```


# 4. Programmatic Integration Operation

There are 3 ways to integrate the parser in your C++ parser:

## 4.1. Annex B H265, Full-File Parsing
If you just have a binary blob with the full contents of a file in Annex B
format, use the `H265BitstreamParser::ParseBitstream()` method. This case
is useful, for example, when you have an Annex B format file (a file with
`.265` or `.h265` extension). You read the whole file in memory, and then
convert the read blob into a set of parsed NAL units.

The following code has been copied from `tools/h265nal.cc`:

```
// read your .265 file into the vector `buffer`
std::vector<uint8_t> buffer(size);

// create bitstream parser from the file
std::unique_ptr<h265nal::H265BitstreamParser::BitstreamState> bitstream =
      h265nal::H265BitstreamParser::ParseBitstream(
          buffer.data(), buffer.size(), options->add_offset,
          options->add_length, options->add_parsed_length);
```

The `H265BitstreamParser::ParseBitstream()` function receives a generic
binary string (`data` and `length`) that you read from the file, plus
some options (whether to add options, length, and parsed length to each
NAL units).

It then:

* (1) splits the input string into a vector of NAL units, and
* (2) parses the NAL units, and add them to the vector


## 4.2. NAL-Unit Parsing
If you have a series of binary blobs with NAL units, use the
`H265NalUnitParser::ParseNalUnit()` method. This case is useful for example
if you have a producer of NAL units (e.g. an encoder), and you want to
parse them as soon as they are produced.

The following code has been copied from `H265BitstreamParser::ParseBitstream()`
in `src/h265_bitstream_parser.cc`:

```
// keep a bitstream parser state (to keep the VPS/PPS/SPS NALUs)
h265nal::H265BitstreamParserState bitstream_parser_state;

// create bitstream parser
std::unique_ptr<h265nal::H265BitstreamParser::BitstreamState> bitstream;

while (1) {
  const uint8_t* data = ...;  // get pointer to the NAL start
	size_t length = ...;  // get NAL size

  auto nal_unit = H265NalUnitParser::ParseNalUnit(
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

The `H265NalUnitParser::ParseNalUnit()` function receives a generic
binary string (`data` and `length`) that contains a NAL unit, plus
a `H265BitstreamParserState` object that keeps all the VPS/SPS/PPS it
ever sees. It then parses the NAL unit, and returns it (including the
parsing offsets).

It will also update the input `H265BitstreamParserState` object if it
sees any VPS/PPS/SPS. This is important if the parsed NAL unit has state
that needs to be used to parse other NAL units (VPS, SPS, PPS): In that
case it will be stored into the `BitstreamParserState` object that is
passed around.

Note that `H265NalUnitParser::ParseNalUnit()` will only parse 1 NAL unit.
There are some producers that will instead produce multiple NAL units
in the output buffer. For example, an h265 encoder producing a key frame
may return 4 NAL units (VPS, PPS, SPS, and slice header).


## 4.3. RTP Packet Parsing
If you want to just pass consecutive RTP packets (rfc7798 format), and get
information on their contents, use the `H265RtpParser::ParseRtp` method.

The following code has been copied from `test/h265_rtp_parser_unittest.cc`.

```
// keep a bitstream parser state (to keep the VPS/PPS/SPS NALUs)
H265BitstreamParserState bitstream_parser_state;

// parse packet(s)
std::unique_ptr<H265RtpParser::RtpState> rtp = H265RtpParser::ParseRtp(
    buffer, arraysize(buffer),
    &bitstream_parser_state);

// packets will return the actual contents into `rtp`, and update the
// bitstream parser state if the RTP packet contains a VPS/SPS/PPS.

// check the main packet contents
switch (rtp->nal_unit_header.nal_unit_type) {
  case AP:
    {
    // an AP (Aggregation Packet) packet contains 2+ NAL Units
    // number_of_packets := rtp->rtp_ap.nal_unit_payloads.size()
    // packet_i := rtp->rtp_ap.nal_unit_payloads[i]
    }
  case FU:
    {
    // an FU (Fragmentation Units) packet contains a piece of a NAL unit
    // has_start_of_packet := rtp->rtp_fu.s_bit
    // internal_type := rtp->rtp_fu.fu_type
    // packet := rtp->rtp_fu.nal_unit_payload
    }
  default:
    {
    // a packet containing a single NAL Unit
    // header := rtp->rtp_single.nal_unit_header
    // payload := rtp->rtp_single.nal_unit_payload
    }
}

// access to the VPS/SPS/PPS map
// e.g. bitstream_parser_state.sps[sps_id].pic_width_in_luma_samples
```


# 5. Requirements
Requires gtests, gmock.

The [`webrtc`](webrtc) directory contains an RBSP parser copied from webrtc.


# 6. Other
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

* no support for PACI (rfc7798 Section 4.4.4)


# 9. License

h265nal is BSD licensed, as found in the [LICENSE](LICENSE) file.


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

