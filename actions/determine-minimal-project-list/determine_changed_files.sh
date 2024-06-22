#!/usr/local/bin/bash

determine_changed_files() {

  IFS=$'\n'
  module_paths=($(find . -name "pom.xml" | sed 's|/[^/]*$||' | sed 's| $||' | awk '{ printf "%d %s/\n", length, $0 }' | sort -nr | cut -d" " -f2-))

  # Output file for dependencies
  output_file="${RUNNER_TEMP}/affected_modules.txt"

  # Clear previous map
  > $output_file

  changed_files=$1

  IFS=' '
  for file in $changed_files; do
      prefixed_file=./$file
      for module_path in "${module_paths[@]}"; do
          # Check if the file path starts with the module path
          if [[ "$module_path" != "./" ]]; then
            match_regex="^${module_path//\//\\/}"
            if [[ "$prefixed_file" =~ $match_regex ]]; then
                echo "$module_path" | tee -a "$output_file"
                break # Break after the first match to avoid checking less specific paths
            fi
          fi
      done
  done

}

#determine_changed_files "$@";