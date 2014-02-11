export BUNDLE_ICUB_VERSION=1.1.14
export BUNDLE_ICUB_TWEAK=0
export BUNDLE_IPOPT_VERSION=3.10.1
export BUNDLE_OPENCV_VERSION=git-snapshot-26-09-12
export BUNDLE_SDL_VERSION=1.2.13
export BUNDLE_GLUT_VERSION=3.7.6
export BUNDLE_ODE_VERSION=0.11.1
export BUNDLE_ODE_QT3=""

_BUNDLE_YARP_DIR="F:\cygwin\home\icub\yarp-packaging\windows\bundle-2.3.61"
export BUNDLE_YARP_DIR=`cygpath $_BUNDLE_YARP_DIR`
export BUNDLE_CMAKE_PARAMETERS="-DENABLE_icubmod_cartesiancontrollerclient:BOOL=TRUE -DENABLE_icubmod_cartesiancontrollerserver:BOOL=TRUE -DENABLE_icubmod_gazecontrollerclient:BOOL=TRUE -DENABLE_icubmod_logpolarclient:BOOL=TRUE -DENABLE_icubmod_logpolarserver:BOOL=TRUE -DENABLE_icubmod_debugInterfaceClient:BOOL=TRUE -DENABLE_icubmod_canmotioncontrol=ON -DENABLE_icubmod_fakecan=ON -DENABLE_icubmod_static_grabber=ON"