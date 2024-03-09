#!/bin/bash
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
bash ./Auto_Mod_DZ_CLI.sh -d -l -s $ip -p $port -n $nname

