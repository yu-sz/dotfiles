### Config ###
source <(fzf --zsh)
bindkey "ç" fzf-cd-widget #特殊文字をfzfのキーバインドに上書き

export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'

export FZF_CTRL_T_COMMAND='rg --files --hidden --follow --glob "!**/.git/*"'
export FZF_CTRL_T_OPTS="""
    --preview 'bat  --color=always --style=header,grid {}'
    --preview-window=right:60%
"""

### Custom Functions ###
# Checkout local Git branch interactively
fzf::br() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD | grep -v remotes/) &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git checkout $(echo "$branch" | sed "s/.* //")
}

# Checkout Git branch interactively (including remotes)
fzf::brm() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# View Git commit log interactively
fzf::log() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(#C0C0C0)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
              (grep -o '[a-f0-9]\{7\}' | head -1 |
              xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
              {}
              FZF-EOF
             "
}

# Kill processes interactively
fzf::kill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

  if [ "x$pid" != "x" ]
  then
    echo $pid | xargs kill -${1:-9}
  fi
}
