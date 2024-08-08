#!/usr/bin/env bash

strip_relative_path() {
  # This will strip any relative path from the given string
  absolute=$(echo -e "$1" | sed -e 's/^\.\///')
  echo "$absolute"
}

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
