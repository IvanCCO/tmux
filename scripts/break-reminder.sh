#!/bin/sh

session_name=$1
break_after_seconds=${BREAK_AFTER_SECONDS:-3600}
state_dir=${TMPDIR:-/tmp}
state_file="$state_dir/tmux-break-reminder-${UID:-$(id -u)}-${session_name}.state"
lock_dir="$state_file.lock"

mkdir "$lock_dir" 2>/dev/null || exit 0
trap 'rmdir "$lock_dir"' EXIT HUP INT TERM

session_created() {
  tmux display-message -p -t "$session_name" '#{session_created}' 2>/dev/null
}

last_break() {
  value=$(cat "$state_file" 2>/dev/null)
  case "$value" in
    ''|*[!0-9]*) session_created ;;
    *) printf '%s\n' "$value" ;;
  esac
}

while tmux has-session -t "$session_name" 2>/dev/null; do
  last=$(last_break)
  now=$(date +%s)

  case "$last" in
    ''|*[!0-9]*) sleep 10; continue ;;
  esac

  if [ $((now - last)) -ge "$break_after_seconds" ]; then
    target_client=$(tmux list-clients -F '#{client_tty}|#{client_session}' |
      awk -F'|' -v session="$session_name" '$2 == session { print $1; exit }')
    [ -n "$target_client" ] || { sleep 10; continue; }
    printf 'locked\n' > "$state_file"
    popup_command="zsh $HOME/.tmux/scripts/melt-break.zsh '$state_file'"
    if ! tmux display-popup -c "$target_client" -E -w 100% -h 100% "$popup_command"; then
      printf '%s\n' "$last" > "$state_file"
    fi
  fi

  sleep 10
done
