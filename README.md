OpenWRT-fastbuild
=================
This collection of scripts comprises a system that streamlines and vastly speeds up the process of configuring and building OpenWRT images.  The scripts add a number of features to the stock OpenWRT buildroot environment, including:
* A build tree setup script that sets up one or more build environments in separate RAMdisks, with as many build components as possible pre-cached for use in future builds
* A build environment manager that allows multiple users to concurrently share multiple independent build trees
* A mechanism for caching the entire tools and toolchain segments of the build process, while performing every other part of the build completely from scratch
* A configuration bundle selection wizard that makes it quick and easy to import various build configurations
Collectively, these additions bring the time needed to complete from-scratch rebuilds of OpenWRT down from around 1.5 hours to approximately 6 minutes.  

WARNING: All parameters must be specified as absolute paths!  These scripts do far too much directory changing to allow any assumptions to be made about what directory a process is likely to be in at any given time.  

##Setup
The greatest speed enhancements offered by this bundle depend on the existance of a pre-built buildroot environment of the desired architecture.  Accordingly, *prepare\_build\_tree.sh* sets up a build environment in a RAMdisk and runs an initial build of commotion-router.  Each build tree requires 7 GB of disk space at peak usage, and this script accordingly will attempt to allocate a 7 GB RAMdisk unless you comment out that particular stanza of the code.  It should be noted that even without a RAMdisk, having a pre-populated build tree with cached tools and toolchain directories will vastly speed up the process of rebuilding OpenWRT

> ./prepare\_build\_tree [empty build directory]

##Configuration
###Single-environment mode

Assuming that a pre-built buildroot environment is available, the next stage is to configure the environment variables of *build.sh*. This can be done either by passing various flags and associated parameters when you call ./build.sh, or by modifying the variable delarations at the top of the script itself.  Here are the most important options that you will likely need to customize:

REQUIRED:
-b, --buildir [$BUILD\_DIR]
        Specify location of pre-populated build tree (the main source directory is expected to exist in this location).  The default location is $WORKSPACE/build
-d, --downloaddir [$DOWNLOAD\_DIR]
        Specify location of the downloads cache.  The default location is $WORKSPACE/downloads
-i, --intervene [$INTERVENE]
        Specify how often the automated process should drop into a shell to allow for manual intervention, on a scale from 0-3.  0 signifies 'never' and 3 signifies 'at every available opportunity'.  The default value is 3
-s, --source [$FETCH\_SRC]
        Exact command to be used to fetch a working copy of the source code.  By default, this is a call to ./multioption_custom_image.sh
-t, --tempdir [$TEMP\_DIR]
        Location to which temporary files will be downloaded
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
* Set up as many independent build trees as you like, perhaps by constructing a simple loop of *prepare_build_tree* calls accross a range of empty build directories named "build\_dir\_\*"

> ./workspace\_manager.sh ./build.sh

##Custom Images: Configuration Bundles

The *multioption\_custom\_image.sh* script allows the build script to be called against a list of possible build configurations, which the user of this system can then choose from.  A single build configuration is called a bundle, and can take the form of a regular directory, a Git repository, or a compressed tar archive.  Bundles are registered with the build system by way of bundles.conf, which is a simple list with a couple of formatting tweaks.   

Each line of the bundle list takes the form ```<bundle name> <bundle type>#<bundle location>. ```
 
A config bundle consists of a folder with at least one the following (and often both):
1.  A script, *configure.sh*, which does whatever is necessary to get the source code tree properly populated
2.  A directory, *files*, which contains configuration files to be copied on top of the populated source tree

To invoke the configuration chooser during the course of the build process, simply set build.sh's $FETCH\_SRC (-s) paramater to ./multioption\_custom\_image.sh, and make sure that the bundle(s) you wish to import are listed in bundles.conf


##USAGE
Once all of the aforementioned configuration is complete, simply run ./build.sh 
(or ./workspace\_manager ./build.sh).

If everything is working correctly, a LOT of automated steps
should take place without you having to do anything (even if you've
asked for a high level of intervention, most operations are taken care 
of for you, because cloning and configuration have to take place in a very
particular order for toolchain caching to work correctly).  
In the first phase of the automated process, the upstream source repository
should be cloned, the openwrt source code fetched, and the files
you just edited copied in place.  (If you are using the custom configuration
bundle selector, you will be prompted to select your desired bundle
before any of these other steps take place).
 When all of these steps are complete, you should see the following text, 
and then be presented with a command prompt:

Copying /tmp/openwrt-tmp/bundle/files to
/tmp/openwrt-tmp/commotion-router/openwrt/files...
Nothing else to do.  Exiting...
Almost ready to build! Make any changes you wish to feeds, menuconfig,
or specific files at the prompt below.  Your working (temporary) files
will then be copied into the final build tree, and built.
Opening a shell within the build environment. Enter "go" to continue
the normal automated process, and "stop" to abort the process.

If you're using a custom configuration bundle, take a quick look at 
./files/etc/*, and make sure that all of the changes you made appear 
in the appropriate places in this file tree.

If everything looks good, go ahead and type "go" on the command
line, hit enter, and then wait for the build to complete.

Assuming the build has completed successfully, you should once
again be presented with some text and then an open command prompt:
The main OpenWRT build process is complete.  If you wish to check or
extract anything in the build tree before it is cleaned up, do so now.
Opening a shell within the build environment. Enter "go" to continue
the normal automated process, and "stop" to abort the process.

Go ahead and type "go"

Your newly-built custom images should now be available in $WORKSPACE/bin!
