#!/bin/sh

# Per-session activity summary for tmux's status bar.
# It only inspects process trees belonging to tmux panes, so background jobs
# outside tmux do not create noise here.

second=$(date +%S)
case $(expr "$second" \* 3 % 10) in
  0) pulse='⠋' ;;
  1) pulse='⠙' ;;
  2) pulse='⠹' ;;
  3) pulse='⠸' ;;
  4) pulse='⠼' ;;
  5) pulse='⠴' ;;
  6) pulse='⠦' ;;
  7) pulse='⠧' ;;
  8) pulse='⠇' ;;
  9) pulse='⠏' ;;
esac

is_ai_running() {
  case "$1" in
    ⠋*|⠙*|⠹*|⠸*|⠼*|⠴*|⠦*|⠧*|⠇*|⠏*|✳*|✻*|✽*) return 0 ;;
    *) return 1 ;;
  esac
}

classify_process() {
  process=$1
  case "$process" in
    *codex*)
      codex=1
      [ "$ai_running" -eq 1 ] && codex_running=1
      ;;
    *claude*)
      claude=1
      [ "$ai_running" -eq 1 ] && claude_running=1
      ;;
    *gemini*)
      gemini=1
      [ "$ai_running" -eq 1 ] && gemini_running=1
      ;;
    *kimi*)
      kimi=1
      [ "$ai_running" -eq 1 ] && kimi_running=1
      ;;
    *node*|*npm\ run\ *|*pnpm\ *|*yarn\ *) node=1 ;;
  esac
}

collect_session_activity() {
  codex=0
  codex_running=0
  claude=0
  claude_running=0
  gemini=0
  gemini_running=0
  kimi=0
  kimi_running=0
  node=0

  # Codex and Claude put an animated marker in their pane title while working.
  # Keep servers visible, but only show an AI spinner when that marker is present.
  for pane_id in $(tmux list-panes -t "$1" -F '#{pane_id}' 2>/dev/null); do
    ai_running=0
    pane_title=$(tmux display-message -p -t "$pane_id" '#{pane_title}' 2>/dev/null)
    is_ai_running "$pane_title" && ai_running=1
    pane_pid=$(tmux display-message -p -t "$pane_id" '#{pane_pid}' 2>/dev/null)
    descendants=$pane_pid
    frontier=$pane_pid
    while [ -n "$frontier" ]; do
      next=''
      for parent_id in $frontier; do
        for child_id in $(pgrep -P "$parent_id" 2>/dev/null); do
          descendants="$descendants $child_id"
          next="$next $child_id"
        done
      done
      frontier=$next
    done
    for process_id in $descendants; do
      classify_process "$(ps -p "$process_id" -o command= 2>/dev/null)"
    done
  done
}

print_activity() {
  if [ "$codex" -eq 1 ] || [ "$claude" -eq 1 ] || [ "$gemini" -eq 1 ] || [ "$kimi" -eq 1 ] || [ "$node" -eq 1 ]; then
    printed=0
    if [ "$codex" -eq 1 ]; then
      [ "$codex_running" -eq 1 ] && loading="$pulse " || loading=''
      printf '#[fg=#ffffff,bg=#10a37f,bold] %scodex #[nobold]' "$loading"
      printed=1
    fi
    if [ "$claude" -eq 1 ]; then
      [ "$printed" -eq 1 ] && printf '#[fg=#ffffff,bg=#45475a] '
      [ "$claude_running" -eq 1 ] && loading="$pulse " || loading=''
      printf '#[fg=#ffffff,bg=#d97757,bold] %sclaude #[nobold]' "$loading"
      printed=1
    fi
    if [ "$gemini" -eq 1 ]; then
      [ "$printed" -eq 1 ] && printf '#[fg=#ffffff,bg=#45475a] '
      [ "$gemini_running" -eq 1 ] && loading="$pulse " || loading=''
      printf '#[fg=#ffffff,bg=#4285f4,bold] %sgemini #[nobold]' "$loading"
      printed=1
    fi
    if [ "$kimi" -eq 1 ]; then
      [ "$printed" -eq 1 ] && printf '#[fg=#ffffff,bg=#45475a] '
      [ "$kimi_running" -eq 1 ] && loading="$pulse " || loading=''
      printf '#[fg=#ffffff,bg=#7c3aed,bold] %skimi #[nobold]' "$loading"
      printed=1
    fi
    if [ "$node" -eq 1 ]; then
      [ "$printed" -eq 1 ] && printf '#[fg=#ffffff,bg=#45475a] '
      printf '#[fg=#ffffff,bg=#68a063,bold] node #[nobold]'
    fi
  else
    printf '#[fg=#ffffff,bg=#6c7086] -- idle '
  fi
}

first_session=1
tmux list-sessions -F '#{session_id}:#{session_name}' 2>/dev/null |
while IFS=':' read -r session_id session_name; do
  [ "$first_session" -eq 0 ] && printf ' '
  first_session=0

  printf '#[fg=#ffffff,bg=#45475a] %s ' "$session_name"
  collect_session_activity "$session_id"
  print_activity
  printf '#[default]'
done

printf '#[default]'
