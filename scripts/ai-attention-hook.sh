#!/bin/sh

action=$1
pane_id=${TMUX_PANE:-}
state_dir=${TMPDIR:-/tmp}
state_file="$state_dir/tmux-ai-attention-${UID:-$(id -u)}-${pane_id#%}"

[ -n "$pane_id" ] || exit 0

case "$action" in
  set) date +%s > "$state_file" ;;
  clear) rm -f "$state_file" ;;
esac
