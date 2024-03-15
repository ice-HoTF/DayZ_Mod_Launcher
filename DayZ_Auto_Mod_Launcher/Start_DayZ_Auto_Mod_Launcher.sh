#!/bin/bash
#export DISPLAY=$(w -h $USER | awk '$2 ~ /:[0-9.]*/{print $2}')
#####################################################################################################################################
### Tested with Debian 11 and 12 ####################################################################################################
#####################################################################################################################################
### Tested with the official steam package: https://wiki.debian.org/Steam ###########################################################
#####################################################################################################################################
### DAYZ Linux CLI LAUNCHER by Bastimeyer https://github.com/bastimeyer/dayz-linux-cli-launcher #####################################
#####################################################################################################################################
### Edited by ice ###################################################################################################################
#####################################################################################################################################


####### LAUNCH OPTION 1 #######

echo ""
echo "\e[1;33mServer Info can be found at \e[1;34m https://www.battlemetrics.com/servers/dayz/ \e[0m"
echo ""
echo "Enter IP-ADDRESS:Port"
sleep 0.5

read ip
echo ""
echo "Enter Query Port Number"
sleep 0.5

read port
echo ""
echo "Enter Username"
sleep 0.5

read nname
echo ""
export ip
export port
export nname
echo ""
bash ./DayZ_Auto_Mod_Launcher.sh -d -l -s $ip -p $port -n $nname
sleep


####### LAUNCH OPTION 1 #######

####### EXAMPLE: #######
:'
ip=164.567.203.230:2502
export ip

port=27018
export port

nname=survivor
export nname

echo ""
bash ./DayZ_Auto_Mod_Launcher.sh -d -l -s $ip -p $port -n $nname 
'
