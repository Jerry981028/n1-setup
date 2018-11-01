# n1-setup
[https://github.com/jxjhheric/n1-setup](https://github.com/jxjhheric/n1-setup)

## install.sh
Install your alarm to emmc.  
You need to partition the emmc first.  
Example layout:  
```
Disk /dev/mmcblk1: 7.3 GiB, 7818182656 bytes, 15269888 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0xac036a47

Device         Boot   Start      End  Sectors  Size Id Type
/dev/mmcblk1p1       221184   483327   262144  128M  e W95 FAT16 (LBA)
/dev/mmcblk1p2       483328  1269760   786433  384M 82 Linux swap / Solaris
/dev/mmcblk1p3      1400832 15269887 13869056  6.6G 83 Linux
```

## offset.sh
Help you modify each emmc partiton  
Usage: offset.sh [-d] partition  

## logo/mklogo.sh
Generate logo.img with any picture  
Usage: mklogo.sh path/to/pic.whatever  
