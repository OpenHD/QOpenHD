Pielines to quickly test if video decoding is working in QOpenHD.
Just select the right video codec under QOpenHD/video and start streaming rtp via udp to 5600 (where QOpenHD always listens for the main video to come in)

KNOWN BUG: Switching to or from MJPEG requires a restart of QOpenHD (bug of avcodec, won't fix soon)

H264
gst-launch-1.0 videotestsrc ! video/x-raw, format=I420,width=640,height=480,framerate=30/1 ! x264enc bitrate=5000 speed-preset=ultrafast tune=zerolatency key-int-max=30 sliced-threads=0 ! queue ! h264parse config-interval=-1 ! rtph264pay mtu=1024 !  udpsink host=127.0.0.1 port=5600

# funky h264
gst-launch-1.0 filesrc location=/home/consti10/Desktop/intra_test/out/wing_1920x1080p60.mkv ! decodebin ! videorate max-rate=60 ! queue ! videoscale ! video/x-raw, format=I420,width=1920, height=1080, framerate=60/1 ! x264enc name=swencoder bitrate=8000 speed-preset=ultrafast  tune=zerolatency key-int-max=5 sliced-threads=false threads=2 intra-refresh=false qp_min=2 qp_step=10 ! queue ! h264parse config-interval=-1 ! rtph264pay mtu=1024 !  udpsink host=192.168.178.63 port=5600


H265
gst-launch-1.0 videotestsrc ! video/x-raw, format=I420,width=640,height=480,framerate=30/1 ! x265enc bitrate=5000 speed-preset=ultrafast tune=zerolatency key-int-max=30 ! queue ! h265parse config-interval=-1 ! rtph265pay mtu=1024 !  udpsink host=127.0.0.1 port=5600 

MJPEG
gst-launch-1.0 videotestsrc ! video/x-raw, format=I420,width=640,height=480,framerate=30/1 ! jpegenc quality=50 ! queue ! jpegparse ! rtpjpegpay mtu=1024 !  udpsink host=127.0.0.1 port=5600 

Clone project:
git clone https://github.com/OpenHD/QOpenHD.git -b 2.3.x-evo-consti-dev --recurse-submodules