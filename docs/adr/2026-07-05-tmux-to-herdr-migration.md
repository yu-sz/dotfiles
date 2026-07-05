# tmux から Herdr への移行と sketchybar 同期のイベント駆動化

Date: 2026-07-05
Status: Accepted

## Context

tmux を土台にした自作基盤（`workspace` CLI + sketchybar）で運用しており、Herdr の目玉「エージェント状態の可視化」は既に実現済みである（Claude Code hooks → 状態ファイル → sketchybar 色表示）。ただし現構成には弱点がある:

- 状態源が Claude hooks + 5 秒ポーリングで、hook に fire 遅延（[claude-code#19627](https://github.com/anthropics/claude-code/issues/19627)、未修正）があり Claude 専用
- gitmux / TPM / smug など tmux 依存部品が多い

[Herdr](https://herdr.dev/) はエージェント状態をネイティブ検知して workspace へ rollup し、socket イベントで push する。sketchybar 同期をこれへ置き換えれば上記を解消でき全エージェントに対応する。ただし Herdr はプラグインでなくマルチプレクサ本体（＝自作基盤の置き換え）かつ pre-1.0 でもある。

そのため中核機構（Herdr のイベントで sketchybar を更新できるか）を実機で検証したうえで、Herdr の導入と sketchybar 同期方式・既存資産の扱いを定める。

## Decision

結論として、以下を決定する:

- **Herdr を唯一のマルチプレクサとして導入し、tmux を置き換える**（並行運用は採らない）。
- **状態同期を Herdr のイベント駆動（plugin `[[events]]`）へ置き換える**（実機検証済み）。
- **tmux 依存資産（`workspace` CLI・smug・gitmux・TPM・Claude 状態 hook）を Herdr へ委譲／廃止する**。

導入後に残る確認は「Herdr が実エージェントの状態遷移を正しく検知するか」「Neovim 実行時の表示・キー操作の使用感」の 2 点で、いずれも上記設計の可否は左右しない。

### 移行方針

| 観点                          | 現状維持 (tmux)                   | Herdr 全面移行                        | tmux + Herdr 並行 |
| ----------------------------- | --------------------------------- | ------------------------------------- | ----------------- |
| エージェント状態の品質        | 自作 hook（遅延あり・Claude限定） | **ネイティブ rollup・全エージェント** | 二重管理          |
| sketchybar 同期               | poll + file + tmux hook           | **socket イベント駆動**               | 2系統を追う       |
| 部品数                        | 多い                              | **削減**                              | 増える            |
| copy-mode-vi / キーボード完結 | **維持**                          | **維持**（prefix + vi copy-mode）     | 併存              |
| 成熟度                        | **15年の実績**                    | pre-1.0                               | —                 |
| 複雑性                        | —                                 | 単一系統                              | **悪化**          |

- 並行運用は workspace CLI が tmux しか知らず、sketchybar が2系統を追い、Herdr のネスト実行（`allow_nested`）も experimental なため複雑性が悪化する → **却下**
- Herdr は pre-1.0 だが、状態同期の中核機構は実機で検証済み（下記）。残る確認は実エージェントの検知精度と Neovim 使用感に限られる

**決定**: Herdr を唯一のマルチプレクサとして導入する。

### sketchybar 同期方式

| 観点             | 現状 (poll+file+hook) | plugin イベント方式（採用）          | 常駐 socket daemon 方式 |
| ---------------- | --------------------- | ------------------------------------ | ----------------------- |
| 駆動             | 5秒ポーリング         | **イベント push**                    | イベント push           |
| プロセス寿命管理 | —                     | **Herdr が管理**                     | 自前（launchd 等）      |
| 実装量           | 既存                  | **小（manifest + 数行）**            | 中（接続/再接続/購読）  |
| 取りこぼし耐性   | poll で吸収           | ペイロードに status 同梱で再取得不要 | 自前で状態保持          |

- Herdr は plugin の `[[events]]` 宣言でイベント毎にプラグイン実行体を起動し、`command` に任意 argv（`sketchybar --trigger`）を指定できる。常駐 daemon が不要
- 実機検証: `workspace.created`/`closed` で plugin command が発火（exit 0・約 6ms）し、`HERDR_PLUGIN_EVENT_JSON` に workspace の `agent_status` が同梱される。状態取得の再クエリも不要

**決定**: plugin の `[[events]]` で `sketchybar --trigger` を発火する方式を採用する（実機検証済み）。常駐 daemon 方式は不要。

### 既存資産の扱い

| 資産                        | 決定                                                                          |
| --------------------------- | ----------------------------------------------------------------------------- |
| `workspace` CLI             | Herdr の workspace/worktree に委譲し **ghq→workspace 生成の薄いラッパへ縮小** |
| smug (`.smug.yml`)          | **廃止**、Herdr layout で代替                                                 |
| gitmux / TPM                | **廃止**（Herdr 内蔵 UI・永続化で代替）                                       |
| Claude 状態 hook (ws-state) | sketchybar 用途では **廃止**、Herdr ネイティブ検知へ委譲                      |

## Consequences

- Claude hook の fire 遅延（#19627）・5秒ポーリング・ws-state ファイルプラミングを撤廃でき、状態源が Herdr の権威ある検知に一本化される（Claude 以外のエージェントも対応）
- gitmux / TPM / smug / 状態 hook を削除でき部品総数は純減する。追加は薄いブリッジ1つ
- キーボード完結ワークフローは維持される（prefix モデル + `prefix+[` の vi copy-mode で hjkl / v / y 選択）。ただし既定キーマップは tmux と一部異なり（split は `v` / `-` 等）、`ctrl+v` の画像ペースト干渉（[#647](https://github.com/ogulcancelik/herdr/issues/647)）は `--remote` 時のみで `remote_image_paste=""` で回避できる。既定は prefix-first のため nvim の直接キー（`<c-.>` 等）とは衝突しない
- Neovim 連携は Sidekick の herdr mux backend（[sidekick.nvim#333](https://github.com/folke/sidekick.nvim/pull/333)、未マージ）に委ねる。マージまでは agent を nvim split で起動（その agent は herdr の状態可視化対象外）し、DIY の `pane send-text` は作らない。nvim 実行時の undercurl 描画等は導入時に検証する
- ブリッジが pre-1.0 API の継ぎ目となり、`herdr-plugin.toml` の `min_herdr_version` 固定と flake input の version pin が必要。API churn 時は追随が要る
- ライセンスは AGPL-3.0。個人 dotfiles での利用は問題ないが、herdr を改変して外部サービスに組み込み配布する場合は commercial license を要確認
- 本決定により [ADR: workspace CLI](./2026-04-08-workspace-cli-design.md) の smug 採用・AI 状態取得方式は **Partially Superseded** となる。撤退が必要になれば flake input / config を除去して現状復帰できる
