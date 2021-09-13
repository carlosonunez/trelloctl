#!/usr/bin/env bash

log_error() {
  msg="$1"
  >&2 echo "$(tput bold)$(tput setaf 1)ERROR$(tput sgr0): $msg"
}

action="$1"
file_for_action="$PWD/$1.rb"
if ! test -f "$file_for_action"
then
  log_error "Couldn't find file: $file_for_action. Did you write it yet?"
  exit 1
fi
ruby "$file_for_action"
