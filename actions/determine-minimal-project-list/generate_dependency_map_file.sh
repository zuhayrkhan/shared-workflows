#!/usr/local/bin/bash

generate_dependency_map() {

  # get directory of current script
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

  # source the utility functions script
  source "$SCRIPT_DIR/utility.sh"

  declare -A maven_to_folder_map

  # Output file for dependencies
  dependency_map_output_file="${RUNNER_TEMP}/dependency-map.txt"
  maven_map_output_file="${RUNNER_TEMP}/maven-map.txt"

  # Clear previous map
  > $dependency_map_output_file
  > $maven_map_output_file

  # List all modules (assuming each subfolder with a pom.xml is a module)
  for module in $(find . -name "pom.xml" -exec dirname {} \;); do
  #  echo "Processing dir: $module"
    cd $module

    # Use grep to find SNAPSHOT dependencies
    while IFS= read -r line; do
      if [[ $line =~ digraph[[:space:]]+\"([^:]+):([^:]+):jar:([^:]+)\" ]]; then
        current_module_groupId=$(trim "${BASH_REMATCH[1]}")
        current_module_artifactId=$(trim "${BASH_REMATCH[2]}")
        current_module_version=$(trim "${BASH_REMATCH[3]}")
        current_module_GAV="$current_module_groupId:$current_module_artifactId:$current_module_version"
        if [[ "$module" =~ .*$current_module_artifactId$ ]]; then
          maven_to_folder_map[$current_module_GAV]="$module"  # Append maven to folder mapping
          echo "$module/|$current_module_GAV" >> "$maven_map_output_file"
        fi
      elif [[ $line =~ \"([^\"]+)\"[^\"]*\"([^\"]+)\" ]]; then
        dependent_module=$(trim "${BASH_REMATCH[1]}")
        dependency_module=$(trim "${BASH_REMATCH[2]}")
        if [[ ! -z "${current_module_GAV}" ]]; then
          if [[ "$module" =~ .*$current_module_artifactId$ ]]; then
            echo "$module/|$current_module_GAV" >> "$maven_map_output_file"
            maven_to_folder_map[$current_module_GAV]="$module"  # Append maven to folder mapping
          fi
        fi
        if [[ "$dependency_module" == *-SNAPSHOT ]]; then
          dependent_module_folder=${maven_to_folder_map[$dependent_module]}
          dependency_module_folder=${maven_to_folder_map[$dependency_module]}
          if [[ ! -z  "${dependent_module_folder}" && ! -z "${dependency_module_folder}" ]]; then
            echo "$dependent_module($dependent_module_folder/)|$dependency_module($dependency_module_folder/)" | tee -a "$dependency_map_output_file"
          fi
        fi
      fi
    done < <(mvn dependency:tree -DoutputType=dot -o)

    cd - > /dev/null
  done

}

generate_dependency_map;