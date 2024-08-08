#!/usr/bin/env bash

# determine_changed_files(): Determines which files have changed
# Takes a list of changed files as the input
determine_changed_files() {
    # Set Internal Field Separator (IFS) to new line character
    IFS=$'\n'

    # Find paths for all "pom.xml" files
    # The paths are then sorted by length in descending order
    # This allows us to match the more specific paths before the less specific ones
    module_paths=($(find . -name "pom.xml" | sed 's|/[^/]*$||' | sed 's| $||' | awk '{ printf "%d %s/\n", length, $0 }' | sort -nr | cut -d" " -f2-))

    # Reset IFS back to its default
    IFS=' '

    # Parse the input arguments as changed files
    changed_files=("$@")

    # Iterate over changed files
    for file in $(echo "${changed_files[@]}" | tr ' ' '\n' | sort | tr '\n' ' ' ); do
        # Prefix the file with "./" to make it compatible with the module_paths
        prefixed_file=./$file

        # Check each changed file against every module path
        # If the file path starts with the module path, it is part of the module
        for module_path in "${module_paths[@]}"; do
            # Ignore the root directory
            if [[ "$module_path" != "./" ]]; then
                # Create a regex for matching
                match_regex="^${module_path//\//\\/}"
                # If the prefixed_file starts with module_path
                if [[ "$prefixed_file" =~ $match_regex ]]; then
                    # Strip the trailing / from the module_path
                    echo "${module_path%/}"
                    break # Exit the loop after the first match to avoid matching less specific paths
                fi
            fi
        done
    done
}