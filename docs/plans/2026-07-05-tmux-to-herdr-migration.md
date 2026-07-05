# tmux → Herdr 移行と sketchybar イベント駆動同期 実装計画

## 概要

- Herdr を唯一のマルチプレクサとして導入する（sketchybar 同期の中核機構は実機とソースで検証済み）
- sketchybar 同期を `tmux ls` + ws-state ファイル + 5秒ポーリングから、Herdr plugin の `[[events]]` によるイベント駆動へ置き換える
- ターミナル内 UI と通知トーストは Herdr に委譲する
- `workspace` CLI は Herdr の workspace/worktree に委譲して ghq ラッパへ縮小、smug / gitmux / TPM / Claude 状態 hook を廃止する
- Herdr は nixpkgs 未収録のため flake input として追加する

**出典**:

- [ADR: tmux から Herdr への移行と sketchybar 同期のイベント駆動化](../adr/2026-07-05-tmux-to-herdr-migration.md)

---

## 要件定義（完成形の仕様）

完成形が満たすべき要件。各項目は受け入れ基準（検証可能）として扱う。

### 機能要件

#### FR-1 マルチプレクサ基盤

- Herdr を単一のマルチプレクサとして常用する（tmux は起動しない）
- prefix=`ctrl+g`、pane 移動=`prefix+h/j/k/l`、分割=`prefix+v`/`prefix+-`、copy=`prefix+[` の vi copy-mode（hjkl/v/y）
- テーマは Tokyo Night（`tokyo-night`）
- detach/reattach でき、マシン再起動後も workspace が復元される（TPM resurrect/continuum 相当を内蔵で代替）
- lazygit / btop を overlay pane で起動（`prefix+shift+l` / `prefix+shift+b`。alt は AeroSpace が占有するため不可）

#### FR-2 エージェント状態可視化（sketchybar）

- menu bar に workspace 単位でエージェント状態（`blocked`/`working`/`done`/`idle`/`unknown`）を色表示する
- 状態反映は **イベント駆動**（5秒ポーリング・状態ファイル・tmux hook を全廃）
- 状態源は Herdr のネイティブ検知。Claude 以外のエージェントにも効く。検知が不十分なら `herdr pane report-agent` で補完できる
- herdr 未起動時は非表示（他の menu bar 項目を壊さない）

#### FR-3 ワークスペース / worktree 管理

- ghq リポジトリを選んで workspace を起動でき、label は repo 名に自動命名される
- workspace の一覧 / 切替 / 削除 / リネームができる
- git worktree をブランチ単位で作成 / 削除できる
- （未決）fzf UX の維持か Herdr native picker（`prefix+w`）採用かは Phase 3 で判断

#### FR-4 通知

- エージェントの完了 / 要対応をトーストで通知する（`[ui.toast] delivery = "herdr"`）

#### FR-5 Neovim 連携

- Sidekick の送信（`<leader>at/af/av`）/ NES / prompt が従来どおり機能する
- [sidekick.nvim#333](https://github.com/folke/sidekick.nvim/pull/333) マージ後は agent を herdr pane で起動し、herdr の状態可視化対象になる
- nvim の直接キー（`<c-.>` 等）と herdr の既定キーが衝突しない

#### FR-6 日本語入力

- CJK IME 下で prefix 入力・IME 候補ウィンドウ追従が破綻しない（`[experimental]` の IME 設定）

### 非機能要件

- **部品削減**: gitmux / TPM / smug / Claude 状態 hook を撤去する
- **単一系統**: tmux との並行運用をしない
- **Nix 管理**: flake overlay 経由の `pkgs.herdr`、config は XDG symlink（`config/herdr`）
- **再現性**: herdr は v0.7.1 を pin（pre-1.0 のため）

### 受け入れ基準（Definition of Done）

- [ ] tmux を起動せず日常運用（リポ切替・worktree・複数エージェント）が回る（tmux 本体は除去済みのため構造上は充足。実運用での継続確認のみ）
- [x] menu bar が working→blocked をポーリングなしで即時反映する（Phase 2 で機構検証、hook 自動発火も 4-8 で実機確認）
- [x] 主要リポで workspace 作成 / 切替 / worktree 作成が動作する（Phase 3-4 で確認）
- [x] `herdr server` 再起動後に workspace が復元される（事前検証で実測済み）
- [x] nvim を herdr pane で動かして描画・キー操作が破綻しない（1-8。undercurl のみ upstream 修正待ちで平坦下線）
- [x] 旧構成（`config/tmux`・gitmux・TPM・ws-state hook）が撤去され `nrs` が通る（Phase 4 + nrs 実行で確認）

### スコープ外 / 非目標

- tmux `display-popup` の floating popup 完全再現（overlay pane で代替）
- Sidekick の herdr 対応そのもの（上流 #333 のマージに依存）
- smug `.smug.yml` の完全互換（レイアウトは Herdr layout で再設計）

---

## 決定事項

| 項目             | 決定                                                                                                                  | 備考                                                                                                                                                                                                                      |
| ---------------- | --------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 導入方式         | **flake input `github:ogulcancelik/herdr/v0.7.1`**                                                                    | nixpkgs 未収録。version を tag で pin                                                                                                                                                                                     |
| sketchybar 同期  | **plugin `[[events]]` → `sketchybar --trigger`**                                                                      | workspace 系は実機で発火確認（exit 0・約 6ms）。`pane.agent_status_changed` も v0.7.1 の `PLUGIN_HOOK_EVENT_KINDS` に含まれ dispatch される（ソース確認）。ペイロードに `agent_status` 同梱で再取得不要、常駐 daemon 不要 |
| snapshot 取得    | **`herdr workspace list`（CLI が JSON 直接返却、nc 不要）**                                                           | `.result.workspaces[].agent_status`。helper 一行の出力まで実測確認                                                                                                                                                        |
| status 値        | **`idle` / `working` / `blocked` / `done` / `unknown` の 5 値**                                                       | `herdr agent wait --status idle\|working\|blocked\|done\|unknown`。`done`（完了）も配色対象に含める                                                                                                                       |
| prefix           | **`ctrl+g`**                                                                                                          | 現 tmux の C-g を踏襲（Herdr default は ctrl+b）                                                                                                                                                                          |
| theme            | **`tokyo-night`**                                                                                                     | Herdr 内蔵。`reload-config` で妥当性確認済み                                                                                                                                                                              |
| 通知トースト     | **`[ui.toast] delivery = "herdr"`**                                                                                   | ターミナル内トーストを Herdr に委譲                                                                                                                                                                                       |
| pane 移動        | **`prefix+h/j/k/l`**                                                                                                  | vim 風。navigate-mode の素キー `j`/`k` も併用可                                                                                                                                                                           |
| popup 代替       | **`[[keys.command]]` type=pane（lazygit=`prefix+shift+l`／btop=`prefix+shift+b`）**                                   | floating popup は無く overlay pane で近似。alt+\* は AeroSpace が OS レベルで占有（実機発覚）、g=goto/b=toggle_sidebar/shift+g=new_worktree も使用中のため shift+l/shift+b へ                                             |
| workspace CLI    | **ghq→`herdr workspace` の薄いラッパへ縮小**                                                                          | worktree は Herdr へ委譲。`--cwd` 指定で label が repo 名に自動命名される（実測）ため命名ロジック不要                                                                                                                     |
| smug             | **廃止**                                                                                                              | Herdr layout で代替。自作前に先行 plugin（herdr-spreader 等）を評価                                                                                                                                                       |
| gitmux / TPM     | **廃止**                                                                                                              | Herdr 内蔵 UI・永続化で不要                                                                                                                                                                                               |
| Claude 状態 hook | **sketchybar 用途では廃止**                                                                                           | 状態源を Herdr ネイティブ検知へ一本化。検知が弱い場合は `herdr pane report-agent` で明示報告できる                                                                                                                        |
| Neovim 連携      | **Sidekick の herdr mux backend に委譲（[sidekick.nvim#333](https://github.com/folke/sidekick.nvim/pull/333) 待ち）** | マージまで `mux.enabled=false`（agent は nvim split・herdr 状態外）。DIY `pane send-text` は作らない                                                                                                                      |

---

## 検証済み事項（実測）

`brew install herdr`（v0.7.1）で導入し、headless server + CLI で以下を実測確認済み。実行後はサーバ停止・生成物削除で痕跡なし。

| 事項                   | 実測結果                                                                                                                                                                                                                                                  |
| ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| config.toml 妥当性     | 下記 config で `herdr server reload-config` が `diagnostics:[] / applied`（警告・エラーゼロ）                                                                                                                                                             |
| キーバインド衝突       | lazygit/btop を `prefix+alt+g/b` にした構成で診断ゼロ（`prefix+g`=goto 等との衝突を回避）                                                                                                                                                                 |
| plugin イベント発火    | `[[events]]` on `workspace.created`/`closed` で command が発火、`exit_code:0 / succeeded`、起動〜終了 **約 6ms**。`pane.agent_status_changed` も v0.7.1 の dispatch 対象（`PLUGIN_HOOK_EVENT_KINDS` をソース確認、高頻度の `pane.output_matched` は除外） |
| イベントペイロード     | `HERDR_PLUGIN_EVENT_JSON` に workspace オブジェクト丸ごと（`workspace_id`/`label`/`agent_status`）を同梱                                                                                                                                                  |
| snapshot 出力          | `herdr workspace list \| jq -r '.result.workspaces[] \| "\(.label)\t\(.agent_status)"'` → `dotfiles<TAB>unknown`                                                                                                                                          |
| workspace 自動命名     | `herdr workspace create --cwd <repo>`（label 省略）で `label` が repo 名（`dotfiles`）に自動設定                                                                                                                                                          |
| worktree CLI           | `herdr worktree list/create/remove --cwd --branch` が実 repo で動作（`repo_name`/`branch`/`path` を返す）                                                                                                                                                 |
| 状態の明示報告 API     | `herdr pane report-agent <pane_id> --source <id> --agent <label> --state idle\|working\|blocked\|unknown`（`--source`/`--agent` も必須。検知フォールバックに使える）                                                                                      |
| socket / named session | 既定 `~/.config/herdr/herdr.sock`、named は `~/.config/herdr/sessions/<name>/herdr.sock`                                                                                                                                                                  |
| セッション永続性       | `herdr server stop`→再起動後も workspace が復元（TPM resurrect/continuum を代替）                                                                                                                                                                         |
| Nix 導入経路           | herdr flake の `overlays.default` を `sharedOverlays` へ足し `pkgs.herdr` で参照（`inputs` 配線不要）                                                                                                                                                     |

**導入時に確認する残件（非ゲート。実エージェント／対話 TTY が必要で headless では検証不能）**:

- 実 claude の working→blocked で Herdr が `pane.agent_status_changed` を emit するか（検知精度）。dispatch 機構は v0.7.1 ソースで確認済み（`PLUGIN_HOOK_EVENT_KINDS` に同イベント在中）のため残件は検知のみ。弱ければ Claude hook から `herdr pane report-agent` を叩けば同イベントが emit され同経路で sketchybar を更新できる（polling 不要）
- nvim を herdr pane で動かした際の LSP 診断 undercurl 描画・clipboard 自動コピー
- prefix / vi copy-mode（`prefix+[`）等のキーボード主観使用感

---

## 設計: Nix 導入（overlay 経由）

herdr flake は `overlays.default`（nixpkgs overlay）を公開しており（`nix flake show` で確認）、既存の `sharedOverlays` に足せば `pkgs.herdr` で参照できる。現状 home モジュールへ `inputs` は渡していないが、overlay 経由なら **inputs 配線は不要**。なお package は Rust をソースビルドするため、brew での事前検証と異なり初回 `nrs` は aarch64-darwin のビルド時間を要する。

```nix
# flake.nix の inputs に追加
inputs.herdr = {
  url = "github:ogulcancelik/herdr/v0.7.1";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

```nix
# flake.nix の sharedOverlays に1行追加
sharedOverlays = [
  inputs.nix-claude-code.overlays.default
  (import ./nix/overlays)
  inputs.herdr.overlays.default # ← 追加
];
```

```nix
# nix/home/packages/editor.nix の home.packages に追加（tmux と同じ共有パッケージ。overlay 経由で herdr が使える）
herdr
```

---

## 設計: config.toml

`herdr server reload-config` で `diagnostics:[]`（警告ゼロ）を実機確認済み。

```toml
# config/herdr/config.toml → ~/.config/herdr/config.toml (symlink)

[theme]
name = "tokyo-night"

[keys]
prefix = "ctrl+g"
new_tab = "prefix+c"
focus_pane_left = "prefix+h"
focus_pane_down = "prefix+j"
focus_pane_up = "prefix+k"
focus_pane_right = "prefix+l"

# lazygit=prefix+shift+l / btop=prefix+shift+b。
# alt+* は AeroSpace（tiling WM）が OS レベルで全部奪うため使用不可（実機で発覚）。
# 平打ち g=goto / b=toggle_sidebar / shift+g=new_worktree も使用中のため shift+l/shift+b を採用。
[[keys.command]]
key = "prefix+shift+l"
type = "pane"
command = "lazygit"
description = "run lazygit"

[[keys.command]]
key = "prefix+shift+b"
type = "pane"
command = "btop"
description = "run btop"

[ui.toast]
delivery = "herdr"

[ui]
mouse_capture = true

# 日本語 IME 対策（実測: config スキーマに存在、macOS 向け）。
# Claude Code / codex の TUI で IME 候補ウィンドウ追従と prefix 入力の
# 取りこぼしを緩和する。experimental のため使用感で取捨する。
[experimental]
reveal_hidden_cursor_for_cjk_ime = true
cjk_ime_agents = ["claude", "codex"]
switch_ascii_input_source_in_prefix = true
```

> `split_vertical = "prefix+v"` / `split_horizontal = "prefix+minus"` など必要な bind は適宜追加する。

---

## 設計: sketchybar 同期ブリッジ

Herdr plugin がイベント毎に `sketchybar --trigger herdr_update` を発火する。sketchybar 側は現 `tmux.lua` を `herdr.lua` に置換し、`herdr_update` を購読して再描画する（ポーリング撤廃）。

```toml
# config/herdr/plugins/sketchybar-sync/herdr-plugin.toml
# 実測: [[events]] の on は単一イベント名。イベント毎に宣言する（配列は使わない）。
id = "sketchybar-sync"
name = "sketchybar sync"
version = "0.1.0"
min_herdr_version = "0.7.0"
platforms = ["macos"]

[[events]]
on = "pane.agent_status_changed"
command = ["sketchybar", "--trigger", "herdr_update"]

[[events]]
on = "workspace.created"
command = ["sketchybar", "--trigger", "herdr_update"]

[[events]]
on = "workspace.closed"
command = ["sketchybar", "--trigger", "herdr_update"]

[[events]]
on = "workspace.renamed"
command = ["sketchybar", "--trigger", "herdr_update"]
```

```zsh
#!/usr/bin/env zsh
# config/sketchybar/helpers/herdr-ws-snapshot
# workspace 単位に `label<TAB>status` を出力する。
# `herdr workspace list` の JSON を jq で整形する（nc / raw socket 不要）。
# 導入時に既定 stdout が JSON か（`worktree list` は明示 --json を持つ）、
# envelope が `.result.workspaces[]` かを実出力で確認してから固定する。
herdr workspace list \
  | jq -r '.result.workspaces[] | "\(.label)\t\(.agent_status)"'
```

`config/sketchybar/items/herdr.lua` は現 `tmux.lua` からの差し替え。主な変更点:

- セッション列挙 `TMUX .. " ls -F ..."` → helper `herdr-ws-snapshot` の実行
- `read_state()`（ws-state ファイル読み）を削除し、helper が返す status を直接 `STATE_COLOR` へマップ
- `STATE_COLOR = { blocked=red, working=yellow, done=green, idle=blue, unknown=fg_dark }`（`agent_status` は 5 値。`done` を落とすと完了エージェントが unknown 色になるため必ず含める。色は現行 tmux.lua 踏襲で調整可）
- `handler:subscribe({ "routine", "forced", "tmux_change" })` + `update_freq=5` → `herdr_update` 購読のみ。`pane.agent_status_changed` は working↔idle で頻発しうるため再描画は軽く debounce する（保険の低頻度 poll は任意）
- SLOT_COUNT / bracket / slot 制御ロジックはそのまま流用

---

## 実装手順

> 事前検証は完了済み（[検証済み事項](#検証済み事項実測)）。以下は導入本番の手順。

### Phase 1: Herdr 導入とベース設定

- [x] 1-1: `flake.nix` の inputs に `herdr`（v0.7.1 pin）を追加
- [x] 1-2: `flake.nix` の `sharedOverlays` に `inputs.herdr.overlays.default` を追加
- [x] 1-3: `nix/home/packages/editor.nix` の `home.packages` に `herdr` を追加（共有パッケージ）
- [x] 1-4: `config/herdr/config.toml` を上記設計どおり作成
- [x] 1-5: `nix/home/symlinks.nix` の `xdg.configFile` に `"herdr".source = mkLink "config/herdr";` を追加

> **予実差異（1-3 配置変更）**: 計画は `pkgs.herdr` を `nix/home/darwin.nix`（macOS 限定）に置く想定だったが、置換対象の `tmux`/`gitmux`/`smug` がいずれも共有パッケージ（`nix/home/packages/{editor,shell}.nix`）にあり配置が不整合。
> herdr 本体も flake が `aarch64-linux`/`x86_64-linux` を提供する（実測）ため、`nix/home/packages/editor.nix`（tmux と同じ）へ配置し macOS + Linux 共有とした。sketchybar/IME 等の macOS 固有部分は従来どおり macOS 限定に留まる。config/herdr の symlink は既に共有ブロックにあり整合。
>
> **予実差異（1-4）**: 設計ノートに従い FR-1 要件の分割キー（`split_vertical = "prefix+v"` / `split_horizontal = "prefix+minus"`）を config.toml に併せて追加した。
>
> **予実差異（1-6 で発覚 → `.gitignore` 追加）**: herdr は runtime 状態を **config ディレクトリ**（`~/.config/herdr/session.json`・`*.sock`）に書き込む。`~/.config/herdr` はリポジトリ `config/herdr` への直リンクのため、herdr 実行のたびに working tree が汚れる。計画に未記載の論点。
> 対処として `config/herdr/.gitignore`（whitelist: `config.toml`・`plugins/**` のみ追跡、他は無視）を追加。`agent-detection`/plugin 状態は `~/.local/state/herdr/` でリポ外のため対象外。
>
> **予実差異（herdr が Claude 統合を自動インストール → gitignore 対応）**: herdr 起動時、`[session] resume_agents_on_restore=true`（既定）で Claude 公式統合を自動インストール。
> `~/.claude/hooks/herdr-agent-state.sh`（`pane.report_agent_session` を報告＝FR-2 の状態源候補）と `~/.claude/settings.json` の `SessionStart` フックを書き込む。両パスはリポジトリ symlink のため repo が書き換わった（settings.json はキー並べ替え＋末尾改行落ちも発生）。
> スクリプトは herdr 管理・バージョン連動・再生成可のため `config/claude/hooks/.gitignore`（`herdr-*.sh`）で追跡除外。settings.json のフック登録のみ追跡。統合自体は Phase 2 で使うため維持。
>
> **予実差異（1-7 で発覚 → overlay キー変更）**: `prefix+alt+g/b`（lazygit/btop）が実機で無反応。原因は **AeroSpace（tiling WM）が `alt+*` を OS レベルで占有**（`config/aerospace/aerospace.toml` に `alt-a`〜`alt-r`/`alt-h/j/k/l`/`alt-1..9` 等）。headless の `reload-config` では診断ゼロだったが WM 実機で発覚。
> `alt` を捨て `prefix+shift+l`=lazygit / `prefix+shift+b`=btop へ変更（平打ち `g`=goto・`b`=toggle_sidebar・`shift+g`=new_worktree は既定使用中のため回避）。それ以外の prefix/theme/splits/pane 移動/永続化は実機で動作良好。
>
> **予実差異（sidekick × tmux 発見 → tmux 撤去前倒し）**: `mux.enabled=false` は sidekick 本体で新規セッションを terminal に強制する（`cli/session/init.lua:82`）が、tmux バックエンドは**無条件登録**され既存 tmux セッションを常時列挙する（`M.setup` ハードコード、`enabled`/`backend` と無関係）。
> そのため裏で生きている tmux サーバ "default"（Ghostty の `tmux new-session -s default` 由来）を拾い `[tmux:default]` として掴んでしまい pane が壊れる。config の `backend` 変更では直らず、third-party 改変は非推奨。→ **根治は tmux 撤去そのもの**（Phase 4）。
> **herdr をまともにテストするには tmux から抜ける必要があるため、Phase 4 の「Ghostty 起動コマンド herdr 化 + tmux サーバ停止」を前倒しする方針に決定**。
>
> **Phase 4 向けメモ（端末統合・計画未記載）**: GUI 端末が2つとも multiplexer 相当になっており herdr と `ctrl+g`・split/pane 役割が衝突する。要方針決定（1-7 検証時に発覚、ユーザー判断は保留）。
>
> - `nix/home/programs/ghostty.nix:35`: `tmux attach || tmux new-session` → **`herdr` へ変更済み（Phase 4 から前倒し実施）**。クイック端末=素 zsh と `ghostty +boo` は温存。反映は `! nrs` 後。
> - `config/wezterm/keymaps.lua:5,118`: WezTerm の `leader = ctrl+g` + split/pane/tab keymap が herdr の prefix を全面横取り（`ctrl+g` が herdr に届かない）。→ **解決（ユーザー決定）**: WezTerm では組み込みマルチプレクサを使い続けるため herdr の実行対象外。衝突は考慮不要で keymap 変更もしない（herdr は Ghostty 側で常用）。
> - 検証自体は `ctrl+g` を横取りしない端末（macOS Terminal.app / Ghostty クイック端末）で実施可能。ただし Terminal.app は truecolor/undercurl 非対応のため 1-8 の描画確認は WezTerm/Ghostty で行う。

- [x] 1-6: `git add` 後 `! nrs` で反映（herdr-0.7.1 ビルド成功・`hm_herdr` symlink 追加・brew 版は `No such keg` で除去確認。実機 config で `reload-config` が `diagnostics:[]/applied`）
- [x] 1-7: prefix(`ctrl+g`)/theme(tokyo-night)/分割/pane 移動/overlay(`shift+l`/`shift+b`) を実機で動作確認。toast は Phase 2（実 agent）で確認
- [x] 1-8: nvim を herdr pane で起動 — 基本描画 / clipboard / `<c-.>`(Sidekick toggle) 疎通OK。**undercurl のみ herdr VT 既知バグ（#894/#895・PR #900）で当面 平坦下線**（stable 未収録。後続タスク参照）
- [x] 1-9: 「普通に動作」報告に含む（重大な破綻なし）。copy-mode(`prefix+[`) の個別使用感は未詳細のため必要なら後日調整

### Phase 2: sketchybar イベント駆動同期

- [x] 2-1: `config/herdr/plugins/sketchybar-sync/herdr-plugin.toml` を作成（上記設計、per-event `[[events]]`）
- [x] 2-2: `herdr workspace list` の実出力で既定フォーマット（JSON か）と jq パスを確定し、`config/sketchybar/helpers/herdr-ws-snapshot` を作成・実行権限付与（既定 stdout が JSON・`.result.workspaces[]` を実出力で再確認。sketchybar launchd の最小 PATH 対策で per-user profile bin を script 内で prepend）
- [x] 2-3: `herdr plugin link` でプラグインを登録し、状態変化で `herdr_update` が発火することを確認（workspace created/closed で `exit_code:0 / succeeded` 約10ms。server PATH で plain `sketchybar` が解決）
- [x] 2-4: `config/sketchybar/items/herdr.lua` を作成（`tmux.lua` を差し替え、helper 駆動・ポーリング撤廃。`update_freq` なし・`forced`+`herdr_update` 購読のみ、in_flight/dirty 合流で debounce）
- [x] 2-5: `config/sketchybar/items/init.lua` の `require("items.tmux")("left")` を `require("items.herdr")("left")` に差し替え（reload 後、初回 reconcile・`herdr_update` トリガ経由の再描画とも実機確認）
- [x] 2-6: 実 claude を working→blocked と遷移させ menu bar が push で即時更新されることを確認。検知が弱ければ Claude の Stop/Notification hook から `herdr pane report-agent <pane_id> --source claude --agent <label> --state <state>` を叩き、同イベント経由で sketchybar を更新する（全チェーン実機確認・hook fallback 実装。詳細は下記予実差異）

> **予実差異（2-6: ネイティブ検知は現構成では効かない → hook fallback を標準経路に昇格）**: claude は Sidekick の **nvim split 内**で動くため（3-5 の既知制約）、herdr の前面プロセス検知は nvim しか見えず `herdr agent list` も空。公式統合（SessionStart→`pane.report_agent_session`）も稼働中セッションには未反映だった。
> 対処として `config/claude/hooks/report-herdr-state.sh` を新設（`HERDR_ENV`/`HERDR_PANE_ID` ガード付き、herdr 管理の `herdr-*.sh` とは別ファイルなので追跡対象）し、settings.json に UserPromptSubmit/PostToolUse→`working`・Notification(permission_prompt)→`blocked`・Stop→`idle`・SessionEnd→`unknown` を配線。
> claude が herdr pane 直下でなく nvim 内でも `HERDR_PANE_ID` 継承で正しい pane に帰属する。report-agent → event → trigger → helper → 再描画の全チェーンで working=yellow / blocked=red の即時反映を実機確認。
>
> **予実差異（2-6: 同一状態の再報告はイベントを emit しない）**: `report-agent` を同状態で連打しても `pane.agent_status_changed` は増えない（実測 before=5/after=5）。PostToolUse の毎ツール発火でもイベント乱発・sketchybar 負荷なし。
>
> **予実差異（2-6: hooks の反映タイミング）**: Claude Code は hooks をセッション開始時に読むため、**稼働中の claude セッションには fallback が効かない**。新規セッションから自動反映が有効になる（実運用での working→blocked 自動遷移の目視確認は次セッションで行う）。
>
> **予実差異（2-1/2-3: plugin command はベアネームで解決）**: 計画どおり `command = ["sketchybar", ...]` のままで動作（herdr server が login shell 由来の PATH を保持）。最小 PATH 問題は sketchybar launchd 側のみで、helper 内の per-user profile prepend で対処した。

### Phase 3: workspace CLI 縮小と worktree 委譲

- [x] 3-1: `workspace` CLI を Herdr `workspace`/`worktree` 委譲構成へ書き換え（ghq→`herdr workspace create --cwd`、label は自動命名に任せる）。**未決→解決**: Herdr native picker（`prefix+w`）へ寄せる方針をユーザー決定。CLI は `new`/`wt`/`wt-rm`/`notify`(互換スタブ) の4サブコマンドへ縮小（約300行→約80行）
- [x] 3-2: smug 依存（`.smug.yml` 検知）を除去し、Herdr layout / 先行 plugin（herdr-spreader 等）での代替方針を評価して README に記載（復元は herdr 内蔵永続化で充足。`.smug.yml` は editor/shell の2 window 定義1件のみだったため削除）
- [x] 3-3: worktree 系サブコマンド（`wt`/`wt-rm`）を `herdr worktree create/remove` へ委譲（実測: create は git worktree 作成 + workspace 起動を一括、remove は git worktree 削除 + workspace close を一括）
- [x] 3-4: 主要リポで list/switch/new/worktree の各操作が Herdr 上で動作することを確認（new の dedupe→focus / missing repo エラー / wt / wt-rm を dotfiles + 実 git repo で確認。list/switch は native picker `prefix+w` のためユーザー目視で最終確認）
- [ ] 3-5: Neovim 連携は Sidekick の herdr mux backend（[sidekick.nvim#333](https://github.com/folke/sidekick.nvim/pull/333)）待ち。マージまで `config/nvim/lua/plugins/sidekick.lua` は `mux.enabled=false` 維持、マージ後 `mux.enabled=true, backend="herdr"` に切替（DIY `pane send-text` は作らない）（現状 `mux.enabled=false` 維持を確認済み。上流マージ待ちのため未完のまま）

> **予実差異（3-1: 旧実装の潜在バグを修正）**: repo 名が ghq list に無い場合に `dir="$(ghq root)/"` へ化け、ghq root 自体が workspace 化して exit 0 になるバグが旧 tmux 版から存在（実テストで発覚）。grep 空振りの明示チェックを追加し `Repository not found` + exit 1 に修正。
>
> **予実差異（3-1: notify は no-op スタブとして温存）**: 稼働中の claude セッションは旧 hooks スナップショット（`workspace notify ...`）を保持しており、サブコマンド削除だと毎ツール呼び出しで hook が失敗する。Phase 4 の settings.json hooks 撤去とあわせて削除する。
>
> **予実差異（3-3: worktree create の副作用）**: `herdr worktree create` は worktree 用 workspace に加えて**ソース repo の workspace も自動で開く**（herdr 仕様）。wt-rm 後の focus はソース workspace へ戻る。委譲方針のため挙動として許容し wrapper では制御しない。worktree の配置は herdr 既定（`~/.herdr/worktrees/<repo>/<branch>`、旧 `../<repo>-<branch>` から変更）。
>
> **予実差異（3-2: `.smug.yml` 削除の前倒し）**: リポジトリ直下の `.smug.yml` 削除は 4-6（smug パッケージ除去）と同時想定だったが、CLI 書き換えで読む者がいなくなるため Phase 3 で削除した。
>
> **追補（Phase 4 完了後のユーザー要望）**: 旧 tmux `prefix+T`（workspace list popup）相当が日常運用に必要と判明。`[[keys.command]]` の overlay pane で `prefix+shift+t` → `workspace new`（ghq repo の fzf 選択）を起動する bind を config.toml に追加（`/bin/sh -lc` 実行のため `$HOME` 絶対パス指定、reload-config で diagnostics ゼロ確認）。既存 workspace の一覧・切替は引き続き `prefix+w`。

### Phase 4: 旧構成の撤去

- [x] 4-1: `config/tmux/` を削除、`nix/home/programs`（tmux プログラム設定があれば）を除去（programs に tmux 設定はなし。`nix/home/packages/editor.nix` から tmux、`nix/home/symlinks.nix` から tmux/gitmux リンクを除去）
- [x] 4-2: `config/gitmux/` を削除（`nix/home/packages/shell.nix` から gitmux も除去）
- [x] 4-3: TPM（resurrect/continuum）参照を削除（参照は `config/tmux/tmux.conf` 内のみで 4-1 と同時に消滅。nix に tmuxPlugins 参照なし）
- [x] 4-4: `config/sketchybar/items/tmux.lua` を削除
- [x] 4-5: Claude Code hooks の ws-state 書き出しのうち sketchybar 用途分を除去（他用途がなければ状態 hook 自体を削除）（settings.json から `workspace notify` 5 hook を除去。残る状態報告は report-herdr-state.sh のみ）
- [x] 4-6: smug パッケージを Nix から除去（`nix/home/packages/shell.nix`）
- [x] 4-7: `CLAUDE.md` / 関連 README のマルチプレクサ記述を Herdr に更新（CLAUDE.md・ルート README にマルチプレクサ記述なしを確認。workspace README は Phase 3 で更新済み、sheldon plugins.toml の tmux popup 前提コメントを更新）
- [x] 4-8: `git add` 後 `! nrs`、シェル再起動で旧参照が消えたことを確認（nrs 成功: tmux/gitmux/smug/tmux-terminfo が REMOVED、`command -v` で消滅確認、`~/.config/{tmux,gitmux}` リンク除去、herdr/sketchybar は正常稼働。加えて report-herdr-state hook の自動発火（UserPromptSubmit→working）を実機で確認、fallback 経路は完全稼働）

> **予実差異（4-5: notify スタブは温存）**: settings.json の hooks 撤去後も、旧 hooks スナップショットを持つ**稼働中の** claude セッションが `workspace notify ...` を呼び続けるため、CLI の no-op スタブは残置した。全旧セッション終了後の削除を後続タスク化。
>
> **予実差異（4-7: 更新対象は実質なし）**: CLAUDE.md / ルート README に tmux・マルチプレクサへの言及はなく、更新は sheldon コメント1箇所と workspace README（Phase 3 済み）のみだった。
>
> **解決（WezTerm の ctrl+g 衝突は考慮不要・ユーザー決定）**: WezTerm では組み込みマルチプレクサを使い続けるため herdr の実行対象外。keymap 変更は行わず、herdr は Ghostty 側で常用する（Phase 1 メモの要方針 (A)/(B)/(C) はいずれも不採用でクローズ）。

---

## 変更対象ファイル一覧

| ファイル                                                 | Phase 1                        | Phase 2                   | Phase 3          | Phase 4       |
| -------------------------------------------------------- | ------------------------------ | ------------------------- | ---------------- | ------------- |
| `flake.nix`                                              | herdr input + overlay 追加     | -                         | -                | -             |
| `nix/home/packages/editor.nix`                           | home.packages に herdr（共有） | -                         | -                | -             |
| `config/herdr/config.toml`                               | 新規                           | -                         | -                | -             |
| `nix/home/symlinks.nix`                                  | config/herdr リンク追加        | -                         | -                | -             |
| `config/herdr/plugins/sketchybar-sync/herdr-plugin.toml` | -                              | 新規                      | -                | -             |
| `config/sketchybar/helpers/herdr-ws-snapshot`            | -                              | 新規                      | -                | -             |
| `config/sketchybar/items/herdr.lua`                      | -                              | 新規（tmux.lua 差し替え） | -                | -             |
| `config/sketchybar/items/init.lua`                       | -                              | tmux→herdr item 参照      | -                | -             |
| `config/zsh/plugins/workspace/bin/workspace`             | -                              | -                         | Herdr 委譲へ書換 | -             |
| `config/nvim/lua/plugins/sidekick.lua`                   | -                              | -                         | #333 後に切替    | -             |
| `config/tmux/`                                           | -                              | -                         | -                | 削除          |
| `config/gitmux/`                                         | -                              | -                         | -                | 削除          |
| `config/sketchybar/items/tmux.lua`                       | -                              | -                         | -                | 削除          |
| `config/claude/`（状態 hook 設定）                       | -                              | -                         | -                | ws-state 撤去 |
| `CLAUDE.md`                                              | -                              | -                         | -                | 記述更新      |

---

## 実現可能性レビュー

| 懸念                                       | 検証結果            | 根拠                                                                                                                                                                                                                                                |
| ------------------------------------------ | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Herdr は nixpkgs にあるか                  | **ない**            | flake `github:ogulcancelik/herdr` を input 追加（[install docs](https://herdr.dev/docs/install/)）                                                                                                                                                  |
| plugin `[[events]]` で外部コマンドを叩くか | **実測+ソース確認** | `workspace.created`/`closed` で command 発火を実測（exit 0・約 6ms）。`pane.agent_status_changed` も v0.7.1 の `PLUGIN_HOOK_EVENT_KINDS` に含まれ dispatch（ソース確認）                                                                            |
| イベント payload に status が載るか        | **実測: 載る**      | `HERDR_PLUGIN_EVENT_JSON` に `workspace.agent_status` 同梱。再取得不要                                                                                                                                                                              |
| `herdr workspace list` の JSON schema      | **実測: 確認**      | `.result.workspaces[]` に `workspace_id`/`label`/`agent_status`。helper 一行の出力まで確認                                                                                                                                                          |
| config.toml が受理されるか                 | **実測: 受理**      | 提案 config で `reload-config` が `diagnostics:[] / applied`                                                                                                                                                                                        |
| workspace 自動命名                         | **実測: される**    | `workspace create --cwd <repo>` で `label` が repo 名に                                                                                                                                                                                             |
| worktree 委譲                              | **実測: 可能**      | `herdr worktree list/create/remove` が実 repo で動作                                                                                                                                                                                                |
| prefix / keybinding の remap 可否          | **実測: 可能**      | `config.toml [keys]` で remap、衝突は診断で検出                                                                                                                                                                                                     |
| copy-mode-vi 相当                          | 対応                | `prefix+[` で vi copy-mode（hjkl/v/y、tmux にほぼ一致）。`ctrl+v` の画像ペースト干渉は v0.7.1 で local は修正済み（[#647](https://github.com/ogulcancelik/herdr/issues/647) CLOSED）。`--remote` のみ既定 `keys.remote_image_paste="ctrl+v"` が残る |
| floating popup（display-popup 相当）       | 近似のみ            | Herdr は floating popup 非対応。`[[keys.command]]` の overlay pane で代替                                                                                                                                                                           |
| 実エージェントの状態検知精度               | 未検証              | dispatch はソース確認済みで、残件は Herdr が実 claude の遷移を emit する検知精度のみ（導入時確認）。弱ければ Claude hook→`herdr pane report-agent`（同イベントを emit）で補完                                                                       |
| nvim の undercurl 描画                     | 未検証              | 対話 TTY が必要（導入時確認）                                                                                                                                                                                                                       |

---

## 後続タスク（Phase 1 実装中に発生）

### undercurl（herdr upstream 待ち・放置でOK）

- 事象: herdr pane 内 nvim で LSP 診断の波線が「文字色の平坦な下線」に化ける。
- 原因: herdr の VT が undercurl escape `\e[4:3m` を平坦描画する既知バグ。
  Issue **#894 / #895**（報告環境も `Herdr 0.7.1 stable` で一致）。
- 状態: **PR #900 で修正済み**（commit `b7015f17`、2026-06-30）。`preview-2026-06-30-...`
  以降に収録。**stable は v0.7.1 が最新で未収録**（label `pending-release`）。非クリティカル。
- 対応: **放置**。次 stable（v0.7.2 見込み）が出たら flake の herdr タグを bump して解消。
- 不採用: 一時的な `TERM=xterm-ghostty` 上書きは v0.7.1 の VT バグでは曲線化しないため撤回済み。

### [x] workspace notify スタブ削除（Phase 4 実装中に発生）

- 旧 hooks スナップショットを持つ claude セッションが全て終了した後、
  `config/zsh/plugins/workspace/bin/workspace` の `notify` スタブと README の記載を削除する。
- **完了**: Claude Code が settings.json の hook 変更をセッション途中で反映する（4-8 で実測）ため
  旧 hooks を呼び続けるセッションは残存しないと判断し、待たずに削除した（ユーザー決定）。

### [ ] herdr stable 追従の自動化（別 workflow・案C）

- 目的: stable タグ pin を保ったまま、新 stable を自動で拾って bump PR を立てる
  （undercurl 修正もこの導線で自動的に入る）。
- 背景: 現 `update-flake.yml`（`DeterminateSystems/update-flake-lock`）は flake.lock 専用で、
  タグ固定の herdr は自動で上がらない。既存ジョブへの混在は不整合になりやすいため別 workflow にする。
- 実装: `.github/workflows/bump-herdr.yml` を新規。週次 cron + `workflow_dispatch`。
  `gh api repos/ogulcancelik/herdr/releases/latest`（pre-release 除外＝stable のみ）で最新タグ取得
  → flake.nix の `github:ogulcancelik/herdr/vX.Y.Z` が古ければ置換 → `nix flake update herdr`
  → `create-pull-request` で bump PR。app-token（`AUTOMATION_CLIENT_ID` /
  `AUTOMATION_APP_PRIVATE_KEY`）を既存 workflow 同様に利用。
- 優先度: 低（後回し）。
