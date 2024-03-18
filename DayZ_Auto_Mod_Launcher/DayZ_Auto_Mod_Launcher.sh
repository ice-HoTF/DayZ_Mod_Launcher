#!/usr/bin/env bash
#####################################################################################################################################
### Tested with Debian 11 and 12 ####################################################################################################
#####################################################################################################################################
### Tested with the official steam package: https://wiki.debian.org/Steam ###########################################################
#####################################################################################################################################
### DAYZ Linux CLI LAUNCHER by Bastimeyer https://github.com/bastimeyer/dayz-linux-cli-launcher #####################################
#####################################################################################################################################
### Edited by ice ###################################################################################################################
#####################################################################################################################################

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

API_URL="https://dayzsalauncher.com/api/v1/query/@ADDRESS@/@PORT@"
API_PARAMS=(
  -sSL
  -m 10
  -H "User-Agent: dayz-linux-cli-launcher"
)
WORKSHOP_URL="https://steamcommunity.com/sharedfiles/filedetails/SubscribeItem/?id=@ID@"


DEBUG=0
LAUNCH=0
STEAM=""
SERVER=""
PORT="${DEFAULT_QUERYPORT}"
NAME=""
INPUT=()
MODS=()
MODS2=()
PARAMS=()

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
    msg "Resolving steam"
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
  [[ -z "${SERVER}" ]] && return

  local query
  local response
  msg "Querying API for server: ${SERVER%:*}:${PORT}"
  query="$(sed -e "s/@ADDRESS@/${SERVER%:*}/" -e "s/@PORT@/${PORT}/" <<< "${API_URL}")"
  debug "Querying ${query}"
  response="$(curl "${API_PARAMS[@]}" "${query}")"
  debug "Parsing API response"
  jq -e '.result.mods | select(type == "array")' >/dev/null 2>&1 <<< "${response}" || err "Missing mods data from API response"
  jq -e '.result.mods[]' >/dev/null 2>&1 <<< "${response}" || { echo ""; echo ""; echo -e "\e[1;36mThis is a Vanilla Server.\e[0m"; echo ""; echo ""; read -p $'\e[36mPress ENTER to launch Vanilla DayZ.' foo; echo ""; echo ""; echo "Starting DayZ.. Please Wait.."; echo ""; echo ""; steam -applaunch 221100 -connect=${ip} --port ${port} -name=${nname} -nolauncher -world=empty; exit; }

  INPUT+=( $(jq -r ".result.mods[] | .steamWorkshopId" <<< "${response}") )

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

echo ""
echo -e "\e[1;40mTo update your mods you need to re-download them.\e[0m\n\e[1;40mThis is recommended if you can't join the server.\e[0m"
echo ""
missing=0   
   for modid in "${INPUT[@]}"; do  
    
    local modpath2="${dir_workshop}/${modid}" 
    local namelink="${modid}"
#    ln -sr -f "${modpath2}" "${dir_workshop}/${namelink}"
    MODS2+=("${namelink}")
    local mods2="$(IFS=";" echo "${MODS2[*]}")"
done
echo ""
read -s -n1 -p $'\e[1;40m\e[20mMenu:\n
\e[1;40mPress " P " to Play DayZ\n
\e[36mPress " M " to Re-Download Mods for this Server\n
\e[33mPress " R " to Remove Mods for this Server\n
\e[31mPress " W " to Remove All Mods
\e[0m' pmrw
case ${pmrw} in 
	p ) echo ""
	    echo ""
	    echo ""
	    echo -e "\e[1;40m\e[1;48mChecking Server Mods ..\e[0m" 
            sleep 0.25
            rm -rf /home/$USER/.steam/debian-installation/steamapps/workshop/content/downloads/*
            rm -r -f /home/$USER/.steam/debian-installation/steamapps/common/DayZ/@*
            sleep 0.1;;

	m ) echo ""
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
            sleep 0.1;;

	r ) echo ""
            echo -e "\e[1;31mDeleting Mods:\n\e[1;33m${mods2}\n\e[1;31mFrom Workshop Directory: ${dir_workshop}"
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
            
	w ) echo ""
            echo -e "\e[1;31mDeleting All Mods From Steam Workshop Directory:\n \e[1;33m${dir_workshop}"
            echo "" 
            sleep 0.1
	    rm -rf /home/$USER/.steam/debian-installation/steamapps/workshop/content/221100/*
	    sleep 0.1
            rm -rf /home/$USER/.steam/debian-installation/steamapps/workshop/downloads/*
            sleep 0.1
	    rm -r -f /home/$USER/.steam/debian-installation/steamapps/common/DayZ/@*
            exit;;

	* ) echo "" 
	    echo -e "|\e[1;33m\n Invalid response. Reply 'P' or 'M' with small characters.\e[0m";
            sleep 0.1
            exit;;
esac

#echo ""

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
     
    local modpath="${dir_workshop}/${modid}" 
    local modmeta="${modpath}/meta.cpp"
    local modlink="@$(dec2base64 "${modid}")"  
#    echo ""
    ln -sr -f "${modpath}" "${dir_dayz}/${modlink}"
    MODS+=("${modlink}")
    local mods="$(IFS=";"; echo "${MODS[*]}")" 
   echo -e "\e[1;40m\e[1;31mMOD MISSING: ${modid}:\e[1;35m $(sed -e"s/@ID@/${modid}/" <<< "${WORKSHOP_URL}")\e[0m"
   echo -e "\e[1;40m\e[1;33mDOWNLOADING MOD: ${modid}...\e[0m"
   echo -e "\e[1;40m| Mod Id: ${modid} | \e[1;40mMod Link: ${modlink} |\e[0m"
   echo ""   
   run_steam steam://url/CommunityFilePage/${modid}+workshop_download_item 221100 ${modid} && wait
   run_steam steam://open/library
   sleep 0.5

  continue
fi  
     done
 
if (( missing == 1 )); then
    echo ""
read -p $'\e[1;40m\e[36mWait for Steam to download the mods and then press ENTER.\e[0m' foo
    echo ""
    echo ""
fi
    missing=0   

for modid in "${INPUT[@]}"; do  
    local modlink="@$(dec2base64 "${modid}")" 
    local modpath="${dir_workshop}/${modid}" 
    local modmeta="${modpath}/meta.cpp"  
    local modname="$(gawk 'match($0,/name\s*=\s*"(.+)"/,m){print m[1];exit}' "${modmeta}")"
    echo -e "\e[1;40m\n
\e[1;32m| Mod Name: ${modname} | Mod Id: ${modid} | Mod Link: ${modlink} |
\e[0m"
    ln -sr -f "${modpath}" "${dir_dayz}/${modlink}"
    MODS+=("${modlink}")
    sleep 0.1
      continue     
done

    echo ""
echo -e "\e[1;40m
\e[1;20mName: $nname
\e[1;40m\e[1;20mGame IP:Port $ip
\e[1;40m\e[1;20mQuery Port: $port\e[0m"
    echo ""
    read -p $'\e[1;40m\e[36mPress ENTER to launch DayZ with mods.\e[0m'
    echo ""
    steam -applaunch 221100 -mod=${mods} -connect=${ip} --port ${port} -name=${nname} -nolauncher -world=empty
    echo ""
    echo ""
    echo -e "\e[1;40mLaunch command for this server:\n\nsteam -applaunch 221100 \"-mod=$mods\" -connect=${ip} --port ${port} -name=${nname} -nolauncher -world=empty\e[0m"
    echo ""
    echo ""
    echo -e "\e[1;40m\e[1;36mStarting DayZ.. Please Wait..\e[0m"
    echo ""
    sleep 2
    echo ""

    read -s -n1 -p $'\e[1;40m
\e[1;40mPress " S " to Save Launch Script for this Server \n
\e[31mPress " Q " to Quit Launcher\e[0m' sq
    echo ""
    case $sq in 
	s ) sleep 0.1;;
	q ) echo -e "\e[1;40m\e[1;33mExiting..\e[0m";
		exit;;
	* ) echo -e "\e[1;40m\e[1;31mInvalid response..\e[0m";
		exit 1;;
    esac
    echo ""
    echo ""    
    echo -e "\e[1;40m\e[1;20mType in a filename:\e[0m"
    sleep 0.5
    read fname
    cat >$fname.sh << ENDMASTER

run_steam -applaunch 221100 "-mod=$mods" -connect=${ip} --port ${port} -name=${nname} -nolauncher -world=empty

ENDMASTER
echo -e "\e[1;40m\e[1;36mLaunch script created: \e[0m\e[1;40m\e\e[1;32m$HOME/$fname.sh\e[0m"
echo ""
exit
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
  query_server_api
  mods_setup "${dir_dayz}" "${dir_workshop}" || exit 1
  local mods="$(IFS=";"; echo "${MODS[*]}")"
  local mods2="$(IFS=";"; echo "${MODS2[*]}")"

}

main
