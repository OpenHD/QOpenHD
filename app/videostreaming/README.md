We got 2 approaches for live video streaming:

1) gstreamer and qmlglsink - deprecated for multiple reasons
2) ffmpeg (avcodec) and custom renderer(s) for various ways to then display the decoded video on the screen
(Best), similar to how moonlight-qt does things.
