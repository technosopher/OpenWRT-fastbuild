NEW_BUNDLE=$1
if [[ -d $NEW_BUNDLE ]]; then
 [[ $(du $NEW_BUNDLE | cut -f 1) -eq 0 ]] || { echo 'Specified path for new bundle, $NEW_BUNDLE, is not empty!  Exiting...'; exit 1 }
else 
 mkdir $NEW_BUNDLE || { echo 'Could not create bundle directory! Exiting...'; exit 1 }
fi
WORKSPACE=`pwd`
cp -rfa /mnt/custom/commotion-router-wrapper $WORKSPACE
cd commotion-router-wrapper
./configure.sh
cd openwrt
find . -not -type d | xargs md5sum > $WORKSPACE/filelist0
make menuconfig
find . -not -type d | xargs md5sum > $WORKSPACE/filelist1
diff /tmp/filelist0 /tmp/filelist1 | grep '>' | sed 's,.*\./,,' | xargs cp -rfa --parents -t $NEW_BUNDLE

