#!/bin/bash

test=$(dpkg -l | grep -c wmctrl)

if [ $test -eq "0" ]; then
    zenity --warning --text="wmctrl not installed.\nPlease install using:\nsudo apt install wmctrl"
    exit 0
fi

game_id=244160
option=$(
    zenity --list \
        --title="Select which game to launch" \
        --width=640 \
        --height=640 \
        --list \
        --column="Option" \
        --column="Game Version" \
        "hw1" "Homeworld 1 Classic" \
        "hw2" "Homeworld 2 Classic" \
        "hwr1" "Homeworld 1 Remastered" \
        "hwr2" "Homeworld 2 Remastered"
)

case ${option} in
hw1)
    GAME_CMD="${HOME}/.local/share/Steam/steamapps/common/Homeworld/Homeworld1Classic/exe/Homeworld.exe"
    GAME_OPT="/noglddraw"
    ;;
hw2)
    GAME_CMD="${HOME}/.local/share/Steam/steamapps/common/Homeworld/Homeworld2Classic/bin/Release/Homeworld2.exe"
    GAME_OPT=""
    ;;
hwr1)
    GAME_CMD="${HOME}/.local/share/Steam/steamapps/common/Homeworld/HomeworldRM/bin/Release/HomeworldRM.exe"
    GAME_OPT="-dlccampaign HW1Campaign.big -campaign HomeworldClassic -moviepath DataHW1Campaign"
    ;;
hwr2)
    GAME_CMD="${HOME}/.local/share/Steam/steamapps/common/Homeworld/HomeworldRM/bin/Release/HomeworldRM.exe"
    GAME_OPT="-dlccampaign HW2Campaign.big -campaign Ascension -moviepath DataHW2Campaign"
    ;;
*)
    exit
    ;;
esac

PROTON_PATH="$(ls -d1 ${HOME}/.local/share/Steam/steamapps/common/Proton* | tail -1)"
[ -d "${PROTON_PATH}" ] || {
    echo "Couldn't find proton path at: ${PROTON_PATH} "
    exit 1
}
WINE_CMD="${PROTON_PATH}/files/bin/wine64"
[ -f "${WINE_CMD}" ] || {
    echo "Couldn't find wine executable at: ${WINE_CMD} "
    exit 1
}
[ -f "${GAME_CMD}" ] || {
    echo "Couldn't find game executable at: ${GAME_CMD} "
    exit 2
}

# Start Steam first if not started already...
if ! pgrep -x "steam"; then
    echo "Steam is not running. Starting it now..."
    nohup /usr/bin/steam &>/dev/null &
    disown
fi

# Wait until Steam is fully running...
while ! pgrep -x "steam" >/dev/null || ! wmctrl -l | grep -qE "Steam$"; do
    echo "Waiting for Steam to launch..."
    sleep 1
done

# Give it 2 more seconds to be sure...
sleep 2

# Run wine command with prepared paramters
WINEDEBUG="-all" \
    WINEPREFIX="${HOME}/.local/share/Steam/steamapps/compatdata/${game_id}/pfx/" \
    SteamGameId="${game_id}" \
    SteamAppId="${game_id}" \
    WINEDLLOVERRIDES="d3d11=n;dxgi=n" \
    STEAM_COMPAT_CLIENT_INSTALL_PATH="${HOME}/.local/share/Steam" \
    "${WINE_CMD}" start /unix ${GAME_CMD} ${GAME_OPT} 2>/tmp/proton.out
