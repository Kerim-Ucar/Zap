#!/bin/zsh

# Made by Kerim Ucar, 11/5/2026
# All functions ending with _e can exit

ZAP_CONFIG_FILE="$HOME/.zap/.config"

# Load config variables or else exit 1, they should add this to java
source "$ZAP_CONFIG_FILE" || {
  echo "zap: $ZAP_CONFIG_FILE does not exist. Run zap-setup.sh with project Directory."
  exit 1
}

# -h help flag, this is pretty cool, didn't know you could do multi lines like this
HELP=$(cat << 'EOF'
Usage: zap [-v] [-s] [-d YYYY-MM-DD]
           [-n Count] [-h] [-r]

Zsh script for mac that will show most recent projects and will auto open selected project in IDE

Supported IDE:
    -Visual Studio
    -Intellij
    -CLion
    -PyCharm
    -Webstorm
    -Rider

All Flags:
    -v Show the version of zap
    -s Open spotify along with the IDE
    -d <Year-Month-Day> Show all projects before Date, ex: ./zap -d 1970-01-01 will show all projects before said date
    -r reverse order of projects (Lower date comes first). Combine with -d to instead show all projects after said date
    -n <Count> Override config file and show N projects instead
    -h Show help
EOF
)

VERSION="V1.0.1"

# Please load source before trying to access these variables :heart_emoji:

# Flags for Flags?
OPEN_SPOTIFY=0
REVERSE=0
OVERRIDE_DATE=0
DATE=""
# Assign count early because if the user doesnt include -n flag, then i dont have to do extra work
COUNT="$MAX_PROJECTS"

# Variables:
# PROJECT_HOME
# MAX_PROJECTS
# SORT_BY

# Flags
# -v version Current = V1.0.1 probably
# -s Open spotify along with IDE
# -d Y-M-D show all projects before Date
# -r reverse count (-dr will cause flip)
# -n count override default project count in .config
# -h help

# This chunk of letters just is every flag, if a flag has : in front of it, it takes a argument
while getopts "e h v r d: n: s" opt; do
    case "$opt" in
    h)
      echo "$HELP"
      exit 0
      ;;
    v)
      echo "$VERSION"
      exit 0
      ;;
    r)
      REVERSE=1
      ;;
    d)
      DATE="$OPTARG"
      OVERRIDE_DATE=1
      ;;
    n)
      COUNT="$OPTARG"
      ;;
    s)
      OPEN_SPOTIFY=1
      ;;
    e)
      echo "4"
      exit 0
      ;;
    *)
      echo "Invalid or Malformed flag, run ./zap.sh -h for help."
      exit 1
      ;;
    esac

  done

# validates the config incase the user does configuration and messes up.
# This method just exits 1 if anything is wrong so i don't have to handle try catches if they even exist in this language :D
function validate_variables_e() {
  if [ ! -d "$PROJECT_HOME" ]; then
    echo "zap: $PROJECT_HOME does not exist. Please Check $ZAP_CONFIG_FILE for file."
    exit 1
  elif  ((MAX_PROJECTS <= 0)); then
    echo "zap: $MAX_PROJECTS is less than or equal to 0. Please fix MAX_PROJECTS."
    exit 1
  elif ((COUNT <= 0)); then
    echo "$COUNT "
    echo "-n cannot be 0 or less."
    exit 1
  elif [ "$SORT_BY" != "Recent"  ] && [ "$SORT_BY" != "Oldest" ]; then
    echo "zap: $SORT_BY: is Not valid. Valid are \"Recent\" or \"Oldest\". Please fix SORT_BY."
    exit 1
  fi
}

# $1 development file in $PROJECT_HOME
# $2 length of list (from $MAX_PROJECTS)
# $3 sort order
# Find searches for only directories and doesnt recurse (This would be very bad if it did)
# Pipe into stat with -exec
# Pipe into sed to strip the $Project_Home env
# -f formats into Strings, with the date attached
# sort -n is for numerical sorting, -nr is numerical in reverse
# DOES NOT RETURN A LIST. ONE STRING WHICH IS THEN PARSED OUTSIDE <-------------- !!!!
function look_up_recent_files() {
  if [[ "$3" == "Oldest" ]]; then
    find "$1" -mindepth 1 -maxdepth 1 -type d \
      -exec stat -f "%Sm %N" -t "%Y-%m-%d" {} + |
      sort -n | head -n "$2" | sed "s|${PROJECT_HOME}/||"

  elif [[ "$3" == "Recent" ]]; then
    find "$1" -mindepth 1 -maxdepth 1 -type d \
      -exec stat -f "%Sm %N" -t "%Y-%m-%d" {} + |
      sort -nr | head -n "$2" | sed "s|${PROJECT_HOME}/||"
  fi
}

# Takes a full path to a directory !!!
# Takes $1, a folder to look for
# Takes $2, a workspace IDE folder to look for.
# returns a IDE folder
# dont check if folder is empty in here
function look_for_ide_e() {
  WORKSPACE_FOLDER=$(find "$1" -type d -name "$2")

  if [ ! -d "$WORKSPACE_FOLDER" ]; then
      echo "zap: $WORKSPACE_FOLDER: IDE workspace is not directory?"
      exit 1
  fi

  echo "$WORKSPACE_FOLDER"
}

# Takes $1, a .idea folder
# Takes $2, the original folder
# returns the ide of the project
# does not return the launcher name
function get_IDE_for_intellij() {
  # Check misc.xml
  MISC_XML=$(find "$1" -type f -name "misc.xml")

  # java, c/c++, python
  if [[ $(grep "project-jdk-name" "$MISC_XML") == *"JavaSDK"* ]]; then
    echo "INTELLIJ"
    return;
  elif [[ $(grep "project-jdk-name" "$MISC_XML") == *"Python SDK"* ]]; then
    echo "PYCHARM"
    return;
  elif [[ $(cat "$MISC_XML") == *"CMakeWorkspace"* ]]; then
    echo "CLION"
    return;
  fi

  # Check for .IML outside and inside for webstorm, C#, Rust
  FOLD=$(basename "$2")
  IML_FOLDER=$(find "$1" -type f -name "$FOLD.iml")
  if [ ! -z "$IML_FOLDER" ]; then
    IML_FOLDER=$(find "$2" -type f -name "$FOLD.iml")
  fi

  if [[ $(cat "$IML_FOLDER") == *"WEB_MODULE"* ]]; then
    echo "WEBSTORM"
    return
  elif [[ $(cat "$IML_FOLDER") == *"RIDER_MODULE"* ]]; then
    echo "RIDER"
    return
  fi

}

# Takes $1, a folder
# Takes $2, the original folder
# wraps check_ide_folders_e
# checks presets like .idea, .vscode
# returns the name of the launcher on macos
# Isn't in quotes so be careful
# does not have any conditions that can exit, but look_for_ide_e can exit so this can also exit too
function check_preset_ide_folders_e() {
  if [[ $(basename "$1") == .vscode ]]; then
      echo "Visual Studio Code"
      return
  fi

  IDE_TYPE=$(get_IDE_for_intellij "$1" "$2")
  printf 'IDE_TYPE=<%s>\n' "$IDE_TYPE" >&2

  if [[ "$IDE_TYPE" == "INTELLIJ" ]]; then
    echo "IntelliJ IDEA"
    return
  elif [[ "$IDE_TYPE" == "CLION" ]]; then
    echo "CLion"
    return
  elif [[ "$IDE_TYPE" == "PYCHARM" ]]; then
    echo "PyCharm"
    return
  elif [[ "$IDE_TYPE" == "WEBSTORM" ]]; then
    echo "WebStorm"
    return
  elif [[ "$IDE_TYPE" == "RIDER" ]]; then
    echo "Rider"
    return
  fi

  echo "zap: $1: Unsupported IDE or Failed IDE Extraction"
}

# Takes $1, a folder
# Takes $2, the original folder
function openIDE_e() {
  # TODO: find out how to open project
  exit 0
}

# takes no params
# Chunked away into a function to use global var
# returns selected file
function user_select() {
  FILE=""

  select OPTION in "${VALUES_LIST[@]}"; do
    [[ -n "$OPTION" ]] || {
      echo "Invalid selection."
      continue;
    }
    # The slashes in $PROJECT_HOME caused the other slashes to turn into escape chars, and the whole thing
    # crumbled down. This is just regex on the option to remove it down to the file
    # Then it adds it to the end of $PROJECT_HOME
    NAME="${OPTION#* }"
    FILE="$PROJECT_HOME/$NAME"
    break;
  done

  echo "$FILE"
}

# Validate source (Uses "$MAX_PROJECTS" instead of "$COUNT" so -n flag won't hide the fact that their .config values are wrong)
validate_variables_e

VALUES=""

# Handle flags
# Structure: (DATE PROJECT_PATH)
# bash doesnt have true or false but you can just evaluate with 1 or 0 (( ))
if ((REVERSE)); then
  # if -rd do show by tail instead in reverse, then do awk on greater than
  if ((OVERRIDE_DATE)); then
    VALUES=$(look_up_recent_files "$PROJECT_HOME" "$COUNT" "$SORT_BY" | tail -r | awk -v cutoff="$DATE" '$1 > cutoff')
  else
    VALUES=$(look_up_recent_files "$PROJECT_HOME" "$COUNT" "$SORT_BY" | tail -r)
  fi
# if only -d then show less than date with only awk
elif ((OVERRIDE_DATE)); then
  VALUES=$(look_up_recent_files "$PROJECT_HOME" "$COUNT" "$SORT_BY" | awk -v cutoff="$DATE" '$1 < cutoff')
else
  VALUES=$(look_up_recent_files "$PROJECT_HOME" "$COUNT" "$SORT_BY")
fi

echo "Searching in: $PROJECT_HOME"
# splits String into a list
# this works
VALUES_LIST=("${(@f)VALUES}")

FILE=$(user_select)
IDE_FOLDER=$(look_for_ide_e "$FILE" ".idea")
openIDE_e "$IDE_FOLDER" "$FILE"
exit 0