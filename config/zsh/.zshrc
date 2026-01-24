## homebrew ###
brew_path="/opt/homebrew/bin/brew"
if [ -e "$brew_path" ]; then
  eval "$($brew_path shellenv)"
fi

### mise ###
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

### sheldon ###
sheldon::load() {
    local profile="${1:-default}"
    local plugins_file="${SHELDON_CONFIG_FILE:-$HOME/.config/sheldon/plugins.toml}"
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sheldon"
    local cache_file="$cache_dir/$profile.zsh"
    local lock_file="$XDG_DATA_HOME/sheldon/plugins.$profile.lock"

    if [[ ! -f "$lock_file"
       || "$plugins_file" -nt "$lock_file"
       || "$ZDOTDIR/eager" -nt "$lock_file"
       || "$ZDOTDIR/lazy" -nt "$lock_file" ]]; then
        sheldon --profile="$profile" lock
    fi

    if [[ ! -f "$cache_file" || "$lock_file" -nt "$cache_file" ]]; then
        mkdir -p "$cache_dir"
        sheldon --profile="$profile" source > "$cache_file"
        zcompile "$cache_file"
    fi

    \builtin source "$cache_file"
}

if command -v sheldon &> /dev/null; then
    sheldon::load
fi

