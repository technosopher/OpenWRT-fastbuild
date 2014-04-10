OpenWRT-fastbuild
=================
This collection of scripts comprises a system that streamlines and vastly speeds up the process of configuring and building OpenWRT images.  The scripts add a number of features to the stock OpenWRT buildroot environment, including:
* A build tree setup script that sets up one or more build environments in separate RAMdisks, with as many build components as possible pre-cached for use in future builds
* A build environment manager that allows multiple users to concurrently share multiple independent build trees
* A mechanism for caching the entire tools and toolchain segments of the build process, while performing every other part of the build completely from scratch
* A configuration bundle selection wizard that makes it quick and easy to import various build configurations
Collectively, these additions bring the time needed to complete from-scratch rebuilds of OpenWRT down from around 1.5 hours to approximately 6 minutes.  

SETUP
====
The greatest speed enhancements offered by this bundle depend on the existance of a pre-built buildroot environment of the desired architecture.  Accordingly, 'prepare_build_tree.sh' sets up a build environment in a RAMdisk and runs an initial build of commotion-router.  Each build tree requires 7 GB of disk space at peak usage, and this script accordingly will attempt to allocate a 7 GB RAMdisk unless you comment out that particular stanza of the code.  It should be noted that even without a RAMdisk, having a pre-populated build tree with cached tools and toolchain directories will vastly speed up the process of rebuilding OpenWRT

./prepare_build_tree [empty build directory]

USAGE: single-environment mode
====
Assuming that a pre-built buildroot environment is available, the next stage is to configure the environment variables of build.sh. This can be done either by passing various flags and associated parameters when you call ./build.sh, or by modifying the variable delarations at the top of the script itself.  Here are the most important options that you will likely need to customize:

REQUIRED:
-b, --buildir [$BUILD_DIR]
        Specify location of pre-populated build tree (the main source directory is expected to exist in this location)
-d, --downloaddir [$DOWNLOAD_DIR]
        Specify location of the downloads cache
-i, --intervene [$INTERVENE]
        Specify how often the automated process should pause at a shell to allow for manual intervention, on a scale from 0-3.  0 signifies 'never' and 3 signifies 'at every available opportunity'
-s, --source [$FETCH_SRC]
        Exact command to be used to fetch a working copy of the source code.  By default, this is a call to multioption_custom_image.sh
-t, --tempdir [$TEMP_DIR]
        Location to which temporary files will be downloaded.  
-w, --workspace [$WORKSPACE]
        Default "root" of entire build envionment, in which all other important directories and files are expected to exist, unless otherwise specified
--bindest [$BINDEST]
        Where to put the final binaries.  The default is $WORKSPACE/bin

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


For example, suppose that you have a pre-populated build tree in /mnt/build_tree, you want your workspace to be /mnt, and your temp directory to be /tmp
