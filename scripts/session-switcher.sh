#!/usr/bin/env bash
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
list_cmd="$dir/list-sessions.sh"
rename_cmd="$dir/rename-session.sh"
new_session_cmd="$dir/new-session.sh"

c_reset=$'\033[0m'
c_dim=$'\033[2m'
c_red=$'\033[1;31m'
c_yellow=$'\033[1;33m'
c_green=$'\033[1;32m'

header_default="${c_dim}enter: switch    n: new session    rr: kill session    cr: rename session    esc: cancel${c_reset}"
header_kill_pending="${c_red}press r again to KILL {1}  \xe2\x80\x94  esc to cancel${c_reset}"
header_rename_pending="${c_yellow}press r to RENAME {1}  \xe2\x80\x94  esc to cancel${c_reset}"
header_new_pending="${c_green}type the new session name, enter: create  \xe2\x80\x94  esc: cancel${c_reset}"

selected=$("$list_cmd" | fzf \
  --layout=default \
  --header-first \
  --prompt '> ' \
  --header "$header_default" \
  --bind "r:transform:
    if [[ \$FZF_PROMPT == 'n> ' ]]; then
      echo \"transform-query:echo -n '\$FZF_QUERY'r\"
    elif [[ \$FZF_PROMPT == 'c> ' ]]; then
      echo \"execute($rename_cmd {1})+reload($list_cmd)+change-prompt(> )+change-header($header_default)\"
    elif [[ \$FZF_PROMPT == 'r> ' ]]; then
      echo \"execute-silent(tmux kill-session -t {1})+reload($list_cmd)+change-prompt(> )+change-header($header_default)\"
    else
      echo \"change-prompt(r> )+change-header($header_kill_pending)\"
    fi" \
  --bind "c:transform:
    if [[ \$FZF_PROMPT == 'n> ' ]]; then
      echo \"transform-query:echo -n '\$FZF_QUERY'c\"
    elif [[ \$FZF_PROMPT == '> ' ]]; then
      echo \"change-prompt(c> )+change-header($header_rename_pending)\"
    else
      echo \"change-prompt(> )+change-header($header_default)+clear-query\"
    fi" \
  --bind "n:transform:
    if [[ \$FZF_PROMPT == 'n> ' ]]; then
      echo \"transform-query:echo -n '\$FZF_QUERY'n\"
    elif [[ \$FZF_PROMPT == '> ' ]]; then
      echo \"change-prompt(n> )+change-header($header_new_pending)+clear-query\"
    else
      echo \"change-prompt(> )+change-header($header_default)+clear-query\"
    fi" \
  --bind "enter:transform:
    if [[ \$FZF_PROMPT == 'n> ' ]]; then
      if [[ -n \$FZF_QUERY ]]; then
        echo \"become($new_session_cmd)\"
      fi
    else
      echo 'accept'
    fi" \
  --bind "esc:transform:
    if [[ \$FZF_PROMPT == '> ' ]]; then
      echo 'abort'
    else
      echo \"change-prompt(> )+change-header($header_default)+clear-query\"
    fi")

if [ -n "$selected" ]; then
  session=$(awk '{print $1}' <<< "$selected")
  tmux switch-client -t "$session"
fi
