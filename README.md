OpenWRT-fastbuild
=================
This collection of scripts comprises a system that streamlines and vastly speeds up the process of configuring and building OpenWRT images.  The scripts add a number of features to the stock OpenWRT buildroot environment, including:
* A build tree setup script that sets up one or more build environments in separate RAMdisks, with as many build components as possible pre-cached for use in future builds
* A build environment manager that allows multiple users to concurrently share multiple independent build trees
* A mechanism for caching the entire tools and toolchain segments of the build process, while performing every other part of the build completely from scratch
* A configuration bundle selection wizard that makes it quick and easy to import various build configurations
Collectively, these additions bring the time needed to complete from-scratch rebuilds of OpenWRT down from around 1.5 hours to approximately 6 minutes.  

##Setup
The greatest speed enhancements offered by this bundle depend on the existance of a pre-built buildroot environment of the desired architecture.  Accordingly, *prepare\_build\_tree.sh* sets up a build environment in a RAMdisk and runs an initial build of commotion-router.  Each build tree requires 7 GB of disk space at peak usage, and this script accordingly will attempt to allocate a 7 GB RAMdisk unless you comment out that particular stanza of the code.  It should be noted that even without a RAMdisk, having a pre-populated build tree with cached tools and toolchain directories will vastly speed up the process of rebuilding OpenWRT

> ./prepare\_build\_tree [empty build directory]

##Configuration
###Single-environment mode

Assuming that a pre-built buildroot environment is available, the next stage is to configure the environment variables of build.sh. This can be done either by passing various flags and associated parameters when you call ./build.sh, or by modifying the variable delarations at the top of the script itself.  Here are the most important options that you will likely need to customize:

REQUIRED:
-b, --buildir [$BUILD\_DIR]
        Specify location of pre-populated build tree (the main source directory is expected to exist in this location).  The default location is $WORKSPACE/build
-d, --downloaddir [$DOWNLOAD\_DIR]
        Specify location of the downloads cache.  The default is $WORKSPACE/downloads
-i, --intervene [$INTERVENE]
        Specify how often the automated process should drop into a shell to allow for manual intervention, on a scale from 0-3.  0 signifies 'never' and 3 signifies 'at every available opportunity'.  The default value is 3.  
-s, --source [$FETCH\_SRC]
        Exact command to be used to fetch a working copy of the source code.  By default, this is a call to ./multioption_custom_image.sh
-t, --tempdir [$TEMP\_DIR]
        Location to which temporary files will be downloaded.  
-w, --workspace [$WORKSPACE]
        Default "root" of entire build envionment, in which all other important directories and files are expected to exist, unless otherwise specified
--bindest [$BINDEST]
        Where to put the final binaries.  The default location is $WORKSPACE/bin

OPTIONAL:
-f, --finishbuild
        Script to be run at the completion of the build process
-o, --output
        Output logfile; all script output sent to standard out if this is unset
-p, --prepbuild
        Script to be run after build tree is cleaned and repopulated with new feed info
-l, --lock
        Location of lock file
-h, --help
        Print this help mess


###Multi-environment mode
* Set up a new UNIX user named "build", and grant all real users of the build environment the right to sudo into a shell owned by that user
* Set up as many independent build trees as you like, perhaps by constructing a simple loop of *prepare_build_tree* calls accross a range of empty build directories

> ./workspace\_manager.sh ./build.sh

##Configuration Bundles

The *multioption\_custom\_image.sh* script allows the build script to be called against a *list* of possible build configurations, which the user of this system can then choose from.  A single build configuration is called a bundle, and can take the form of a regular directory, a Git repository, or a compressed tar archive.  Bundles are registered with the build system by way of bundles.conf, which is a simple list with a couple of formatting tweaks.   

A config bundle consists of a folder with at least one the following (and often both):
1.  A script, ./configure, which does whatever is necessary to get the source code tree properly populated
2.  A directory, *files*, which contains configuration files to be copied on top of the populated source tree

To invoke the configuration chooser during the course of the build process, simply set build.sh's $FETCH\_SRC (-s) paramater to ./multioption\_custom\_image.sh, and make sure that the bundle(s) you wish to import are entered into bundles.conf

This
folder contains the configuration files that need to be tweaked to
customize passwords, SSIDs, and other paramters.  The bundle also
currently enables the AP by default.  There are four files you'll
probably need to customize:

(Begin detailed digression)
----
./files/etc/config/network: contains information on all
permanent network interfaces, which should include both Mesh and AP
interfaces.

./files/etc/commotion/profiles.d/*Mesh: The Commotion-managed
Mesh network profile

./files/etc/commotion/profiles.d/*AP: The Commotion-managed AP
network profile

./files/etc/uci-defaults/add_network: The script that turns on
the AP even before quickstart has been run.  ALL NETWORK SETTINGS IN
THIS FILE ARE TEMPORARY (unless replicated in the commotion profiles).

The best way to figure out how these files are interlinked is probably
to look at how they are currently set up, but here are a couple of
pointers regarding pieces that may be less clear:

/etc/config/network needs to have the names of the two interface files
in /etc/commotion/profiles.d/ listed in appropriate stanzas.  For example
if the names of the two interface files were MyMesh and MyAP, /etc/config/network 
would need to have the following two stanzas:

config 'interface' 'mesh'
option 'profile' 'MyMesh'
option 'proto' 'commotion'

config 'interface' 'ap'
option 'profile' 'MyAP'
option 'proto' 'commotion


The uci-defaults script works like this:

To set some system defaults the first time the device boots, create a
script in the folder /etc/uci-defaults/.  All scripts in that folder
are automatically executed by /etc/init.d/S10boot and if they exited
with code 0 deleted afterwards (scripts that did not exit with code 0
are not deleted and will be re-executed during the next boot until
they also successfully exit).
------
(End detailed digression)


5.  Once all of the files have been edited appropriately, return to
/mnt/custom, and execute ./build.sh

6.  You'll be asked to select a configuration bundle from a list.
I've already added the Detroit bundle to the list, so simply enter
"detroit."
The format of the bundle list (bundles.conf) should be
pretty self-explanatory: each line takes the form <bundle name>
<bundle type>#<bundle location>.  

7.  If everything is working correctly, a LOT of automated steps
should take place without you having to do anything (the parent repo
should be cloned, the openwrt source code fetched, and the files
you just edited copied in place.  When all of these steps are
complete, you should see the following text, and then be presented
with a command prompt:

Copying /tmp/openwrt-tmp/bundle/files to
/tmp/openwrt-tmp/commotion-router/openwrt/files...
Nothing else to do.  Exiting...
Almost ready to build! Make any changes you wish to feeds, menuconfig,
or specific files at the prompt below.  Your working (temporary) files
will then be copied into the final build tree, and built.
Opening a shell within the build environment. Enter "go" to continue
the normal automated process, and "stop" to abort the process.

8.  Take a quick look at ./files/etc/*, and make sure that all of the
changes you made appear in the appropriate places in this file tree.

9. If everything looks good, go ahead and type "go" on the command
line, hit enter, and then wait for the build to complete (it should
take around 6 minutes).

10.  Assuming the build has completed successfully, you should once
again be presented with some text and then an open command prompt:
The main OpenWRT build process is complete.  If you wish to check or
extract anything in the build tree before it is cleaned up, do so now.
Opening a shell within the build environment. Enter "go" to continue
the normal automated process, and "stop" to abort the process.

11.  Go ahead and type "go"

12.  Your newly-built custom images should now be available in $WORKSPACE/bin!
