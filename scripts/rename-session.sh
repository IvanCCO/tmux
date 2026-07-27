#!/usr/bin/env bash
# Prompts for a new name (in the popup's own terminal) and renames the session.
session="$1"
read -rp "New name for '$session': " newname </dev/tty
if [[ -n "$newname" ]]; then
  tmux rename-session -t "$session" "$newname"
fi
