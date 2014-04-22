#!/bin/bash

BUNDLES_LIST="$WORKSPACE/bundles.conf"
BUNDLE_NAMES=()
BUNDLE_LOCATIONS=()


# Takes as a parameter the location of an unpacked config bundle.  
# Runs the bundle's configure.sh, if it exists.  configure.sh is expected
# to set the $SRC_DIR variable to the location of the source code directory.
# Finally, copies the contents of the bundle's "file" folder to SRC_DIR.

function cleanTemp {
	if [ -d "$TEMP_DIR/$1" ]; then rm -rf "$TEMP_DIR/$1"; fi
}

function ParseBundle {
	pushd "$TEMP_DIR"
	if [[ -x "$1/configure.sh" ]]; then 
		echo "Running $1/configure.sh..."
		. $1/configure.sh
	else SRC_DIR=$1
	fi
	if [[ -d "$1/files" ]]; then 
		echo "Copying $1/files/ to $SRC_DIR/files..."
		cp -af $1/files/* $SRC_DIR/files
	fi
	echo 'Nothing else to do.  Exiting...'
	popd
	cd "$SRC_DIR"
}

function FetchFileBundle {
	cleanTemp "$2"
	if [[ "$1" =~ '.tar.gz'  ]]; then tar -xzf $1 $TEMP_DIR/$2
	elif [[ "$1" =~ '.tar.bz2' ]]; then tar -xjf $1 $TEMP_DIR/$2
	elif [[ "$1" =~ '.zip' ]]; then unzip -d $TEMP_DIR/$2 $1
	elif [[ -d "$1" ]]; then cp -af $1 $TEMP_DIR/$2 
	else
		echo 'Malformed file bundle!  Files bundles must either be archives or directories.  Exiting...'
		exit -1
        fi
	echo 'File Bundle fetched!'
	ParseBundle "$TEMP_DIR/$2"
}

function FetchGitBundle {
	cleanTemp "$2"
	git clone "$1" "$TEMP_DIR/$2"
	#Check clone exit status; if there was an error, halt
	echo 'Git Bundle fetched!'
	ParseBundle "$TEMP_DIR/$2"
}
function FetchHttpBundle {
	cleanTemp "$2"
	pushd "$TEMP_DIR"
	wget "$1"
	file=`echo $1 | sed 's,.*/,,g'`
	echo 'Http Bundle fetched!'
	#if [[ "$1" =~ '.tar.gz'  ]]; then 
	#if [[ "$1" =~ '.tar.bz2' ]]
	#if [[ "$1" =~ '.zip' ]]
	popd
	ParseBundle "$TEMP_DIR/$2"
}


while read bundle; do
        BUNDLE_NAMES+=(`echo $bundle | sed "s,\s.\+,,"`)
        BUNDLE_LOCATIONS+=(`echo $bundle | sed "s,^.*\s,,"`)
done < $BUNDLES_LIST

i=1
for config_bundle in "${BUNDLE_NAMES[@]}"; do
	echo -e "$((i++)). $config_bundle (`echo ${BUNDLE_LOCATIONS[$i-2]} | sed -e 's,.*#,,'`)"
done

i=0
while [ $i -lt 1 ]; do
	read -p "Please enter the number or name of the config bundle you wish to use: " choice
        if [[ "$choice" =~ ^[0-9]*$ ]] && [ "$choice" -gt 0 ] && [ "$choice" -le ${#BUNDLE_NAMES[@]} ]; then
		i=$choice
                choice=${BUNDLE_NAMES[$i-1]} 
                break
        elif [[ ${BUNDLE_NAMES[@]} =~ "$choice" ]]; then
		i=1
		for config_bundle in ${BUNDLE_NAMES[@]}; do
			if [ $config_bundle = "$choice" ]; then break; else i=$((i+1)); fi
		done
		if [ $i -le ${#BUNDLE_NAMES[@]} ]; then break; else i=0; fi
	fi
	echo -e "\nError: Invalid input.  Please type the name of the config bundle or a number in the range of 1-${#BUNDLE_NAMES[@]}.\n\n"
done
IFS='#' read -a location <<< "${BUNDLE_LOCATIONS[$i-1]}"
Fetch${location[0]}Bundle ${location[1]} $choice


