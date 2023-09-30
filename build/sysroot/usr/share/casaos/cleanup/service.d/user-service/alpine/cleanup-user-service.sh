#!/bin/sh

set -e

readonly CASA_EXEC=casaos-user-service
readonly CASA_SERVICE=casaos-user-service

CASA_CONF=/etc/casaos/user-service.conf


CASA_DB_PATH=$( (grep -i dbpath "${CASA_CONF}" || echo "/var/lib/casaos/db") | cut -d'=' -sf2 | xargs )
readonly CASA_DB_PATH

CASA_DB_FILE=${CASA_DB_PATH}/user-service.db

readonly COLOUR_GREEN='\e[38;5;154m' # green  		| Lines, bullets and separators
readonly COLOUR_WHITE='\e[1m'        # Bold white	| Main descriptions
readonly COLOUR_GREY='\e[90m'        # Grey  		| Credits
readonly COLOUR_RED='\e[91m'         # Red   		| Update notifications Alert
readonly COLOUR_YELLOW='\e[33m'      # Yellow		| Emphasis

Show() {
    case $1 in
        0 ) echo -e "${COLOUR_GREY}[$COLOUR_RESET${COLOUR_GREEN}  OK  $COLOUR_RESET${COLOUR_GREY}]$COLOUR_RESET $2";;  # OK
        1 ) echo -e "${COLOUR_GREY}[$COLOUR_RESET${COLOUR_RED}FAILED$COLOUR_RESET${COLOUR_GREY}]$COLOUR_RESET $2";;    # FAILED
        2 ) echo -e "${COLOUR_GREY}[$COLOUR_RESET${COLOUR_GREEN} INFO $COLOUR_RESET${COLOUR_GREY}]$COLOUR_RESET $2";;  # INFO
        3 ) echo -e "${COLOUR_GREY}[$COLOUR_RESET${COLOUR_YELLOW}NOTICE$COLOUR_RESET${COLOUR_GREY}]$COLOUR_RESET $2";; # NOTICE
    esac
}

Warn() {
    echo -e "${COLOUR_RED}$1$COLOUR_RESET"
}

trap 'onCtrlC' INT
onCtrlC() {
    echo -e "${COLOUR_RESET}"
    exit 1
}

if [ ! -x "$(command -v ${CASA_EXEC})" ]; then
    Show 2 "${CASA_EXEC} is not detected, exit the script."
    exit 1
fi

while true; do
    echo -n -e "         ${COLOUR_YELLOW}Do you want delete user database? Y/n :${COLOUR_RESET}"
    read -r input
    case $input in
    [yY][eE][sS] | [yY])
        REMOVE_USER_DATABASE=true
        break
        ;;
    [nN][oO] | [nN])
        REMOVE_USER_DATABASE=false
        break
        ;;
    *)
        echo -e "         ${COLOUR_RED}Invalid input, please try again.${COLOUR_RESET}"
        ;;
    esac
done

while true; do
    echo -n -e "         ${COLOUR_YELLOW}Do you want delete user directory? Y/n :${COLOUR_RESET}"
    read -r input
    case $input in
    [yY][eE][sS] | [yY])
        REMOVE_USER_DIRECTORY=true
        break
        ;;
    [nN][oO] | [nN])
        REMOVE_USER_DIRECTORY=false
        break
        ;;
    *)
        echo -e "         ${COLOUR_RED}Invalid input, please try again.${COLOUR_RESET}"
        ;;
    esac
done

Show 2 "Stopping ${CASA_SERVICE}..."
{
    rc-update del "${CASA_SERVICE}"
    rc-service --ifexists "${CASA_SERVICE}" stop
} || Show 3 "Failed to disable ${CASA_SERVICE}"

rm -rvf "$(which ${CASA_EXEC})" || Show 3 "Failed to remove ${CASA_EXEC}"
rm -rvf "${CASA_CONF}" || Show 3 "Failed to remove ${CASA_CONF}"

if [ "${REMOVE_USER_DATABASE}" = "true" ]; then
    rm -rvf "${CASA_DB_FILE}" || Show 3 "Failed to remove ${CASA_DB_FILE}"
fi

if [ "${REMOVE_USER_DIRECTORY}" = "true" ]; then
    Show 2 "Removing user directories..."
    rm -rvf /var/lib/casaos/[1-9]*
fi
