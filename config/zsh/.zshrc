## homebrew ###
brew_path="/opt/homebrew/bin/brew"
if [ -e $brew_path ]; then
  eval "$($brew_path shellenv)"
fi

### mise ###
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

### sheldon ###
sheldon::load() {
    local profile="$1"
    local plugins_file="$SHELDON_CONFIG_FILE"
    local cache_file="$XDG_CACHE_HOME/sheldon/$profile.zsh"

    if [[ ! -f "$cache_file" || "$plugins_file" -nt "$cache_file" ]]; then
        mkdipath r -p "$XDG_CACHE_HOME/sheldon"
        sheldon --profile="$profile" source > "$cache_file"
        zcompile "$cache_file" 
    fi

    \builtin source "$cache_file"
}

if command -v sheldon &> /dev/null; then
    sheldon::load
fi
