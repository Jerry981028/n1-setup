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

mv /bin/mount /bin/mount.old
ln -s /sbin/mount /bin/mount

log_warning_msg "ROOTFLAGS: ${ROOTFLAGS}"
#echo 'ROOT=/dev/loop6' > /conf/param.conf
echo 'ROOTFLAGS=-o,offset=2269118464,data=writeback' >> /conf/param.conf

#export rootmnt=/root

# Mount
#losetup -o 2269118464 /dev/loop6 /dev/mmcblk1
#mount -o ro -t ext4 /dev/loop6 /root

# Random stuff from gentoo
# Clean up.
#umount /proc
#umount /sys
# Boot the real thing.
#exec run-init -n /root /sbin/init
#exec run-init /root /sbin/init
