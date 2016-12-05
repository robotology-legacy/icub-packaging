export BUNDLE_ICUB_VERSION=1.6.0
export BUNDLE_ICUB_TWEAK=1
export BUNDLE_BINARIES_URL="http://wiki.icub.org/iCub/downloads/packages/windows/binaries"
export BUNDLE_OPENCV_VERSION=2.4.9
export BUNDLE_OPENCV_URL="https://github.com/Itseez/opencv/archive"
export BUNDLE_ODE_VERSION="0.13"
export BUNDLE_ODE_URL="$BUNDLE_BINARIES_URL"
export BUNDLE_GLUT_VERSION="3.7.6"
export BUNDLE_GLUT_URL="$BUNDLE_BINARIES_URL"
export BUNDLE_SDL_VERSION="1.2.15"
export BUNDLE_SDL_URL="$BUNDLE_BINARIES_URL"
export BUNDLE_IPOPT_VERSION="3.11.7" 
export BUNDLE_IPOPT_URL="$BUNDLE_BINARIES_URL"
export BUNDLE_GSL_VERSION="1.14"
export BUNDLE_GSL_URL="http://ftpmirror.gnu.org/gsl"

_BUNDLE_YARP_DIR="E:\Cygwin64\home\icub\yarp\packaging\windows\build"
export BUNDLE_YARP_DIR=`cygpath $_BUNDLE_YARP_DIR`
export BUNDLE_CMAKE_PARAMETERS="\
 -DENABLE_icubmod_cartesiancontrollerclient:BOOL=TRUE \
 -DENABLE_icubmod_cartesiancontrollerserver:BOOL=TRUE \
 -DENABLE_icubmod_gazecontrollerclient:BOOL=TRUE \
 -DENABLE_icubmod_logpolarclient:BOOL=TRUE \
 -DENABLE_icubmod_debugInterfaceClient:BOOL=TRUE \
 -DENABLE_icubmod_fakecan=ON \
 -DENABLE_icubmod_static_grabber=ON \
 -DYARP_FORCE_DYNAMIC_PLUGINS=ON"
 