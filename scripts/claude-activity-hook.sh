#!/bin/sh

action=$1
pane_id=${TMUX_PANE:-}
state_dir=${TMPDIR:-/tmp}
state_file="$state_dir/tmux-claude-activity-${UID:-$(id -u)}-${pane_id#%}"

[ -n "$pane_id" ] || exit 0

case "$action" in
  start) date +%s > "$state_file" ;;
  stop) rm -f "$state_file" ;;
esac
