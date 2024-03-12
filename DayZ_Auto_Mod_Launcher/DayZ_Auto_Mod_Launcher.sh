#!/usr/bin/env bash
#####################################################################################################################################
### Tested with Debian 11 and 12. ###################################################################################################
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
  [gawk]="required for parsing the mod metadata"
  [curl]="required for querying the server API"
  [jq]="required for parsing the server API's JSON response"
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
  echo >&2 "[${SELF}][error] ${@}"
#   echo ""
  exit 1
}

msg() {
  echo "[${SELF}][info] ${@}"
#   echo ""
}

debug() {
  if [[ ${DEBUG} == 1 ]]; then
    echo "[${SELF}][debug] ${@}"
#   echo ""
  fi
}

check_dir() {
  debug "Checking directory: ${1}"
  [[ -d "${1}" ]] || err "Invalid/missing directory: ${1}"
}

check_dep() {
  command -v "${1}" >/dev/null 2>&1
}

check_deps() {
  for dep in "${!DEPS[@]}"; do
    check_dep "${dep}" || err "'${dep}' is missing (${DEPS["${dep}"]}). Aborting."
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
  sleep 0.5

if test -f /home/$USER/.steam/debian-installation/steamapps/workshop/appworkshop_221100.acf; then
  echo "File exists."
rm /home/$USER/.steam/debian-installation/steamapps/workshop/appworkshop_221100.acf

fi
if test -f /home/$USER/.steam/debian-installation/steamapps/workshop/appworkshop_241100.acf; then
  echo "File exists."
rm /home/$USER/.steam/debian-installation/steamapps/workshop/appworkshop_241100.acf  
fi

} 


mods_setup() {

  local dir_dayz="${1}"
  local dir_workshop="${2}"
  
for modid in "${INPUT[@]}"; do 

  local modpath="${dir_workshop}/${modid}" 

if ! [[ -d "${modpath}" ]]; then

   missing=1
   echo -e "\e[1;31mMOD MISSING: ${modid}:\e[1;35m $(sed -e"s/@ID@/${modid}/" <<< "${WORKSHOP_URL}") \e[0m"
   echo -e "\e[1;33mDOWNLOADING MOD: ${modid}\e[0m"
   run_steam steam://url/CommunityFilePage/${modname}+workshop_download_item 221100 ${modid} && wait
   steam steam://open/library
   local modlink="@$(dec2base64 "${modid}")" 
   sleep 0.5

  continue
fi
    done
if (( missing == 1 )); then    

    echo ""
    read -p $'\e[36mWait for Steam to download the mods and then press ENTER.' foo
    echo ""
sleep 0.5
fi

    missing=0   

for modid in "${INPUT[@]}"; do  

    local modpath="${dir_workshop}/${modid}" 
    local modmeta="${modpath}/meta.cpp"
    local modname="$(gawk 'match($0,/name\s*=\s*"(.+)"/,m){print m[1];exit}' "${modmeta}")"     
    sleep 0.2
    echo ""
    echo -e "\e[1;32mMod ${modname} status OK\e[0m"
    local modlink="@$(dec2base64 "${modid}")"     
    ln -sr -f "${modpath}" "${dir_dayz}/${modlink}"
    MODS+=("${modlink}")
    local mods="$(IFS=";"; echo "${MODS[*]}")"   
      continue      
done

    echo ""
    echo -e "\e[1;34mName: $nname"
    echo -e "\e[1;34mGame IP:Port $ip"
    echo -e "\e[1;34mQuery Port: $port"
    echo -e "\e[1;34mMods: $mods"
    echo ""
    echo ""
    read -p $'\e[36mPress ENTER to launch DayZ with mods.' #foo
    echo ""
    echo -e "\e[1;32m""\e[0m"
    run_steam -applaunch 221100 -mod=${mods} -connect=${ip} --port ${port} -name=${nname} -nolauncher -world=empty
    echo ""
    echo ""
    echo -e "\e[1;40mLaunch command for this server:\n\nsteam -applaunch 221100 \"-mod=$mods\" -connect=${ip} --port ${port} -name=${nname} -nolauncher -world=empty\e[0m"
    echo ""
    echo ""
    echo -e "\e[1;33mStarting DayZ.. Please Wait..\e[0m"
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

}

main
