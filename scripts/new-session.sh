#!/usr/bin/env bash
# Takes the name from $FZF_QUERY (typed into fzf's own search box), creates
# the session and switches into it. Called via fzf's `become`, so it
# replaces the fzf process entirely — once it returns, the popup closes.
name="$FZF_QUERY"

if [[ -z "$name" ]]; then
  exit 0
fi

if tmux has-session -t "$name" 2>/dev/null; then
  printf "Session '%s' already exists.\n" "$name" >/dev/tty
  read -rsn1 -p "Press any key to close..." </dev/tty
  echo >/dev/tty
  exit 0
fi

tmux new-session -d -s "$name"
tmux switch-client -t "$name"
