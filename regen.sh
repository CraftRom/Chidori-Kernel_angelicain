export ARCH=arm64
make angelican_defconfig
cp .config arch/arm64/configs/angelican_defconfig
git commit -am "defconfig: angelican: Regenerate" --signoff
