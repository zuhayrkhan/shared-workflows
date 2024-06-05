#!/usr/local/bin/bash

escape() {
    local unescaped=$1
    escaped=$(echo "$unescaped" | sed -e 's!\/!_SEP_!g' -e 's!\.!_DOT_!g' -e 's!:!_COLON_!g' -e 's!-!_MINUS_!g')
    echo "$escaped"
}

unescape() {
    local escaped=$1
    unescaped=$(echo "$escaped" | sed -e 's!_SEP_!/!g' -e 's!_DOT_!.!g' -e 's!_COLON_!:!g' -e 's!_MINUS_!-!g')
    echo "$unescaped"
}

trim() {
  local all_detail=$1
  trimmed=$(echo "$all_detail" | sed -e 's/:compile$//g' -e 's/:test$//g' -e 's/:jar//g')
  echo "$trimmed"
}
