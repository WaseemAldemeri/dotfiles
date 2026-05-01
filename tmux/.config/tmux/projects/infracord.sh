SESSION_NAME="infracord"

launch() {
  local S="$SESSION_NAME"
  local DIR="$HOME/Work/Test/infracord"

  sk() { tmux send-keys -t "$1:$2.$3" "$4" Enter; }

  # ── Window 1: dev  (left zsh | right claude) ──────────────────────────────
  tmux new-session  -d -s "$S" -n "dev"    -c "$DIR"
  tmux split-window -h -t "$S:dev.1"       -c "$DIR"
  sk "$S" dev 2 "claude"
  tmux select-pane  -t "$S:dev.1"
}
