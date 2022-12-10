#!/bin/bash

########################################################################################################################################################################
#                                                                                                                                                                      #
# Power Check script by Yordan Dimitrov (@yddimitrov)                                                                                                                  #
#                                                                                                                                                                      #
# The script is pinging 3 devices on the network from an UnRaid server to detect power loss and shutdown the server.                                                   #
# The main use case is when an UnRaid server is connected to a dummy UPS and there is not integration with it.                                                         #
#                                                                                                                                                                      #
# Two check devices must be on the same network as the UnRaid server but not attached to an UPS.                                                                       #
# The control device must be on the same network as the UnRaid server AND must be attached to the UPS as well.                                                         #
#                                                                                                                                                                      #
# The idea is to ping all 3 devices and if the control device (e.g. main router) is still available but the two test                                                   #
# devices are off to treat it as a power loss and initiate graceful server shutdown while there is still power in the dumb UPS.                                        #
# The control device is used for cases where there is a network outage or maintenance period and the UnRaid server has no network connection -                         #
# in these scenarios the server should not be stopped.                                                                                                                 #
#                                                                                                                                                                      #
# KNOWN ISSUES:                                                                                                                                                        #
## False Positive                                                                                                                                                      #
### If both check devices are down or inaccessible in the network for other reasons (e.g. update or maintenance) a false positive shutdown will be triggered           #
#                                                                                                                                                                      #
## False Negative                                                                                                                                                      #
### If during a power outage the control is also down the server won't be turned off.                                                                                  #
## Other                                                                                                                                                               #
### If the script is not scheduled properly in the crontab the server won't be turned off during a power outage.                                                       #
### While running on battery the server will be turned off based on the crontab configuration - too little and you risk turning the server prematurely even if the     #
### power will be restored shortly and the UPS can cover the time. Too much and the battery of the UPS will run out.                                                   #
### There is not integration with the UPS and there is no knowledge of the battery charge level. If you power on the server while the battery is low or still charging #
### you risk running out of battery. Manual charge level management is required.                                                                                       #
########################################################################################################################################################################
date
echo "[PW-CHECK] Starting power check..."

#Configure two nodes in the network to be pinged + a control node.
CHECK_ONE='xxx.xxx.xxx.xxx2'
CHECK_TWO='xxx.xxx.xxx.xxx2'
CONTROL='xxx.xxx.xxx.xxx'

#Ping each node 5 times with 3 seconds waiting time
check_one_count=$(ping -c 5 -W 3 $CHECK_ONE | grep -c from*)
check_two_count=$(ping -c 5 -W 3 $CHECK_TWO | grep -c from*)
control_count=$(ping -c 5 -W 3 $CONTROL | grep -c from*)

echo "[PW-CHECK] First Check Ping Count: $check_one_count --- Second Check Ping Count: $check_two_count --- Control Ping Count: $control_count"

#If the two check devices are not responding but the control device is available we are shutting down the server.
if [ $check_one_count == 0 ] && [ $check_two_count == 0 ] && [ $control_count != 0 ]; then
  echo "[PW-CHECK] Executing graceful shutdown due to missing check devices..."
  /usr/local/emhttp/webGui/scripts/notify -e "PW-CHECK Shutdown" -s "Power Outage Detected!" -d "Shutting down UnRaid Server..." -i "warning"
  sleep 60
  powerdown
fi
