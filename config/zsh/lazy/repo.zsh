repo() {
    local action="${1:-list}"
    
    case "$action" in
        "list"|"l")
            # List all repositories with fzf selection
            local selected_repo
            selected_repo=$(ghq list | fzf --height=50% --border --preview="echo {}" --preview-window=down:3:wrap)
            if [[ -n "$selected_repo" ]]; then
                echo "Selected: $selected_repo"
                echo "Path: $(ghq root)/$selected_repo"
            fi
            ;;
        "cd"|"c")
            # Change directory to selected repository
            local selected_repo
            selected_repo=$(ghq list | fzf --height=50% --border --preview="echo {}" --preview-window=down:3:wrap)
            if [[ -n "$selected_repo" ]]; then
                cd "$(ghq root)/$selected_repo" || return 1
            fi
            ;;
        "remove"|"rm"|"r")
            # Remove selected repository
            local selected_repo
            selected_repo=$(ghq list | fzf --height=50% --border --preview="echo {}" --preview-window=down:3:wrap --prompt="Select repository to remove: ")
            if [[ -n "$selected_repo" ]]; then
                echo "Are you sure you want to remove $selected_repo? [y/N]"
                read -r confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    rm -rf "$(ghq root)/$selected_repo"
                    echo "Removed: $selected_repo"
                else
                    echo "Cancelled"
                fi
            fi
            ;;
        "get"|"g")
            # Clone/get a new repository
            if [[ -z "$2" ]]; then
                # Interactive mode: show remote repositories via gh + fzf
                local selected_repo
                selected_repo=$(gh repo list --limit 100 --json nameWithOwner --jq '.[].nameWithOwner' | fzf --height=50% --border --preview="gh repo view {} --json description,url,pushedAt --template '{{.description}}\n{{.url}}\nLast updated: {{.pushedAt}}'" --preview-window=down:5:wrap --prompt="Select repository to clone: ")
                if [[ -n "$selected_repo" ]]; then
                    ghq get "github.com/$selected_repo"
                fi
            else
                ghq get "$2"
            fi
            ;;
        "create"|"new"|"n")
            # Create a new repository directory
            if [[ -z "$2" ]]; then
                echo "Usage: repo create <repository_path>"
                echo "Example: repo create github.com/user/new-repo"
                return 1
            fi
            local repo_path="$(ghq root)/$2"
            mkdir -p "$repo_path"
            cd "$repo_path" || return 1
            git init
            echo "Created and initialized: $2"
            ;;
        "open"|"o")
            # Open repository in editor (default: code)
            local editor="${2:-code}"
            local selected_repo
            selected_repo=$(ghq list | fzf --height=50% --border --preview="echo {}" --preview-window=down:3:wrap)
            if [[ -n "$selected_repo" ]]; then
                local repo_path="$(ghq root)/$selected_repo"
                if command -v "$editor" > /dev/null; then
                    "$editor" "$repo_path"
                else
                    echo "Editor '$editor' not found. Trying fallback editors..."
                    if command -v code > /dev/null; then
                        code "$repo_path"
                    elif command -v vim > /dev/null; then
                        vim "$repo_path"
                    else
                        echo "No suitable editor found (code, vim)"
                    fi
                fi
            fi
            ;;
        "help"|"h"|*)
            # Show help
            cat << 'EOF'
Repository management with ghq and fzf

Usage: repo <command> [args]

Commands:
  list, l         List repositories with fzf selection
  cd, c           Change directory to selected repository
  remove, rm, r   Remove selected repository (with confirmation)
  get, g [url]    Clone repository (interactive if no url)
  create, new, n  Create and initialize a new repository
  open, o [editor] Open repository in editor (default: code)
  help, h         Show this help message

Examples:
  repo                    # List repositories
  repo cd                 # Change to selected repository
  repo get                # Interactive repository selection
  repo get github.com/user/repo
  repo create github.com/user/new-repo
  repo remove             # Remove selected repository
  repo open               # Open repository in code (default)
  repo open vim           # Open repository in vim
  repo open nvim          # Open repository in neovim

Requirements: ghq, fzf, git, gh (for interactive get)
EOF
            ;;
    esac
}

_repo_completion() {
    local -a commands
    commands=(
        'list:List repositories'
        'l:List repositories'
        'cd:Change directory'
        'c:Change directory'
        'get:Clone repository'
        'g:Clone repository'
        'remove:Remove repository'
        'rm:Remove repository'
        'create:Create new repository'
        'n:Create new repository'
        'open:Open in editor'
        'o:Open in editor'
        'help:Show help'
    )
    _describe -t commands 'repo commands' commands
}

compdef _repo_completion repo
