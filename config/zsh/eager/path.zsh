# Nix environment (GLOBAL_RCS=off で /etc/zshrc がスキップされる対策)
if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

typeset -gU PATH path
typeset -gU FPATH fpath

path=(
    "$HOME/.local/bin"(N-/)
    "/etc/profiles/per-user/$USER/bin"(N-/)
    "/run/current-system/sw/bin"(N-/)
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
