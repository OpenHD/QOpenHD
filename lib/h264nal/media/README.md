# Notes on Test Videos

# 1. Synthetic Videos

Just some synthetic videos with some minor color changes.

From [here](https://mux.com/blog/your-browser-and-my-browser-see-different-colors/)

See the [Makefile](Makefile) file for details.


# 2. Test-Clip Testing

We got some clips (from
[test-videos.co.uk](https://test-videos.co.uk/bigbuckbunny/mp4-h264) and
[h264info.com](https://www.h264info.com/clips.html)), and ran the
`tools/h264nal` tool on them to make sure it does not crash.
Then, we compared the results with those produced by ffmpeg BSF mode.

The process (per-video) is as follows:

```
# convert mp4 to Annex-B format
$ ffmpeg -y -i clip.mp4 -codec:v copy clip.mp4.264

# get bsf data
$ ffmpeg -i clip.mp4.264 -c:v copy -bsf:v trace_headers -f null - >& clip.mp4.264.bsf

# get h264nal parsed data
$ ./h264nal/build/tools/h264nal --noas-one-line --add-offset --add-length --add-parsed-length clip.mp4.264 > clip.mp4.264.txt
```

And then we do manual comparison of clip.mp4.264.bsf and clip.mp4.264.txt.


# 3. Codec Testing

Idea is to test the most common FOSS encoders
([x264](https://www.videolan.org/developers/x264.html),
[OpenH264](https://github.com/cisco/openh264), and others), using different
encoder values, and compare the results with those of ffmpeg BSF mode.

