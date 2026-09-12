---
name: hunk-review
description: ライブの Hunk セッションを使ってレビューし、diff にインライン注釈を残す。Use when reviewing changes in an open `hunk diff` / `hunk show` session.
---

# Hunk Review

起動中の Hunk セッションへ注釈を書き込む際の手順とハウスルール。

## 手順

1. `hunk skill path` を実行し、返ったパスの `SKILL.md` を読んでコマンド仕様を把握する
2. セッションは `--repo .` で解決する（同一 repo に複数ウィンドウがある場合のみ位置引数 `<session-id>` で指定）
3. まず `hunk session review --repo . --json` で現在の diff 状態を把握する（`--include-patch` は必要時のみ）
4. 注釈は `hunk session comment apply --repo . --stdin` で一括投入し、重要指摘は `--focus` で該当行へジャンプさせる
5. さらに編集したら `hunk session reload --repo . -- diff` で再読込する

## ハウスルール

- 注釈は日本語。要点（リスク / 修正提案）を先頭に置く
- **レビュー中はファイルを編集しない**（authoring 側の sidekick セッションと working tree を共有するため）。修正が要る場合は指摘に留め、実装は別途
- 明白でない指摘には根拠（該当行・影響）を添える
