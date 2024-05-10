#!/usr/local/bin/bash

IFS=$'\n'
module_paths=($(find . -name "pom.xml" | sed 's|/[^/]*$||' | sed 's| $||' | awk '{ printf "%d %s/\n", length, $0 }' | sort -nr | cut -d" " -f2-))
echo "module_paths in this repo: ${module_paths[@]}"

# Output file for dependencies
output_file="${RUNNER_TEMP}/affected_modules.txt"

# Clear previous map
> $output_file

git fetch origin master
changed_files=$1
echo "Changed files: $changed_files"

IFS=' '
for file in $changed_files; do
    prefixed_file=./$file
    for module_path in "${module_paths[@]}"; do
        # Check if the file path starts with the module path
        if [[ "$module_path" != "./" ]]; then
          match_regex="^${module_path//\//\\/}"
          if [[ "$prefixed_file" =~ $match_regex ]]; then
              echo "$module_path" >> "$output_file"
              break # Break after the first match to avoid checking less specific paths
          fi
        fi
    done
done
