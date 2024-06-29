#!/usr/local/bin/bash

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

    dependency_mavenGAV_escaped=$(escape "$mavenGAV" )
    dependency_folder_escaped=$(escape "$folder" )
    maven_to_folder_map["$dependency_mavenGAV_escaped"]="$dependency_folder_escaped "
    folder_to_maven_map["$dependency_folder_escaped"]="$dependency_mavenGAV_escaped "

    echo "$dependency_mavenGAV_escaped" "$dependency_folder_escaped"

}

generate_and_handle_dependency_map() {

    while IFS= read -r line; do

        IFS="|" read -r dependent dependency <<< "$line"

        read -r dependent_mavenGAV_escaped dependent_folder_escaped <<< "$(process_module_and_dir "$dependent")"

        maven_to_folder_map["$dependent_mavenGAV_escaped"]="$dependent_folder_escaped "
        folder_to_maven_map["$dependent_folder_escaped"]="$dependent_mavenGAV_escaped "

        read -r dependency_mavenGAV_escaped dependency_folder_escaped <<< "$(process_module_and_dir "$dependency")"

        maven_to_folder_map["$dependency_mavenGAV_escaped"]="$dependency_folder_escaped "
        folder_to_maven_map["$dependency_folder_escaped"]="$dependency_mavenGAV_escaped "

        echo "dependency_mavenGAV=$(unescape $dependency_mavenGAV_escaped)"
        echo "dependent_mavenGAV=$(unescape $dependent_mavenGAV_escaped)"
        echo "dependent_mavenGAV_escaped=$dependency_mavenGAV_escaped"

        key="nothing"
        if [[ -v dependency_map["$key"] ]]; then
          echo "(1a)dependency_map[nothing]=${dependency_map["$key"]}"
        fi

        if [[ -v dependency_map["$key"] && ${dependency_map["$key"]} ]]; then
          echo "(2a)dependency_map[nothing]=${dependency_map["$key"]}"
        fi

        dependency_map["$dependency_mavenGAV_escaped"]+="$dependent_mavenGAV_escaped "

        echo "dependency_map[$(unescape $dependent_mavenGAV_escaped)]=${dependency_map[$dependent_mavenGAV_escaped]}"

        if [[ -v dependency_map["$dependent_mavenGAV_escaped"] ]]; then
          echo "(0b)dependency_map[$dependent_mavenGAV_escaped]=${dependency_map["$dependent_mavenGAV_escaped"]}"
        fi

        key="nothing"
        if [[ -v dependency_map["$key"] ]]; then
          echo "(1b)dependency_map[nothing]=${dependency_map["$key"]}"
        fi

        if [[ -v dependency_map["$key"] && ${dependency_map["$key"]} ]]; then
          echo "(2b)dependency_map[nothing]=${dependency_map["$key"]}"
        fi

        for key in "${!dependency_map[@]}"; do
            echo "Key: $key"
            echo "Value: ${dependency_map["$key"]}"
        done

        declare -p dependency_map

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

    echo "affected_module_GAV=$(unescape $affected_module_GAV_escaped)"

    if [[ -v dependency_map["$affected_module_GAV_escaped"] && ${dependency_map[$affected_module_GAV_escaped]} ]]; then

        echo "found entries in dependency_map - ${dependency_map[$affected_module_GAV_escaped]}"

        for dependent in ${dependency_map[$affected_module_GAV_escaped]}; do
            dependent_escaped=$(escape "$dependent")
            affected_modules_map["$dependent_escaped"]=$dependent_escaped
        done
    else

        echo "didn't find entries in dependency_map, adding $(unescape $affected_module_GAV_escaped)"

        if [[ -n "$affected_module_GAV_escaped" ]]; then
            affected_modules_map["$affected_module_GAV_escaped"]=$affected_module_GAV_escaped
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
        local affected_folder_unescaped
        affected_folder_unescaped=$(trim "$(unescape "$affected_folder")")
        project_list["$affected_folder_unescaped"]=$affected_folder_unescaped
    done

    echo "project_list=$(echo "${project_list[@]}" | sed 's|/./||g' | tr ' ' ',' )" | tee -a $GITHUB_OUTPUT

}

create_project_list(){

    generate_and_handle_dependency_map
    determine_and_handle_changed_files "$@"
    list_affected_projects

}
