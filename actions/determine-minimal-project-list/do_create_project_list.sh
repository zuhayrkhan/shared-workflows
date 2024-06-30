#!/usr/bin/env bash

#declare -A assoc_array
#assoc_array["known"]+="value_for_known "
#
#if [[ -v assoc_array["unknown"] ]]; then
#     echo "Key 'unknown' is set."
#else
#     echo "Key 'unknown' is not set."
#fi
#
#echo "Value for the key 'known': '${assoc_array["known"]}'"
#echo "Value for the key 'unknown': '${assoc_array["unknown"]}'"
#
#exit 0;

# get directory of current script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# source the utility functions script
source "$SCRIPT_DIR/create_project_list.sh"

create_project_list "$@"