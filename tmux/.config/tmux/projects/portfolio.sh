SESSION_NAME="portfolio"

launch() {
  local S="$SESSION_NAME"
  local DIR="$HOME/Work/Test/portfolio"

  sk() { tmux send-keys -t "$1:$2.$3" "$4" Enter; }

  # ── Window 1: dev  (left zsh | right claude) ──────────────────────────────
  tmux new-session  -d -s "$S" -n "dev"    -c "$DIR"
  tmux split-window -h -t "$S:dev.1"       -c "$DIR"
  sk "$S" dev 2 "claude"
  tmux select-pane  -t "$S:dev.1"

  # ── Window 2: server  (hugo dev server) ───────────────────────────────────
  tmux new-window   -t "$S" -n "server"    -c "$DIR"
  sk "$S" server 1 "hugo server -D --disableFastRender --ignoreCache --renderToMemory"

  tmux select-window -t "$S:dev"
}
