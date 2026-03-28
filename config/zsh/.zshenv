### locale ###
export LANG="ja_JP.UTF-8"

unsetopt GLOBAL_RCS

### XDG ###
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

### zsh ###
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

### sheldon ###
export SHELDON_CONFIG_DIR="$ZDOTDIR/sheldon"
export SHELDON_CONFIG_FILE="$SHELDON_CONFIG_DIR/plugins.toml"

### less ###
export LESSHISTFILE="$XDG_CACHE_HOME/lesshst"
