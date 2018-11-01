#!/usr/bin/env bash
set -Eeuo pipefail

trap "echo \
'The script cannot continue due to an error.
Please unmount and remove /ddbr' \
" ERR

echo "This script copys your alarm to emmc"

mkdir /ddbr
chmod 777 /ddbr

VER=`uname -r`

PART_ROOT="/dev/mmcblk1p3"
PART_BOOT="/dev/mmcblk1p1"
DIR_INSTALL="/ddbr/install"

if ! echo "$VER" |grep -iq "arch"; then echo 'Not Archlinux'; exit 1; fi

if ! ([ -e $PART_ROOT ] && [ -e $PART_BOOT ]); then
echo "No emmc partitions"
exit 1
fi

if [ -e 'offset.sh' ]; then
cat offset.sh > /tmp/offset.sh
chmod +x /tmp/offset.sh
else
echo "no offset.sh"
exit 1
fi

which fw_setenv >/dev/null


echo "Formatting ROOT partition..."
umount $PART_ROOT || true
mkfs.ext4 $PART_ROOT
e2fsck -f $PART_ROOT
echo "done."

echo "Copying ROOTFS."

if [ -d $DIR_INSTALL ] ; then
    rm -rf $DIR_INSTALL
fi

mkdir -p $DIR_INSTALL
mount -o rw $PART_ROOT $DIR_INSTALL

cd /

echo "Copy BIN"
tar --xattrs --acls -cpf - bin | (cd $DIR_INSTALL; tar --xattrs --acls -xpf -)

echo "Create DEV"
mkdir -p $DIR_INSTALL/dev

echo "Copy ETC"
tar --xattrs --acls -cpf - etc | (cd $DIR_INSTALL; tar --xattrs --acls -xpf -)

echo "Copy HOME"
tar --xattrs --acls -cpf - home | (cd $DIR_INSTALL; tar --xattrs --acls -xpf -)

echo "Copy LIB"
tar --xattrs --acls -cpf - lib | (cd $DIR_INSTALL; tar --xattrs --acls -xpf -)

echo "Create MNT"
mkdir -p $DIR_INSTALL/mnt

echo "Copy OPT"
tar --xattrs --acls -cpf - opt | (cd $DIR_INSTALL; tar --xattrs --acls -xpf -)

echo "Create PROC"
mkdir -p $DIR_INSTALL/proc

echo "Copy ROOT"
tar --xattrs --acls -cpf - root | (cd $DIR_INSTALL; tar --xattrs --acls -xpf -)

echo "Create RUN"
mkdir -p $DIR_INSTALL/run

echo "Copy SBIN"
tar --xattrs --acls -cpf - sbin | (cd $DIR_INSTALL; tar --xattrs --acls -xpf -)

echo "Copy SRV"
tar --xattrs --acls -cpf - srv | (cd $DIR_INSTALL; tar --xattrs --acls -xpf -)

echo "Create SYS"
mkdir -p $DIR_INSTALL/sys

echo "Create TMP"
mkdir -p $DIR_INSTALL/tmp

echo "Copy USR"
tar --xattrs --acls -cpf - usr | (cd $DIR_INSTALL; tar --xattrs --acls -xpf -)

echo "Copy VAR"
tar --xattrs --acls -cpf - var | (cd $DIR_INSTALL; tar --xattrs --acls -xpf -)

echo "Create BOOT"
mkdir -p $DIR_INSTALL/boot

echo "Formatting BOOT partition..."
umount $PART_BOOT || true
mkfs.fat -F 16 $PART_BOOT
echo "Copy BOOT"
mount $PART_BOOT $DIR_INSTALL/boot
cp -R /boot/* $DIR_INSTALL/boot/
echo "Prepare uboot files:"
echo -e "\t1. s905_autoscript"
echo 'setenv env_addr "0x10400000"
setenv kernel_addr "0x11000000"
setenv initrd_addr "0x13000000"
setenv boot_start booti ${kernel_addr} ${initrd_addr} ${dtb_mem_addr}
if fatload mmc 1 ${kernel_addr} zImage; then if fatload mmc 1 ${initrd_addr} uInitrd; then if fatload mmc 1 ${env_addr} uEnv.ini; then env import -t ${env_addr} ${filesize};fi; if fatload mmc 1 ${dtb_mem_addr} dtb.img; then run boot_start; else store dtb read ${dtb_mem_addr}; run boot_start;fi;fi;fi;' > $DIR_INSTALL/boot/s905_autoscript.cmd
/usr/bin/mkimage -C none -A arm -T script -d $DIR_INSTALL/boot/s905_autoscript.cmd $DIR_INSTALL/boot/s905_autoscript
echo -e "\t2. uEnv.ini"
echo 'bootargs=root=LABEL=MMCROOTFS rootflags=data=ordered rw console=ttyAML0,115200n8 console=tty0 no_console_suspend consoleblank=0 fsck.fix=yes fsck.repair=yes net.ifnames=0' > $DIR_INSTALL/boot/uEnv.ini
echo 'done'

echo "Writing fstab"

rm $DIR_INSTALL/etc/fstab

echo '# Static information about the filesystems.
# See fstab(5) for details.
# <file system> <dir> <type> <options> <dump> <pass>

LABEL=MMCROOTFS / ext4 relatime,data=ordered,errors=remount-ro 0 1
LABEL=MMCBOOT /boot vfat defaults 0 2
tmpfs /tmp tmpfs defaults,nosuid 0 0' > $DIR_INSTALL/etc/fstab

cd /
sync
umount -R $DIR_INSTALL
rmdir $DIR_INSTALL
rmdir /ddbr

echo "*******************************************"
echo "Done copy files"
echo "*******************************************"


e2label $PART_ROOT "MMCROOTFS"
fatlabel $PART_BOOT "MMCBOOT"
echo -n "${PART_ROOT} label: "
e2label $PART_ROOT
echo -n "${PART_BOOT} label: "
fatlabel $PART_BOOT

###
echo "Write uboot start script"
echo '/tmp/env		0x000000	0x10000 	0x10000' > /etc/fw_env.config
pushd '/tmp'
/tmp/offset.sh 'env'
fw_setenv start_autoscript "if usb start ; then run start_usb_autoscript; fi; if fatload mmc 1 1020000 s905_autoscript; then autoscr 1020000; fi;"
/tmp/offset.sh -d 'env'
popd

echo "*******************************************"
echo "Copied alarm to emmc"
echo "*******************************************"
