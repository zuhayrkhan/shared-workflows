#!/usr/bin/env bash

# Get directory of current script
# This allows the script to be run from anywhere, not just the directory it is located in
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Source the script containing the create_project_list function
# This allows us to use the function in this script
source "$SCRIPT_DIR/create_project_list.sh"

# Call the create_project_list function and pass all command line arguments to it
create_project_list "$@"