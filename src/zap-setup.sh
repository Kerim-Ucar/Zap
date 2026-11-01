#!/bin/zsh

# Made by Kerim Ucar, 11/1/2026

# Creates a .config file so the user can specify pre-hand config values instead of long flags
# ./zap will read these config files
# Makes it so its kinda like a wordplay like "zap"
# Flags will be added to zap but they will mostly be on or off flags, like -s to open spotify
# along with the ide

ZAP_FOLDER="$HOME/.zap"
ZAP_CONFIG="$HOME/.zap/.config"

if [ $# -ne 1 ]; then
    echo "Usage ./zap-setup <Project_file_Name>"
    exit 1
fi

# Check if arg is a directory
if [  ! -d "$1" ]; then
  echo "zap-setup: $1: No such directory"
  exit 1
fi

mkdir -p "$ZAP_FOLDER"
touch "$ZAP_CONFIG"

if [ ! -f "$ZAP_CONFIG" ]; then
    echo "zap-setup: $ZAP_CONFIG could not be made"
    exit 1
fi

printf 'PROJECT_HOME=%s\n' "$1" > "$ZAP_CONFIG"
printf 'MAX_PROJECTS=10\n' >> "$ZAP_CONFIG"
printf 'SORT_BY="Recent"\n' >> "$ZAP_CONFIG"

echo "config file successfully created in $ZAP_CONFIG"
