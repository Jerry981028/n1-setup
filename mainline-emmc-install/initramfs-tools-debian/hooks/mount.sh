#!/bin/sh
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

. /usr/share/initramfs-tools/hook-functions
# Begin real processing below this line
if [ -f /tmp/mount ]
then
chmod +x /tmp/mount
copy_exec /tmp/mount /sbin
fi
