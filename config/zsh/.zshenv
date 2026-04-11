### locale ###
export LANG="ja_JP.UTF-8"

unsetopt GLOBAL_RCS

### XDG ###
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

### dotfiles ###
export DOTFILES_DIR="$HOME/Projects/dotfiles"

### zsh ###
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

### sheldon ###
export SHELDON_CONFIG_DIR="$ZDOTDIR/sheldon"
export SHELDON_CONFIG_FILE="$SHELDON_CONFIG_DIR/plugins.toml"

### less ###
if [[ -f "$XDG_CACHE_HOME/lesshst" && ! -f "$XDG_STATE_HOME/lesshst" ]]; then
	mv "$XDG_CACHE_HOME/lesshst" "$XDG_STATE_HOME/lesshst"
fi
export LESSHISTFILE="$XDG_STATE_HOME/lesshst"
