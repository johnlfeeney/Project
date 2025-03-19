#!/bin/bash

set -x
set -e

# Check if the --repo parameter is provided
if [ "$#" -lt 2 ] || [ "$1" != "--repo" ]; then
    echo "Usage: $0 --repo <repository_url> [--clean]"
    exit 1
fi

REPPREFIX_URL="$2/"
REPO_URL_TI_DEB="$2/debian-repos"""
REPO_URL="$2/vyos-build"
REPO_NAME="vyos-build"
ROOTDIR=$(pwd)

# Check if the --clean parameter is provided
CLEAN=false
if [ "$#" -eq 3 ] && [ "$3" == "--clean" ]; then
    CLEAN=true
fi

# Delete the repository if it already exists and --clean is specified
if [ -d "$REPO_NAME" ]; then
    if [ "$CLEAN" = true ]; then
        echo "Cleaning up existing repository $REPO_NAME."
        rm -rf "$REPO_NAME"
    else
        echo "Repository $REPO_NAME already exists. Skipping clone."
    fi
fi

# Clone the repository if it doesn't exist or was cleaned
if [ ! -d "$REPO_NAME" ]; then
    git clone -b current --single-branch "$REPO_URL"
fi

# Install package scripts
cp -rf package-build-iGOS vyos-build/scripts/package-build-iGOS

# Find all .toml files in the package-build-iGOS directory and replace the URL
find vyos-build/scripts/package-build-iGOS -type f -name "*.toml" -exec sed -i "s|https://github.com/[^/]\+/|$REPPREFIX_URL|g" {} +

# Install build_flavor
cp -rf $ROOTDIR/updates/arm64fs.toml $ROOTDIR/vyos-build/data/build-flavors/arm64fs.toml

#hack new salt-minion key
curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | tee $ROOTDIR/vyos-build/data/live-build-config/archives/salt-archive-keyring.key.chroot
rm -rf $ROOTDIR/vyos-build/data/live-build-config/archives/saltstack.key.chroot

# hack for new salt-minion repository
cp -rf $ROOTDIR/arm64.toml $ROOTDIR/vyos-build/data/architectures/arm64.toml

#frr build fix need to be fixed up later on it the build process
export EMAIL="johnlfeeney@gmail.com"

./package-build.py --dir package-build --include telegraf owamp net-snmp frr frr_exporter blackbox_exporter strongswan openvpn-otp opennhrp \
aws-gwlbtun node_exporter podman ddclient dropbear hostap kea keepalived netfilter pam_tacplus pmacct radvd isc-dhcp ndppd \
hsflowd pyhumps vpp vyos-1x

./package-build.py --dir package-build-iGOS --include ethtool vyatta-bash vyos-user-utils vyatta-biosdevname libvyosconfig \
vyatta-cfg vyos-http-api-tools vyos-utils ipaddrcheck udp-broadcast-relay hvinfo \
libmnl libpam-radius-auth libnss-mapuser
#libtacplus-map libpam-tacplus libnss-tacplus


TSK=ti-linux-firmware
BLT=.filesystem.$TSK.built
if [ ! -f "$BLT" ]; then
    echo "=== I: $0: $TSK BEGIN"

    # symlink everything to the build directory
    for a in $(find $ROOTDIR/vyos-build/scripts -type f -name "*.deb")
    do
        case "$a" in
        *libsnmp-dev_*64.deb)  # Needed for frr (despite -dev_ pattern)
            ;;
        *vpp-dev_*64.deb) # Needed for vpp  (despite -dev_ pattern)
            ;;
        *libvppinfra-dev_*64.deb) # Needed for vpp  (despite -dev_ pattern)
            ;;
        *-dev_*|*-dbg_*|*-doc_*|*-dbgsym_*)  # Unwanted general patterns
            continue
            ;;
        *libtac2-bin_*|*libpam-tacplus_1.4.3*)  # Unwanted packages
            continue
            ;;
        */hsflowd.deb|*/sflowovsd.deb)  # Not actually .deb
            continue
            ;;
        esac

        echo "Symlinking package: $a"
        ln -vrfs $a $ROOTDIR/vyos-build/packages/
    done
fi

# this section needs some rework to clean up how this ti firmware is pulled.
sudo rm -rf debian-repos
git clone $REPO_URL_TI_DEB

cd debian-repos

sudo DEB_SUITE=bookworm ./run.sh ti-linux-firmware
cd ${ROOTDIR}
#find debian-repos/build/bookworm/ti-linux-firmware/ -type f | grep '\.deb$' | xargs -I {} cp {} build/
cp -rf debian-repos/build/bookworm/ti-linux-firmware/*64*.deb $ROOTDIR/vyos-build/packages/
# end of section for rework

sudo ./build_iGOS_TMDS64EVM_fs_ext.sh