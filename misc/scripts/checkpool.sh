#!/bin/bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    ${SCRIPT_NAME}
#%
#% DESCRIPTION
#%    This script is checking pool processes and reboots 
#%    if something went wrong.
#%    Send info and errors to Telegram channel
#%
#================================================================
#- IMPLEMENTATION
#-    version         ${SCRIPT_NAME} (www.coin-garden.io) 0.0.1
#-    author          Jürg Binggeli, Nathanael Kammermann
#-    copyright       Copyright (c) http://www.coin-garden-io
#-    license         MIT 
#-
#================================================================
#  HISTORY
#     2018/07/21 : j.binggeli : Script creation
#
#================================================================
#  DEBUG OPTION
#    not yet ..
#
#================================================================
# END_OF_HEADER
#================================================================

#== general variables for script ==#
POOLNAME="Ellaism Pool"
POOLCONFIGDIR=/home/ubuntu/open-ellaism-pool
POOLAPP=/home/ubuntu/open-ellaism-pool/build/bin/open-ethereum-pool
DEAMONSTARTCMD=/home/ubuntu/startdeamon.sh

POOLSTRATUM='config.json'
POOLUNLOCKER='unlocker.json'
POOLPAYOUTS='payouts.json'
POOLAPI='api.json'
DEAMON='parity'  # geth or parity

TOKEN="<TOKEN>"
CHAT_ID="<CHAT_ID>"
URL="https://api.telegram.org/bot$TOKEN/sendMessage"


#####################################
# Send Telegram Notification
# param %1 message
#
####################################
function sendTelegram() {
    SEND=`curl -s -X POST $URL -d chat_id=$CHAT_ID -d text="$1"`
}

###################################### 
# check process and solve Problems
# param %1 search pattern
# param %2 auto restart
# param %3 max retries
# param %3 screen name
# param %4 screen process command 
###################################### 
function checkservice() {
    SEARCHPATTERN=$1
    AUTORESTART=$2
    MAXRETRIES=$3
    SCREENNAME=$4
    SCREENCMD=$5
    
    #== check process is running ==#
    if ps ax | grep -v grep | grep $SEARCHPATTERN > /dev/null
    then
        # process is running
        echo "RUNNING: $SCREENNAME"
    else
        # process is offline
        if $AUTORESTART ; then
	    echo "RESTART: $SCREENNAME restart"
	    sendTelegram "$POOLNAME Restart: $SCREENNAME $SCREENCMD"
            screen -dmS $SCREENNAME $SCREENCMD
	else
	    sendTelegram "$POOLNAME: Critical ERROR: $SCREENNAME offline"
	fi
    fi
}

echo `date "+%Y-%m-%d %H:%M"`

# Check Pool Processes
checkservice $DEAMON true 99 "parity" "$DEAMONSTARTCMD"
checkservice $POOLSTRATUM true 99 "pool" "$POOLAPP ${POOLCONFIGDIR}/$POOLSTRATUM" 
checkservice $POOLAPI true 99 "api" "$POOLAPP ${POOLCONFIGDIR}/$POOLAPI" 
checkservice $POOLUNLOCKER true 99 "unlocker" "$POOLAPP ${POOLCONFIGDIR}/$POOLUNLOCKER" 
checkservice $POOLPAYOUTS false 3 "payouts" "$POOLAPP ${POOLCONFIGDIR}/$POOLPAYOUTS" 

