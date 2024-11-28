#!/bin/bash

set -x
set -e
ROOTDIR=$(pwd)

cd $ROOTDIR/vyos-build

./build-vyos-image arm64fs --architecture arm64 --build-by "jfeeney@perle.com"

cd $ROOTDIR

# Check ISO file
LIVE_IMAGE_ISO=vyos-build/build/live-image-arm64.hybrid.iso

if [ ! -e ${LIVE_IMAGE_ISO} ]; then
  echo "File ${LIVE_IMAGE_ISO} not exists."
  exit -1
fi

ISOLOOP=$(losetup --show -f ${LIVE_IMAGE_ISO})
echo "Mounting iso on loopback: ${ISOLOOP}"

rm -rf build
mkdir build
mkdir build/tmp/

mount -o ro ${ISOLOOP} build/tmp/

unsquashfs -d build/fs build/tmp/live/filesystem.squashfs

#rm -rf build/fs/boot/grub
mkdir build/fs/boot/dtb

cp -R build/fs/usr/lib/linux-image*/ti build/fs/boot/dtb

# Temporary fix for DUID in vyos-1x until a more complete solution is thought about
cp -Rf $ROOTDIR/updates/vyos-router $ROOTDIR/build/fs/usr/libexec/vyos/init/vyos-router
# Temporary fix for console support until a more complete solution is thought about
#cp -Rf $ROOTDIR/updates/system_console.py /$ROOTDIR/build/fs/usr/libexec/vyos/conf_mode/system_console.py

# replace console ttyS0 with ours at ttyS2
sudo sed -i 's/ttyS0/ttyS2/' $ROOTDIR/build/fs/usr/share/vyos/config.boot.default

# journald fixups
sudo sed -i \
-e 's/#Storage=persistent/Storage=volatile/' \
-e 's/#RuntimeMaxUse=/RuntimeMaxUse=256K/' \
-e 's/MaxLevelSyslog=debug/MaxLevelSyslog=info/' \
    $ROOTDIR/build/fs/etc/systemd/journald.conf

cat build/fs/boot/vmlinuz* | gunzip -d > build/fs/boot/Image

umount -d build/tmp

