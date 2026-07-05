# workspace

ghq リポジトリから herdr workspace を起動する sheldon プラグイン。
workspace の一覧・切替・リネーム・削除は herdr native picker（`prefix+w`）に委譲する。

## 依存ツール

| ツール | 必須 | 用途                      |
| ------ | ---- | ------------------------- |
| herdr  | yes  | workspace / worktree 管理 |
| fzf    | yes  | 対話的選択 UI             |
| ghq    | yes  | リポジトリパス解決        |
| jq     | yes  | herdr CLI の JSON パース  |

## サブコマンド

| コマンド                | 用途                                                                                      |
| ----------------------- | ----------------------------------------------------------------------------------------- |
| `workspace new [repo]`  | workspace 起動（デフォルト）。同 label があれば focus、なければ ghq リポジトリから create |
| `workspace wt [branch]` | worktree 作成 + workspace 起動（`herdr worktree create` 委譲）                            |
| `workspace wt-rm`       | worktree と紐付く workspace を削除（`herdr worktree remove` 委譲）                        |
| `workspace notify ...`  | 旧 tmux 構成の Claude hooks 互換 no-op スタブ（hooks 撤去時に削除予定）                   |

## 呼び出し元

| 呼び出し元        | コマンド                                  |
| ----------------- | ----------------------------------------- |
| シェル            | `ws`（zabrze abbreviation → `workspace`） |
| Claude Code hooks | `workspace notify ...`（互換スタブ）      |

## レイアウト管理（旧 smug）の方針

- workspace の復元は herdr 内蔵の session 永続化が担う（`herdr server` 再起動後も復元される）
- 旧 `.smug.yml` は editor/shell の 2 window 定義のみで herdr の復元で用が足りるため廃止
- 定型レイアウトの一括起動が将来必要になったら、自作前に herdr layout / 先行 plugin（herdr-spreader 等）を評価する
