#!/bin/bash

# Output file for dependencies
output_file="${RUNNER_TEMP}/maven-map.txt"

# Clear previous map
> $output_file

# List all modules (assuming each subfolder with a pom.xml is a module)
for module in $(find . -name "pom.xml" -exec dirname {} \; | sed 's|^\./||'); do

  pomPath=$module/pom.xml

  groupId=$(mvn -f "$pomPath" help:evaluate -Dexpression=project.groupId -q -DforceStdout)
  artifactId=$(mvn -f "$pomPath" help:evaluate -Dexpression=project.artifactId -q -DforceStdout)
  version=$(mvn -f "$pomPath" help:evaluate -Dexpression=project.version -q -DforceStdout)

  # Output them in a single line
  echo "$module/|$groupId:$artifactId:$version" | tee -a "$output_file"

done
