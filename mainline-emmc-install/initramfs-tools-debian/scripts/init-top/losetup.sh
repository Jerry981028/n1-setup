#!/bin/sh
# Example frobnication boot script

PREREQ=""
prereqs()
{
	echo "$PREREQ"
}

case $1 in
prereqs)
	prereqs
	exit 0
	;;
esac

. /scripts/functions
# Begin real processing below this line

echo 'ROOT=/dev/loop7' > /conf/param.conf
echo 'ROOTFLAGS=-o,data=writeback' >> /conf/param.conf

# losetup
losetup -o 2269118464 /dev/loop7 /dev/mmcblk1
