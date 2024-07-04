#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Source required scripts
source "$SCRIPT_DIR/utility.sh"
source "$SCRIPT_DIR/generate_dependency_map.sh"

# Global associative arrays declarations
declare -gA MAVEN_TO_FOLDER_MAP
declare -gA FOLDER_TO_MAVEN_MAP
declare -gA AFFECTED_MODULES_MAP
declare -gA PROJECT_LIST
declare -gA DEPENDENCY_MAP

# process_module_and_dir(): Extracts the module and directory from a given string
process_module_and_dir() {
    local mavenGAV_and_dir="$1"
    IFS="(" read -r mavenGAV dir <<< "$mavenGAV_and_dir"
    folder=${dir%)*}
    MAVEN_TO_FOLDER_MAP["$mavenGAV"]="$folder "
    FOLDER_TO_MAVEN_MAP["$folder"]="$mavenGAV "
    echo "$mavenGAV" "$folder"
}

# generate_and_handle_dependency_map(): Generates a map of dependencies between different modules
generate_and_handle_dependency_map() {
    while IFS= read -r line; do
      IFS="|" read -r dependent dependency <<< "$line"

      read -r dependent_mavenGAV dependent_folder <<< "$(process_module_and_dir "$dependent")"
      MAVEN_TO_FOLDER_MAP["$dependent_mavenGAV"]="$dependent_folder "
      FOLDER_TO_MAVEN_MAP["$dependent_folder"]="$dependent_mavenGAV "

      read -r dependency_mavenGAV dependency_folder <<< "$(process_module_and_dir "$dependency")"
      MAVEN_TO_FOLDER_MAP["$dependency_mavenGAV"]="$dependency_folder "
      FOLDER_TO_MAVEN_MAP["$dependency_folder"]="$dependency_mavenGAV "

      DEPENDENCY_MAP["$dependency_mavenGAV"]+="$dependent_mavenGAV "

    done < <(generate_dependency_map)
}

source "$SCRIPT_DIR/determine_changed_files.sh"

# process_affected_module(): Process a given affected module by adding it and its dependents to the AFFECTED_MODULES_MAP
process_affected_module() {
    local affected_module="$1"
    local affected_module_GAV=${FOLDER_TO_MAVEN_MAP["$affected_module"]}
    affected_module_GAV="${affected_module_GAV% }"

    if [[ -v DEPENDENCY_MAP["$affected_module_GAV"] ]]; then
        for dependent in ${DEPENDENCY_MAP[$affected_module_GAV]}; do
            AFFECTED_MODULES_MAP["$dependent"]=$dependent
        done
    elif [[ -n "$affected_module_GAV" ]]; then
        AFFECTED_MODULES_MAP["$affected_module_GAV"]=$affected_module_GAV
    fi
}

# determine_and_handle_changed_files(): Identifies the changed files and handle the affected modules
determine_and_handle_changed_files() {
    while IFS= read -r affected_module; do
      process_affected_module "$affected_module"
    done < <(determine_changed_files "$@")
}

# list_affected_projects(): Lists all the projects affected by the changes
list_affected_projects() {
    for affected_module in "${AFFECTED_MODULES_MAP[@]}"; do
        local affected_folder=${MAVEN_TO_FOLDER_MAP[$affected_module]}
        local affected_folder_trimmed=$(trim "$affected_folder")
        PROJECT_LIST["$affected_folder_trimmed"]=$affected_folder_trimmed
    done
    # Output the affected projects list
    echo "project_list=$(echo "${PROJECT_LIST[@]}" | sed 's|/./||g' | tr ' ' ',' )" | tee -a $GITHUB_OUTPUT
}

# create_project_list(): The main function that ties all the other functions together
create_project_list() {
    generate_and_handle_dependency_map
    determine_and_handle_changed_files "$@"
    list_affected_projects
}