# TODO list



## 1. fix old TODOs

```
$ grep todo src/*| sed 's/.*\/\/\(.*\)/\1/' |sort |uniq -c | sort -nr
grep: src/other: Is a directory
      4  TODO(chemag): add support for supplemental_enhancement_information() (sei)
      4  TODO(chemag): add support for scaling_list_data()
      4  TODO(chemag): add support for hrd_parameters()
      3  TODO(chemag): add support for pps_range_extension()
      2  TODO(chemag): add support for sps_3d_extension()
      2  TODO(chemag): add support for ref_pic_lists_modification()
      2  TODO(chemag): add support for pps_multilayer_extension()
      2  TODO(chemag): add support for pps_3d_extension()
      2  TODO(chemag): add support for NumDeltaPocs
      2  TODO(chemag): add support for filler_data()
      2  TODO(chemag): add support for end_of_seq(()
      2  TODO(chemag): add support for end_of_bitstream(()
      1  TODO(chemag): not clear what to do in other cases. As the same paragraph
      1  TODO(chemag): implement byte_alignment()
      1  TODO(chemag): fix more_rbsp_data()
      1  TODO(chemag): calculate NumPicTotalCurr support (page 99)
```

## 2. comparison with ffmpeg BSF

```
$ ffmpeg -i ~/work/video/h265/encoder/akiyo.kvazaar.qp_05.265 -c:v copy -bsf:v trace_headers -f null - >& /tmp/kvazaar.bsf.05.txt
$ ./build/tools/h265nal --noas-one-line ~/work/video/h265/encoder/akiyo.kvazaar.qp_05.265 > /tmp/kvazaar.h265nal.05.txt
```

and for the latter:

```
:%s/^\[[^\]]*\] [0-9]*  */    /
:%s/^\[[^\]]*\] [0-9]* *//
:%s/    *[0-1]* = /: /
```

then meld.

