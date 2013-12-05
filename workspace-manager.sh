#!/bin/bash

WORKSPACE_ROOT='/mnt'
ACTIVE_WORKSPACE=''
USER=`whoami`
for workspace in "$WORKSPACE_ROOT/workspace*"; do 
	lock=`find /mnt/ -maxdepth 1 -name *.lock`
        if [ -z "$lock" ]; then
                echo "$workspace is available!  Claiming it..."
                touch "$WORKSPACE_ROOT/$workspace/$USER.lock"
		ACTIVE_WORKSPACE="$workspace"
        else
	echo "$workspace is in use by `echo $lock | sed 's,\..*,,'`"
	fi
done

if [ -n "$ACTIVE_WORKSPACE" ]; then
	sudo -u build build.sh -b $ACTIVE_WORKSPACE
else
	echo "There are no free workspaces!  Please try again later, or badger the people listed above 
