setlocal
cd E:\Cygwin64\home\icub\yarp-packaging\windows\build\yarp\src\libYARP_rosmsg
if %errorlevel% neq 0 goto :cmEnd
E:
if %errorlevel% neq 0 goto :cmEnd
E:\Cygwin64\home\icub\yarp-packaging\windows\build\yarp-v14-x86-Release\bin\Release\yarpidl_rosmsg.exe --no-ros true --no-cache --no-index --out E:/Cygwin64/home/icub/yarp-packaging/windows/build/yarp-v14-x86-Release/src/libYARP_rosmsg/include ../../extern/ros/std_msgs/msg/Bool.msg
if %errorlevel% neq 0 goto :cmEnd
:cmEnd
endlocal & call :cmErrorLevel %errorlevel% & goto :cmDone
:cmErrorLevel
exit /b %1
:cmDone
if %errorlevel% neq 0 goto :VCEnd
