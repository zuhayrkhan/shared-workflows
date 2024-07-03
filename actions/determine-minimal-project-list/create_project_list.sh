#!/usr/bin/env bash

# get directory of current script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# source the utility functions script
source "$SCRIPT_DIR/utility.sh"

source "$SCRIPT_DIR/generate_dependency_map.sh"

declare -gA maven_to_folder_map
declare -gA folder_to_maven_map
declare -gA affected_modules_map
declare -gA project_list
declare -gA dependency_map

process_module_and_dir(){

    local mavenGAV_and_dir="$1"

    IFS="(" read -r mavenGAV dir <<< "$mavenGAV_and_dir"
    folder=${dir%)*}

    maven_to_folder_map["$mavenGAV"]="$folder "
    folder_to_maven_map["$folder"]="$mavenGAV "

    echo "$mavenGAV" "$folder"

}

generate_and_handle_dependency_map() {

    while IFS= read -r line; do

        IFS="|" read -r dependent dependency <<< "$line"

        read -r dependent_mavenGAV dependent_folder <<< "$(process_module_and_dir "$dependent")"

        maven_to_folder_map["$dependent_mavenGAV"]="$dependent_folder "
        folder_to_maven_map["$dependent_folder"]="$dependent_mavenGAV "

        read -r dependency_mavenGAV dependency_folder <<< "$(process_module_and_dir "$dependency")"

        maven_to_folder_map["$dependency_mavenGAV"]="$dependency_folder "
        folder_to_maven_map["$dependency_folder"]="$dependency_mavenGAV "

        dependency_map["$dependency_mavenGAV"]+="$dependent_mavenGAV "

    done < <(generate_dependency_map)

}

source "$SCRIPT_DIR/determine_changed_files.sh"

process_affected_module(){

    local affected_module
    affected_module="$1"
    local affected_module_GAV=${folder_to_maven_map[$affected_module]}
    affected_module_GAV="${affected_module_GAV% }"

    if [[ -v dependency_map["$affected_module_GAV"] && ${dependency_map[$affected_module_GAV]} ]]; then
        for dependent in ${dependency_map[$affected_module_GAV]}; do
            affected_modules_map["$dependent"]=$dependent
        done
    else
        if [[ -n "$affected_module_GAV" ]]; then
            affected_modules_map["$affected_module_GAV"]=$affected_module_GAV
        fi
    fi

}

determine_and_handle_changed_files(){

    while IFS= read -r affected_module; do
      process_affected_module "$affected_module"
    done < <(determine_changed_files "$@")

}

list_affected_projects(){

    for affected_module in "${affected_modules_map[@]}"; do
        local affected_folder=${maven_to_folder_map[$affected_module]}
        local affected_folder_trimmed
        affected_folder_trimmed=$(trim "$affected_folder")
        project_list["$affected_folder_trimmed"]=$affected_folder_trimmed
    done

    echo "project_list=$(echo "${project_list[@]}" | sed 's|/./||g' | tr ' ' ',' )" | tee -a $GITHUB_OUTPUT

}

create_project_list(){

    generate_and_handle_dependency_map
    determine_and_handle_changed_files "$@"
    list_affected_projects

}
