#!/bin/bash

OUT_DIR="out"
KERNEL_DIR=$PWD
KERN_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb
ZIP_DIR=$KERNEL_DIR/AnyKernel3
CONFIG=angelican_defconfig
BUILD_START=$(date +"%s")

#Set Color
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

# Set configs
mkdir ${OUT_DIR}
export ARCH=arm64
export CROSS_COMPILE
export CROSS_COMPILE_ARM32
_ksetup_old_path="$PATH"
export PATH="$clang_bin:$PATH"

# Main Staff
clang_bin="$HOME/toolchains/proton-clang/bin"
CROSS_COMPILE="aarch64-linux-gnu-"
CROSS_COMPILE_ARM32="arm-linux-gnueabi-"

compile_kernel ()
{

echo -e "$cyan Make DefConfig $nocol"
make O=${OUT_DIR} $CONFIG
echo -e "$cyan Build kernel $nocol"
make O=${OUT_DIR} -j$(grep -c ^processor /proc/cpuinfo)

if ! [ -a $KERN_IMG ];
then
echo -e "$red Kernel Compilation failed! Fix the errors! $nocol"
fi
}

case $1 in
clean)
make ARCH=arm64 -j$(grep -c ^processor /proc/cpuinfo) clean mrproper
;;
*)
compile_kernel
;;
esac
echo -e "$cyan Build flash file $nocol"
# For MIUI Build
# Credit Adek Maulana <adek@techdro.id>
OUTDIR="$KERNEL_DIR/out/"
VENDOR_MODULEDIR="$KERNEL_DIR/AnyKernel3/modules/vendor/lib/modules"

STRIP="$HOME/toolchains/proton-clang/aarch64-linux-gnu/bin/strip$(echo "$(find "$HOME/toolchains/proton-clang/bin" -type f -name "aarch64-*-gcc")" | awk -F '/' '{print $NF}' |\
            sed -e 's/gcc/strip/')"
for MODULES in $(find "${OUTDIR}" -name '*.ko'); do
    "${STRIP}" --strip-unneeded --strip-debug "${MODULES}"
    "${OUTDIR}"/scripts/sign-file sha512 \
            "${OUTDIR}/certs/signing_key.pem" \
            "${OUTDIR}/certs/signing_key.x509" \
            "${MODULES}"
    find "${OUTDIR}" -name '*.ko' -exec cp {} "${VENDOR_MODULEDIR}" \;
done
cd libufdt/src && python2 mkdtboimg.py create $OUTDIR/arch/arm64/boot/dtbo.img $OUTDIR/arch/arm64/boot/dts/qcom/*.dtbo
echo -e "$yelow \n(i) Done moving modules"

cd $ZIP_DIR
cp $KERN_IMG zImage
cp $OUTDIR/arch/arm64/boot/dtbo.img $ZIP_DIR
make normal &>/dev/null
echo "Flashable zip generated under $ZIP_DIR."
cd ..
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
echo "Enjoy Mansi kernel"
