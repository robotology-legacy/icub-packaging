PACKAGE_VERSION="1.13.0"
# Always use a revision number >=1
DEBIAN_REVISION_NUMBER=2
#ICUB_SOURCES_VERSION="1.13.0"
ICUB_SOURCES_VERSION="devel"

#IPOPT="Ipopt-3.11.7"
YCM_PACKAGE_URL_bionic="https://launchpad.net/~robotology/+archive/ubuntu/ppa/+files/ycm-cmake-modules_0.11.0-1~ubuntu18.04~robotology3_all.deb"
YCM_PACKAGE_URL_buster="https://launchpad.net/~robotology/+archive/ubuntu/ppa/+files/ycm-cmake-modules_0.11.0-1_all.deb"

SUPPORTED_DISTRO_LIST="buster stretch bionic"
SUPPORTED_TARGET_LIST="amd64"

APT_OPTIONS="-q -y"
SVN_OPTIONS="-q --force --non-interactive"  # -q is quiet option, do not prints out each file downloaded, less verbose log file.

ICUB_COMMON_CONFLICT=""  

ICUB_DEPS_COMMON="libace-dev libc6 python libgsl0-dev libncurses5-dev libsdl1.2-dev subversion git gfortran cmake libxmu-dev libode-dev wget unzip qtbase5-dev qtdeclarative5-dev qtmultimedia5-dev libqt5svg5 libqt5opengl5-dev libopencv-dev freeglut3-dev libtinyxml-dev libblas-dev coinor-libipopt-dev liblapack-dev libmumps-dev qml-module-qtmultimedia qml-module-qtquick-dialogs qml-module-qtquick-controls libedit-dev libeigen3-dev libjpeg-dev libsimbody-dev libxml2-dev"
ICUB_DEPS_bionic="libode6"
ICUB_DEPS_cosmic="libode6"
ICUB_DEPS_disco="libode8"
ICUB_DEPS_stretch="libode6"
ICUB_DEPS_BACKPORTS_STRING_disco=""
ICUB_DEPS_BACKPORTS_STRING_cosmic=""
ICUB_DEPS_BACKPORTS_STRING_bionic=""
ICUB_DEPS_BACKPORTS_STRING_stretch=""

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
 -DENABLE_icubmod_xsensmtx=OFF \
 -DYARP_FORCE_DYNAMIC_PLUGINS=ON"
CMAKE_OPTIONS_disco=""
CMAKE_OPTIONS_cosmic=""
CMAKE_OPTIONS_bionic=""
CMAKE_OPTIONS_stretch=""
