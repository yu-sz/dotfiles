### homebrew ###
brew_path="/opt/homebrew/bin/brew"
if [[ -e "$brew_path" ]]; then
  brew_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/brew_shellenv.zsh"
  if [[ ! -f "$brew_cache" || "$brew_path" -nt "$brew_cache" ]]; then
    mkdir -p "${brew_cache:h}"
    "$brew_path" shellenv > "$brew_cache"
  fi
  source "$brew_cache"
fi

### mise ###
mise_path="${XDG_DATA_HOME:-$HOME/.local/share}/mise/bin/mise"
if [[ -x "$mise_path" ]]; then
  mise_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/mise_activate.zsh"
  if [[ ! -f "$mise_cache" || "$mise_path" -nt "$mise_cache" ]]; then
    mkdir -p "${mise_cache:h}"
    "$mise_path" activate zsh > "$mise_cache"
  fi
  source "$mise_cache"
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

sheldon::update() {
    local profile="${1:-default}"
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sheldon"
    sheldon --profile="$profile" lock --update
    rm -f "$cache_dir/$profile.zsh"*
    sheldon::load "$profile"
}

if command -v sheldon &> /dev/null; then
    sheldon::load
fi

