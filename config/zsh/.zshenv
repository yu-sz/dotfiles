### locale ###
export LANG="ja_JP.UTF-8"

unsetopt GLOBAL_RCS

### XDG ###
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR%/}"
elif [[ "$OSTYPE" == darwin* && -n "${TMPDIR:-}" ]]; then
  export XDG_RUNTIME_DIR="${TMPDIR%/}"
else
  export XDG_RUNTIME_DIR="/tmp/runtime-$UID"
  mkdir -pm 700 "$XDG_RUNTIME_DIR" 2>/dev/null
fi

### dotfiles ###
export DOTFILES_DIR="$HOME/Projects/dotfiles"

### zsh ###
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

### sheldon ###
export SHELDON_CONFIG_DIR="$ZDOTDIR/sheldon"
export SHELDON_CONFIG_FILE="$SHELDON_CONFIG_DIR/plugins.toml"

### less ###
export LESSHISTFILE="$XDG_STATE_HOME/lesshst"

### herdr ###
export HERDR_SOCKET_PATH="${HERDR_SOCKET_PATH:-${XDG_RUNTIME_DIR}/herdr.sock}"


