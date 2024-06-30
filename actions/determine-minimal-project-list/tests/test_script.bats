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
  run determine_changed_files shared/shared-a/dummy.java
  [ "$status" -eq 0 ]
  expected=$(cat << EOF
./shared/shared-a/
EOF
)
  [[ "$output" = "$expected" ]] || fail "$(printf "The output doesn't match the expected value\noutput:\n%s\nexpect:\n%s\n" "$output" "$expected")"
}

@test "dependency-map and maven-map will include entries for all pom.xml files" {
  source "$BATS_TEST_DIRNAME/../generate_dependency_map.sh"
  run generate_dependency_map
  [ "$status" -eq 0 ]
  expected=$(cat << EOF
com.zuhayrkhan.example.services:service-a:1.0.0-SNAPSHOT(./services/service-a/)|com.zuhayrkhan.example.shared:shared-a:1.0.0-SNAPSHOT(./shared/shared-a/)
com.zuhayrkhan.example.services:service-a:1.0.0-SNAPSHOT(./services/service-a/)|com.zuhayrkhan.example.shared:shared-c:1.0.0-SNAPSHOT(./shared/shared-c/)
com.zuhayrkhan.example.services:service-a:1.0.0-SNAPSHOT(./services/service-a/)|com.zuhayrkhan.example.shared:shared-a:1.0.0-SNAPSHOT(./shared/shared-a/)
com.zuhayrkhan.example.services:service-a:1.0.0-SNAPSHOT(./services/service-a/)|com.zuhayrkhan.example.shared:shared-c:1.0.0-SNAPSHOT(./shared/shared-c/)
com.zuhayrkhan.example.services:service-b:1.0.0-SNAPSHOT(./services/service-b/)|com.zuhayrkhan.example.shared:shared-b:1.0.0-SNAPSHOT(./shared/shared-b/)
com.zuhayrkhan.example.services:service-b:1.0.0-SNAPSHOT(./services/service-b/)|com.zuhayrkhan.example.shared:shared-c:1.0.0-SNAPSHOT(./shared/shared-c/)

EOF
)
  [[ "$output" = "$expected" ]] || fail "$(printf "The output doesn't match the expected value\noutput:\n%s\nexpect:\n%s\n" "$output" "$expected")"
}

@test "create_project_list.process_module_and_dir will split and escape MavenGAV and folder" {
  source "$BATS_TEST_DIRNAME/../create_project_list.sh"
  run process_module_and_dir "com.zuhayrkhan.example.services:service-a:1.0.0-SNAPSHOT(./services/service-a/)"
  [ "$status" -eq 0 ]
  expected=$(cat << EOF
com_DOT_zuhayrkhan_DOT_example_DOT_services_COLON_service_MINUS_a_COLON_1_DOT_0_DOT_0_MINUS_SNAPSHOT _DOT__SEP_services_SEP_service_MINUS_a_SEP_
EOF
)
  [[ "$output" = "$expected" ]] || fail "$(printf "The output doesn't match the expected value\noutput:\n%s\nexpect:\n%s\n" "$output" "$expected")"
}


@test "create_project_list will return maven project-list to build all modules affected by changed files in shared-a" {
  source "$BATS_TEST_DIRNAME/../create_project_list.sh"
  run create_project_list shared/shared-a/dummy.java
  [ "$status" -eq 0 ]
  expected=$(cat << EOF
project_list=./services/service-a/
EOF
)
  [[ "$output" = "$expected" ]] || fail "$(printf "The output doesn't match the expected value\noutput:\n%s\nexpect:\n%s\n" "$output" "$expected")"
}

@test "create_project_list will return maven project-list to build all modules affected by changed files in shared-c" {
  source "$BATS_TEST_DIRNAME/../create_project_list.sh"
  run create_project_list shared/shared-c/dummy.java
  [ "$status" -eq 0 ]
  expected=$(cat << EOF
project_list=./services/service-b/,./services/service-a/
EOF
)
  [[ "$output" = "$expected" ]] || fail "$(printf "The output doesn't match the expected value\noutput:\n%s\nexpect:\n%s\n" "$output" "$expected")"
}

