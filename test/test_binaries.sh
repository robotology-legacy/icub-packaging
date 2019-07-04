#!/bin/bash -e 
#set -x
SLEEP_TIME_SEC="6"
yarp server &
sleep $SLEEP_TIME_SEC
iCub_SIM &
sleep $SLEEP_TIME_SEC
yarpmotorgui &
read -n 1
pkill yarpmotorgui
sleep $SLEEP_TIME_SEC
pkill iCub_SIM
sleep $SLEEP_TIME_SEC
pkill yarp
