typeset -gU PATH path
typeset -gU FPATH fpath

path=(
    "/opt/homebrew/bin"(N-/)
    "/opt/homebrew/sbin"(N-/)
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
