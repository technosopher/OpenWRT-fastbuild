#!/bin/bash
#TODO: Clean up build.sh flags, add in custom download dir and bindest handlers, add logic to create bin dir, tmp dir if they don't exist (prompt if intervene=3?), make lockfile check in build.sh more global, so that it prevents people who are not using the wrapper from clobbering anything

BUILDTREE_ROOT='/mnt'
SHARED_DOWNLOAD_DIR='/tmp/downloads'
USER=`whoami`
ACTIVE_BUILDTREE=''
for TREE in $BUILDTREE_ROOT/build_tree*; do
        echo $TREE 
	lock=`find $TREE -maxdepth 1 -name *.lock`
        if [ -z "$lock" ]; then
                echo "$TREE is available!  Claiming it..."
		ACTIVE_BUILDTREE="$TREE"
                break
        else
	echo "$build_tree is in use by: `echo $lock | sed 's,\..*,,' | cut -d '/' -f 4`"
	fi
done

if [ -n "$ACTIVE_BUILDTREE" ]; then
        sudo -u build cp --preserve=timestamps -r $SHARED_DOWNLOAD_DIR "$ACTIVE_BUILDTREE/tmp"
	sudo -u build "$@" -b $ACTIVE_BUILDTREE -l "$ACTIVE_BUILDTREE/$USER.lock" -t "$ACTIVE_BUILDTREE/tmp" -d "$ACTIVE_BUILDTREE/tmp/downloads" --bindest "$BUILDTREE_ROOT/bin/$USER-`date +%F--%H.%M.%S`"
	if [ $? -eq 0 ]; then
		if [ -e "$ACTIVE_BUILDTREE/$USER.lock" ]; then
			sudo -u build rm "$ACTIVE_BUILDTREE/$USER.lock"
			sudo -u build rm -r "$ACTIVE_BUILDTREE/tmp/downloads"
		fi
	else 
		if [ -e "$ACTIVE_BUILDTREE/$USER.lock" ]; then
			sudo -u build rm "$ACTIVE_BUILDTREE/$USER.lock"
			sudo -u build rm -r "$ACTIVE_BUILDTREE/tmp/downloads"
		fi
	fi
else
	echo "There are no free build trees!  Please try again later, or badger the people listed above"
fi 
