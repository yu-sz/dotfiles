# workspace CLI 実装計画

## 概要

- tmux セッション管理コマンド `workspace`（エイリアス: `ws`）を新規作成
- 命令的サブコマンド + fzf 対話モードの2層構造で、一覧表示中にセッション操作を完結させる
- Claude Code hooks で AI エージェント状態をファイルに書き出し、セッション一覧に表示する
- レイアウトテンプレートは smug を採用し、セッション作成時に自動適用する

**出典**:

- [ADR: workspace CLI の技術選定と設計方針](../adr/2026-04-08-workspace-cli-design.md)

---

## 決定事項

| 項目                       | 決定                                     | 備考                                                                                 |
| -------------------------- | ---------------------------------------- | ------------------------------------------------------------------------------------ |
| コマンド名                 | **`workspace`（エイリアス: `ws`）**      | 既存 `tm` は Phase 1 で削除（後述）                                                  |
| 実装言語                   | **zsh**                                  | バックエンド言語不要                                                                 |
| 対話 UI                    | **fzf**                                  | `--bind` + `reload` で複数アクション                                                 |
| レイアウト                 | **smug**                                 | `.smug.yml` で宣言的定義                                                             |
| AI 状態取得                | **Claude Code hooks → ファイル書き出し** | `$TMPDIR/ws-state/` 配下                                                             |
| 通知ロジック               | **`workspace-notify` に集約**            | スタンドアロンスクリプト（後述）                                                     |
| ファイル配置（zsh 関数）   | **`config/zsh/lazy/workspace.zsh`**      | 対話的エントリポイント                                                               |
| ファイル配置（スクリプト） | **`config/zsh/bin/`**                    | fzf/tmux/hooks から呼ぶロジック                                                      |
| PATH 登録                  | **`config/zsh/eager/path.zsh` に追加**   | `$XDG_CONFIG_HOME/zsh/bin` を PATH へ                                                |
| セッション一覧の初期表示   | **既存セッションのみ**                   | `ctrl-g` でリポジトリ一覧に切替                                                      |
| アクティブセッション削除時 | **tmux が別セッションに自動切替**        | `detach-on-destroy previous` を `tmux.conf` に追加（デフォルトはデタッチ）           |
| worktree セレクタ          | **`workspace wt` サブコマンドに統合**    | `<prefix> W` も維持                                                                  |
| gwt.zsh との関係           | **共存**                                 | gwt は worktree 操作（cd/rm/prune）に特化、workspace wt は tmux セッション作成に特化 |

---

## 仕様: サブコマンド体系

```zsh
# 命令的（直接実行）※ ws は workspace のエイリアス
workspace switch <session>        # セッション切替
workspace new <repo>              # セッション新規作成（smug 自動適用）
workspace new --bare <name>       # 素のセッション作成
workspace delete <session>        # セッション削除
workspace rename <old> <new>      # セッションリネーム
workspace wt                      # git worktree からセッション作成

# 対話的（引数なしで fzf 起動）
workspace list                    # → fzf でセッション一覧（フルインタラクティブ）
workspace                         # → workspace list のエイリアス
workspace switch                  # → fzf でセッション選択
workspace new                     # → fzf で ghq リポジトリ選択
workspace wt                      # → fzf で worktree 選択
```

## 仕様: fzf 一覧の表示フォーマット

### セッション一覧（デフォルト表示）

```text
● my-app (main) [active]  🤖 ai claude waiting
  other-project (feature/xxx)
● api-server (develop)    🤖 ai codex done
  docs (main)
```

| 要素                    | 表示条件                   | 用途           |
| ----------------------- | -------------------------- | -------------- |
| `●`                     | AI 状態変化がある場合      | 視認用バッジ   |
| セッション名            | 常時                       | 識別           |
| `(branch)`              | git リポジトリの場合       | ブランチ確認   |
| `[active]`              | 現在アタッチ中のセッション | アクティブ状態 |
| `🤖 ai <name> <status>` | AI エージェント稼働中のみ  | AI 状態表示    |

### フィルタ用テキストラベル

fzf の通常入力でフィルタリング可能:

| 入力               | 絞り込み対象            |
| ------------------ | ----------------------- |
| `ai`               | AI 使用中の全セッション |
| `claude` / `codex` | 特定 AI のセッション    |
| `waiting` / `done` | AI 状態で絞り込み       |
| `active`           | アクティブなセッション  |

### リポジトリ一覧（ctrl-g で切替）

ghq 管理下のリポジトリをフラットに表示。選択すると:

- 既存セッションがあれば → セッションに切替
- なければ → 新規作成（`.smug.yml` があれば自動適用）

### fzf 操作

| キー     | アクション                                       | 実装方式                                                                                                     |
| -------- | ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| `Enter`  | セッション切替（リポジトリモード: 作成 or 切替） | `accept` or `become`                                                                                         |
| `Ctrl-d` | セッション削除（確認なし）+ 一覧 reload          | `execute-silent` + `reload`（[fzf#3347](https://github.com/junegunn/fzf/issues/3347): execute 内 read 不可） |
| `Ctrl-n` | 素のセッション作成 → 接続                        | `become`（fzf を抜ける）                                                                                     |
| `Ctrl-r` | セッションリネーム + 一覧に戻る                  | fzf 終了 → シェル側 `read` → リネーム → ループで fzf 再起動（execute 内 read 不可の回避策）                  |
| `Ctrl-g` | セッション一覧 / リポジトリ一覧のトグル          | `transform` + `reload`                                                                                       |

## 仕様: AI エージェント状態の管理

### 状態ファイル

- パス: `${TMPDIR:-/tmp}/ws-state/<ai>_<session>`（セッションごと、上書き）
- AI 名と セッション名の区切りは `_`（アンダースコア）を使用する。`-` はセッション名に頻出するため曖昧になる。**制約: AI 名にアンダースコアは使用不可**（ファイル名の分割で壊れるため）
- `$TMPDIR` を使用する理由: macOS ではユーザー固有の一時ディレクトリ（`/var/folders/...`）であり、他ユーザーと衝突せず、再起動で自動消去される
- macOS の `$TMPDIR` は末尾 `/` 付きのため `${TMPDIR%/}/ws-state` で結合する
- 内容: `<status>:<timestamp>`（例: `idle:1712345678`）
- `end` 時はファイル削除

### Claude Code hooks → 状態ファイル

| Hook イベント                    | workspace-notify 呼び出し                           |
| -------------------------------- | --------------------------------------------------- |
| `PreToolUse` (matcher なし)      | 状態ファイルが存在すれば削除（idle/waiting の解消） |
| `Stop`                           | `workspace-notify state $SESSION claude idle`       |
| `Notification` (`""`: 全通知)    | `workspace-notify state $SESSION claude waiting`    |
| `SessionEnd` (prompt_input_exit) | `workspace-notify state $SESSION claude end`        |

### 状態遷移と通知の設計

`running` 状態は明示的に管理しない。`idle`/`waiting` の表示が残ったまま処理が再開される問題を、`PreToolUse` hook での状態ファイル削除で解消する。

**検討経緯**:

1. **timestamp 推定方式（初期案）**: `ws-list-sessions` が「idle の timestamp が 5 秒以上前」を `running` と推定 → 放置と区別できないため却下
2. **running 状態の明示管理**: `PreToolUse` で `running` を書き出し → ファイルが残り続けるため毎回 cat + 比較が必要。ファイル削除方式の方がシンプル
3. **attached ガード**: 同一セッションにいる場合は hooks をスキップ → `Notification` 後に応答せず別セッションに移動するとき `waiting` が記録されない問題が発生するため却下
4. **採用案: 全 hook 常時書き出し + PreToolUse でファイル削除**: 全パターンで不整合なし

**状態遷移**:

```text
                    ┌─────────────────────────────────┐
                    │       ファイルなし (非表示)        │
                    └──┬──────────┬──────▲──▲──▲──▲───┘
                       │          │      │  │  │  │
                  SessionEnd  Claude起動  │  │  │  │
                  (常に削除)  (初期状態)   │  │  │  │
                       │          │      │  │  │  │
                       ▲          ▼      │  │  │  │
┌──────────────────────┴──┐    ┌─┴──┴──┴──┴────────┐
│   waiting (● バッジ)     │    │  idle (● バッジ)    │
│   Notification で上書き   │    │  Stop で上書き      │
└─────┬───────────▲───────┘    └──┬──────▲─────────┘
      │           │               │      │
      │     Notification          │    Stop
      │           │               │      │
      └───────────┼──── Stop ────►┘      │
                  └── Notification ──────┘

削除トリガー（→ ファイルなし）:
  - PreToolUse: ファイルがあれば削除
  - SessionEnd: 常に削除
  - セッション切替: 状態ファイル削除（既読化）
```

**パフォーマンス**: `PreToolUse` は全ツール呼び出しで発火するが、状態ファイルは `idle`/`waiting` 時のみ存在する。大半の呼び出しは `[[ ! -f ]]` の stat 1回で即終了するため影響は最小限。

**`rm` の安全性**: hooks は bash で実行されるため、zsh の `gomi` エイリアスは影響しない。また `PreToolUse` の `matcher: "Bash"` による `rm` ブロック hook は Claude Code の Bash ツール使用時のみ発火し、hook 自身のプロセスには適用されない。

### 通知ファイル

- パス: `${TMPDIR:-/tmp}/ws-state/notifications-<session>`（セッションごとに分離）
- 形式: 1行1通知（`time:message`）
- セッション切替時に tmux hook で該当ファイルを削除（既読化）
- セッション分離により `send`（append）と `read`（削除）の race condition を大幅に軽減

### workspace-notify インターフェース

```zsh
workspace-notify state <session> <ai> <status>   # AI 状態を書き出す（上書き）
workspace-notify send <session> <message>         # 通知を追記
workspace-notify read <session>                   # 該当セッションの通知を既読（削除）
workspace-notify rename <old> <new>               # セッションリネーム時に状態・通知ファイルを追従
workspace-notify badge                            # 全セッション横断の未読数を返す（ステータスバー用: "● N"）
workspace-notify clear                            # 全消し
```

---

## 設計: アーキテクチャ

fzf の `reload`/`execute` は `$SHELL -c`（本環境では zsh）で新プロセスを起動し、tmux `run-shell` は `/bin/sh`、Claude Code hooks はデフォルトで `bash` を使用する（hook handler の `shell` フィールドで変更可）。いずれも Sheldon で lazy-load された zsh 関数にアクセスできない。

> **制約**: fzf `execute` 内では対話入力（`read` 等）が動作しない。fzf が `/dev/tty` を占有するため（[junegunn/fzf#3347](https://github.com/junegunn/fzf/issues/3347) で作者が明言）。対話入力が必要な操作は fzf を終了してシェル側で処理し、ループで fzf に戻る構造とする。

そのため、外部プロセスから呼ばれるロジックは**スタンドアロンスクリプト**に切り出す：

| 配置先                            | 役割                                       | 呼び出し元                                          |
| --------------------------------- | ------------------------------------------ | --------------------------------------------------- |
| `config/zsh/bin/ws-list-sessions` | セッション一覧のフォーマット出力           | fzf `reload`                                        |
| `config/zsh/bin/ws-connect-repo`  | ghq リポジトリからセッション作成 or 切替   | fzf `become`                                        |
| `config/zsh/bin/workspace-notify` | AI 状態・通知管理                          | fzf `execute`, tmux `run-shell`/`#()`, Claude hooks |
| `config/zsh/lazy/workspace.zsh`   | 対話的エントリポイント + 補完              | ユーザーの対話的シェル                              |
| ↳ `workspace-session()`           | サブコマンド処理（`workspace.zsh` 内関数） | `workspace()` から呼び出し                          |

> **前提**: `config/zsh/bin/` は `config/zsh/eager/path.zsh` の `path=()` に登録して PATH に含める。

## 設計: workspace コマンド本体

```zsh
# config/zsh/lazy/workspace.zsh

workspace() {
  local subcmd="${1:-list}"
  shift 2>/dev/null

  case "$subcmd" in
    list)     workspace-session list "$@" ;;
    switch)   workspace-session switch "$@" ;;
    new)      workspace-session new "$@" ;;
    delete)   workspace-session delete "$@" ;;
    rename)   workspace-session rename "$@" ;;
    wt)       workspace-session wt "$@" ;;
    notify)   workspace-notify "$@" ;;
    *)        workspace-session list ;;
  esac
}

alias ws='workspace'

_workspace() {
  local -a commands
  commands=(
    'list:Session list (interactive)'
    'switch:Switch session'
    'new:Create new session'
    'delete:Delete session'
    'rename:Rename session'
    'wt:Create session from git worktree'
    'notify:Notification management'
  )
  _describe -t commands 'workspace commands' commands
}
compdef _workspace workspace
compdef _workspace ws
```

## 設計: ws-list-sessions スクリプト

```zsh
#!/usr/bin/env zsh
# config/zsh/bin/ws-list-sessions
# fzf reload から呼ばれるスタンドアロンスクリプト

state_dir="${TMPDIR%/}/ws-state"

# tmux セッション不在の状態ファイルを cleanup（kill -9 等で SessionEnd 未発火時の救済）
if [[ -d "$state_dir" ]]; then
  sessions=(${(f)"$(tmux list-sessions -F '#{session_name}' 2>/dev/null)"})
  for f in "$state_dir"/*_*(N); do
    fname="$(basename "$f")"
    [[ "$fname" == notifications-* ]] && continue
    sess="${fname#*_}"
    if (( ! ${sessions[(Ie)$sess]} )); then
      rm -f "$f"
    fi
  done
fi

tmux list-sessions -F "#{session_name}" 2>/dev/null | while IFS= read -r session; do
  ai_label=""
  for state_file in "$state_dir"/*_"$session"(N); do
    [[ -f "$state_file" ]] || continue
    ai_name="${$(basename "$state_file")%_$session}"
    IFS=: read -r status timestamp < "$state_file"
    now=$(date +%s)
    if [[ "$status" == "idle" && $((now - timestamp)) -gt 5 ]]; then
      status="running"
    fi
    ai_label+="🤖 ai $ai_name $status "
  done

  notify_file="$state_dir/notifications-${session}"
  count=0
  [[ -f "$notify_file" ]] && count=$(wc -l < "$notify_file" | tr -d ' ')

  branch=""
  session_path=$(tmux display-message -t "$session" -p '#{pane_current_path}' 2>/dev/null)
  [[ -n "$session_path" ]] && branch=$(git -C "$session_path" branch --show-current 2>/dev/null)

  active=""
  attached=$(tmux display-message -t "$session" -p '#{session_attached}' 2>/dev/null)
  [[ "$attached" -gt 0 ]] && active="[active] "

  badge=""
  [[ $count -gt 0 || -n "$ai_label" ]] && badge="● "
  printf "%s%s (%s) %s%s\n" "$badge" "$session" "${branch:-?}" "$active" "$ai_label"
done
```

## 設計: workspace-session

```zsh
# config/zsh/lazy/workspace.zsh 内の関数

workspace-session() {
  local subcmd="${1:-list}"
  shift 2>/dev/null

  # fzf は表示と選択に専念し、対話入力（read）はシェル側で処理する。
  # fzf execute 内では read が動作しないため（junegunn/fzf#3347）。
  # ctrl-r（リネーム）は fzf を抜けてシェルで read → ループで fzf に戻る。
  case "$subcmd" in
    list)
      while true; do
        local selected
        selected=$(ws-list-sessions | fzf --ansi --reverse \
          --prompt "session> " \
          --header "enter:switch  ctrl-d:delete  ctrl-n:new  ctrl-r:rename  ctrl-g:repos" \
          --expect "ctrl-r" \
          --bind "ctrl-d:execute-silent(
            session=\$(echo {} | sed 's/^● //' | awk '{print \$1}');
            count=\$(tmux list-sessions 2>/dev/null | wc -l);
            [[ \$count -le 1 ]] && exit 0;
            tmux kill-session -t \"\$session\"
          )+reload(ws-list-sessions)" \
          --bind "ctrl-n:become(
            printf 'Session name: ';
            read -r name;
            [[ -n \"\$name\" ]] && tmux new-session -d -s \"\$name\" && tmux switch-client -t \"\$name\"
          )" \
          --bind "ctrl-g:transform:[[ \$FZF_PROMPT == session* ]] &&
            echo 'reload(ghq list)+change-header(enter:create  ctrl-g:sessions)+change-prompt(repo> )' ||
            echo 'reload(ws-list-sessions)+change-header(enter:switch  ctrl-d:delete  ctrl-n:new  ctrl-r:rename  ctrl-g:repos)+change-prompt(session> )'" \
          --bind "enter:transform:[[ \$FZF_PROMPT == repo* ]] &&
            echo 'become(ws-connect-repo {})' ||
            echo 'accept'")

        # --expect で ctrl-r が押された場合: 1行目がキー名、2行目が選択行
        local key line
        key=$(echo "$selected" | head -1)
        line=$(echo "$selected" | tail -1)

        if [[ "$key" == "ctrl-r" && -n "$line" ]]; then
          local session
          session=$(echo "$line" | sed 's/^● //' | awk '{print $1}')
          printf 'Rename "%s" to: ' "$session"
          read -r name
          if [[ -n "$name" ]]; then
            tmux rename-session -t "$session" "$name"
            workspace-notify rename "$session" "$name"
          fi
          continue  # ループで fzf に戻る
        fi

        [[ -z "$line" ]] && return
        local session_name
        session_name=$(echo "$line" | sed 's/^● //' | awk '{print $1}')
        workspace-session switch "$session_name"
        break
      done
      ;;
    switch)
      if [[ -n "$1" ]]; then
        if ! tmux has-session -t "$1" 2>/dev/null; then
          echo "Session not found: $1" >&2
          return 1
        fi
        if [[ -n "$TMUX" ]]; then
          tmux switch-client -t "$1"
        else
          tmux attach-session -t "$1"
        fi
      else
        local selected
        selected=$(ws-list-sessions | fzf --ansi --reverse --header "Select session")
        [[ -z "$selected" ]] && return
        local name
        name=$(echo "$selected" | sed 's/^● //' | awk '{print $1}')
        if [[ -n "$TMUX" ]]; then
          tmux switch-client -t "$name"
        else
          tmux attach-session -t "$name"
        fi
      fi
      ;;
    new)
      if [[ "$1" == "--bare" ]]; then
        local name="${2:?Session name required}"
        tmux new-session -d -s "$name"
        if [[ -n "$TMUX" ]]; then
          tmux switch-client -t "$name"
        else
          tmux attach-session -t "$name"
        fi
      elif [[ -n "$1" ]]; then
        local dir
        dir="$(ghq root)/$1"
        [[ ! -d "$dir" ]] && dir="$(ghq root)/$(ghq list | grep -E "/$1$" | head -1)"
        [[ ! -d "$dir" ]] && echo "Repository not found: $1" && return 1
        ws-connect-repo --name "$(basename "$dir")" --dir "$dir"
      else
        local repo
        repo=$(ghq list | fzf --reverse --header "Select repository")
        [[ -z "$repo" ]] && return
        local dir="$(ghq root)/$repo"
        ws-connect-repo --name "$(basename "$repo")" --dir "$dir"
      fi
      ;;
    delete)
      local session="${1}"
      if [[ -z "$session" ]]; then
        session=$(tmux list-sessions -F "#{session_name}" | fzf --reverse --header "Delete session")
      fi
      [[ -z "$session" ]] && return
      local count
      count=$(tmux list-sessions 2>/dev/null | wc -l)
      if [[ $count -le 1 ]]; then
        echo "Cannot delete the last session"
        return 1
      fi
      read -q "?Delete session '$session'? [y/N] " || return
      echo
      tmux kill-session -t "$session"
      local state_dir="${TMPDIR%/}/ws-state"
      rm -f "$state_dir"/*_"$session" "$state_dir/notifications-$session"
      ;;
    rename)
      local old="${1}" new="${2}"
      [[ -z "$old" || -z "$new" ]] && echo "Usage: workspace rename <old> <new>" && return 1
      tmux rename-session -t "$old" "$new"
      workspace-notify rename "$old" "$new"
      ;;
    wt)
      local selected dir name
      selected=$(git worktree list 2>/dev/null | grep -v "$(pwd)" | fzf --reverse --header "Select worktree")
      [[ -z "$selected" ]] && return
      dir=$(echo "$selected" | awk '{print $1}')
      name=$(basename "$dir")
      ws-connect-repo --name "$name" --dir "$dir"
      ;;
  esac
}
```

## 設計: ws-connect-repo スクリプト

```zsh
#!/usr/bin/env zsh
# config/zsh/bin/ws-connect-repo
# セッション接続の共通ロジック（唯一の実装）
# 呼び出し元: fzf become, workspace-session
#
# 使い方:
#   ws-connect-repo <ghq-repo-path>          # ghq リポジトリパスから接続
#   ws-connect-repo --name <name> --dir <dir> # 名前とディレクトリを直接指定

typeset -A opts
zparseopts -A opts -D -- -name: -dir:

if [[ -n "${opts[--name]}" ]]; then
  name="${opts[--name]}" dir="${opts[--dir]}"
else
  repo="$1"
  [[ -z "$repo" ]] && exit 1
  dir="$(ghq root)/$repo"
  [[ ! -d "$dir" ]] && exit 1
  name="$(basename "$repo")"
fi

if tmux has-session -t "$name" 2>/dev/null; then
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$name"
  else
    tmux attach-session -t "$name"
  fi
else
  if [[ -n "$dir" && -f "$dir/.smug.yml" ]] && command -v smug >/dev/null 2>&1; then
    smug_name=$(grep '^session:' "$dir/.smug.yml" | awk '{print $2}' | tr -d "\"'")
    if smug start -f "$dir/.smug.yml"; then
      name="${smug_name:-$name}"
    else
      tmux new-session -d -c "$dir" -s "$name"
    fi
  else
    tmux new-session -d -c "${dir:-.}" -s "$name"
  fi
  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$name"
  else
    tmux attach-session -t "$name"
  fi
fi
```

## 設計: workspace-notify スクリプト

```bash
#!/usr/bin/env bash
# config/zsh/bin/workspace-notify
# スタンドアロンスクリプト: bash/sh/zsh いずれからも呼べる
# 呼び出し元: Claude Code hooks (bash), tmux run-shell, fzf execute ($SHELL -c)

subcmd="${1}"
shift 2>/dev/null
state_dir="${TMPDIR%/}/ws-state"
mkdir -p "$state_dir"

case "$subcmd" in
  state)
    session="$1" ai="$2" status="$3"
    [[ -z "$session" ]] && exit 0
    state_file="$state_dir/${ai}_${session}"
    if [[ "$status" == "end" ]]; then
      rm -f "$state_file"
    else
      echo "${status}:$(date +%s)" > "$state_file"
    fi
    ;;
  send)
    session="$1" message="$2"
    echo "$(date +%H:%M):${message}" >> "$state_dir/notifications-${session}"
    ;;
  read)
    session="$1"
    rm -f "$state_dir/notifications-${session}"
    ;;
  rename)
    old="$1" new="$2"
    [[ -z "$old" || -z "$new" ]] && exit 0
    for f in "$state_dir"/*_"$old"; do
      [[ -e "$f" ]] || continue
      mv "$f" "${f%_$old}_$new"
    done
    [[ -f "$state_dir/notifications-$old" ]] && mv "$state_dir/notifications-$old" "$state_dir/notifications-$new"
    ;;
  badge)
    count=0
    for f in "$state_dir"/notifications-*; do
      [[ -e "$f" ]] || continue
      c=$(wc -l < "$f" | tr -d ' ')
      count=$((count + c))
    done
    [[ $count -gt 0 ]] && echo "● $count"
    ;;
  clear)
    rm -f "$state_dir"/notifications-*
    rm -f "$state_dir"/*
    ;;
esac
```

## 設計: Claude Code hooks 拡張

Claude Code hooks はイベント種別を環境変数で渡さない（stdin JSON の `hook_event_name` で取得可能だが、本設計では使用しない）。イベント種別は `settings.json` の登録セクション（`Stop`, `Notification` 等）で決まるため、`notify.sh` にロジックを混在させず、`settings.json` の各 hook セクションから `workspace-notify` を直接呼ぶ。

```jsonc
// config/claude/settings.json の hooks セクションに追加
// 構造: hooks → [Event] → [Matcher Groups] → [Handlers]（3階層ネスト必須）
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          /* 既存: 危険コマンドブロック */
        ],
      },
      {
        "hooks": [
          {
            "type": "command",
            "command": "state_file=\"${TMPDIR%/}/ws-state/claude_$(tmux display-message -p '#{session_name}' 2>/dev/null)\"; [[ -f \"$state_file\" ]] && rm -f \"$state_file\"; exit 0",
          },
        ],
      },
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/notify.sh 'Task Completed!'",
          },
          {
            "type": "command",
            "command": "[[ -n \"$TMUX\" ]] && ~/.config/zsh/bin/workspace-notify state \"$(tmux display-message -p '#{session_name}')\" claude idle",
          },
        ],
      },
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/notify.sh 'Awaiting Confirmation...'",
          },
          {
            "type": "command",
            "command": "[[ -n \"$TMUX\" ]] && ~/.config/zsh/bin/workspace-notify state \"$(tmux display-message -p '#{session_name}')\" claude waiting",
          },
        ],
      },
    ],
    "SessionEnd": [
      {
        "matcher": "prompt_input_exit",
        "hooks": [
          {
            "type": "command",
            "command": "[[ -n \"$TMUX\" ]] && ~/.config/zsh/bin/workspace-notify state \"$(tmux display-message -p '#{session_name}')\" claude end",
          },
        ],
      },
    ],
  },
}
```

> **注 1**: `workspace-notify` はフルパス（`~/.config/zsh/bin/workspace-notify`）で呼び出す。Claude Code hooks は bash で実行されるため、zsh の PATH 設定（`$XDG_CONFIG_HOME/zsh/bin`）が適用されない。`Stop` は matcher 非対応（常に発火）のため `matcher` フィールドを省略している。
>
> **注 2**: `PreToolUse` に matcher なしの hook を追加し、状態ファイルが存在すれば削除する。既存の `matcher: "Bash"`（危険コマンドブロック）とは別の matcher group として共存する。`PreToolUse` hook 内の `rm -f` は hook 自身のプロセスで実行されるため、既存の Bash ツール用 `rm` ブロック hook の影響を受けない。
>
> **注 3**: `Notification` の matcher を空文字（全マッチ）としている。matcher 値は `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog` の4種。`auth_success` で `waiting` になるのは厳密には不正確だが、発火頻度が極めて低いため全マッチで許容する。

## 設計: tmux.conf 拡張

```bash
# config/tmux/tmux.conf: <prefix> T/R を workspace に差し替え（Phase 1）
# popup 内でインタラクティブ zsh を起動し workspace list を実行
# popup 内シェルなので read も正常動作し、fzf ループ構造も機能する
# セッション破棄時に直前のセッションへ自動切替（デフォルトはデタッチ）
set -g detach-on-destroy previous

bind-key "T" display-popup -E -w 60% -h 60% "zsh -ic 'workspace list'"
bind-key "R" display-popup -E -w 70% -h 70% "zsh -ic 'workspace new'"

# config/tmux/tmux.conf に追加（Phase 2）

# workspace-notify: セッション切替時に既読化
set-hook -g client-session-changed 'run-shell "workspace-notify read #{session_name}"'

# workspace-notify: ステータスバーにバッジ表示
# "#(workspace-notify badge)" を既存の status-right の先頭に挿入
```

## 設計: ステータスバー変更

```bash
# config/tmux/tmux.conf の status-right を変更
set -g status-right "#(workspace-notify badge) #[fg=#{TN_CYAN}] #(cd \"#{pane_current_path}\" && basename \"$(git rev-parse --show-toplevel 2>/dev/null)\" 2>/dev/null) #[default]#(gitmux -cfg ~/.config/gitmux/gitmux.conf \"#{pane_current_path}\")"
```

---

## 実装手順

### Phase 1: セッション管理の拡張

- [x] 1-0: `config/zsh/bin/` ディレクトリを新規作成
- [x] 1-1: `config/zsh/eager/path.zsh` の `path=()` に `"$XDG_CONFIG_HOME/zsh/bin"(N-/)` を追加
- [x] 1-2: `config/zsh/bin/ws-list-sessions` を新規作成（`chmod +x`）
- [x] 1-3: `config/zsh/bin/ws-connect-repo` を新規作成（`chmod +x`）
- [x] 1-4: `config/zsh/lazy/workspace.zsh` を新規作成（`workspace`, `workspace-session`, 補完関数）
- [x] 1-5: サブコマンド実装（`list`, `switch`, `new`, `delete`, `rename`, `wt`）
- [x] 1-6: fzf 対話モード実装（`ctrl-d`: `execute-silent`+`reload`, `ctrl-r`: `expect`+シェルループ, `ctrl-n`: `become`, `ctrl-g`: `transform`+`reload`）
- [x] 1-7: 既存の tmux.conf の `<prefix> T/R` バインドを `display-popup -E "zsh -ic 'workspace list'"` に差し替え。`<prefix> W`（worktree セレクタ）は据え置き（`detach-on-destroy previous` も追加）
- [x] 1-8: `config/zsh/lazy/tmux.zsh` を削除（gomi でゴミ箱に移動）
- [x] 1-9: `git add` して `! drs`（新規ファイルのため）
- [x] 1-10: 動作検証（`ws-list-sessions` の出力確認済み。対話的検証はユーザーに委任）

### Phase 2: AI 状態表示 + 通知バッジ

- [x] 2-1: `config/zsh/bin/workspace-notify` を新規作成（bash, `chmod +x`）
- [x] 2-2: `config/claude/settings.json` の hooks に workspace-notify 呼び出しを追加（Stop, Notification, SessionEnd）
- [x] 2-3: `config/tmux/tmux.conf` に `client-session-changed` hook を追加
- [x] 2-4: `config/tmux/tmux.conf` の `status-right` にバッジ表示を追加（status-right-length を 120 に拡張）
- [x] 2-5: `ws-list-sessions` に AI 状態・バッジ表示を統合（Phase 1 で作成済み）
- [x] 2-6: 動作検証（workspace-notify の state/send/badge/clear 動作確認済み。hooks の実稼働検証はユーザーに委任）
- [x] 2-7: `PreToolUse` hook を追加（状態ファイルが存在すれば削除し、idle/waiting 表示を解消）
- [x] 2-8: `ws-list-sessions` から timestamp 推定ロジックを削除
- [x] 2-9: `workspace-notify read` で状態ファイルも削除（既読化）
- [x] 2-10: hooks の `workspace-notify` をフルパスに変更（2-2 で対応済み）
- [x] 2-11: 動作検証（waiting 表示→ファイル削除で解消、idle+通知→read で両方削除を確認）

### Phase 3: レイアウトテンプレート連携

- [x] 3-1: `nix/home/packages/shell.nix` に smug を追加（smug-0.3.17）
- [x] 3-2: `git add` して `! drs`（smug 0.3.17 追加確認）
- [x] 3-3: `ws-connect-repo` の `.smug.yml` 検知・`smug start` 呼び出しは Phase 1 で実装済み
- [x] 3-4: dotfiles リポジトリに `.smug.yml` を作成（editor + shell の2ウィンドウ構成）
- [x] 3-5: 動作検証（`ws new dotfiles` → smug テンプレートで editor + shell の2ウィンドウ自動作成を確認）

---

## 予実差異

### Phase 1

- `ws-list-sessions` に AI 状態表示ロジックを Phase 1 の時点で含めた（Plans では Phase 2 で統合予定だったが、スクリプト全体を一括作成したため前倒し）
- `<prefix> W`（worktree）は Plans 通り据え置き

### Phase 2

- `status-right-length` を 100 → 120 に拡張（バッジ追加による表示幅増加に対応。Plans には明記なし）

### Phase 3

- `.smug.yml` は dotfiles リポジトリのみ作成（Plans では「1-2個」、1個で十分と判断）
- 予実差異なし（それ以外）

---

## 変更対象ファイル一覧

| ファイル                          | Phase 1                                                                   | Phase 2                                  | Phase 3   |
| --------------------------------- | ------------------------------------------------------------------------- | ---------------------------------------- | --------- |
| `config/zsh/eager/path.zsh`       | `zsh/bin` を PATH に追加                                                  | -                                        | -         |
| `config/zsh/bin/ws-list-sessions` | 新規作成（セッション一覧出力スクリプト）                                  | AI 状態・バッジ表示統合                  | -         |
| `config/zsh/bin/ws-connect-repo`  | 新規作成（リポジトリ→セッション接続）                                     | -                                        | -         |
| `config/zsh/bin/workspace-notify` | -                                                                         | 新規作成（通知管理スクリプト）           | -         |
| `config/zsh/lazy/workspace.zsh`   | 新規作成（workspace, workspace-session, 補完）                            | -                                        | -         |
| `config/zsh/lazy/tmux.zsh`        | 削除（機能は workspace に統合）                                           | -                                        | -         |
| `config/tmux/tmux.conf`           | `<prefix> T/R` を workspace に差し替え、`detach-on-destroy previous` 追加 | hook 追加、status-right にバッジ         | -         |
| `config/claude/settings.json`     | -                                                                         | hooks に workspace-notify 呼び出しを追加 | -         |
| `nix/home/packages/shell.nix`     | -                                                                         | -                                        | smug 追加 |
| 各リポジトリの `.smug.yml`        | -                                                                         | -                                        | 新規作成  |
