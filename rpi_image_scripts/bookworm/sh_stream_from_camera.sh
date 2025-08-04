#!/bin/bash

gst-launch-1.0 -v libcamerasrc ! "video/x-raw,width=1280,height=720,framerate=30/1,format=YUY2" ! videoconvert ! v4l2sink device=/dev/video3


