#!/bin/zsh

ZAP_CONFIG_FILE="$HOME/.zap/.config"

# Load config variables
source "$ZAP_CONFIG_FILE"

# $1 development file in $PROJECT_HOME
# $2 length of list (from $MAX_PROJECTS)
# $3 sort order
#
# Find searches for only directories and doesnt recurse (This would be very bad if it did)
# Pipes into stat with -exec
# -f formats into Strings, with the date attached
# sort -n is for numerical sorting, -nr is numerical in reverse
function look_up_recent_files() {
    if [[ "$3" == "Oldest" ]]; then
        find "$1" -mindepth 1 -maxdepth 1 -type d \
            -exec stat -f "%Sm %N" -t "%Y-%m-%d" {} + |
            sort -n | head -n "$2"

    elif [[ "$3" == "Recent" ]]; then
        find "$1" -mindepth 1 -maxdepth 1 -type d \
            -exec stat -f "%Sm %N" -t "%Y-%m-%d" {} + |
            sort -nr | head -n "$2"

    else
        echo "SORT_BY in \"$ZAP_CONFIG_FILE\" is malformed or incorrect."
        echo "Valid values are either \"Recent\" or \"Oldest\"."
        exit 1
    fi
}

look_up_recent_files "$PROJECT_HOME" "$MAX_PROJECTS" "$SORT_BY"