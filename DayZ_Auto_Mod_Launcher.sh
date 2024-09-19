#!/usr/bin/env bash

#####################################################################################################################################
### DAYZ MOD LAUNCHER ###
#####################################################################################################################################


startmenu() {

unset number
until [[ $number == +([1-2]) ]] ; do

read -s -n1 -p $'
\e[1;40m
\e[92m Select:\n
\e[92m 1) Normal Mod Setup\n
\e[92m 2) Fixed Mod Setup
\e[0m\n' number
done
case ${number} in 

######################################################
#### Normal Mod Setup Start ##########################
######################################################

[1] )

echo ""
echo -e "\e[1;40m\n
\e[1;33m Server Info can be found at \e[1;36m https://www.battlemetrics.com/servers/dayz/
\e[0m"
sleep 0.5
echo ""

ppath=/home/$USER/

echo -e "\e[1;40m\n
\e[92m Enter IP-Address:Port
\e[0m"
sleep 0.5
read SSERVER
sleep 0.5

echo -e "\e[1;40m\n
\e[92m Enter Query Port Number
\e[0m"
sleep 0.5
read PPORT
sleep 0.5

echo -e "\e[1;40m\n
\e[92m Enter Username
\e[0m"
sleep 0.5
read NNAME
sleep 0.5;;


######################################################
#### Normal Mod Setup End ############################
######################################################



######################################################
#### Static Mod Setup Start ##########################
######################################################	

[2] )

# Replace this server info with your server info..
echo ""
SSERVER=87.236.196.137:2302  # IP-Adress:Port

PPORT=15001 		    # Query Port

NNAME=ice       	    # Username

ppath=/home/$USER/

#echo -e "\e[1;44m\n
#\e[30m IP-Address:Port: $SSERVER
#\e[30m Query Port: $PPORT
#\e[30m Username: $NNAME
#\e[0m";
sleep 0.1;;


esac

}
######################################################
#### Static Mod Setup End ############################
######################################################


set -eo pipefail

SELF=$(basename "$(readlink -f "${0}")")

DAYZ_ID=221100

DEFAULT_GAMEPORT=2302
DEFAULT_QUERYPORT=27016

API_URL="https://dayzsalauncher.com/api/v1/query/@ADDRESS@/@PPORT@"
API_PARAMS=(
  -sSL
  -m 10
  -H "User-Agent: $USER"
)
WORKSHOP_URL="https://steamcommunity.com/sharedfiles/filedetails/SubscribeItem/?id=@ID@"

SSERVER=""
PPORT="${DEFAULT_QUERYPORT}"
DEBUG=0
LAUNCH=0
STEAM=""
SERVER=""
PORT="${DEFAULT_QUERYPORT}"
NAME=""
NNAME=""
INPUT=()
MODS=()
MODS2=()
PARAMS=()
IP=()
PORT=()

declare -A DEPS=(

  [gawk]="required for mod metadata. Try: sudo apt install gawk"
  [curl]="required for the server API. Try: sudo apt install curl"
  [jq]="required for the server API's JSON response. Try: sudo apt install jq"
)

while (( "$#" )); do
  case "${1}" in
    -h|--help)
      print_help
      exit
      ;;
    -d|--debug)
      DEBUG=1
      ;;
    --steam)
      STEAM="${2}"
      shift
      ;;
    -l|--launch)
      LAUNCH=1
      ;;
    -s|--server)
      SERVER="${2}"
      [[ "${SERVER}" = *:* ]] || SERVER="${SERVER}:${DEFAULT_GAMEPORT}"
      shift
      ;;
    -p|--port)
      PORT="${2}"
      shift
      ;;
    -n|--name)
      NAME="${2}"
      shift
      ;;
    --)
      shift
      PARAMS+=("${@}")
      LAUNCH=1
      break
      ;;
    *)
      INPUT+=("${1}")
      ;;
  esac
  shift
done

err() {
echo -e >&2 "[\e[1;31m${SELF}][error] ${@}"

exit 1
}

msg() {

echo "[${SELF}][info] ${@}"
}

debug() {
if [[ ${DEBUG} == 1 ]]; then
echo "[${SELF}][debug] ${@}"
  fi
}

check_dir() {

debug "Checking directory: ${1}"
if [ ! -d "${1}" ] ; then
mkdir "/home/$USER/.steam/debian-installation/steamapps/workshop/content/221100"
fi
}

check_dep() {
  command -v "${1}" >/dev/null 2>&1
}

check_deps() {
  for dep in "${!DEPS[@]}"; do
    check_dep "${dep}" || err "'${dep}' not installed (${DEPS["${dep}"]})"
done
}

dec2base64() {
  echo "$1" \
    | LC_ALL=C gawk '
      {
        do {
          printf "%c", and($1, 255)
          $1 = rshift($1, 8)
        } while ($1 > 0)
      }
    ' \
    | base64 \
    | sed 's|/|-|g; s|+|_|g; s|=||g'
}

resolve_steam() {
    if [[ -n "${STEAM}" ]]; then
    check_dep "${STEAM}" || err "Could not find the '${STEAM}' executable"
    fi

    if check_dep steam; then
    STEAM=steam    
    fi
}

query_server_api() {

  [[ -z "${SSERVER}" ]] && return

  local query
  local response
  echo ""
  echo -e "\e[1;40m\n
\e[32m Server IP   : $SSERVER
\e[32m Query Port  : $PPORT
\e[32m UserName    : $NNAME
\e[0m"
  query="$(sed -e "s/@ADDRESS@/${SSERVER%:*}/" -e "s/@PPORT@/${PPORT}/" <<< "${API_URL}")"
  debug "Querying ${query}"
  response="$(curl "${API_PARAMS[@]}" "${query}")"
  debug "Parsing API response"
  jq -e '.result.mods | select(type == "array")' >/dev/null 2>&1 <<< "${response}" || err "Missing data from API response. Try again in a few seconds"
  jq -e '.result.mods[]' >/dev/null 2>&1 <<< "${response}" || { echo ""; echo ""; echo -e "\e[1;36m This is a Vanilla Server.\e[0m"; echo ""; echo ""; read -p $'\e[36m Press ENTER to launch Vanilla DayZ.' foo; echo ""; echo ""; echo "Starting DayZ.. Please Wait.."; echo ""; echo ""; steam -applaunch 221100 -connect=${SSERVER} --PPORT ${PPORT} -name=${NNAME} -nolauncher -world=empty; exit; }

  INPUT+=( $(jq -r ".result.mods[] | .steamWorkshopId" <<< "${response}") )
}

mainmenu(){

sleep 0.25
if [ -f "/home/$USER/.steam/debian-installation/steamapps/workshop/appworkshop_221100.acf" ] ; then
rm /home/$USER/.steam/debian-installation/steamapps/workshop/appworkshop_221100.acf  
fi
sleep 0.25
if [ -f "/home/$USER/.steam/debian-installation/steamapps/workshop/appworkshop_241100.acf" ] ; then
rm /home/$USER/.steam/debian-installation/steamapps/workshop/appworkshop_241100.acf  
fi
sleep 0.25

missing=0  

unset number
until [[ $number == +([1-4]) ]] ; do
read -s -n1 -p $'
\e[1;40m\n
\e[1;92m 1) Join Server\n
\e[1;92m 2) Mods Menu\n
\e[1;92m 3) Save Menu\n
\e[1;92m 4) Quit
\e[0m\n' number
done
case $number in
    [1])
	    echo ""
	    echo -e "\e[1;40m\n
\e[1;48m Checking Server Mods ..
\e[0m" 
            sleep 0.25
            rm -rf /home/$USER/.steam/debian-installation/steamapps/workshop/content/downloads/*
            rm -r -f /home/$USER/.steam/debian-installation/steamapps/common/DayZ/@*
            sleep 0.1;;
    [2])
    submenu1
    ;;
    [3])
    submenu2
    ;;    
    [4])
    exit
    ;;
        *)
        echo "invalid answer, please try again"
        ;;

esac

}

submenu1(){
unset number
until [[ $number == +([1-4]) ]] ; do
read -s -n1 -p $'
\e[1;40m\n
\e[1;92m 1) Verify Mods\n
\e[1;92m 2) Remove Mods Used By This Server\n
\e[1;92m 3) Remove All Mods\n
\e[1;92m 4) Back
\e[0m\n' number
done

#echo ""
case $number in

"1") ######################################################################################

read -p $'\e[1;40m\n
\e[31m Press Enter to Verify Mods for this Server.
\e[0m\n' foo
            sleep 0.25
            for modid in "${INPUT[@]}"; do  
	    rm -rf /home/$USER/.steam/debian-installation/steamapps/workshop/content/221100/${modid}            
	    rm -r -f /home/$USER/.steam/debian-installation/steamapps/common/DayZ/@*
	    continue
	   done
            sleep 0.1
            rm -rf /home/$USER/.steam/debian-installation/steamapps/workshop/content/downloads/*
            sleep 0.1
            rm -r -f /home/$USER/.steam/debian-installation/steamapps/common/DayZ/@*        
            sleep 0.1
            if [ -f "/home/$USER/.steam/debian-installation/steamapps/workshop/appworkshop_221100.acf" ] ; then
            rm /home/$USER/.steam/debian-installation/steamapps/workshop/appworkshop_221100.acf  
            fi
sleep 0.1;;

"2") ######################################################################################

   unset mods2
   for modid in "${INPUT[@]}"; do  
    
    local modpath2="${dir_workshop}/${modid}" 
    local namelink="${modid}"
    MODS2+=("${namelink}")
    local mods2="$(IFS=";" echo "${MODS2[*]}")"
done

read -p $'\e[1;40m\n
\e[31m Press Enter to Delete Mods Used By This Server.
\e[0m\n' foo
echo -e "\e[1;40m\n
\e[31m Mods Deleted:\n ${mods2}\n From Workshop Directory: \n ${dir_workshop}
\e[0m"
            sleep 0.1
	    for modid in "${INPUT[@]}"; do  
	    rm -rf /home/$USER/.steam/debian-installation/steamapps/workshop/content/221100/${modid}
	    continue
	    done
            rm -rf /home/$USER/.steam/debian-installation/steamapps/workshop/downloads/*
            sleep 0.1
	    rm -r -f /home/$USER/.steam/debian-installation/steamapps/common/DayZ/@*
            if [ -f "/home/$USER/.steam/debian-installation/steamapps/workshop/appworkshop_221100.acf" ] ; then
            rm /home/$USER/.steam/debian-installation/steamapps/workshop/appworkshop_221100.acf  
            fi
#exit;;
 
mainmenu "${dir_dayz}" "${dir_workshop}" || exit 1;; 
            
"3") ######################################################################################
    
read -p $'\e[1;40m\n
\e[31m Press Enter to Delete All DayZ Mods.
\e[0m' foo  
            echo ""
            echo -e "\e[1;31m Deleted All Mods From Steam Workshop Directory:\n \e[1;33m${dir_workshop}"
            echo "" 
            sleep 0.1
      rm -rf /home/$USER/.steam/debian-installation/steamapps/workshop/content/221100/*
      sleep 0.1
            rm -rf /home/$USER/.steam/debian-installation/steamapps/workshop/downloads/*
            sleep 0.1
      rm -r -f /home/$USER/.steam/debian-installation/steamapps/common/DayZ/@*

#exit;;

mainmenu "${dir_dayz}" "${dir_workshop}" || exit 1;; 
    
"4") ######################################################################################

    mainmenu
    ;;    
    
      *)
    echo "invalid answer, please try again"
    ;;
esac

}

submenu2(){
unset number
until [[ $number == +([1-3]) ]] ; do
read -s -n1 -p $'
\e[1;40;92m\n
1) Save Script\n
2) Save Alias\n
3) Back
\e[0m\n' number
done

case $number in

"1") ############################# Mods 1 ##########################################################

    echo -e "\e[1;40m\n
\e[1;92m Choose a filename for the Server Launch Script:
\e[0m";
    read fname;	   	   
    echo ""
    unset MODS
for modid in "${INPUT[@]}"; do 
    local modlink="@$(dec2base64 "${modid}")" 
    local modpath="${dir_workshop}/${modid}" 
    local modmeta="${modpath}/meta.cpp"
    MODS+=("${modlink}")
    local mods="$(IFS=";"; echo "${MODS[*]}")"
    local modlink="@$(dec2base64 "${modid}")" 
    sleep 0.2   
done	

    cat > $ppath$fname.sh << ENDMASTER
steam -applaunch 221100 "-mod=$mods" -connect=${SSERVER} --port ${PPORT} -name=${NNAME} -nolauncher -world=empty
ENDMASTER
    echo -e "\e[1;40m\n
\e[1;92m Launch script created:\e[0m\e[1;40m\e\e[1;32m$ppath$fname.sh
\e[0m";
   echo "";
mainmenu "${dir_dayz}" "${dir_workshop}" || exit 1;;

"2") ############################# Mods 2 ##########################################################

    echo -e "\e[1;40m\n
\e[1;92m Choose alias for the Server Launch Script:
\e[0m"
    echo ""
    unset MODS
for modid in "${INPUT[@]}"; do 
    local modlink="@$(dec2base64 "${modid}")" 
    local modpath="${dir_workshop}/${modid}" 
    local modmeta="${modpath}/meta.cpp"
    MODS+=("${modlink}")
    local mods="$(IFS=";"; echo "${MODS[*]}")"
    local modlink="@$(dec2base64 "${modid}")" 
    sleep 0.2         

done
    read fname
    sed -i -e '1i'"alias $fname='steam -applaunch 221100 \"-mod=$mods\" -connect=${SSERVER} --port ${PPORT} -name=${NNAME} -nolauncher -world=empty'" /home/$USER/.bash_aliases;
    source /home/$USER/.bash_aliases;
    echo -e "\e[1;40m\n
\e[1;92m Alias created in '/home/$USER/.bash_aliases'
\e[0m";
    echo ""
mainmenu "${dir_dayz}" "${dir_workshop}" || exit 1;;
	
"3") ######################################################################################
        mainmenu;;
*) ######################################################################################
    echo "invalid answer, please try again" ;;
esac

}

mods_setup() {

    local dir_dayz="${1}"
    local dir_workshop="${2}"
    unset MODS
    
for modid in "${INPUT[@]}"; do 

    local modlink="@$(dec2base64 "${modid}")" 
    local modpath="${dir_workshop}/${modid}" 

if ! [[ -d "${modpath}" ]]; then

    missing=1
    echo -e "\e[1;40m\n
\e[1;31m  MOD MISSING: ${modid}:\e[1;35m $(sed -e"s/@ID@/${modid}/" <<< "${WORKSHOP_URL}")
\e[1;92m  DOWNLOADING MOD: ${modid}...
\e[0m";
    echo ""
    steam steam+workshop_download_item 221100 ${modid} && wait

  continue
fi

done

if (( missing == 1 )); then

   echo -e "\e[1;44m\n 
\e[1;32m Please Wait While Steam Download The Mods.
\e[0m"
   sleep 10
   until [ ! -d "/home/$USER/.steam/debian-installation/steamapps/workshop/temp/221100" ] && sleep 5 && [ ! -d "/home/$USER/.steam/debian-installation/steamapps/workshop/temp/221100" ]; 
   do
   echo -e "\e[1;44m\n 
\e[1;32m ..Downloading Mods. Please wait..
\e[0m"
   sleep 10
   done
echo ""
   echo -e "\e[1;47m\n 
\e[1;34m Mods Finished Downloading.
\e[0m"
fi
    echo ""
    missing=0
    unset MODS
    for modid in "${INPUT[@]}"; do 
    local modlink="@$(dec2base64 "${modid}")" 
    local modpath="${dir_workshop}/${modid}" 
    local modmeta="${modpath}/meta.cpp"
    ln -sr -f "${modpath}" "${dir_dayz}/${modlink}"
    MODS+=("${modlink}")
    local mods="$(IFS=";"; echo "${MODS[*]}")"
    local modlink="@$(dec2base64 "${modid}")" 
  continue

    done

    echo -e "\e[1;42m\n
\e[1;30m Name: $NNAME
\e[1;30m Game IP:Port $SSERVER
\e[1;30m Query Port: $PPORT
\e[0m"
    echo ""

    echo -e "\e[1;40m\n
\e[1;40m\e[1;32m Launch command for this server:\n\n steam -applaunch 221100 \"-mod=$mods\" -connect=${SSERVER} --port ${PPORT} -name=${NNAME} -nolauncher -world=empty
\e[0m"
echo ""
read -p $'\e[1;40m\n
\e[1;92m Press " Enter " to Launch DayZ
\e[0m\n' foo

echo -e "\e[1;40m\n
\e[1;31m Starting DayZ.. Please Wait..
\e[0m\n";

steam -applaunch 221100 "-mod=$MODS" -connect=${SSERVER} --port ${PPORT} -name=${NNAME} -nolauncher -world=empty
           echo "";
	exit;
}


main() {
  check_deps
  resolve_steam

  if [[ -z "${STEAM_ROOT}" ]]; then
  STEAM_ROOT="${XDG_DATA_HOME:-${HOME}/.steam}/steam"
  fi
  STEAM_ROOT="${STEAM_ROOT}/steamapps"
  local dir_dayz="${STEAM_ROOT}/common/DayZ"
  local dir_workshop="${STEAM_ROOT}/workshop/content/${DAYZ_ID}"
  check_dir "${dir_dayz}"
  check_dir "${dir_workshop}"
  startmenu "${dir_dayz}" "${dir_workshop}" || exit 1
  query_server_api
  mainmenu "${dir_dayz}" "${dir_workshop}" || exit 1
  mods_setup "${dir_dayz}" "${dir_workshop}" || exit 1
  local mods="$(IFS=";"; echo "${MODS[*]}")"
  local mods2="$(IFS=";"; echo "${MODS2[*]}")"

}

main
