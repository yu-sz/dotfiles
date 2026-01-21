# git worktree shortcuts (zsh)
gwt()  { git worktree "$@"; }
gwtl() { git worktree list; }
gwtp() { git worktree prune; }

# ブランチ名だけで worktree を作る（dir省略時は ../<repo名>-<branch>）
gwtnew() {
  local b="$1"
  local dir="${2:-../$(basename "$PWD")-$b}"
  git fetch origin
  git worktree add -b "$b" "$dir"
}

# 既存ブランチを worktree に追加
gwtadd() {
  local b="$1"
  local dir="${2:-../$(basename "$PWD")-$b}"
  git worktree add "$dir" "$b"
}

# worktree を消して prune
gwtrm() {
  local dir="$1"
  git worktree remove "$dir" && git worktree prune
}

# ブランチ名だけで worktree を作り cd
gwtnewcd() {
  local b="$1"
  local dir="${2:-../$(basename "$PWD")-$b}"
  git fetch origin
  git worktree add -b "$b" "$dir" && cd "$dir"
}

# タブ補完の設定（コマンドの説明を表示）
_gwt_commands() {
  local -a commands
  commands=(
    'gwt:git worktreeの生コマンド'
    'gwtl:worktree一覧を表示'
    'gwtp:削除されたworktreeの参照を掃除'
    'gwtnew:新規ブランチ+worktree作成'
    'gwtnewcd:新規ブランチ+worktree作成して移動'
    'gwtadd:既存ブランチをworktreeに追加'
    'gwtrm:worktreeを削除してprune'
  )
  _describe 'git worktree shortcuts' commands
}

compdef _gwt_commands gwt gwtl gwtp gwtnew gwtnewcd gwtadd gwtrm
