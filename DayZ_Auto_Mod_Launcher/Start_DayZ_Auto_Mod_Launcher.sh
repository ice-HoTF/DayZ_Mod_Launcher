#!/bin/bash
#####################################################################################################################################
### Tested with Debian 11 and 12. ###################################################################################################
#####################################################################################################################################
### Tested with the official steam package: https://wiki.debian.org/Steam ###########################################################
#####################################################################################################################################
### DAYZ Linux CLI LAUNCHER by Bastimeyer https://github.com/bastimeyer/dayz-linux-cli-launcher #####################################
#####################################################################################################################################
### Edited by ice ###################################################################################################################
#####################################################################################################################################


################################## OPTION 1 ################################################################

# When using this method the terminal will ask you for IP:Port, Query Port and Username and automatically download mods and join server.

echo ""
echo "\e[1;33mServer Info can be found at \e[1;34m https://www.battlemetrics.com/servers/dayz/ \e[0m"
echo ""
echo "Enter IP-ADDRESS:Port"
read ip
echo ""
echo "Enter Query Port Number"
read port
echo ""
echo "Enter Username"
read nname
echo ""
export ip
export port
export nname
echo ""
bash ./DayZ_Auto_Mod_Launcher.sh -d -l -s $ip -p $port -n $nname


################################## OPTION 2 ################################################################

# When using this method you just have to replace the IP:Port, Query Port and Username in "Start_DayZ_Auto_Mod_Launcher.sh".
#
# Example: 

# ip=71.27.252.186:2322
# port=2323
# nname=ice

# export ip
# export port
# export nname
# echo ""
# bash ./DayZ_Auto_Mod_Launcher.sh -d -l -s $ip -p $port -n $nname
