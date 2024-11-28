./buildvyoscontainer[arm64].sh

./rundocker[arm64].sh

./build_iGOS_TMDS64EVM_kernel.sh --repo https://github.com/johnlfeeney --clean

./build_iGOS_TMDS64EVM_fs.sh --repo https://github.com/johnlfeeney

sudo ./build_iGOS_drivers.sh --repo https://github.com/johnlfeeney

exit

sudo ./buildiGOSti.sh bookworm-am64xx-evm

sudo ./create-sdcard.sh bookworm-am64xx-evm

