DOWNLOADS_DIR="$TREE/tmp/downloads"
TREE=$1
MOUNT_INFO=`mount`

if [ ! -d $TREE ]; then
	echo "Specified path, $TREE, does not exist, and hence cannot be initialized as a build tree.  Exiting..."
        exit 1
fi

if [[ $MOUNT_INFO != *$TREE* ]]; then 
	mount -t tmpfs -o size=7g tmpfs $TREE
fi

if [ -n $DOWNLOADS_DIR ]; then
	rm -rf $DOWNLOADS_DIR/*
fi

cd $TREE
if [ -n $TREE/tmp ]; then
	rm -rf $TREE/tmp
fi
if [ -n $TREE/commotion-router ]; then
	rm -rf $TREE/commotion-router
fi
mkdir -p $TREE/tmp/downloads
cp -ra /tmp/downloads/* $DOWNLOADS_DIR
git clone https://github.com/opentechinstitute/commotion-router
cd $TREE/commotion-router
./setup.sh
cd $TREE/commotion-router/openwrt
sed -i .config -e 's,.*CONFIG_CCACHE.*,CONFIG_CCACHE=y,'
sed -i .config -e "s,CONFIG_DOWNLOAD_FOLDER=\"\",CONFIG_DOWNLOAD_FOLDER=\"$DOWNLOADS_DIR\","
make
make clean

