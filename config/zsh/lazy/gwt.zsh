gwt() {
    local action="${1:-list}"

    case "$action" in
        "list"|"l")
            local selected
            selected=$(git worktree list | fzf --height=50% --border)
            if [[ -n "$selected" ]]; then
                echo "$selected"
            fi
            ;;
        "new"|"n")
            shift
            local do_cd=false
            if [[ "$1" == "-c" ]]; then
                do_cd=true
                shift
            fi
            local branch="$1"
            if [[ -z "$branch" ]]; then
                echo "Usage: gwt new [-c] <branch>"
                return 1
            fi
            local dir="${2:-../$(basename "$PWD")-$branch}"
            git fetch origin
            git worktree add -b "$branch" "$dir"
            if [[ "$do_cd" == true ]]; then
                cd "$dir" || return 1
            fi
            ;;
        "add"|"a")
            shift
            local branch="$1"
            if [[ -z "$branch" ]]; then
                echo "Usage: gwt add <branch>"
                return 1
            fi
            local dir="${2:-../$(basename "$PWD")-$branch}"
            git worktree add "$dir" "$branch"
            ;;
        "cd"|"c")
            local selected
            selected=$(git worktree list | grep -v "$(pwd)" | fzf --height=50% --border --prompt="Select worktree: ")
            if [[ -n "$selected" ]]; then
                local dir
                dir=$(echo "$selected" | awk '{print $1}')
                cd "$dir" || return 1
            fi
            ;;
        "rm"|"remove"|"r")
            local selected
            selected=$(git worktree list | grep -v "$(pwd)" | fzf --height=50% --border --prompt="Select worktree to remove: ")
            if [[ -n "$selected" ]]; then
                local dir
                dir=$(echo "$selected" | awk '{print $1}')
                echo "Remove $dir? [y/N]"
                read -r confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    git worktree remove "$dir" && git worktree prune
                    echo "Removed: $dir"
                else
                    echo "Cancelled"
                fi
            fi
            ;;
        "prune"|"p")
            git worktree prune
            ;;
        "help"|"h"|*)
            cat << 'EOF'
Git worktree management with fzf

Usage: gwt <command> [args]

Commands:
  list, l              List worktrees with fzf selection
  new, n [-c] <branch> Create new branch + worktree (-c: cd after create)
  add, a <branch>      Add existing branch as worktree
  cd, c                Change directory to selected worktree
  rm, remove, r        Remove selected worktree (with confirmation)
  prune, p             Prune stale worktree references
  help, h              Show this help message

Examples:
  gwt                  # List worktrees
  gwt new feature      # Create new branch 'feature' with worktree
  gwt new -c feature   # Create and cd into worktree
  gwt add hotfix       # Add existing 'hotfix' branch as worktree
  gwt cd               # Select and cd to worktree
  gwt rm               # Select and remove worktree

Requirements: git, fzf
EOF
            ;;
    esac
}

_gwt() {
    local state
    _arguments -C \
        '1: :->command' \
        '*: :->args'

    case "$state" in
        command)
            local -a commands
            commands=(
                'list:List worktrees'
                'l:List worktrees'
                'new:Create new branch + worktree'
                'n:Create new branch + worktree'
                'add:Add existing branch as worktree'
                'a:Add existing branch as worktree'
                'cd:Change directory to worktree'
                'c:Change directory to worktree'
                'rm:Remove worktree'
                'remove:Remove worktree'
                'r:Remove worktree'
                'prune:Prune stale references'
                'p:Prune stale references'
                'help:Show help'
                'h:Show help'
            )
            _describe -t commands 'gwt commands' commands
            ;;
        args)
            case "$words[2]" in
                add|a)
                    local -a branches
                    branches=(${(f)"$(git branch -a --format='%(refname:short)' 2>/dev/null)"})
                    _describe -t branches 'branches' branches
                    ;;
                new|n)
                    _arguments '-c[cd after create]' '*: :'
                    ;;
            esac
            ;;
    esac
}

compdef _gwt gwt
