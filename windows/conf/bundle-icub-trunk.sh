export BUNDLE_ICUB_VERSION=trunk
export BUNDLE_ICUB_TWEAK=0
export BUNDLE_OPENCV_VERSION=2.4.9
export BUNDLE_OPENCV_URL="https://github.com/Itseez/opencv/archive"
export BUNDLE_ODE_VERSION="0.11.1"
export BUNDLE_ODE_URL="http://wiki.icub.org/iCub/downloads/packages/windows"
export BUNDLE_GLUT_VERSION="3.7.6"
export BUNDLE_GLUT_URL="http://wiki.icub.org/iCub/downloads/packages/windows/common"
export BUNDLE_SDL_VERSION="1.2.13"
export BUNDLE_SDL_URL="http://wiki.icub.org/iCub/downloads/packages/windows/common"
export BUNDLE_IPOPT_VERSION=3.10.1

_BUNDLE_YARP_DIR="E:\Cygwin64\home\icub\yarp-packaging-windows\build"
export BUNDLE_YARP_DIR=`cygpath $_BUNDLE_YARP_DIR`
export BUNDLE_CMAKE_PARAMETERS="-DENABLE_icubmod_cartesiancontrollerclient:BOOL=TRUE -DENABLE_icubmod_cartesiancontrollerserver:BOOL=TRUE -DENABLE_icubmod_gazecontrollerclient:BOOL=TRUE -DENABLE_icubmod_logpolarclient:BOOL=TRUE -DENABLE_icubmod_debugInterfaceClient:BOOL=TRUE -DENABLE_icubmod_fakecan=ON -DENABLE_icubmod_static_grabber=ON"