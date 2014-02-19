ICUB_VERSION='1.1.14'
DEBIAN_REVISION_NUMBER=0
IPOPT="Ipopt-3.10.1"
SUPPORTED_DISTRO_LIST="precise quantal raring squeeze wheezy"

APT_OPTIONS="-q --no-install-recommends -y --force-yes"
SVN_OPTIONS="-q --force --non-interactive"  # -q is quiet option, do not prints out each file downloaded, less verbose log file.

# Basic dependencies, yarp with version and libode will be added to the dependencies list in the build-icub-package if and when needed because ICUB_REQYARP_VERSION variable can change and depends on icub source.
# See build-iCub-package.sh file, for further details

ICUB_DEPENDENCIES="libace-dev, libgsl0-dev, libc6, python (<= 3), libncurses5-dev, libgtkmm-2.4-dev, libglademm-2.4-dev, libqt4-dev, libqt4-opengl-dev, libcv-dev, libhighgui-dev, libcvaux-dev,  libsdl1.2-dev, subversion, git, gfortran, freeglut3-dev, cmake (>= 2.8.7), libxmu-dev, libode1 (>= 0.11.1), libode-dev"  #Debian control file wants commas (,) to separate name of packages
BUILD_DEPENDENCIES="libace-dev libgsl0-dev cmake wget unzip subversion gfortran libncurses5-dev libgtkmm-2.4-dev libglademm-2.4-dev libqt4-dev libqt4-opengl-dev libcv-dev libhighgui-dev libcvaux-dev freeglut3-dev libsdl1.2-dev libxmu-dev "	# apt-get do not wants commas

ICUB_COMMON_CONFLICT="coinor-libipopt0, coinor-libipopt-dev"  

if [ "$PLATFORM_KEY" == "precise" ] || [ "$PLATFORM_KEY" == "quantal" ] || [ "$PLATFORM_KEY" == "wheezy" ] ; then
	ICUB_DEPENDENCIES="$ICUB_DEPENDENCIES, libopencv-dev"     	# Debian control file wants commas (,) to separate name of packages
	BUILD_DEPENDENCIES="$BUILD_DEPENDENCIES libopencv-dev"	# apt-get DO NOT wants commas
fi

ICUB_REPO_URL="https://github.com/robotology/icub-main"
