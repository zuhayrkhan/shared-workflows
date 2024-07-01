#!/usr/bin/env bash

declare -A seen_folders

process_module() {

  declare -A maven_to_folder_map

  module=$1

  seen_folders[$module]=1

  echo "processing module=$module"

  cd "$module" || exit

  # Use grep to find SNAPSHOT dependencies
  while IFS= read -r line; do

    echo "line=$line"

    if [[ $line =~ from[[:space:]](.+)/pom.xml ]]; then

      referenced_pom="$module/${BASH_REMATCH[1]}"

    elif [[ $line =~ digraph[[:space:]]+\"([^:]+):([^:]+):pom:([^:]+)\" ]]; then

        seen_folders[$referenced_pom]=1

    elif [[ $line =~ digraph[[:space:]]+\"([^:]+):([^:]+):jar:([^:]+)\" ]]; then

      current_module_groupId=$(trim_for_GAV "${BASH_REMATCH[1]}")
      current_module_artifactId=$(trim_for_GAV "${BASH_REMATCH[2]}")
      current_module_version=$(trim_for_GAV "${BASH_REMATCH[3]}")
      current_module_GAV="$current_module_groupId:$current_module_artifactId:$current_module_version"

      if [[ "$referenced_pom" =~ .*$current_module_artifactId$ ]]; then
        maven_to_folder_map[$current_module_GAV]="$referenced_pom"  # Append maven to folder mapping
        seen_folders[$referenced_pom]=1
      fi

    elif [[ $line =~ \"([^\"]+)\"[^\"]*\"([^\"]+)\" ]]; then

      dependent_module=$(trim_for_GAV "${BASH_REMATCH[1]}")
      dependency_module=$(trim_for_GAV "${BASH_REMATCH[2]}")

      if [[ ! -z "${current_module_GAV}" ]]; then
        if [[ "$module" =~ .*$current_module_artifactId$ ]]; then
          maven_to_folder_map[$current_module_GAV]="$referenced_pom"  # Append maven to folder mapping
          seen_folders[$referenced_pom]=1
        fi
      fi

      if [[ "$dependency_module" == *-SNAPSHOT ]]; then
        dependent_module_folder=${maven_to_folder_map[$dependent_module]}
        dependency_module_folder=${maven_to_folder_map[$dependency_module]}

        if [[ ! -z  "${dependent_module_folder}" && ! -z "${dependency_module_folder}" ]]; then
          echo "$dependent_module($dependent_module_folder/)|$dependency_module($dependency_module_folder/)"
        fi
      fi
    fi
  done < <(mvn dependency:tree -DoutputType=dot -o)

}

generate_dependency_map() {

  # get directory of current script
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

  # source the utility functions script
  source "$SCRIPT_DIR/utility.sh"

  if [[ -e "pom.xml" ]]; then
    process_module .
  fi

  # List all modules (assuming each subfolder with a pom.xml is a module)
  for module in $(find . -name "pom.xml" -exec dirname {} \; | sort -r); do

    if [[ ! ${seen_folders["$module"]} ]]; then
      process_module $module
    fi

    cd - > /dev/null || exit

  done

}

#generate_dependency_map;