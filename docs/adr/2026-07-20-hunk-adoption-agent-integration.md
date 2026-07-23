# Hunk 導入とエージェント連携アーキテクチャ

Date: 2026-07-20
Status: Accepted

## Context

Agent（Claude Code）が書く変更のレビュー体験を強化したい。現状の diff 閲覧は delta（lazygit の内蔵 pager `delta --dark --paging=never` と git `core.pager`）と lazygit / diffview.nvim に閉じており、AI が書いたコードを腰を据えてレビューし、指摘をその場に残せる場がない。

[Hunk](https://www.hunk.dev/)（[modem-dev/hunk](https://github.com/modem-dev/hunk)、MIT）は "review-first terminal diff viewer for agentic coders"。対話 TUI・side-by-side・watch に加え、ローカル daemon（`127.0.0.1:47657`）越しに agent が**ライブのレビュー画面へインライン注釈**を書ける（`hunk session comment`）点が既存ツールにない価値である。

一方で制約と前提がある:

- delta（Rust・非対話フィルタ）は lazygit のインライン色付けに最適で置き換え不要。Hunk を lazygit の captured pager にすると split 未対応・Bun 起動コストで劣化する。
- Neovim では [sidekick.nvim](https://github.com/folke/sidekick.nvim) で Claude を起動しており、multiplexer は herdr へ移行済み（[ADR: tmux から Herdr への移行](./2026-07-05-tmux-to-herdr-migration.md)）。
  sidekick の herdr mux backend は [#333](https://github.com/folke/sidekick.nvim/pull/333) が未マージで、Claude は nvim split 内＝herdr の agent 検知外にある。

この前提で「Hunk を導入するか / delta とどう共存するか / Claude との連携をどう実現するか / どのセッションモデルで運用するか / Hunk をどこに配置するか」を一括で決める。

## Decision

### 1. Hunk を review 専用 viewer として導入し、delta とは役割分担で共存する

| 観点                 | delta 単独維持   | Hunk で pager 置換       | 共存（採用）            |
| -------------------- | ---------------- | ------------------------ | ----------------------- |
| lazygit インライン   | **最適（Rust）** | split 非対応・起動が重い | **delta 据え置き**      |
| 対話レビュー         | 非対話（less）   | 対話 TUI                 | **Hunk が担当**         |
| AI インライン注釈    | ❌               | ✅                       | **✅（Hunk）**          |
| side-by-side         | ✅（git config） | captured pager では ❌   | delta ✅ / Hunk 単体 ✅ |
| 日常 `git diff` 体感 | 軽い             | Bun 起動で重い           | **無変更**              |

- delta は lazygit の非対話フィルタ（`--paging=never`）として最適・軽量で side-by-side 済み。`core.pager` / lazygit `pagers` は**据え置き**（[Hunk lazygit 連携でも captured pager は split 未対応](https://zander.wtf/blog/lazygit-with-hunk/)）
- Hunk は「腰を据えたレビュー + AI 注釈」の**専用画面**として追加し、pager の役割は持たせない

### 2. Claude→Hunk 連携は `hunk session` CLI + SKILL.md 経路とする（MCP 登録ではない）

| 観点       | MCP server 登録          | CLI + skill（採用）                  | `--agent-context` JSON |
| ---------- | ------------------------ | ------------------------------------ | ---------------------- |
| 標準準拠   | 要 MCP transport         | 不要（普通のシェル実行）             | 不要                   |
| ライブ制御 | —                        | **可（session daemon 経由）**        | ❌（事前生成のみ）     |
| 導入コスト | daemon は MCP 標準でない | **`hunk skill path` を読ませるだけ** | JSON 生成が要る        |

- `hunk mcp serve` / `HUNK_MCP_PORT` という名前はあるが命名だけで、daemon の実体は `127.0.0.1:47657` の **HTTP/JSON 内部 API**（`curl .../session-api`）であり MCP プロトコルではない → `.mcp.json` には載せない
- 公式の agent 連携は [`hunk skill path`](https://github.com/modem-dev/hunk/blob/main/docs/agent-workflows.md) が返す `skills/hunk-review/SKILL.md` を読ませ、`hunk session review / comment / navigate / reload` で live session を操作する方式
- `--agent-context` は事前生成注釈用（ライブ制御なし）。ライブ注釈が主目的なので **CLI + skill を採用**

### 3. sidekick と Hunk-review Claude は別セッションで運用する

| 観点             | 会話 resume ブリッジ                 | 別セッション（採用）                | mux-attach 共有         |
| ---------------- | ------------------------------------ | ----------------------------------- | ----------------------- |
| 事故りやすさ     | cwd/`--mcp-config` 整合が必要        | **結合なし**                        | —                       |
| 同時ライブ性     | ❌（引き継ぎ型、二重 resume で交錯） | 独立2セッション                     | ✅（同一 live process） |
| レビューの独立性 | 著者バイアスを引き継ぐ               | **独立レビュアー（diff のみ見る）** | 引き継ぐ                |
| 実現時期         | 今                                   | **今**                              | #333 待ち               |

- Claude Code の会話 session は per-project 保存。`claude -c` / `--resume` は**別プロセスが同一 session に追記を続ける引き継ぎ**であり、同一会話の同時ライブ共有ではない（同一 session を2端末で resume すると transcript に両者の発言が交錯するため、公式も並行作業には `--fork-session` を推奨している）
- 別セッションなら会話結合が消え、レビュー側は diff だけ見る**独立レビュアー**になる（著者バイアス排除。Hunk の "review-first" 思想と合致）
- 「同一 live Claude を sidekick と herdr で真に共有」は multiplexer 層の話で [#333](https://github.com/folke/sidekick.nvim/pull/333) 待ち。別セッションはこれと**前方互換**

### 4. Hunk は on-demand で開く（lazygit customCommands + herdr `[[keys.command]]` popup）

| 観点           | nvim 内ネスト   | 常駐 review tab                   | on-demand popup（採用）                  |
| -------------- | --------------- | --------------------------------- | ---------------------------------------- |
| TUI 操作性     | 二重 TUI で窮屈 | 独立した全画面                    | **独立した popup（90%）**                |
| herdr との結合 | —               | tab 運用・多重生成ガードが要る    | **`[[keys.command]]` 1エントリのみ**     |
| セッション規律 | —               | 1 repo = 1 セッションの運用が要る | **都度1つで規律不要**                    |
| 注釈の寿命     | —               | プロセス常駐で保持                | 開いている間（閉じたら Claude が再適用） |

- sidekick の Claude は nvim split 内で herdr の agent 検知外（[herdr ADR](./2026-07-05-tmux-to-herdr-migration.md) の既知制約）。Hunk を nvim にネストすると二重 TUI で操作性が悪い
- 開き方は lazygit `customCommands`（`H`）と herdr `[[keys.command]]`（popup。lazygit / btop と同じ既存パターン）の2導線に絞る。常駐 tab の多重生成ガードやセッション規律が不要になり、herdr との結合が最小で済む
- popup は command 終了で閉じるため、注釈の寿命は開いている間になる見込み。閉じた後に読み返す場合は review Claude に `comment apply` を再実行させる（指摘は Claude の context にあり再適用は安価）
- 腰を据えた往復レビューが要る時だけ、手動で tab に `hunk diff --watch` を立てて常駐させる（config 変更不要のためいつでも選べる）
- Claude↔Hunk 制御は daemon 越しなので、multiplexer / session 境界に依存しない。#333 マージ後は sidekick の Claude を herdr pane 化して統合でき、本決定と非競合

## Consequences

- delta の lazygit 統合・`core.pager` は無変更のまま、Hunk が「対話レビュー + AI 注釈」を上乗せする。Hunk は Bun ランタイム依存だが pager には使わないため日常の `git diff` 体感に影響はなく、撤退も Hunk 除去だけで現状復帰できる
- Hunk は lazygit `H` または herdr `prefix+shift+h`（popup）から on-demand で開き、閉じれば消える。注釈もセッション限りの見込みのため、読み返しは review Claude に `comment apply` を再実行させる。往復レビューを長く続ける時だけ手動で tab に `hunk diff --watch` を立てる（config 不要）
- Claude が `hunk session comment` で自分の変更へインライン注釈でき、レビュー往復が diff 上で完結する。review Claude は herdr pane で直接動くため herdr のネイティブ検知で状態可視化される（nvim split 補完用の `report-herdr-state.sh` フックも pane 内でそのまま動作する）
- authoring（sidekick）と review（herdr pane の別 Claude）は独立。ただし working tree / git は共有のため**同時編集は不可**（片方を idle にする運用規律が要る）
- daemon は MCP プロトコル対応でないため `.mcp.json` は変更しない。将来 hunk が正式な MCP server を提供したら登録へ格上げする余地がある
- Hunk は pre-1.0（v0.x）。flake を tag pin し、API churn 時は追随が要る（herdr 同様に bump 自動化の余地）
