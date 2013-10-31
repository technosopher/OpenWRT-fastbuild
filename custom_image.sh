echo "Customizing image now ..."

# This directory should look like the base / of an 
# commotion-openwrt build. All files will be copied
# from the custom workspace to the base install. 
# It might be useful to put scripts that customize
# the install on boot into the /etc/uci-defaults/
# directory.
CUSTOM_WORKSPACE="${WORKSPACE}/customworkspacedir"

#Create /builddata.txt
echo "Built on" `date` > ${WORKSPACE}/commotion-openwrt/openwrt/files/builddata.txt

cp -r ${CUSTOM_WORKSPACE}/* ${WORKSPACE}/commotion-openwrt/openwrt/files/

echo "UCI defaults:"
ls ${WORKSPACE}/commotion-openwrt/openwrt/files/etc/uci-defaults/
echo "Commotion profiles:"
ls ${WORKSPACE}/commotion-openwrt/openwrt/files/etc/commotion/profiles.d/
echo "Network file contents:"
cat ${WORKSPACE}/commotion-openwrt/openwrt/files/etc/config/network
