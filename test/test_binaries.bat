@echo off
start /b cmd /c yarp server
timeout 3 > NUL
start /b cmd /c iCub_SIM
timeout 10 > NUL
start /b cmd /c yarpmotorgui