#!/bin/bash

set -x
set -e
ROOTDIR=$(pwd)

rm -rf drivers
mkdir drivers

# should do this as Deb later
echo "Build/Install NXP 88Q9098/88W9098"

cd drivers
git clone https://github.com/johnlfeeney/mwifiex.git -b lf-6.6.3_1.0.0

cd mwifiex
git clone https://github.com/johnlfeeney/imx-firmware.git lf-6.6.3_1.0.0

cd mxm_wifiex/wlan_src
make -C $ROOTDIR/vyos-build-tik/packages/linux-kernel/linux M=$PWD

cd $ROOTDIR
mkdir -p $ROOTDIR/build/fs/lib/modules/nxp
cp -rf drivers/mwifiex/mxm_wifiex/wlan_src/*.ko $ROOTDIR/build/fs/lib/modules/nxp/
cp -rfp wifi.sh $ROOTDIR/build/fs/lib/modules/nxp/wifi.sh

mkdir -p $ROOTDIR/build/fs/lib/firmware/nxp
cp -rf drivers/mwifiex/lf-6.6.3_1.0.0/nxp/FwImage_9098_PCIE/*.bin $ROOTDIR/build/fs/lib/firmware/nxp/
cp -rf drivers/mwifiex/lf-6.6.3_1.0.0/nxp/wifi_mod_para.conf $ROOTDIR/build/fs/lib/firmware/nxp/wifi_mod_para.conf
cp -rf 99-default.link $ROOTDIR/build/fs/etc/systemd/network/99-default.link
cp -rf 60-Perle-pcie-card-nxp9098.rules $ROOTDIR/build/fs/etc/udev/rules.d/60-Perle-pcie-card-nxp9098.rules

# TI firmware we shoulld do these as deb later just picking the ones we need
#cp -rf $ROOTDIR/vyos-build-tik/packages/linux-kernel/linux-firmware/ti* $ROOTDIR/build/fs/lib/firmware/ti-ipc/am64xx/
