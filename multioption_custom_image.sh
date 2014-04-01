#!/bin/bash

#Question: Read in each parameter as a different array, or read in each line as a single array entry, and parse later?
BUILD_TREE_ROOT=`pwd` #OR PASS IT IN?

BUNDLE_NAMES=('lts' 'redhook' 'detroit') #`ls custom_image_configs`, or a flat file with a list of name-location pairs
BUNDLE_LOCATIONS=('File#/tmp/file' 'Git#https://github.com/opentechinstitute.org/commotion-router' 'Http#example.org')
BUNDLES_LIST=$BUILD_TREE_ROOT/bundles.conf
TEMP_DIR='/tmp'

while read bundle; do
	BUNDLE_NAMES+=(`echo $bundle | sed "s, .*,,"`)
	BUNDLE_LOCATIONS+=(`echo $bundle | sed "s,^.* ,,"`)
done < $BUNDLES_LIST




function ParseBundle {
	if [[ -x $1/configure.sh ]]; then 
	echo 'Running $1/configure.sh...'
	. $1/configure.sh
	fi
	if [[ -d $1/files ]]; then 
	echo 'Copying $1/files to $BUILD_TREE_ROOT/openwrt/files...'
	cp -a $1/files $BUILD_TREE_ROOT/openwrt/files
	fi
}

function FetchFileBundle {
	if [[ "$1" =~ '.tar.gz'  ]]; then tar -xzf $1 $TEMP_DIR/$2
	elif [[ "$1" =~ '.tar.bz2' ]]; then tar -xjf $1 $TEMP_DIR/$2
	elif [[ "$1" =~ '.zip' ]]; then unzip -d $2 $1
	else cp -a $1 $TEMP_DIR/$2
	echo 'File Bundle fetched!'
	ParseBundle $TEMP_DIR/$2
}
function FetchGitBundle {
	git clone $1 $TEMP_DIR/$2
	echo 'Git Bundle fetched!'
	ParseBundle $TEMP_DIR/$2
}
function FetchHttpBundle {
	pushd $TEMP_DIR
	wget $1
	file=`echo $1 | sed 's,.*/,,g'`
	echo 'Http Bundle fetched!'
	#if [[ "$1" =~ '.tar.gz'  ]]; then 
	#if [[ "$1" =~ '.tar.bz2' ]]
	#if [[ "$1" =~ '.zip' ]]
	popd
}

i=1
for config_bundle in "${CONFIG_BUNDLE_NAMES[@]}"; do
	echo -e "$((i++)): $config_bundle"
done

i=0
while [ $i -lt 1 ]; do
	read -p "Please enter the number or name of the config bundle you wish to use: " choice
        if [[ "$choice" =~ ^[0-9]*$ ]] && [ "$choice" -gt 0 ] && [ "$choice" -le ${#CONFIG_BUNDLE_NAMES[@]} ]; then
		i=$choice
                break
        elif [[ ${CONFIG_BUNDLE_NAMES[@]} =~ "$choice" ]]; then
		i=1
		for config_bundle in ${CONFIG_BUNDLE_NAMES[@]}; do
			if [ $config_bundle = "$choice" ]; then break; else i=$((i+1)); fi
		done
		if [ $i -le ${#CONFIG_BUNDLE_NAMES[@]} ]; then break; else i=0; fi
	fi
	echo -e "\nError: Invalid input.  Please type the name of the config bundle or a number in the range of 1-${#CONFIG_BUNDLE_NAMES[@]}.\n\n"
done
echo $i
IFS='#' read -a location <<< "${CONFIG_BUNDLE_LOCATIONS[$i-1]}"
echo "${location[0]}"
echo "${location[1]}"
Fetch${location[0]}Bundle ${location[1]} $choice


#Copy specified source into tmpdir, by way of a method specified with -s (git:, /, svn:. etc.)
#Run prepare.sh, if it exists; otherwise exit with an error




