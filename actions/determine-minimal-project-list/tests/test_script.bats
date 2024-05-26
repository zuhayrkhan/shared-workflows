#!/usr/bin/env bats

setup() {
  export RUNNER_TEMP=.
  cd example_monorepo || return
}

@test "affected_modules will include entries for all pom.xml files" {
  run bash "$BATS_TEST_DIRNAME/../determine_changed_files.sh" shared/shared-a/dummy.java
  [ "$status" -eq 0 ]
  expected=$(cat << EOF
module_paths in this repo: ./services/service-b/ ./services/service-a/ ./shared/shared-c/ ./shared/shared-b/ ./shared/shared-a/ ./services/ ./shared/ ./
Changed files: shared/shared-a/dummy.java
./shared/shared-a/
EOF
)
  [ "$output" = "$expected" ]
}

@test "dependency-map and maven-map will include entries for all pom.xml files" {
  run bash "$BATS_TEST_DIRNAME/../generate_dependency_map_file.sh"
  [ "$status" -eq 0 ]
  expected=$(cat << EOF
module_paths in this repo: ./services/service-b/ ./services/service-a/ ./shared/shared-c/ ./shared/shared-b/ ./shared/shared-a/ ./services/ ./shared/ ./
Changed files: shared/shared-a/dummy.java
./shared/shared-a/
EOF
)
  [ "$output" = "$expected" ]
}
