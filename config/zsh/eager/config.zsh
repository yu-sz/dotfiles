### history ###
export HISTFILE="$XDG_STATE_HOME/history"
export HISTSIZE=12000
export SAVEHIST=10000

### opts ###
# 履歴管理系
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS    # HIST_SAVE_NO_DUPS を削除
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS       # 履歴保存時に重複を削除 (削除)
# ディレクトリ操作系
setopt AUTO_PUSHD
setopt INTERACTIVE_COMMENTS
setopt NO_SHARE_HISTORY
# その他
setopt NO_BEEP
setopt GLOBDOTS
setopt PRINT_EIGHT_BIT
setopt NO_FLOW_CONTROL

### hooks ###
zshaddhistory() {
    local line="${1%%$'\n'}"
    [[ ! "$line" =~ "^(cd|history|jj?|lazygit|lazydocker|la|ll|ls|rm|rmdir|trash|z|zi)($| )" ]]
}

