PACKAGE_VERSION="1.16.0"
# Always use a revision number >=1
DEBIAN_REVISION_NUMBER=1
#ICUB_SOURCES_VERSION="1.13.0"
#ICUB_SOURCES_VERSION="devel"

#IPOPT="Ipopt-3.11.7"
YCM_PACKAGE="ycm-cmake-modules"
YCM_PACKAGE_URL_bionic="https://launchpad.net/~robotology/+archive/ubuntu/ppa/+files/${YCM_PACKAGE}_0.11.3-1~ubuntu18.04~robotology1_all.deb"
YCM_PACKAGE_URL_buster="https://launchpad.net/~robotology/+archive/ubuntu/ppa/+files/${YCM_PACKAGE}_0.11.3-1_all.deb"
YCM_PACKAGE_URL_focal="https://launchpad.net/~robotology/+archive/ubuntu/ppa/+files/${YCM_PACKAGE}_0.11.3-1_all.deb"

ICUB_COMMON_PACKAGE="iCub-common"
ICUB_COMMON_PACKAGE_URL_bionic="https://github.com/robotology/icub-main/releases/download/v${PACKAGE_VERSION}/${ICUB_COMMON_PACKAGE}${PACKAGE_VERSION}-1.bionic_amd64.deb"
ICUB_COMMON_PACKAGE_URL_buster="https://github.com/robotology/icub-main/releases/download/v${PACKAGE_VERSION}/${ICUB_COMMON_PACKAGE}${PACKAGE_VERSION}-1.buster_amd64.deb"
ICUB_COMMON_PACKAGE_URL_focal="https://github.com/robotology/icub-main/releases/download/v${PACKAGE_VERSION}/${ICUB_COMMON_PACKAGE}${PACKAGE_VERSION}-1.focal_amd64.deb"

SUPPORTED_DISTRO_LIST="buster bionic focal"
SUPPORTED_TARGET_LIST="amd64"

APT_OPTIONS="-q -y"
SVN_OPTIONS="-q --force --non-interactive"  # -q is quiet option, do not prints out each file downloaded, less verbose log file.

SKIP_TESTS="true"

ICUB_COMMON_CONFLICT=""  

CMAKE_MIN_REQ_VER="3.12.0"

ICUB_DEPS_COMMON="libace-dev libc6 python libgsl0-dev libncurses5-dev libsdl1.2-dev subversion git gfortran libxmu-dev libode-dev wget unzip qtbase5-dev qtdeclarative5-dev qtmultimedia5-dev libqt5svg5 libqt5opengl5-dev libopencv-dev freeglut3-dev libtinyxml-dev libblas-dev coinor-libipopt-dev liblapack-dev libmumps-dev qml-module-qtmultimedia qml-module-qtquick-dialogs qml-module-qtquick-controls libedit-dev libeigen3-dev libjpeg-dev libsimbody-dev libxml2-dev libjs-underscore ${YCM_PACKAGE}"
ICUB_DEPS_bionic="libode6"
ICUB_DEPS_focal="libode8"
ICUB_DEPS_buster="libode8"
ICUB_DEPS_BACKPORTS_STRING_focal=""
ICUB_DEPS_BACKPORTS_STRING_bionic=""
ICUB_DEPS_BACKPORTS_STRING_buster="deb http://deb.debian.org/debian buster-backports main"

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
CMAKE_OPTIONS_focal=""
CMAKE_OPTIONS_bionic=""
CMAKE_OPTIONS_buster=""
