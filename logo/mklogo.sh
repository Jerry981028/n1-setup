#!/bin/bash
ffmpeg -i "$1" -pix_fmt rgb565 -s 1920x1080 output.bmp
cat logo.img.1 output.bmp logo.img.3 logo.img.4 > logo.img
stat logo.img logo.img.orig
