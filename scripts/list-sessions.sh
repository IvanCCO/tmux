#!/usr/bin/env bash
# Lists tmux sessions, one per line, marking the current one with "(current)".
current=$(tmux display-message -p '#S')
tmux list-sessions -F '#S' | while IFS= read -r s; do
  if [[ "$s" == "$current" ]]; then
    printf '%s  (current)\n' "$s"
  else
    printf '%s\n' "$s"
  fi
done
