Code for decoding and then displaying video via QT.
RN I've tested sw decoding via gstreamer on standard linux.
NOTE: For hw-accelerated h265 on rpi we will need ffmpeg and some quite complicated windowing stuff.
Since we therefore already have to deal with ffmpeg, it would be worth checking out if ffmpeg simplifies decoding on other platforms, too.
##TODO 
we need platform-dependent hw-accelerated methods here, but this is a lot of work and the legacy code is not maintainable, therefore not directly usable.
