#!/usr/bin/env bats

batslib_err() {
  { if (( $# > 0 )); then
      echo "$@"
    else
      cat -
    fi
  } >&2
}

fail() {
  (( $# == 0 )) && batslib_err || batslib_err "$@"
  return 1
}

setup() {
  export RUNNER_TEMP=.
  cd $BATS_TEST_DIRNAME/example_monorepo || return
}

@test "affected_modules will include entries for all pom.xml files" {
  source "$BATS_TEST_DIRNAME/../determine_changed_files.sh"
  run determine_changed_files shared/shared-a/dummy.java shared/shared-c/dummy.java
  [ "$status" -eq 0 ]
  expected=$(cat << EOF
./shared/shared-a
./shared/shared-c
EOF
)
  [[ "$output" = "$expected" ]] || fail "$(printf "The output doesn't match the expected value\noutput:\n%s\nexpect:\n%s\n" "$output" "$expected")"
}

@test "dependency-map and maven-map will include entries for all pom.xml files" {
  source "$BATS_TEST_DIRNAME/../generate_dependency_map.sh"
  run generate_dependency_map
  [ "$status" -eq 0 ]
  expected=$(cat << EOF
com.zuhayrkhan.example.disconnected_service:disconnected-service-a:1.0.0-SNAPSHOT(./disconnected/disconnected-service-a)|com.zuhayrkhan.example.disconnected_shared:disconnected-shared-a:1.0.0-SNAPSHOT(./disconnected/disconnected-shared-a)
com.zuhayrkhan.example.services:service-a:1.0.0-SNAPSHOT(./services/service-a)|com.zuhayrkhan.example.shared:shared-a:1.0.0-SNAPSHOT(./shared/shared-a)
com.zuhayrkhan.example.services:service-a:1.0.0-SNAPSHOT(./services/service-a)|com.zuhayrkhan.example.shared:shared-c:1.0.0-SNAPSHOT(./shared/shared-c)
com.zuhayrkhan.example.services:service-b:1.0.0-SNAPSHOT(./services/service-b)|com.zuhayrkhan.example.shared:shared-b:1.0.0-SNAPSHOT(./shared/shared-b)
com.zuhayrkhan.example.services:service-b:1.0.0-SNAPSHOT(./services/service-b)|com.zuhayrkhan.example.shared:shared-c:1.0.0-SNAPSHOT(./shared/shared-c)
com.zuhayrkhan.example.shared:shared-c:1.0.0-SNAPSHOT(./shared/shared-c)|com.zuhayrkhan.example.shared:shared-d:1.0.0-SNAPSHOT(./shared/shared-d)
EOF
)
  [[ "$output" = "$expected" ]] || fail "$(printf "The output doesn't match the expected value\noutput:\n%s\nexpect:\n%s\n" "$output" "$expected")"
}

@test "create_project_list.process_module_and_dir will split MavenGAV and folder" {
  source "$BATS_TEST_DIRNAME/../create_project_list.sh"
  run process_module_and_dir "com.zuhayrkhan.example.services:service-a:1.0.0-SNAPSHOT(./services/service-a)"
  [ "$status" -eq 0 ]
  expected=$(cat << EOF
com.zuhayrkhan.example.services:service-a:1.0.0-SNAPSHOT ./services/service-a
EOF
)
  [[ "$output" = "$expected" ]] || fail "$(printf "The output doesn't match the expected value\noutput:\n%s\nexpect:\n%s\n" "$output" "$expected")"
}


@test "create_project_list will return maven project-list to build all modules affected by changed files in shared-a" {
  source "$BATS_TEST_DIRNAME/../create_project_list.sh"
  run create_project_list shared/shared-a/dummy.java
  [ "$status" -eq 0 ]
  expected=$(cat << EOF
project_list=./services/service-a,./shared/shared-a
EOF
)
  [[ "$output" = "$expected" ]] || fail "$(printf "The output doesn't match the expected value\noutput:\n%s\nexpect:\n%s\n" "$output" "$expected")"
}

@test "create_project_list will return maven project-list to build all modules affected by changed files in shared-c" {
  source "$BATS_TEST_DIRNAME/../create_project_list.sh"
  run create_project_list shared/shared-c/dummy.java
  [ "$status" -eq 0 ]
  expected=$(cat << EOF
project_list=./services/service-b,./services/service-a,./shared/shared-c
EOF
)
  [[ "$output" = "$expected" ]] || fail "$(printf "The output doesn't match the expected value\noutput:\n%s\nexpect:\n%s\n" "$output" "$expected")"
}

@test "create_project_list will return maven project-list to build all modules affected by changed files in shared-a and shared-c" {
  source "$BATS_TEST_DIRNAME/../create_project_list.sh"
  run create_project_list shared/shared-a/dummy.java shared/shared-c/dummy.java
  [ "$status" -eq 0 ]
  expected=$(cat << EOF
project_list=./services/service-b,./services/service-a,./shared/shared-c,./shared/shared-a
EOF
)
  [[ "$output" = "$expected" ]] || fail "$(printf "The output doesn't match the expected value\noutput:\n%s\nexpect:\n%s\n" "$output" "$expected")"
}

@test "create_project_list will return maven project-list to build all modules affected by changed files in shared-d (transitive dependency)" {
  source "$BATS_TEST_DIRNAME/../create_project_list.sh"
  run create_project_list shared/shared-d/dummy.java
  [ "$status" -eq 0 ]
  expected=$(cat << EOF
project_list=./services/service-b,./services/service-a,./shared/shared-d,./shared/shared-c
EOF
)
  [[ "$output" = "$expected" ]] || fail "$(printf "The output doesn't match the expected value\noutput:\n%s\nexpect:\n%s\n" "$output" "$expected")"
}

