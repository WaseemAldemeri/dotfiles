SESSION_NAME="WAJ"

launch() {
  local S="$SESSION_NAME"
  local WAJ="$HOME/Work/WAJ/waj"
  local DB="$HOME/Work/WAJ/waj-db"
  local WL="$HOME/Work/WAJ/whitelabel_v2.0"
  local ROOT="$HOME/Work/WAJ"

  # Helper: send keys to a named window + pane index
  sk() { tmux send-keys -t "$1:$2.$3" "$4" Enter; }

  # ── Window 1: waj  (2×2 grid) ─────────────────────────────────────────────
  #   pane 1 (top-left)     → empty zsh
  #   pane 2 (bottom-left)  → claude
  #   pane 3 (top-right)    → fvm flutter run -d chrome
  #   pane 4 (bottom-right) → fvm flutter pub run build_runner watch
  tmux new-session -d -s "$S" -n "waj" -c "$WAJ"
  tmux split-window -h -t "$S:waj.1" -c "$WAJ"
  tmux split-window -v -t "$S:waj.1" -c "$WAJ"
  tmux split-window -v -t "$S:waj.3" -c "$WAJ"
  sk "$S" waj 2 "claude"
  sk "$S" waj 3 "fvm flutter run -d web-server --web-port=8080"
  sk "$S" waj 4 "fvm flutter pub run build_runner watch"
  tmux select-pane -t "$S:waj.1"

  # ── Window 2: waj-db  (2×2 grid) ──────────────────────────────────────────
  #   pane 1 (top-left)     → empty zsh
  #   pane 2 (bottom-left)  → claude
  #   pane 3 (top-right)    → supabase restart + functions serve
  #   pane 4 (bottom-right) → cloudflared tunnel
  tmux new-window -t "$S" -n "waj-db" -c "$DB"
  tmux split-window -h -t "$S:waj-db.1" -c "$DB"
  tmux split-window -v -t "$S:waj-db.1" -c "$DB"
  tmux split-window -v -t "$S:waj-db.3" -c "$DB"
  sk "$S" waj-db 2 "claude"
  sk "$S" waj-db 3 "npx supabase stop && npx supabase start && npx supabase functions serve --no-verify-jwt"
  sk "$S" waj-db 4 "cloudflared tunnel run supabase"
  tmux select-pane -t "$S:waj-db.1"

  # ── Window 3: whitelabel  (left 2-stack | right single) ───────────────────
  #   pane 1 (top-left)     → empty zsh
  #   pane 2 (bottom-left)  → claude
  #   pane 3 (right)        → npm run dev
  tmux new-window -t "$S" -n "whitelabel" -c "$WL"
  tmux split-window -h -t "$S:whitelabel.1" -c "$WL"
  tmux split-window -v -t "$S:whitelabel.1" -c "$WL"
  sk "$S" whitelabel 2 "claude"
  sk "$S" whitelabel 3 "npm run dev"
  tmux select-pane -t "$S:whitelabel.1"

  # ── Window 4: root  (left | right) ────────────────────────────────────────
  #   pane 1 (left)  → empty zsh
  #   pane 2 (right) → claude
  tmux new-window -t "$S" -n "root" -c "$ROOT"
  tmux split-window -h -t "$S:root.1" -c "$ROOT"
  sk "$S" root 2 "claude"
  tmux select-pane -t "$S:root.1"

  # ── Window 5: ai_agent  (left 2-stack | right single) ────────────────────
  #   pane 1 (top-left)     → empty zsh
  #   pane 2 (bottom-left)  → claude
  #   pane 3 (right)        → source venv + python main.py
  local AI="$DB/ai_agent"
  tmux new-window -t "$S" -n "ai_agent" -c "$AI"
  tmux split-window -h -t "$S:ai_agent.1" -c "$AI"
  tmux split-window -v -t "$S:ai_agent.1" -c "$AI"
  sk "$S" ai_agent 2 "claude"
  sk "$S" ai_agent 3 "source venv/bin/activate && python main.py"
  tmux select-pane -t "$S:ai_agent.1"

  tmux select-window -t "$S:waj"
}
