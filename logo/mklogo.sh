#!/bin/bash
ffmpeg -i "$1" -pix_fmt rgb565 -s 1920x1080 output.bmp
[ $? != 0 ] && echo "ffmpeg exited with a non-zero value" && read -p 'Continue?'
cat logo.img.1 output.bmp logo.img.3 logo.img.4 > logo.img
[ "$(du -b logo.img |awk '{print $1}')" == "$(du -b logo.img.orig |awk '{print $1}')" ] && echo -e "\nOK\n" || echo -e "\nWarning: Wrong size! Don't flash\n"
md5sum logo.img
