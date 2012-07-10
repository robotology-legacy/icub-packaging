ICUB_VERSION='1.1.10'
DEBIAN_REVISION_NUMBER=1
IPOPT="Ipopt-3.10.1"

APT_OPTIONS="-q --no-install-recommends -y --force-yes"
SVN_OPTIONS="-q --force --non-interactive"  # -q is quiet option, do not prints out each file downloaded, less verbose log file.

# Basic dependencies, yarp with version and libode will be added to the dependencies list in the build-icub-package if and when needed because ICUB_REQYARP_VERSION variable can change and depends on icub source.
# See build-iCub-package.sh file, for further details

ICUB_DEPENDENCIES="libace-dev, libgsl0-dev, libc6, python (<= 3), libncurses5-dev, libgtkmm-2.4-dev, libglademm-2.4-dev, libqt3-mt-dev,  libcv-dev, libhighgui-dev, libcvaux-dev,  libsdl1.2-dev, subversion, gfortran, freeglut3-dev, cmake"  #Debian control file wants commas (,) to separate name of packages
BUILD_DEPENDENCIES="libace-dev libgsl0-dev cmake wget unzip subversion gfortran libncurses5-dev libgtkmm-2.4-dev libglademm-2.4-dev libqt3-mt-dev libcv-dev libhighgui-dev libcvaux-dev freeglut3-dev libsdl1.2-dev"   	# apt-get do not wants commas

ICUB_COMMON_CONFLICT="coinor-libipopt0, coinor-libipopt-dev"  

if [ $PLATFORM_KEY = "lenny" ] || [ $PLATFORM_KEY = "lucid" ]; then
	ICUB_COMMON_CONFLICT="$ICUB_COMMON_CONFLICT, libode-dev, libode0, libode0debian1"
	EXTENDED_COMMENT=" and libode library"
else
	ICUB_DEPENDENCIES="$ICUB_DEPENDENCIES, cmake-curses-gui"     	# Debian control file wants commas (,) to separate name of packages
	BUILD_DEPENDENCIES="$BUILD_DEPENDENCIES cmake-curses-gui"		# apt-get DO NOT wants commas
fi

if [ $PLATFORM_KEY = "precise" ] ; then
	ICUB_DEPENDENCIES="$ICUB_DEPENDENCIES, libopencv-dev"     	# Debian control file wants commas (,) to separate name of packages
	BUILD_DEPENDENCIES="$BUILD_DEPENDENCIES libopencv-dev"		# apt-get DO NOT wants commas
fi
