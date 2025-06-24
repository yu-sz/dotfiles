### setup ###
autoload -Uz compinit
zsh-defer -a -t0.01 compinit -d "$XDG_STATE_HOME/zcompdump"

zmodload -i zsh/complist

zstyle ':completion:*:default' menu select=1
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

### keys ###
bindkey -M menuselect '^h' vi-backward-char
bindkey -M menuselect '^j' vi-down-line-or-history
bindkey -M menuselect '^k' vi-up-line-or-history
bindkey -M menuselect '^l' vi-forward-char
