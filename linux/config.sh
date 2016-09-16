PACKAGE_VERSION="1.4.0"
# Always use a revision number >=1
DEBIAN_REVISION_NUMBER=5
ICUB_SOURCES_VERSION="1.4.0"
#ICUB_SOURCES_VERSION="trunk"

#IPOPT="Ipopt-3.11.7"

SUPPORTED_DISTRO_LIST="wily xenial jessie"
SUPPORTED_TARGET_LIST="i386 amd64"

APT_OPTIONS="-q --no-install-recommends -y --force-yes"
SVN_OPTIONS="-q --force --non-interactive"  # -q is quiet option, do not prints out each file downloaded, less verbose log file.

ICUB_COMMON_CONFLICT=""  

ICUB_DEPS_COMMON="libace-dev libgsl0-dev libc6 python libncurses5-dev libcv-dev libhighgui-dev libcvaux-dev libsdl1.2-dev subversion git gfortran cmake libxmu-dev libode-dev wget unzip qtbase5-dev qtdeclarative5-dev qtmultimedia5-dev libqt5svg5 libqt5opengl5-dev libopencv-dev freeglut3-dev libtinyxml-dev libblas-dev coinor-libipopt-dev liblapack-dev libmumps-dev qml-module-qtmultimedia qml-module-qtquick-dialogs qml-module-qtquick-controls libedit-dev"
ICUB_DEPS_xenial="libgtkdataboxmm-dev libgoocanvasmm-2.0-dev libode4"
ICUB_DEPS_wily="libgtkdataboxmm-dev libgoocanvasmm-2.0-dev libode1"
ICUB_DEPS_wheezy="libgoocanvasmm-dev libode1"
ICUB_DEPS_jessie="libgtkdataboxmm-dev libgoocanvasmm-dev libode1"
ICUB_DEPS_BACKPORTS_STRING_xenial=""
ICUB_DEPS_BACKPORTS_STRING_wily=""
ICUB_DEPS_BACKPORTS_STRING_jessie=""
ICUB_DEPS_BACKPORTS_STRING_wheezy="deb http://http.debian.net/debian wheezy-backports main"

ICUB_REPO_URL="https://github.com/robotology/icub-main"
ICUB_PACKAGE_MAINTAINER="Matteo Brunettini <matteo.brunettini@iit.it>"

ICUB_CMAKE_OPTIONS="\
 -DCMAKE_BUILD_TYPE=Release \
 -DICUB_USE_SDL=ON \
 -DICUB_USE_ODE=ON \
 -DIPOPT_DIR=/usr \
 -DICUB_USE_IPOPT=ON \
 -DICUB_USE_GLUT=ON \
 -DENABLE_icubmod_canmotioncontrol=OFF \
 -DENABLE_icubmod_cartesiancontrollerclient=ON \
 -DENABLE_icubmod_cartesiancontrollerserver=ON \
 -DENABLE_icubmod_fakecan=ON \
 -DENABLE_icubmod_gazecontrollerclient=ON \
 -DENABLE_icubmod_skinprototype=ON \
 -DENABLE_icubmod_socketcan=ON \
 -DENABLE_icubmod_static_grabber=ON \
 -DENABLE_icubmod_xsensmtx=ON \
 -DYARP_FORCE_DYNAMIC_PLUGINS=ON"
