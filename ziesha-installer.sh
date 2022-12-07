#!/bin/bash
#
# This is an easy installer script for Ziesha Helper to a computer/server.
#

header=$(cat <<EOF
  _______ ___ ___ _  _   _   
 |_  /_ _| __/ __| || | /_\  
  / / | || _|\__ \ __ |/ _ \ 
 /___|___|___|___/_||_/_/ \_\

                   \xF0\x9F\x94\xA5 HELPER-\xCE\xB2

EOF
)

ZIESHA_PATH=$HOME
PROFILE=$HOME/.profile
URL="https://raw.githubusercontent.com/isezen/ziesha-helper/main/%s"
EXE="${0##*/}"
LOG_FILE="$HOME/ziesha-installer.log"

# shellcheck source=~/.profile
source "$PROFILE"

source <(curl -s $(printf "$URL" "ziesha_common.sh"))

install_pre_deps "screen jq curl wget git ccze"
clear

txt=$(red "$header\n" | sed 's/^/                             /')
echo -e "$txt"
grn "⬣ Web"; echo -n "      : "; blu "https://ziesha.network\n"
grn "⬣ Discord"; echo -n "  : "; blu "https://discord.gg/zieshanetwork\n"
grn "⬣ Github"; echo -n "   : "; blu "https://twitter.com/ZieshaNetwork\n"
grn "⬣ Telegram"; echo -n " : "; blu "https://t.me/ZieshaNetworkTurkish\n"
line2; echo -e ""
msg_note "$(ylw "NOTES: ")"; echo -e ""
cyn " - You need to install Bazuka node to get a wallet.\n"
cyn " - You can install Uzi-miner as much as computers you want.\n"
cyn " - You can install Bazuka and Uzi-miner to different computers.\n"
cyn " - Solo miners, select (3).\n"
cyn " - Pool operators, select (4).\n"
line2; echo -e "\n"

opts=("Install Bazuka Node"
      "Install Uzi-miner"
      "Solo-miner (Bazuka + Zoro)"
      "Pool operator (Bazuka + Zoro + Uzi-pool)"
      "Just install Ziesha Helper"
      "Exit")
PS3=$'\n'$'\033[0;33m'"⬣ What would you like to do?: "
COLUMNS=1
select opt in "${opts[@]}";
do
  case $opt in
    "Install Bazuka Node")
      break
      ;;
    "Install Uzi-miner")
      break
      ;;
    "Solo-miner (Bazuka + Zoro)")
      break
      ;;
    "Pool operator (Bazuka + Zoro + Uzi-pool)")
      break
      ;;
    "Just install Ziesha Helper")
      break
      ;;
    "Exit")
        red "-ByE\U02763\U1F60B\n"
      break
      ;;
    *)
        echo "Invalid $REPLY"
      ;;
  esac
done
