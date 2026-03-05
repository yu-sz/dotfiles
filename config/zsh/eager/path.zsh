typeset -gU PATH path
typeset -gU FPATH fpath

path=(
    "$HOME/.local/bin"(N-/)
    "/opt/homebrew/bin"(N-/)
    "/opt/homebrew/sbin"(N-/)
    "/opt/homebrew/opt/libpq/bin"(N-/)
    "$XDG_DATA_HOME/mise/shims"
    "/usr/local/bin"(N-/)
    "/usr/local/sbin"(N-/)
    "/usr/bin"(N-/)
    "/usr/sbin"(N-/)
    "/bin"(N-/)
    "/sbin"(N-/)
    "$path[@]"
)

fpath=(
    "$XDG_DATA_HOME/zsh/completions"(N-/)
    "$fpath[@]"
)
