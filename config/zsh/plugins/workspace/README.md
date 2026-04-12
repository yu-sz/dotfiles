# workspace

tmux セッション管理の sheldon プラグイン。セッションの作成・切替・削除と、Claude Code の AI 状態追跡を提供する。

## サブコマンド

### 対話操作

| コマンド                       | 用途                                       |
| ------------------------------ | ------------------------------------------ |
| `workspace list`               | セッション一覧 + fzf 対話 UI（デフォルト） |
| `workspace switch [name]`      | セッション切替                             |
| `workspace new [repo]`         | セッション作成（ghq + smug 対応）          |
| `workspace delete [session]`   | セッション削除                             |
| `workspace rename <old> <new>` | セッションリネーム                         |
| `workspace wt`                 | git worktree からセッション作成            |

### 状態管理（Claude Code hooks / tmux から呼ばれる）

| コマンド                              | 用途                         |
| ------------------------------------- | ---------------------------- |
| `workspace notify idle`               | AI アイドル状態を記録        |
| `workspace notify waiting`            | AI 確認待ち状態を記録        |
| `workspace notify end`                | AI 状態をクリア              |
| `workspace notify clear-state`        | state ファイル削除           |
| `workspace notify read [session]`     | 通知を既読化                 |
| `workspace notify rename <old> <new>` | リネーム時の状態ファイル追従 |

### データ生成（fzf --bind から呼ばれる）

| コマンド                        | 用途                               |
| ------------------------------- | ---------------------------------- |
| `workspace list-sessions`       | セッション一覧のフォーマット出力   |
| `workspace connect-repo <path>` | リポジトリからセッション作成・接続 |

## 呼び出し元

| 呼び出し元               | コマンド                                  |
| ------------------------ | ----------------------------------------- |
| tmux `prefix+T`          | `workspace list`                          |
| tmux `prefix+R`          | `workspace new`                           |
| tmux `prefix+W`          | `workspace wt`                            |
| tmux hook (session 切替) | `workspace notify read #{session_name}`   |
| Claude Code PreToolUse   | `workspace notify clear-state`            |
| Claude Code Stop         | `workspace notify idle`                   |
| Claude Code Notification | `workspace notify waiting`                |
| Claude Code SessionEnd   | `workspace notify end`                    |
| fzf reload               | `workspace list-sessions`                 |
| fzf become               | `workspace connect-repo {}`               |
| シェル                   | `ws`（zabrze abbreviation → `workspace`） |

## 状態ファイル

`$TMPDIR/ws-state/` に一時ファイルとして管理（再起動で自動消去）。

- `claude_<session>` — AI 状態（`idle:timestamp` or `waiting:timestamp`）
- `notifications-<session>` — 通知メッセージ（未使用）
