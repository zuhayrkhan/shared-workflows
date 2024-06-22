#!/usr/bin/env bats

setup() {
  export RUNNER_TEMP=.
  cd example_monorepo || return
}

@test "affected_modules will include entries for all pom.xml files" {
  . "$BATS_TEST_DIRNAME/../determine_changed_files.sh"
  run bash -c 'determine_changed_files shared/shared-a/dummy.java'
  [ "$status" -eq 0 ]
  expected=$(cat << EOF
./shared/shared-a/
EOF
)
  [ "$output" = "$expected" ]
}

@test "dependency-map and maven-map will include entries for all pom.xml files" {
  run bash "$BATS_TEST_DIRNAME/../generate_dependency_map_file.sh"
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
  [ "$output" = "$expected" ]
}
