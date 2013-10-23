#!/bin/bash
# This script pulls allows you to execute a build within a pre-established build environment, complete with pre-built tools and toolchain.  
# The script assumes that a succssful build has already been run within the $BUILD_DIR folder, 
# and that the commotion-openwrt folder is located immediately under (within) $BUILD_DIR.
# The script automatically cleans the existing build tree, clones a new copy of the commotion-openwrt repo into $TEMP_DIR,
# checks out a fresh copy of the OpenWRT build system into this directory, and then copies all of the new files into the pre-existing
# build tree.  The script then opens a command prompt, which allows the user to make any desired changes to feeds, menuconfig, makefiles, etc.
# Once this subshell is closed, the build will proceed.  At the end of the build, the script will copy ONLY the "standard" six images 
# (for the bullet, nano, and rocket) to $FINAL_BIN_DEST, which is by default set to $WORKSPACE.

# IMPORTANT NOTE: Please do not execute any part of the build "manually" - let the script do everything for you, and/or modify the script 
# to get it to do want you want.  The script embeds several non-intuitive assumptions, which you may run afoul of if you try to go "off-script"

umask 002
WORKSPACE="/mnt"
BUILD_DIR="$WORKSPACE"
TEMP_DIR="$WORKSPACE/tmp"
INIT_CLONE_OPTS=""
DOWNLOAD_DIR="/tmp/downloads"
FINAL_BIN_DEST="$WORKSPACE"

if [ "$WORKSPACE/commotion-openwrt/openwrt/toolchain/Makefile" -nt "$WORKSPACE/commotion-openwrt/openwrt/build_dir/toolchain-mips_r2_gcc-4.6-linaro_uClibc-0.9.33.2" ]; then
 echo "Specified workspace does not contain a pre-populated build tree!  Please run a full build in $WORKSPACE, then try again"
 return 1
 exit
fi

function cleanBuildTree {
 echo "Cleaning up build environment..."
 if [ -e "$TEMP_DIR" ]; then
  rm -rf "$TEMP_DIR"
 fi
 cd "$BUILD_DIR/commotion-openwrt/openwrt"
 if [ -e build_dir/linux-ar71xx_generic ]; then
  make clean
  find . -type d -not -name '.' -not -regex ".*/\(toolchain\|tools\|staging_dir\|build_dir\|.*/\).*" | xargs rm -rf
  find . -type f -not -name '.' -not -regex ".*/\(toolchain\|tools\|staging_dir\|build_dir\)/.*" | xargs rm -f
  cd "$BUILD_DIR/commotion-openwrt"
  find . -not -name '.' -not -regex ".*openwrt.*" | xargs rm -rf
  find . -type d -name .svn -o -name 'target-mips_r2_uClibc-0.9.33.2' | xargs rm -rf
 fi
 echo "Done!"
}

cleanBuildTree
mkdir -p $TEMP_DIR
echo "Cloning main repo into $TEMP_DIR/commotion-openwrt..."
cd "$TEMP_DIR"
git clone "https://github.com/opentechinstitute/commotion-openwrt.git$INIT_CLONE_OPTS"
cd commotion-openwrt
# Add an additional bash call here if you need to make changes to ./setup or any other part of the initial build tree before ./setup runs.
./setup.sh
echo "Moving dynamic elements of build tree from $TEMP_DIR to build directory $BUILD_DIR..."
cp -ra .git* $BUILD_DIR/commotion-openwrt/
cd openwrt
rm -rf  staging_dir tools toolchain
cp -ra . $BUILD_DIR/commotion-openwrt/openwrt

echo "Entering $BUILD_DIR and setting build options..."
cd $BUILD_DIR/commotion-openwrt/openwrt
sed -i .config -e 's,.*CONFIG_CCACHE.*,CONFIG_CCACHE=y,'
sed -i .config -e "s,CONFIG_DOWNLOAD_FOLDER=\"\",CONFIG_DOWNLOAD_FOLDER=\"$DOWNLOAD_DIR\","
echo "Selectively purging downloads directory..."
find $DOWNLOAD_DIR -regex ".*\(commotion\|luci\|serval\|olsrd\|avahi\|batphone\).*" | xargs rm -f
echo "Ready to build! Make any changes you wish to feeds, menuconfig, or anything else at the prompt below, and then exit to continue the build. Exit 5 to abort the build."
bash
if [ $? -eq 5 ]; then
 echo "Aborting the build."
 exit
else
 echo "Starting the build."
fi
make -j 13

echo "Moving built binaries to $FINAL_BIN_DEST"
if [ -e bin/ar71xx ]; then
 cp -r "bin/ar71xx $FINAL_BIN_DEST"
 chmod -R g+w "$FINAL_BIN_DEST/*"
fi
echo "Done!"

cleanBuildTree
chmod -R g+w "$BUILD_DIR/commotion-openwrt"
chmod -R g+w "DOWNLOADS_DIR"
exit


