#!/usr/bin/env bash

trim() {
    # This will remove leading and trailing spaces
    trimmed=$(echo -e "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    echo "$trimmed"
}

trim_for_GAV() {
  local all_detail=$1
  trimmed=$(echo "$all_detail" | sed -e 's/:compile$//g' -e 's/:test$//g' -e 's/:jar//g')
  echo "$trimmed"
}
