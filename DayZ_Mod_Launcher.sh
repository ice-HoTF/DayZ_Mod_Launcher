#!/usr/bin/env bash

#####################################################################################################################################
### DAYZ Linux CLI LAUNCHER by Bastimeyer https://github.com/bastimeyer/dayz-linux-cli-launcher #####################################
#####################################################################################################################################
### Tested with Debian 11 and 12 ####################################################################################################
#####################################################################################################################################
### Tested with the official steam package: https://wiki.debian.org/Steam ###########################################################
#####################################################################################################################################
### Edited by ice_hotf ##############################################################################################################
#####################################################################################################################################


choose() {
  
echo -e "\e[1;40m\n
\e[1;93m Menu:\n
\e[1;92m   Press ' N '  Normal Mod Setup\n
\e[1;96m   Press ' S ' for Static Mod Setup\n
\e[0m"

read -n1 -s ns

case $ns in


######################################################
#### Normal Mod Setup Start ##########################
######################################################

[Nn]* ) 
echo ""
echo -e "\e[1;40m\n
\e[1;33m Server Info can be found at \e[1;36m https://www.battlemetrics.com/servers/dayz/
\e[0m"
sleep 0.5
echo ""

echo -e "\e[1;40m\n
\e[1;40m Enter IP-Address:Port
\e[0m"
sleep 0.5
read SSERVER
sleep 0.5

echo -e "\e[1;40m\n
\e[1;40m Enter Query Port Number
\e[0m"
sleep 0.5
read PPORT
sleep 0.5

echo -e "\e[1;40m\n
\e[1;40m Enter Username
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

[Ss]* ) 

# Replace this server info with your server info..

SSERVER=71.27.252.186:2322  # IP-Adress:Port

PPORT=2323 		    # Query Port

NNAME=Insert_Name_here	    # Username

ppath=/home/$USER/

sleep 0.1;;

*) echo "invalid option";
   exit;;

esac

######################################################
#### Static Mod Setup End ############################
######################################################

}



set -eo pipefail

SELF=$(basename "$(readlink -f "${0}")")

DAYZ_ID=221100

DEFAULT_GAMEPORT=2302
DEFAULT_QUERYPORT=27016

FLATPAK_STEAM="com.valvesoftware.Steam"
FLATPAK_PARAMS=(
  --branch=stable
  --arch=x86_64
  --command=/app/bin/steam-wrapper
)

API_URL="https://dayzsalauncher.com/api/v1/query/@ADDRESS@/@PPORT@"
API_PARAMS=(
  -sSL
  -m 10
  -H "User-Agent: dayz-linux-cli-launcher"
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

check_flatpak() {
  check_dep flatpak \
    && flatpak info "${FLATPAK_STEAM}" >/dev/null 2>&1 \
    && { flatpak ps | grep "${FLATPAK_STEAM}"; } >/dev/null 2>&1
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


# ----


resolve_steam() {

  if [[ "${STEAM}" == flatpak ]]; then
    check_flatpak || err "Could not find a running instance of the '${FLATPAK_STEAM}' flatpak package"
  elif [[ -n "${STEAM}" ]]; then
    check_dep "${STEAM}" || err "Could not find the '${STEAM}' executable"
  else
#    msg "Resolving steam"
    if check_flatpak; then
      STEAM=flatpak
    elif check_dep steam; then
      STEAM=steam
    else
      err "Could not find a running instance of the '${FLATPAK_STEAM}' flatpak package or the 'steam' executable"
    fi
  fi
}




query_server_api() {

  [[ -z "${SSERVER}" ]] && return

  local query
  local response
   echo ""
   echo -e "\e[1;40m\n
\e[1;40m\e[1;90mQuerying API for Server $SSERVER:$PPORT
   \e[0m" 
 
#  msg "Querying API for Server: ${SSERVER%:*}:${PPORT}"
  query="$(sed -e "s/@ADDRESS@/${SSERVER%:*}/" -e "s/@PPORT@/${PPORT}/" <<< "${API_URL}")"
  debug "Querying ${query}"
  response="$(curl "${API_PARAMS[@]}" "${query}")"
  debug "Parsing API response"
  jq -e '.result.mods | select(type == "array")' >/dev/null 2>&1 <<< "${response}" || err "Missing mods data from API response"
  jq -e '.result.mods[]' >/dev/null 2>&1 <<< "${response}" || { echo ""; echo ""; echo -e "\e[1;36m This is a Vanilla SSERVER.\e[0m"; echo ""; echo ""; read -p $'\e[36m Press ENTER to launch Vanilla DayZ.' foo; echo ""; echo ""; echo "Starting DayZ.. Please Wait.."; echo ""; echo ""; steam -applaunch 221100 -connect=${ip} --PPORT ${PPORT} -name=${nname} -nolauncher -world=empty; exit; }

  INPUT+=( $(jq -r ".result.mods[] | .steamWorkshopId" <<< "${response}") )
}


menu() {
  
sleep 0.25
if [ -f "/home/$USER/.steam/debian-installation/steamapps/workshop/appworkshop_221100.acf" ] ; then
rm /home/$USER/.steam/debian-installation/steamapps/workshop/appworkshop_221100.acf  
fi
sleep 0.25
if [ -f "/home/$USER/.steam/debian-installation/steamapps/workshop/appworkshop_241100.acf" ] ; then
rm /home/$USER/.steam/debian-installation/steamapps/workshop/appworkshop_241100.acf  
fi
sleep 0.25

echo ""
missing=0   
   for modid in "${INPUT[@]}"; do  
    
    local modpath2="${dir_workshop}/${modid}" 
    local namelink="${modid}"
    MODS2+=("${namelink}")
    local mods2="$(IFS=";" echo "${MODS2[*]}")"
done

read -s -n1 -p $'\e[1;40m\n
\e[20m Press " P " to Play DayZ\n
\e[36m Press " M " to Re-Download Mods for this Server\n
\e[33m Press " R " to Remove Mods for this Server\n
\e[31m Press " W " to Remove All Mods\n\e[0m' pmrw
case ${pmrw} in 
   [Pp]* )  echo ""
	    echo ""
	    echo -e "\e[1;40m\n
\e[1;48m Checking Server Mods ..
\e[0m" 
            sleep 0.25
            rm -rf /home/$USER/.steam/debian-installation/steamapps/workshop/content/downloads/*
            rm -r -f /home/$USER/.steam/debian-installation/steamapps/common/DayZ/@*
            sleep 0.1;;

    [Mm]* ) echo ""
            sleep 0.25
            for modid in "${INPUT[@]}"; do  
	    rm -rf /home/$USER/.steam/debian-installation/steamapps/workshop/content/221100/${modid}
	    rm -r -f /home/$USER/.steam/debian-installation/steamapps/common/DayZ/@*
	    echo -e "\e[1;31m Deleting ${modid}"
	    continue
	   done
            sleep 0.1
            rm -rf /home/$USER/.steam/debian-installation/steamapps/workshop/content/downloads/*
            sleep 0.1
            rm -r -f /home/$USER/.steam/debian-installation/steamapps/common/DayZ/@*
            sleep 0.1;;

    [Rr]* ) echo ""
            echo -e "\e[1;31m Deleting Mods:\n\e[1;33m${mods2}\n\e[1;31mFrom Workshop Directory: ${dir_workshop}"
            echo "" 
            sleep 0.1
	    for modid in "${INPUT[@]}"; do  
	    rm -rf /home/$USER/.steam/debian-installation/steamapps/workshop/content/221100/${modid}
	    continue
	    done
            rm -rf /home/$USER/.steam/debian-installation/steamapps/workshop/downloads/*
            sleep 0.1
	    rm -r -f /home/$USER/.steam/debian-installation/steamapps/common/DayZ/@*
            exit;;
            
    [Ww]* ) echo ""
            echo -e "\e[1;31m Deleting All Mods From Steam Workshop Directory:\n \e[1;33m${dir_workshop}"
            echo "" 
            sleep 0.1
	    rm -rf /home/$USER/.steam/debian-installation/steamapps/workshop/content/221100/*
	    sleep 0.1
            rm -rf /home/$USER/.steam/debian-installation/steamapps/workshop/downloads/*
            sleep 0.1
	    rm -r -f /home/$USER/.steam/debian-installation/steamapps/common/DayZ/@*
            exit;;

	* ) echo -e "\e[1;40m\n
\e[1;33m\n Invalid response..
            sleep 0.1
           \e[0m"
            
            exit;;
esac

}

mods_setup() {

  echo ""
  local dir_dayz="${1}"
  local dir_workshop="${2}"
  
for modid in "${INPUT[@]}"; do 
    local modlink="@$(dec2base64 "${modid}")" 
    local modpath="${dir_workshop}/${modid}" 
    local modmeta="${modpath}/meta.cpp"
    ln -sr -f "${modpath}" "${dir_dayz}/${modlink}"
    MODS+=("${modlink}")
    local mods="$(IFS=";"; echo "${MODS[*]}")"
    local modlink="@$(dec2base64 "${modid}")" 
    sleep 0.2
   
         
if ! [[ -d "${modpath}" ]]; then

   missing=1

   echo -e "\e[1;40m\e[1;31m MOD MISSING: ${modid}:\e[1;35m $(sed -e"s/@ID@/${modid}/" <<< "${WORKSHOP_URL}")\e[0m"
   echo -e "\e[1;40m\e[1;33m DOWNLOADING MOD: ${modid}...\e[0m"
   echo -e "\e[1;40m| Mod Id: ${modid} | \e[1;40m Mod Link: ${modlink} |\e[0m"
   echo ""   
   run_steam steam://url/CommunityFilePage/${modid}+workshop_download_item 221100 ${modid} && wait
   run_steam steam://open/library
   sleep 0.5

  continue
fi  
     done
 
if (( missing == 1 )); then
    echo ""
read -p $'\e[1;40m\n
\e[36m Wait for Steam to download the mods and then press ENTER.
\e[0m' foo

    echo ""
fi
    missing=0   

for modid in "${INPUT[@]}"; do  
    local modpath="${dir_workshop}/${modid}" 
    local modmeta="${modpath}/meta.cpp"  
    local modlink="@$(dec2base64 "${modid}")" 
    local modname="$(gawk 'match($0,/name\s*=\s*"(.+)"/,m){print m[1];exit}' "${modmeta}")"
    echo -e "\e[1;40m\n
\e[1;32m| Mod Name: ${modname} | Mod Id: ${modid} | Mod Link: ${modlink} |
\e[0m"
    ln -sr -f "${modpath}" "${dir_dayz}/${modlink}"
    MODS+=("${modlink}")
    echo ""
    sleep 0.1
      continue     
done


    echo -e "\e[1;40m\n
\e[1;20m Name: $NNAME
\e[1;40m\e[1;20m Game IP:Port $SSERVER
\e[1;40m\e[1;20m Query Port: $PPORT
\e[0m"
    echo ""

    echo -e "\e[1;40m\n
\e[1;40m\e[1;92m Launch command for this server:\n\n steam -applaunch 221100 \"-mod=$mods\" -connect=${SSERVER} --port ${PPORT} -name=${NNAME} -nolauncher -world=empty
\e[0m"

    echo ""    
    echo -e "\e[1;40m\n
\e[1;20m Press ' P ' to Play DayZ\n    
\e[1;94m Press ' S ' to Save a Launch Script for this Server in 'home/$USER/' \n
\e[1;36m Press ' A ' to Save an Alias for the Server Launch Script \n
\e[1;31m Press ' Q ' to Quit Launcher
\e[0m"

    read -s -n1 -p $'' psaq
    case $psaq in 
    
    
    [Pp]* ) echo ""
	   echo -e "\e[1;40m\n
	   
\e[1;20m Starting DayZ.. Please Wait..
\e[0m";

run_steam -applaunch 221100 "-mod=$mods" -connect=${SSERVER} --port ${PPORT} -name=${NNAME} -nolauncher -world=empty
           echo "";
	exit;;
    
    [Ss]* ) echo ""
	   echo -e "\e[1;40m\n
\e[1;20m Choose a filename for the Server Launch Script:
\e[0m";
	   read fname;
 	   cat > $ppath$fname.sh << ENDMASTER
steam -applaunch 221100 "-mod=$mods" -connect=${SSERVER} --port ${PPORT} -name=${NNAME} -nolauncher -world=empty
ENDMASTER
   	   echo -e "\e[1;40m\n
\e[1;36m Launch script created:\e[0m\e[1;40m\e\e[1;32m$ppath$fname.sh
\e[0m";
    	   echo "";
	exit;;
	
   [Aa]* ) echo ""
	   echo -e "\e[1;40m\n
\e[1;20m Choose alias for the Server Launch Script:
\e[0m";
	   read fname
	   sed -i -e '17i'"alias $fname='steam -applaunch 221100 \"-mod=$mods\" -connect=${SSERVER} --port ${PPORT} -name=${NNAME} -nolauncher -world=empty'" /home/$USER/.bash_aliases;
     	   source /home/$USER/.bash_aliases;
   	   echo -e "\e[1;40m\n
\e[1;34m Alias created in '/home/$USER/.bash_aliases'
\e[0m";
    	   echo ""
	exit;;
	
    [Qq]* ) echo ""
            echo -e "\e[1;40m\n
\e[1;90m Exit
\e[0m"
	    echo ""
		exit;;
		
        * ) echo -e "\e[1;40m\n
\e[1;31m Invalid response..
\e[0m";
	    echo "";
		exit 1;;
    esac

}

run_steam() {
  if [[ "${STEAM}" == flatpak ]]; then
    ( set -x; flatpak run "${FLATPAK_PARAMS[@]}" "${FLATPAK_STEAM}" "${@}"; )
  else
    ( set -x; steam "${@}"; )
  fi
wait

}

main() {
  check_deps
  resolve_steam

  if [[ -z "${STEAM_ROOT}" ]]; then
    if [[ "${STEAM}" == flatpak ]]; then
      STEAM_ROOT="${HOME}/.var/app/${FLATPAK_STEAM}/data/Steam"
    else
      STEAM_ROOT="${XDG_DATA_HOME:-${HOME}/.steam}/steam"
    fi
  fi
  STEAM_ROOT="${STEAM_ROOT}/steamapps"

  local dir_dayz="${STEAM_ROOT}/common/DayZ"
  local dir_workshop="${STEAM_ROOT}/workshop/content/${DAYZ_ID}"
  check_dir "${dir_dayz}"
  check_dir "${dir_workshop}"
  choose "${dir_dayz}" "${dir_workshop}" || exit 1
  query_server_api
  menu "${dir_dayz}" "${dir_workshop}" || exit 1
  mods_setup "${dir_dayz}" "${dir_workshop}" || exit 1
  local mods="$(IFS=";"; echo "${MODS[*]}")"
  local mods2="$(IFS=";"; echo "${MODS2[*]}")"

}

main
