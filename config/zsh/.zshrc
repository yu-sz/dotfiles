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
# Nix ストアは mtime=0 で -nt が効かないため、実パス（ストアハッシュ）の一致で判定
if mise_path="$(command -v mise)" 2>/dev/null; then
  mise_real="$(readlink -f "$mise_path")"
  mise_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/mise_activate.zsh"
  if [[ ! -f "$mise_cache" ]] || ! head -1 "$mise_cache" | grep -qF "$mise_real"; then
    mkdir -p "${mise_cache:h}"
    { echo "# $mise_real"; "$mise_path" activate zsh; } > "$mise_cache"
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

    local newest_eager=("$ZDOTDIR"/eager/*.zsh(Nom[1]))
    local newest_lazy=("$ZDOTDIR"/lazy/*.zsh(Nom[1]))
    if [[ ! -f "$lock_file"
       || "$plugins_file" -nt "$lock_file"
       || "$newest_eager" -nt "$lock_file"
       || "$newest_lazy" -nt "$lock_file" ]]; then
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

