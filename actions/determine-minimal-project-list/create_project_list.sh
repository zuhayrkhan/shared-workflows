#!/usr/local/bin/bash

# get directory of current script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# source the utility functions script
source "$SCRIPT_DIR/utility.sh"

source "$SCRIPT_DIR/generate_dependency_map_file.sh"

declare -gA maven_to_folder_map
declare -gA folder_to_maven_map
declare -gA affected_modules_map
declare -gA project_list

process_module_and_dir(){

  local mavenGAV_and_dir="$1"

  IFS="(" read -r mavenGAV dir <<< "$mavenGAV_and_dir"
  folder=${dir%)*}

  mavenGAV_escaped=$(escape "$mavenGAV" )
  folder_escaped=$(escape "$folder" )
  maven_to_folder_map["$mavenGAV_escaped"]="$folder_escaped "
  folder_to_maven_map["$folder_escaped"]="$mavenGAV_escaped "

  echo $mavenGAV_escaped $folder_escaped

}

handle_dependency_map() {
    while IFS= read -r line; do
        IFS="|" read -r dependent dependency <<< $line

        read -r mavenGAV_escaped folder_escaped <<< "$(process_module_and_dir "$dependent")"
        dependent_module_escaped=$mavenGAV_escaped

        maven_to_folder_map["$mavenGAV_escaped"]="$folder_escaped "
        folder_to_maven_map["$folder_escaped"]="$mavenGAV_escaped "

        read -r mavenGAV_escaped folder_escaped <<< "$(process_module_and_dir "$dependency")"
        dependency_module_escaped=mavenGAV_escaped

        maven_to_folder_map["$mavenGAV_escaped"]="$folder_escaped "
        folder_to_maven_map["$folder_escaped"]="$mavenGAV_escaped "

        dependency_map["$dependency_module_escaped"]+="$dependent_module_escaped "

    done < <(generate_dependency_map)
}

source "$SCRIPT_DIR/determine_changed_files.sh"

process_affected_module(){
    local affected_module
    affected_module="$1"
    local affected_module_escaped
    affected_module_escaped=$(escape "$affected_module" )
    local affected_module_GAV_escaped=${folder_to_maven_map[$affected_module_escaped]}
    affected_module_GAV_escaped="${affected_module_GAV_escaped% }"
    if [[ -v dependency_map[$affected_module_GAV_escaped] && ${dependency_map[$affected_module_GAV_escaped]} ]]; then
        for dependent in ${dependency_map[$affected_module_GAV_escaped]}; do
            dependent_escaped=$(escape "$dependent")
            affected_modules_map["$dependent_escaped"]=$dependent_escaped
        done
    else
        if [[ -n "$affected_module_GAV_escaped" ]]; then
            affected_modules_map["$affected_module_GAV_escaped"]=$affected_module_GAV_escaped
        fi
    fi
}

handle_changed_files(){
    while IFS= read -r affected_module; do
      process_affected_module "$affected_module"
    done < <(determine_changed_files "$@")
}

list_affected_projects(){
    for affected_module in "${affected_modules_map[@]}"; do
        local affected_folder=${maven_to_folder_map[$affected_module]}
        local affected_folder_unescaped
        affected_folder_unescaped=$(unescape "$affected_folder")
        project_list["$affected_folder_unescaped"]=$affected_folder_unescaped
    done
    echo "project_list=$(echo "${project_list[@]}" | sed 's|/./||g' | tr ' ' ',' )" | tee -a $GITHUB_OUTPUT
}

handle_dependency_map

handle_changed_files "$@"

list_affected_projects
