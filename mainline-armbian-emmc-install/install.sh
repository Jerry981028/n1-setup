#!/bin/bash
set -e
echo "Start copy system for DATA partition."

mkdir -p /ddbr
chmod 777 /ddbr

VER=`uname -r`

offset_sh_path=$(readlink -f ../offset.sh)
pushd /root
$offset_sh_path data
$offset_sh_path env
popd

IMAGE_KERNEL="/boot/zImage"
IMAGE_INITRD="/boot/initrd.img-$VER"
PART_ROOT="/root/data"
DIR_INSTALL="/ddbr/install"
IMAGE_DTB="/boot/dtb.img"


if [ ! -f $IMAGE_KERNEL ] ; then
    echo "No KERNEL.  STOP install !!!"
    return
fi

if [ ! -f $IMAGE_INITRD ] ; then
    echo "No INITRD.  STOP install !!!"
    return
fi

#edit by achaoge,
#disable 64bit and metadata_csum features for uboot compatibility
#ref: https://kshadeslayer.wordpress.com/2016/04/11/my-filesystem-has-too-many-bits/
#/sbin/resize2fs -s $PART_ROOT
#/sbin/tune2fs -O ^metadata_csum $PART_ROOT

echo "Formatting DATA partition..."
umount -f $PART_ROOT
mke2fs -F -q -t ext4 -m 0 -O ^64bit,^metadata_csum $PART_ROOT
e2fsck -f $PART_ROOT
echo "done."

echo "Copying ROOTFS."

if [ -d $DIR_INSTALL ] ; then
    rm -rf $DIR_INSTALL
fi

mkdir -p $DIR_INSTALL
mount -o rw $PART_ROOT $DIR_INSTALL

pushd /
echo "Copy BIN"
tar -cf - bin | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy BOOT"
#mkdir -p $DIR_INSTALL/boot
tar -cf - boot | (cd $DIR_INSTALL; tar -xpf -)
echo "Create DEV"
mkdir -p $DIR_INSTALL/dev
#tar -cf - dev | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy ETC"
tar -cf - etc | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy HOME"
tar -cf - home | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy LIB"
tar -cf - lib | (cd $DIR_INSTALL; tar -xpf -)
echo "Create MEDIA"
mkdir -p $DIR_INSTALL/media
#tar -cf - media | (cd $DIR_INSTALL; tar -xpf -)
echo "Create MNT"
mkdir -p $DIR_INSTALL/mnt
#tar -cf - mnt | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy OPT"
tar -cf - opt | (cd $DIR_INSTALL; tar -xpf -)
echo "Create PROC"
mkdir -p $DIR_INSTALL/proc
echo "Copy ROOT"
tar -cf - root | (cd $DIR_INSTALL; tar -xpf -)
echo "Create RUN"
mkdir -p $DIR_INSTALL/run
echo "Copy SBIN"
tar -cf - sbin | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy SELINUX"
tar -cf - selinux | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy SRV"
tar -cf - srv | (cd $DIR_INSTALL; tar -xpf -)
echo "Create SYS"
mkdir -p $DIR_INSTALL/sys
echo "Create TMP"
mkdir -p $DIR_INSTALL/tmp
echo "Copy USR"
tar -cf - usr | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy VAR"
tar -cf - var | (cd $DIR_INSTALL; tar -xpf -)

popd

echo "Copy fstab"

rm $DIR_INSTALL/etc/fstab
cp -a fstab $DIR_INSTALL/etc/

echo "Modify files for N1 emmc boot"
/bin/sed -e "/usb [23]/d" -e 's/fatload mmc 0 \([^ ]*\) \([^;]*\)/ext4load mmc 1:c \1 \/boot\/\2/g' -i $DIR_INSTALL/boot/s905_autoscript.cmd
#/bin/sed -e 's/LABEL=ROOTFS/\/dev\/data/' -e "s/mac=.*/mac=${mac}/" -i $DIR_INSTALL/boot/uEnv.ini
/usr/bin/mkimage -C none -A arm -T script -d $DIR_INSTALL/boot/s905_autoscript.cmd $DIR_INSTALL/boot/s905_autoscript
echo "Emmc boot fixed end"

#rm $DIR_INSTALL/root/install.sh
rm $DIR_INSTALL/root/fstab
rm $DIR_INSTALL/usr/bin/ddbr
rm $DIR_INSTALL/usr/bin/ddbr_backup_nand
rm $DIR_INSTALL/usr/bin/ddbr_restore_nand


echo "patch initramfs"
mkdir -p /etc/initramfs-tools/scripts/init-top
mkdir -p $DIR_INSTALL/etc/initramfs-tools/scripts/init-top
cat initramfs-tools-debian/scripts/init-top/losetup.sh > /etc/initramfs-tools/scripts/init-top/losetup.sh
cat initramfs-tools-debian/scripts/init-top/losetup.sh > $DIR_INSTALL/etc/initramfs-tools/scripts/init-top/losetup.sh
chmod +x /etc/initramfs-tools/scripts/init-top/losetup.sh
chmod +x $DIR_INSTALL/etc/initramfs-tools/scripts/init-top/losetup.sh
update-initramfs -b $DIR_INSTALL/boot -ut
rm /etc/initramfs-tools/scripts/init-top/losetup.sh


sync

umount $DIR_INSTALL

echo "*******************************************"
echo "Done copy ROOTFS"
echo "*******************************************"

cp -a fw_env.config /etc/

echo "Write env bootargs"
fw_setenv initargs "root=/dev/data rootflags=data=writeback rw console=ttyS0,115200n8 console=tty0 no_console_suspend consoleblank=0 fsck.repair=yes net.ifnames=0 mac=\${mac}"
#Edit by achaoge 2018-06-22, for Phicomm N1 boot from emmc
fw_setenv start_autoscript "if usb start ; then run start_usb_autoscript; fi; if ext4load mmc 1:c 1020000 /boot/s905_autoscript; then autoscr 1020000; fi;"

pushd /root
$offset_sh_path -d data
popd

echo "*******************************************"
echo "Complete copy OS to eMMC parted DATA"
echo "*******************************************"
