#!/usr/bin/env bash

usage() {
  _gather_commands() { commands=""
    for file in *.rb
    do
      command="$(sed 's/.rb$//' <<< "$file")"
      separator="$(seq -s' ' 60 | tr -d '[:digit:]')"
      action="$(grep -E "^# $command:" "$file" | sed "s/^# $command: //")"
      if test -z "$action"
      then
        action="No description specified?"
      fi
      commands="$commands$(printf "%s %s %s\n" "$command" "${separator:${#action}}" "$action")"
    done
    echo "$commands"
  }
  cat <<-USAGE
$0 [command] [-h|--help]
Performs Trello maintenance

SUBCOMMANDS

$(_gather_commands)

GLOBAL OPTIONS

  -h, --help        Prints help text
USAGE
}

log_error() {
  msg="$1"
  >&2 echo "$(tput bold)$(tput setaf 1)ERROR$(tput sgr0): $msg"
}

if test "$1" == "-h" || test "$1" == "--help"
then
  usage
  exit 0
fi

action="$1"
file_for_action="$PWD/$1.rb"
if ! test -f "$file_for_action"
then
  log_error "Couldn't find file: $file_for_action. Did you write it yet?"
  exit 1
fi
ruby -I/app/lib "$file_for_action" "${@:2}"
