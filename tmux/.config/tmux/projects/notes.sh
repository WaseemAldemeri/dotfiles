SESSION_NAME="notes"

launch() {
  local S="$SESSION_NAME"
  local NOTES_DIR="$HOME/Work/Test/notes"

  # Window 1: nvim
  tmux new-session -d -s "$S" -n "nvim" -c "$NOTES_DIR"
  tmux send-keys -t "$S:nvim.1" "nvim ." Enter

  # Window 2: zsh
  tmux new-window -t "$S" -n "zsh" -c "$NOTES_DIR"

  # Start on the nvim window
  tmux select-window -t "$S:nvim"
}
