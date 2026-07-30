#!/bin/sh

session_number=$1

case "$session_number" in
  [1-9]) ;;
  *) exit 1 ;;
esac

session_id=$(tmux list-sessions -F '#{session_id}' | awk -v number="$session_number" 'NR == number { print; exit }')
[ -n "$session_id" ] && tmux switch-client -t "$session_id"
