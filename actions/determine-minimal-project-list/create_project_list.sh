#!/usr/local/bin/bash

escape() {
    local unescaped=$1
    escaped=$(echo "$unescaped" | sed -e 's!\/!_SEP_!g' -e 's!\.!_DOT_!g' -e 's!:!_COLON_!g')
    echo "$escaped"
}

unescape() {
    local escaped=$1
    unescaped=$(echo "$escaped" | sed -e 's!_SEP_!/!g' -e 's!_DOT_!.!g' -e 's!_COLON_!:!g')
    echo "$unescaped"
}

# Load the maven map
declare -A maven_to_folder_map
declare -A folder_to_maven_map
while IFS= read -r line; do
    IFS="|" read -r folder mavenGAV <<< $line
    mavenGAV_escaped=$(escape "$mavenGAV" )
    folder_escaped=$(escape "$folder" )
    maven_to_folder_map["$mavenGAV_escaped"]+="$folder_escaped "  # Append dependents
    folder_to_maven_map["$folder_escaped"]+="$mavenGAV_escaped "  # Append dependents
done < ${RUNNER_TEMP}/maven-map.txt

# Load the dependency map
declare -A dependency_map
while IFS= read -r line; do
    IFS="|" read -r dependent_module dependency_module <<< $line
    dependent_module_escaped=$(escape "$dependent_module")
    dependency_module_escaped=$(escape "$dependency_module")
    dependency_map["$dependency_module_escaped"]+="$dependent_module_escaped "
done < ${RUNNER_TEMP}/dependency-map.txt

# Load the affected modules list
declare -A affected_modules_map
while IFS= read -r affected_module; do
  affected_module_escaped=$(escape "$affected_module" )
  affected_module_GAV_escaped=${folder_to_maven_map[$affected_module_escaped]}
  affected_module_GAV_escaped="${affected_module_GAV_escaped% }"
    if [[ -v dependency_map[$affected_module_GAV_escaped] && ${dependency_map[$affected_module_GAV_escaped]} ]]; then
      for dependent in ${dependency_map[$affected_module_GAV_escaped]}; do
        dependent_escaped=$(escape "$dependent")
        affected_modules_map["$dependent_escaped"]=$dependent_escaped
      done
    else
      affected_modules_map["$affected_module_GAV_escaped"]=$affected_module_GAV_escaped
    fi
done < ${RUNNER_TEMP}/affected_modules.txt

declare -A project_list

for affected_module in ${affected_modules_map[@]}; do
  affected_folder=${maven_to_folder_map[$affected_module]}
  affected_folder_unescaped=$(unescape "$affected_folder")
  project_list["$affected_folder_unescaped"]=$affected_folder_unescaped
done

echo "project_list=$(echo ${project_list[@]} | sed 's|/./||g' | tr ' ' ',' )"
echo "project_list=$(echo ${project_list[@]} | sed 's|/./||g' | tr ' ' ',' )" >> $GITHUB_OUTPUT