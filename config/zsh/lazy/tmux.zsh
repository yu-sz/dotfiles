tm() {
  local subcmd="${1:-repo}"

  _tm_connect() {
    local name="$1" dir="$2"
    tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -qE "^${name}$" ||
      tmux new-session -d -c "$dir" -s "$name"
    if [[ -n "$TMUX" ]]; then
      tmux switch-client -t "$name"
    else
      tmux attach-session -t "$name"
    fi
  }

  case "$subcmd" in
    "repo"|"r"|"")
      shift 2>/dev/null
      local dir name
      if [[ -n "$1" ]]; then
        name="$1"
        dir="$(pwd)"
      else
        dir="$(ghq root)/$(ghq list | fzf --height=50% --border)"
        [[ -z "$dir" || "$dir" == "$(ghq root)/" ]] && return
        name="$(basename "$dir")"
      fi
      _tm_connect "$name" "$dir"
      ;;
    "wt"|"w")
      local selected dir name
      selected=$(git worktree list 2>/dev/null | grep -v "$(pwd)" | fzf --height=50% --border)
      [[ -z "$selected" ]] && return
      dir=$(echo "$selected" | awk '{print $1}')
      name=$(basename "$dir")
      _tm_connect "$name" "$dir"
      ;;
    "list"|"l")
      tmux list-sessions
      ;;
    "kill"|"k")
      local session
      session=$(tmux list-sessions -F "#{session_name}" | fzf --height=50% --border --prompt="Kill: ")
      [[ -n "$session" ]] && tmux kill-session -t "$session"
      ;;
    "help"|"h"|*)
      cat << 'EOF'
tmux session management

Usage: tm [command] [args]

Commands:
  repo, r [name]  Create session from ghq repo (default)
  wt, w           Create session from git worktree
  list, l         List existing sessions
  kill, k         Kill selected session
  help, h         Show this help

Examples:
  tm              # Select ghq repo → create session
  tm myproject    # Create session "myproject" in current dir
  tm wt           # Select worktree → create session
  tm kill         # Select and kill session
EOF
      ;;
  esac
}

_tm() {
  local -a commands
  commands=(
    'repo:Create session from ghq repository'
    'r:Create session from ghq repository'
    'wt:Create session from git worktree'
    'w:Create session from git worktree'
    'list:List existing sessions'
    'l:List existing sessions'
    'kill:Kill selected session'
    'k:Kill selected session'
    'help:Show help'
    'h:Show help'
  )
  _describe -t commands 'tm commands' commands
}
compdef _tm tm
