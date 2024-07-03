#!/usr/bin/env bash

# Global associative array to keep track of processed directories
declare -A SEEN_FOLDERS

# process_module(): Processes a given module to generate a mapping between Maven coordinates and directories
process_module() {
    declare -A maven_to_folder_map
    module=$1
    SEEN_FOLDERS[$module]=1
    cd "$module" || exit

    while IFS= read -r line; do
        if [[ $line =~ from[[:space:]](.+)/pom.xml ]]; then
            # Extract a referenced Pom file
            referenced_pom="$module/${BASH_REMATCH[1]}"

        elif [[ $line =~ digraph[[:space:]]+\"([^:]+):([^:]+):pom:([^:]+)\" ]]; then
            # Mark intermediate Poms as seen without processing further
            SEEN_FOLDERS[$referenced_pom]=1

        elif [[ $line =~ digraph[[:space:]]+\"([^:]+):([^:]+):jar:([^:]+)\" ]]; then
            # Extract Maven coordinates for a module
            current_module_groupId=$(trim_for_GAV "${BASH_REMATCH[1]}")
            current_module_artifactId=$(trim_for_GAV "${BASH_REMATCH[2]}")
            current_module_version=$(trim_for_GAV "${BASH_REMATCH[3]}")
            current_module_GAV="$current_module_groupId:$current_module_artifactId:$current_module_version"

            # Map Maven coordinates to directories
            if [[ "$referenced_pom" =~ .*$current_module_artifactId$ ]]; then
                maven_to_folder_map[$current_module_GAV]="$referenced_pom"  # Append maven to folder mapping
                SEEN_FOLDERS[$referenced_pom]=1
            fi

        elif [[ $line =~ \"([^\"]+)\"[^\"]*\"([^\"]+)\" ]]; then
            # Extract Maven coordinates for a dependency
            dependent_module=$(trim_for_GAV "${BASH_REMATCH[1]}")
            dependency_module=$(trim_for_GAV "${BASH_REMATCH[2]}")

            if [[ ! -z "${current_module_GAV}" ]]; then
                if [[ "$module" =~ .*$current_module_artifactId$ ]]; then
                    maven_to_folder_map[$current_module_GAV]="$referenced_pom"  # Append maven to folder mapping
                    SEEN_FOLDERS[$referenced_pom]=1
                fi
            fi

            # If the dependency is a snapshot version, output it and its dependent
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

# generate_dependency_map(): Main function to generate the dependency map for the whole Maven project
generate_dependency_map() {
    # get directory of current script
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

    # source the utility functions script
    source "$SCRIPT_DIR/utility.sh"

    # Process the root module if a Pom exists
    if [[ -e "pom.xml" ]]; then
        process_module .
    fi

    # Process every module, each subfolder with a Pom is seen as a module)
    for module in $(find . -name "pom.xml" -exec dirname {} \; | sort -r); do
        # Only process the module if it hasn't been processed before
        if [[ ! ${SEEN_FOLDERS["$module"]} ]]; then
            process_module $module
        fi
        cd - > /dev/null || exit
    done
}