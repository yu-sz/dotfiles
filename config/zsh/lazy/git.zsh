gi() {
    local action="${1:-help}"

    case "$action" in
        "branch"|"br"|"b")
            shift
            local branches branch
            if [[ "$1" == "-a" ]]; then
                branches=$(git branch --all | grep -v HEAD)
                branch=$(echo "$branches" | fzf --height=50% --border)
                [[ -n "$branch" ]] && git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
            else
                branches=$(git branch --all | grep -v HEAD | grep -v remotes/)
                branch=$(echo "$branches" | fzf --height=50% --border)
                [[ -n "$branch" ]] && git checkout $(echo "$branch" | sed "s/.* //")
            fi
            ;;
        "log"|"l")
            shift
            git log --graph --color=always \
                --format="%C(auto)%h%d %s %C(#C0C0C0)%C(bold)%cr" "$@" |
            fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
                --bind "ctrl-m:execute:(grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
{}
FZF-EOF"
            ;;
        "help"|"h"|*)
            cat << 'EOF'
Git operations with fzf

Usage: gi <command> [args]

Commands:
  branch, br, b      Checkout branch (local only)
  branch -a, br -a   Checkout branch (including remotes)
  log, l             Interactive git log viewer
  help, h            Show this help message

Examples:
  gi branch          # Select and checkout local branch
  gi br -a           # Select and checkout any branch
  gi log             # Browse git log interactively

Requirements: git, fzf
EOF
            ;;
    esac
}

_gi() {
    local state
    _arguments -C \
        '1: :->command' \
        '*: :->args'

    case "$state" in
        command)
            local -a commands
            commands=(
                'branch:Checkout branch'
                'br:Checkout branch'
                'b:Checkout branch'
                'log:Interactive git log'
                'l:Interactive git log'
                'help:Show help'
                'h:Show help'
            )
            _describe -t commands 'gi commands' commands
            ;;
        args)
            case "$words[2]" in
                branch|br|b)
                    _arguments '-a[include remote branches]'
                    ;;
            esac
            ;;
    esac
}

compdef _gi gi
