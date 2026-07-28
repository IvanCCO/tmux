#!/bin/sh

break_after_seconds=${BREAK_AFTER_SECONDS:-3600}
state_dir=${TMPDIR:-/tmp}
reminder_prefix="$state_dir/tmux-break-reminder-${UID:-$(id -u)}"
lock_dir="$reminder_prefix.lock"

mkdir "$lock_dir" 2>/dev/null || exit 0
trap 'rmdir "$lock_dir"' EXIT HUP INT TERM

session_created() {
  tmux display-message -p -t "$1" '#{session_created}' 2>/dev/null
}

last_break() {
  state_file=$1
  session_id=$2
  value=$(cat "$state_file" 2>/dev/null)
  case "$value" in
    locked) printf '%s\n' "$value" ;;
    ''|*[!0-9]*) session_created "$session_id" ;;
    *) printf '%s\n' "$value" ;;
  esac
}

remind_session() {
  session_id=$1
  state_file="$reminder_prefix-${session_id}.state"
  last=$(last_break "$state_file" "$session_id")
  now=$(date +%s)

  [ "$last" = locked ] && return

  case "$last" in
    ''|*[!0-9]*) return ;;
  esac

  if [ $((now - last)) -ge "$break_after_seconds" ]; then
    target_client=$(tmux list-clients -F '#{client_tty}|#{session_id}' |
      awk -F'|' -v session_id="$session_id" '$2 == session_id { print $1; exit }')
    [ -n "$target_client" ] || return

    printf 'locked\n' > "$state_file"
    popup_command="zsh $HOME/.tmux/scripts/melt-break.zsh '$state_file'"
    if ! tmux display-popup -c "$target_client" -E -w 100% -h 100% "$popup_command"; then
      printf '%s\n' "$last" > "$state_file"
    fi
  fi
}

while tmux list-sessions >/dev/null 2>&1; do
  for session_id in $(tmux list-sessions -F '#{session_id}'); do
    remind_session "$session_id"
  done

  sleep 10
done
