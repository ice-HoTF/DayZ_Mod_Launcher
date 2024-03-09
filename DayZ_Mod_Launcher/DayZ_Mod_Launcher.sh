#!/usr/bin/env bash
#####################################################################################################################################
#####################################################################################################################################
### Tested with Debian 11 and 12. ###################################################################################################
#####################################################################################################################################
### Tested with the official steam package: https://wiki.debian.org/Steam ###########################################################
#####################################################################################################################################
### DAYZ Linux CLI LAUNCHER by Bastimeyer https://github.com/bastimeyer/dayz-linux-cli-launcher #####################################
#####################################################################################################################################
### Edited by ice ###################################################################################################################
#####################################################################################################################################
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
  jq -e '.result.mods[]' >/dev/null 2>&1 <<< "${response}" || { msg "This server is unmodded"; return; }

  INPUT+=( $(jq -r ".result.mods[] | .steamWorkshopId" <<< "${response}") )

}

mods_setup() {

  local dir_dayz="${1}"
  local dir_workshop="${2}"
  local missing=0

  for modid in "${INPUT[@]}"; do
    local modpath="${dir_workshop}/${modid}" 

  if ! [[ -d "${modpath}" ]]; then
      missing=1
     echo -e "\e[1;31mMOD MISSING: ${modid}:\e[1;35m $(sed -e"s/@ID@/${modid}/" <<< "${WORKSHOP_URL}") \e[0m"
     echo -e "\e[1;33mDOWNLOADING MOD: ${modid}\e[0m"
     steam steam://url/CommunityFilePage/${modname}+workshop_download_item 221100 ${modid} && wait
     steam steam://open/library
     sleep 0.5
     local modpath="${dir_workshop}/${modid}"
     
      continue 
    fi
  done
}

setup_mods() {
  echo ""
  read -p $'\e[33mWait for Steam to download mods and then click enter.\e[0m' foo
#  read -p "Wait for Steam to download mods and then click enter." 
  local dir_dayz="${1}"
  local dir_workshop="${2}"
  local missing=0

  for modid in "${INPUT[@]}"; do

    local modpath="${dir_workshop}/${modid}" 
    if ! [[ -d "${modpath}" ]]; then
      missing=1
     echo -e "\e[1;31mMOD MISSING: ${modid}:\e[1;35m $(sed -e"s/@ID@/${modid}/" <<< "${WORKSHOP_URL}") \e[0m"
     echo -e "\e[1;33mDOWNLOADING MOD: ${modid}\e[0m"
     local modpath="${dir_workshop}/${modid}"
      continue 
    fi

    local modmeta="${modpath}/meta.cpp"
    [[ -f "${modmeta}" ]] || err "Missing mod metadata for: ${modid}"

    local modname="$(gawk 'match($0,/name\s*=\s*"(.+)"/,m){print m[1];exit}' "${modmeta}")"
    [[ -n "${modname}" ]] || err "Missing mod name for: ${modid}"
    [[ -n "${modname}" ]] || err "Missing mod name for: ${WORKSHOP_URL}"
     
    sleep 0.2
    echo -e "\e[1;34mMod ${modname} status OK\e[0m"
    local modlink="@$(dec2base64 "${modid}")"
      
    if ! [[ -L "${dir_dayz}/${modlink}" ]]; then
      msg "Creating mod symlink for: ${modname} (${modlink})"
      ln -sr "${modpath}" "${dir_dayz}/${modlink}"
    fi    
 MODS+=("${modlink}")
#    sleep 0.2
  done

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

  if [[ "${STEAM}" == flatpak ]]; then
    msg "Using flatpak mode"
  else
    msg "Using non-flatpak mode: ${STEAM}"
  fi

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
  setup_mods "${dir_dayz}" "${dir_workshop}" || exit 1

  local mods="$(IFS=";"; echo "${MODS[*]}")"

  if [[ "${LAUNCH}" == 1 ]]; then
    local cmdline=()
    [[ -n "${mods}" ]] && cmdline+=("-mod=${mods}")
#    [[ -n "${SERVER}" ]] && cmdline+=("-connect=${SERVER}" -nolauncher -world=empty)
    [[ -n "${NAME}" ]] && cmdline+=("-name=${NAME}")




##########################################################
############### THE GOOD STUFF ###########################
##########################################################
sleep 0.5
echo "Name: $nname"
echo "Game IP:Port $ip"
echo "Query Port: $port"
echo "Mods: $mods"
echo ""
read -p $'\e[33mPress any key to launch DayZ with mods.\e[0m' foo
#read -p "Press any key to launch DayZ with mods."  
################################### FIRE ################################################
steam -applaunch 221100 "-mod=${mods}" -connect=${ip} --port ${port} -name=${nname}
#########################################################################################

  elif [[ -n "${mods}" ]]; then

    echo "Mods: $mods"
    
    case $yn in 
	y ) echo proceeding;;
	n ) echo exiting...;
		exit;;
	* ) echo invalid response;
		exit 1;;
esac

################################### FIRE ################################################
steam -applaunch 221100 "-mod=${mods}" -connect=${ip} --port ${port} -name=${nname} 
#########################################################################################
    
  else
    msg "Nothing to do..."
    msg "No mod-ID list, --server address, or --launch parameter set."
    msg "See --help for all the available options."
  fi
}

main
