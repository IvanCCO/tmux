#!/bin/zsh

state_file=${1:-"${TMPDIR:-/tmp}/tmux-break-reminder-${UID:-$(id -u)}-tmux-codex-loading.state"}
unlock_phrase='I bite'
unlock_display='"I bite"'
typed=''
frame=0
unlocked=0
glyphs=('╵' '┊' '│' '╷' '·')
canvas_width=56
content_height=20

finish() {
  printf '\033[0m\033[?25h'
  (( ! unlocked )) && date +%s > "$state_file"
}

refresh_layout() {
  rows=$(tput lines)
  columns=$(tput cols)
  top=$(( (rows - content_height) / 2 ))
  left=$(( (columns - canvas_width) / 2 ))
  (( top < 1 )) && top=1
  (( left < 1 )) && left=1
}

print_at() {
  printf '\033[%d;%dH' "$1" "$2"
  print -Pn "%F{$3}$4%f"
}

print_centered_in_canvas() {
  local row=$1 text=$2 color=$3 x=$(( left + (canvas_width - ${#text}) / 2 ))
  print_at "$row" "$x" "$color" "$text"
}

draw_melt() {
  local row glyph drift line

  refresh_layout
  printf '\033[H\033[2J'
  print_centered_in_canvas "$top" 'T I M E   T O   M E L T' 160

  for row in {1..14}; do
    glyph=${glyphs[$(( (frame + row) % ${#glyphs} + 1 ))]}
    drift=$(( (frame * 2 + row * 7) % 22 ))
    line="${(l:$drift:: :)}${glyph}  m e l t  ${glyph}  m e l t  ${glyph}"
    print_at "$((top + row + 1))" "$left" $((160 + row % 4 * 15)) "$line"
  done

  print_centered_in_canvas "$((top + 17))" 'Step away. Drink water. Look somewhere else.' 250
  print_centered_in_canvas "$((top + 18))" "Type ${unlock_display} and press Enter to return." 203
  print_centered_in_canvas "$((top + 19))" "> ${typed}_" 245
}

trap finish EXIT
tput civis
while true; do
  draw_melt

  if read -rs -t 0.1 -k 1 key; then
    case "$key" in
      $'\n'|$'\r')
        if [[ "$typed" == "$unlock_phrase" ]]; then
          date +%s > "$state_file"
          unlocked=1
          break
        fi
        typed=''
        ;;
      $'\177'|$'\b') typed=${typed[1,-2]} ;;
      *) typed+=$key ;;
    esac
  fi

  (( frame++ ))
done
