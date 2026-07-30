#!/bin/sh

# Per-session activity summary for tmux's status bar.
# It only inspects process trees belonging to tmux panes, so background jobs
# outside tmux do not create noise here.

ACTIVITY_GRACE_SECONDS=8
active_session_id=$1
show_session_numbers=$2

second=$(date +%S)
now=$(date +%s)
state_dir=${TMPDIR:-/tmp}
state_prefix="$state_dir/tmux-ai-activity-${UID:-$(id -u)}"
claude_state_prefix="$state_dir/tmux-claude-activity-${UID:-$(id -u)}"
attention_state_prefix="$state_dir/tmux-ai-attention-${UID:-$(id -u)}"
case $(expr "$second" % 10) in
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

is_ai_title() {
  case "$1" in
    ⠋*|⠙*|⠹*|⠸*|⠼*|⠴*|⠦*|⠧*|⠇*|⠏*|✳*|✻*|✽*) return 0 ;;
    *) return 1 ;;
  esac
}

is_ai_running() {
  pane_id=$1
  pane_title=$2
  state_file="$state_prefix-${pane_id#%}"

  is_ai_title "$pane_title" || return 1

  if [ -r "$state_file" ]; then
    IFS=' ' read -r changed_at previous_title < "$state_file"
  else
    printf '0 %s\n' "$pane_title" > "$state_file"
    return 1
  fi

  if [ "$pane_title" != "$previous_title" ]; then
    changed_at=$now
    printf '%s %s\n' "$changed_at" "$pane_title" > "$state_file"
  fi

  [ "$(expr "$now" - "$changed_at")" -le "$ACTIVITY_GRACE_SECONDS" ]
}

is_claude_running() {
  state_file="$claude_state_prefix-${1#%}"
  [ -r "$state_file" ]
}

needs_human_attention() {
  state_file="$attention_state_prefix-${1#%}"
  [ -r "$state_file" ]
}

classify_process() {
  process=$1
  case "$process" in
    *codex*)
      pane_codex=1
      [ "$ai_running" -eq 1 ] && pane_codex_running=1
      [ "$pane_needs_attention" -eq 1 ] && pane_codex_attention=1
      ;;
    *claude*)
      pane_claude=1
      [ "$claude_hook_running" -eq 1 ] && pane_claude_running=1
      [ "$pane_needs_attention" -eq 1 ] && pane_claude_attention=1
      ;;
    *gemini*)
      pane_gemini=1
      [ "$ai_running" -eq 1 ] && pane_gemini_running=1
      ;;
    *kimi*)
      pane_kimi=1
      [ "$ai_running" -eq 1 ] && pane_kimi_running=1
      ;;
    *node*|*npm\ run\ *|*pnpm\ *|*yarn\ *) pane_node=1 ;;
  esac
}

collect_session_activity() {
  codex_count=0
  codex_running=0
  codex_attention=0
  claude_count=0
  claude_running=0
  claude_attention=0
  gemini_count=0
  gemini_running=0
  kimi_count=0
  kimi_running=0
  node_count=0

  # Codex title updates are its activity heartbeat. Claude uses lifecycle hooks,
  # because its working title does not reliably change between frames.
  for pane_id in $(tmux list-panes -t "$1" -F '#{pane_id}' 2>/dev/null); do
    pane_codex=0
    pane_codex_running=0
    pane_codex_attention=0
    pane_claude=0
    pane_claude_running=0
    pane_claude_attention=0
    pane_gemini=0
    pane_gemini_running=0
    pane_kimi=0
    pane_kimi_running=0
    pane_node=0
    ai_running=0
    claude_hook_running=0
    pane_needs_attention=0
    pane_title=$(tmux display-message -p -t "$pane_id" '#{pane_title}' 2>/dev/null)
    is_ai_running "$pane_id" "$pane_title" && ai_running=1
    is_claude_running "$pane_id" && claude_hook_running=1
    needs_human_attention "$pane_id" && pane_needs_attention=1
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
    codex_count=$((codex_count + pane_codex))
    claude_count=$((claude_count + pane_claude))
    gemini_count=$((gemini_count + pane_gemini))
    kimi_count=$((kimi_count + pane_kimi))
    node_count=$((node_count + pane_node))
    [ "$pane_codex_running" -eq 1 ] && codex_running=1
    [ "$pane_codex_attention" -eq 1 ] && codex_attention=1
    [ "$pane_claude_running" -eq 1 ] && claude_running=1
    [ "$pane_claude_attention" -eq 1 ] && claude_attention=1
    [ "$pane_gemini_running" -eq 1 ] && gemini_running=1
    [ "$pane_kimi_running" -eq 1 ] && kimi_running=1
  done
}

print_badge() {
  color=$1
  name=$2
  count=$3
  running=$4
  attention=$5
  suffix=''
  [ "$count" -gt 1 ] && suffix=" ($count)"
  loading=''
  if [ "$attention" -eq 1 ]; then
    loading="#[fg=#1e1e2e,bg=#f38ba8,bold] ! #[fg=#ffffff,bg=$color,bold] "
  elif [ "$running" -eq 1 ]; then
    loading="$pulse "
  fi
  [ "$printed" -eq 1 ] && printf '#[fg=#ffffff,bg=#45475a] '
  printf '#[fg=#ffffff,bg=%s,bold] %s%s%s #[nobold]' "$color" "$loading" "$name" "$suffix"
  printed=1
}

print_activity() {
  if [ "$codex_count" -gt 0 ] || [ "$claude_count" -gt 0 ] || [ "$gemini_count" -gt 0 ] || [ "$kimi_count" -gt 0 ] || [ "$node_count" -gt 0 ]; then
    printed=0
    [ "$codex_count" -gt 0 ] && print_badge '#10a37f' codex "$codex_count" "$codex_running" "$codex_attention"
    [ "$claude_count" -gt 0 ] && print_badge '#d97757' claude "$claude_count" "$claude_running" "$claude_attention"
    [ "$gemini_count" -gt 0 ] && print_badge '#4285f4' gemini "$gemini_count" "$gemini_running" 0
    [ "$kimi_count" -gt 0 ] && print_badge '#7c3aed' kimi "$kimi_count" "$kimi_running" 0
    [ "$node_count" -gt 0 ] && print_badge '#68a063' node "$node_count" 0 0
  else
    printf '#[fg=#ffffff,bg=#6c7086] -- idle '
  fi
}

first_session=1
session_number=1
tmux list-sessions -F '#{session_id}:#{session_name}' 2>/dev/null |
while IFS=':' read -r session_id session_name; do
  [ "$first_session" -eq 0 ] && printf ' '
  first_session=0

  session_label=$session_name
  if [ "$show_session_numbers" = 1 ] && [ "$session_number" -le 9 ]; then
    session_label="[$session_number] $session_name"
  fi

  if [ "$session_id" = "$active_session_id" ]; then
    printf '#[range=session|%s]#[fg=#ffffff,bg=#45475a,bold] %s #[nobold]#[norange]' "$session_id" "$session_label"
  else
    printf '#[range=session|%s]#[fg=#ffffff,bg=#45475a] %s #[norange]' "$session_id" "$session_label"
  fi
  collect_session_activity "$session_id"
  print_activity
  printf '#[default]'
  session_number=$((session_number + 1))
done

printf '#[default]'
