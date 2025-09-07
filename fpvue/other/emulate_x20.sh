#bin/bash

gst-launch-1.0 filesrc location=/home/consti10/Desktop/intra_test/out/wing_1920x1080p60.mkv ! \
matroskademux ! queue ! \
rtph264pay mtu=1024 !  udpsink port=5600

