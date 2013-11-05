#!/bin/bash
# This script pulls allows you to execute a build within a pre-established build environment, complete with pre-built tools and toolchain.  
# The script assumes that a succssful build has already been run within the $BUILD_DIR folder, 
# and that the commotion-openwrt folder is located immediately under (within) $BUILD_DIR.
# The script automatically cleans the existing build tree, clones a new copy of the commotion-openwrt repo into $TEMP_DIR,
# checks out a fresh copy of the OpenWRT build system into this directory, and then copies all of the new files into the pre-existing
# build tree.  The script then opens a command prompt, which allows the user to make any desired changes to feeds, menuconfig, makefiles, etc.
# Once this subshell is closed, the build will proceed.  At the end of the build, the script will the entirety of the bin/ar71xx directory
# to $FINAL_BIN_DEST, which is by default set to $WORKSPACE/bin.

# IMPORTANT NOTE: Please do not execute any part of the build "manually" - let the script do everything for you, and/or modify the script 
# to get it to do want you want.  The script embeds several non-intuitive assumptions, which you may run afoul of if you try to go "off-script"

umask 002
WORKSPACE="/tmp"
BUILD_DIR="/mnt"
TEMP_DIR="/tmp/openwrt-fastbuild"
INIT_CLONE_SRC='https://github.com/opentechinstitute/commotion-openwrt.git'
DOWNLOAD_DIR="$WORKSPACE/downloads"
FINAL_BIN_DEST="$WORKSPACE/bin"
LOCKFILE="$BUILD_DIR/.lock"
INTERVENE=3
CLEAN_ONLY=0
#BUILD_OUTPUT_LOGFILE="$WORKSPACE/build.log"
#CUSTOM_BUILD_HANDLER="$WORKSPACE/custom_build.sh"
#FINISH_BUILD_HANDLER="$WORKSPACE/finish_build.sh"

USAGE=$(cat <<END_OF_USAGE
Usage:
-b, --buildir
	Specify location of pre-populated build tree (the commotion-openwrt folder is expected to exist in this location)
-c, --clonesrc
	Exact URL to be used to get the initial clone of commotion-openwrt; append a -b flag if you need to specify a branch
-d, --downloaddir
	Specify location of the downloads cache
-i, --intervene
	Specify degree of manual intervention desired from 0-3, where 0 signifies none and 3 signifies a lot
-f, --finishbuild
	Script to be run at the completion of the build process
-o, --output
	Output logfile; all script output sent to standard out if this is unset
-p, --prepbuild
	Script to be run after build tree is cleaned and repopulated with new feed info
-t, --tempdir
	Location to which temporary files will be downloaded
-w, --workspace
	Default "root" of entire build envionment, in which all other important directories and files are expected to exist, unless otherwise specified
--bindest
	Where to put the final binaries
-l, --lock
	Location of lock file
--clean
	Clean only
-h, --help
	Print this help message and exit\n
END_OF_USAGE
)

ARGS=`getopt -o "b:c:d:hi:p:t:w:f:o:l:" -l "builddir:,clonesrc:,downloaddir:,help,intervene:,output:,prepbuild:,tempdir:,workspace:,bindest:,lock:,clean" -- "$@"`

if [ $? -ne 0 ]; then
 exit 1
fi

while (( $# )); do
  case "$1" in
    -b|--builddir)
      shift;
      BUILD_DIR="$1"
      shift;
      ;;
    -c|--clonesrc)
      shift;
      INIT_CLONE_SRC="$1"
      shift;
      ;;
    -d|--downloaddir)
      shift;
      DOWNLOAD_DIR="$1"
      shift;
      ;;
    -f|--finishbuild)
      shift;
      FINISH_BUILD_HANDLER="$1"
      shift;
      ;;
    -i|--intervene)
      shift;
      INTERVENE="$1"
      shift;
      ;;
    -o|--output)
      shift;
      BUILD_OUTPUT_LOGFILE="$1"
      shift;
      ;;
    -p|--prepbuild)
      shift;
      CUSTOM_BUILD_HANDLER="$1"
      shift;
      ;;
    -t|--tempdir)
      shift;
      TEMP_DIR="$1"
      shift;
      ;;
    -w|--workspace)
      shift;
      WORKSPACE="$1"
      shift;
      ;;
    --bindest)
      shift;
      FINAL_BIN_DEST="$1"
      shift;
      ;;
    --clean)
      shift;
      CLEAN_ONLY=1
      ;;
    -l|--lock)
      shift;
      LOCKFILE="$1"
      shift;
      ;;
    -h|--help)
      echo -e "$USAGE"
      exit 0
      ;;
    *)
      echo -e "$USAGE"
      exit 1 
      ;;
  esac
done

#destination for images
#Intelligently choose an open builddir
#Add checks for validity of workspace, if downloads directory is usable, 

if [ "$BUILD_DIR/commotion-openwrt/openwrt/toolchain/Makefile" -nt "$BUILD_DIR/commotion-openwrt/openwrt/build_dir/toolchain-mips_r2_gcc-4.6-linaro_uClibc-0.9.33.2" ]; then
 echo "Specified workspace does not contain a pre-populated build tree!  Please run a full build in $BUILD_DIR, then try again"
 exit 1
fi

if [ `id -u` != `stat $BUILD_DIR/commotion-openwrt -c %u` ]; then
 echo "You must be the owner of the entire build tree, \"`stat $BUILD_DIR/commotion-openwrt -c %U`\", to run this script!  Exiting..."
 exit 1
fi

if [ -e "$LOCKFILE" ]; then
 echo "ERROR: Lockfile found! A build is already in progress.  Exiting..."
 exit 1
else
 touch "$LOCKFILE"
fi

function cleanBuildTree {
 echo "Cleaning up build environment..."
 if [ -e "$TEMP_DIR" ]; then
  rm -rf "$TEMP_DIR"
 fi
 cd "$BUILD_DIR/commotion-openwrt/openwrt"
 if [ -e build_dir/linux-ar71xx_generic ]; then
  make clean
  find . -type d -not -name '.' -not -regex ".*/\(logs\|toolchain\|tools\|staging_dir\|build_dir\|.*/\).*" | xargs rm -rf
  find . -type f -not -name '.' -not -regex ".*/\(logs\|toolchain\|tools\|staging_dir\|build_dir\)/.*" | xargs rm -f
  cd "$BUILD_DIR/commotion-openwrt"
  find . -not -name '.' -not -regex ".*openwrt.*" | xargs rm -rf
  find . -type d -name '.svn' -o -name 'target-mips_r2_uClibc-0.9.33.2' | xargs rm -rf
 fi
 echo "Done!"
}

function intervene {
 echo "Opening a shell within the build environment. Exit the shell to continue the normal automated process.  Exit 5 to abort the automated process."
 bash
 if [ $? -eq 5 ]; then
  echo "Aborting the script."
  rm "$LOCKFILE"
  exit
 else
  echo "Continuing the script..."
 fi
}

cleanBuildTree
if [ "$CLEAN_ONLY" -eq 1 ]; then
 rm "$LOCKFILE"
 exit
fi

mkdir -p "$TEMP_DIR"
echo "Cloning main repo into $TEMP_DIR/commotion-openwrt..."
cd "$TEMP_DIR"
git clone "$INIT_CLONE_SRC" 
cd commotion-openwrt

if [ "$INTERVENE" -gt 2 ]; then
 echo "Make changes to ./setup or any other part of the initial build tree before ./setup runs."
 intervene
fi

if [ -n "$BUILD_OUTPUT_LOGFILE" ]; then
 ./setup.sh 2>&1 | tee "$BUILD_OUTPUT_LOGFILE"
else
 ./setup.sh
fi

echo "Moving dynamic elements of build tree from $TEMP_DIR to build directory $BUILD_DIR..."
cp -rf .git* "$BUILD_DIR/commotion-openwrt/"
cd openwrt
rm -rf  staging_dir tools toolchain
cp -rf . "$BUILD_DIR/commotion-openwrt/openwrt"

echo "Entering $BUILD_DIR and setting build options..."
cd "$BUILD_DIR/commotion-openwrt/openwrt"
sed -i .config -e 's,.*CONFIG_CCACHE.*,CONFIG_CCACHE=y,'
sed -i .config -e "s,CONFIG_DOWNLOAD_FOLDER=\"\",CONFIG_DOWNLOAD_FOLDER=\"$DOWNLOAD_DIR\","
echo "Selectively purging downloads directory..."
find "$DOWNLOAD_DIR" -regex ".*\(commotion\|luci\|serval\|olsrd\|avahi\|batphone\|nodog\).*" | xargs rm -f


if [ -e "$CUSTOM_BUILD_HANDLER" ]; then
 . "$CUSTOM_BUILD_HANDLER"
elif [ -n "$CUSTOM_BUILD_HANDLER" ]; then
echo "Build customization script, $CUSTOM_BUILD_HANDLER, does not exist! Skipping..."
fi

if [ "$INTERVENE" -gt 0 ]; then
 echo "Ready to build! Make any changes you wish to feeds, menuconfig, or specific files at the prompt below."
 intervene
fi

if [ -n "$BUILD_OUTPUT_LOGFILE" ]; then
 make -j 13 2>&1 | tee "$BUILD_OUTPUT_LOGFILE"
else
 make -j 13
fi

echo "Moving built binaries to $FINAL_BIN_DEST"
if [ -e bin/ar71xx ]; then
 cp -rf bin/ar71xx "$FINAL_BIN_DEST"
 chmod -Rf g+w "$FINAL_BIN_DEST"
fi
echo "Done!"

if [ "$INTERVENE" -gt 1 ]; then
 echo "The main OpenWRT build process is complete.  If you wish to check or extract anything in the build tree before it is cleaned up, do so now."
 intervene
fi

cleanBuildTree
chmod -Rf g+w "$BUILD_DIR/commotion-openwrt"
find "$DOWNLOAD_DIR" ! -perm -g+w | xargs chmod g+w
rm "$LOCKFILE"

if [ -e "$FINISH_BUILD_HANDLER" ]; then
 . "$FINISH_BUILD_HANDLER"
elif [ -n "$FINISH_BUILD_HANDLER" ]; then
  echo "Build finishing script, $FINISH_BUILD_HANDLER, does not exist! Skipping..."
fi

exit
