# Hunk 導入とエージェント連携 実装計画

## 概要

- Hunk を flake input（tag pin）+ インライン overlay で導入（`pkgs.hunk`）。設定は手書きの `config/hunk/config.toml` を XDG symlink する
- delta（lazygit pager / `core.pager`）は無変更で共存させる
- lazygit に `customCommands` を追加し、選択 commit / working tree を Hunk 全 TUI で開く導線を作る
- herdr には `[[keys.command]]`（`prefix+shift+h` / popup）で `hunk diff` を開くキーを1つ追加する（常駐 review tab は採らない）
- Claude 連携: `config/claude/skills/hunk-review/SKILL.md`（house rule ラッパ）+ `settings.json` に `hunk` 権限を許可
- review 用 Claude は herdr pane（sidekick とは別セッション）で起動し、daemon 越しに注釈する

**出典**:

- [ADR: Hunk 導入とエージェント連携アーキテクチャ](../adr/2026-07-20-hunk-adoption-agent-integration.md)
- [ADR: tmux から Herdr への移行](../adr/2026-07-05-tmux-to-herdr-migration.md)（配置・キー規約の前提）

---

## 決定事項

| 項目           | 決定                                                                                                     | 備考                                                                                                                        |
| -------------- | -------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| 導入方式       | **flake input `github:modem-dev/hunk`（tag pin）+ `sharedOverlays` のインライン overlay で `pkgs.hunk`** | hunk flake は overlay 未 export（`packages` / `homeManagerModules` のみ）。HM module は config 手書き方針に反するため不採用 |
| パッケージ配置 | **`nix/home/packages/dev.nix`（delta と同居）**                                                          | 共有パッケージ（macOS + Linux）                                                                                             |
| 設定           | **手書き `config/hunk/config.toml` + `symlinks.nix` で XDG symlink**                                     | `mode=split` / `agent_notes=true`。Nix 生成でなく live 編集可                                                               |
| delta          | **無変更で共存**                                                                                         | `core.pager`・lazygit `pagers` を触らない                                                                                   |
| Claude 連携    | **`hunk session` CLI + `hunk skill path` SKILL.md**                                                      | MCP ではない。`.mcp.json` 変更なし                                                                                          |
| セッション     | **別セッション（sidekick=authoring / herdr pane=review）**                                               | resume ブリッジ不採用。working tree 共有のため同時編集しない                                                                |
| Hunk 配置      | **on-demand（lazygit `H` + herdr `prefix+shift+h` の `[[keys.command]]` popup）**                        | 常駐 tab は不採用。長い往復レビュー時のみ手動で tab に `hunk diff --watch`（config 不要）                                   |
| lazygit        | **`customCommands`（commits/files context、key `H`、`output: terminal`）**                               | pager は不変。`H` は universal `scrollLeft` を意図的にシャドウ                                                              |
| 権限           | **`settings.json` allow に `Bash(hunk ...)` を追加**                                                     | 注釈往復のプロンプト抑止。`nc` は使わない（deny 維持）                                                                      |
| skill 配置     | **`config/claude/skills/hunk-review/SKILL.md`**                                                          | `.claude/skills` は symlink 済み → symlink 追加不要                                                                         |
| version pin    | **flake を tag pin（pre-1.0）**                                                                          | herdr 同様、後で bump 自動化の余地                                                                                          |

---

## 設計: Nix 導入（overlay 経由）

herdr と同様に flake input を tag pin し、`pkgs.hunk` で参照する。
hunk の flake は overlay を export していない（export は `packages.${system}.{default,hunk}` / `apps` / `homeManagerModules.{hunk,default}`）ため、
`flake.nix` の `sharedOverlays` にインライン overlay を書いて `pkgs.hunk` へ橋渡しする。`nix/overlays/` は `inputs` を参照できないため使わない。
`homeManagerModules` は設定が Nix 生成になり live 編集の方針に反するため不採用とする。

```nix
# flake.nix の inputs に追加（nixpkgs は follows しない。下記の予実差異を参照）
inputs.hunk.url = "github:modem-dev/hunk/v0.17.3"; # 2026-07-19 時点の最新 stable tag
```

```nix
# flake.nix の sharedOverlays に追加
sharedOverlays = [
  # ...既存...
  (_: prev: {
    hunk = inputs.hunk.packages.${prev.stdenv.hostPlatform.system}.hunk;
  })
];
```

```nix
# nix/home/packages/dev.nix の home.packages に追加（delta と同居）
hunk
```

> hunk は Bun ベース（`bun2nix`）。aarch64-darwin を含む 4 system に対応するが、herdr（Rust ソースビルド）とはビルド特性が異なるため、初回 `nrs` の所要時間とキャッシュの効きは実機で確認する。

---

## 設計: config.toml

```toml
# config/hunk/config.toml → ~/.config/hunk/config.toml (symlink)

mode = "split"        # side-by-side（delta の嗜好に合わせる。有効値: auto / split / stack）
line_numbers = true
agent_notes = true    # Claude のインライン注釈を表示（既定は false）

# 組み込み theme は github 系のみで tokyo-night は無い。
# auto は端末背景を検出して github-light/dark-default を自動選択する。
theme = "auto"
```

> `watch` は config 既定 false のまま、必要時に `hunk diff --watch` で明示する。

---

## 設計: lazygit customCommands（pager は不変）

`config/lazygit/config.yml` の `git.pagers`（delta）は**触らず**、`customCommands` を追加して Hunk 全 TUI への導線だけ生やす。

```yaml
# config/lazygit/config.yml に追加（既存 git.pagers / gui.language は不変）
customCommands:
  - key: "H"
    context: "commits"
    command: "hunk show {{.SelectedCommit.Hash}}"
    output: terminal
  - key: "H"
    context: "files"
    command: "hunk diff"
    output: terminal
```

> `SelectedLocalCommit` は deprecated、`subprocess` は `output` に置き換え済みのため、現行仕様の `SelectedCommit.Hash` / `output: terminal` を使う。`H` は universal `scrollLeft` の既定キーで、この 2 context では customCommand が優先されて main パネルの横スクロールが使えなくなるが、常用しないため許容する（必要になれば `scrollLeft` を再割当して回避する）。

---

## 設計: herdr キーバインド（on-demand）

hunk は常駐させず、herdr の `[[keys.command]]`（lazygit / btop と同じ popup パターン。v0.7.4+）で都度開く。

```toml
# config/herdr/config.toml の [[keys.command]] に追加
[[keys.command]]
key = "prefix+shift+h"
type = "popup"
command = "hunk diff"
description = "review diff with hunk"
width = "90%"
height = "90%"
```

- popup は command 終了で閉じる。注釈の寿命も開いている間の見込みで（2-5 で実機確認）、閉じた後に読み返す場合は review Claude に `comment apply` を再実行させる
- キーは既存慣例（shift+l / shift+b / shift+t）に合わせて `prefix+shift+h` を使う。`prefix+h` は `focus_pane_left` で使用済み。衝突有無は reload-config の diagnostics で確認する
- 同一 repo で hunk を同時に複数開かない（`hunk session ... --repo .` の自動解決が曖昧になり、位置引数 `<session-id>` が要るため）。on-demand 運用なら通常は常に1つで済む
- 長い往復レビューをしたい時だけ、手動で tab を作り `hunk diff --watch` を常駐させる（herdr config の変更は不要。その間はこのキーや lazygit `H`（files）で二重に開かない）

---

## 設計: Claude review skill

hunk 本体の skill（`hunk skill path`）を読み込ませたうえで、house rule だけを定義する薄いラッパを `config/claude/skills/hunk-review/SKILL.md` に置く。`.claude/skills` は symlink 済みのため配置のみで有効。

```markdown
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
```

---

## 設計: settings.json 権限差分

`config/claude/settings.json` の `permissions.allow` に追加（注釈往復でのプロンプトを抑止）。daemon は HTTP/JSON で `nc` を使わないため既存 deny はそのまま。

```jsonc
// permissions.allow に追加
"Bash(hunk session:*)",
"Bash(hunk skill:*)",
"Bash(hunk diff:*)",
"Bash(hunk show:*)"
```

---

## 実装手順

### Phase 1: Hunk 導入（Nix + config + symlink）

- [x] 1-1: `nix flake show github:modem-dev/hunk/v0.17.3` で outputs を確認（`packages.${system}.hunk`・aarch64-darwin・最新 stable tag が想定どおりか）

> **検証済み（2026-07-22）**: `packages.aarch64-darwin.hunk` = `hunkdiff-0.17.3`（`default` も同一）、4 system 分 export、`homeManagerModules` あり、overlays 無し。flake に `nixpkgs` input があり `follows` 有効。locked rev `82b19cd`。

- [x] 1-2: `flake.nix` の inputs に `hunk`（tag pin）を追加
- [x] 1-3: `flake.nix` の `sharedOverlays` にインライン overlay を追加して `pkgs.hunk` を有効化
- [x] 1-4: `nix/home/packages/dev.nix` の `home.packages` に `hunk` を追加
- [x] 1-5: `config/hunk/config.toml` を上記設計どおり作成
- [x] 1-6: `nix/home/symlinks.nix` の `xdg.configFile` に `"hunk".source = mkLink "config/hunk";` を追加

> **評価確認（2026-07-22）**: `nix eval` で darwin 構成の `home.packages` に `hunkdiff-0.17.3` が入ることを確認。`config/hunk` は `git add` 済み。
>
> **予実差異**: `inputs.nixpkgs.follows = "nixpkgs"` は不可だった。手元の nixpkgs-unstable（26.11）が x86_64-darwin サポートを削除しており、
> follows で注入すると hunk 内部の flake-parts（bun2nix / treefmt-nix）が x86_64-darwin の outputs を評価した時点で throw する
> （初回 `nrs` で発覚。事前 `nix eval` は `home.packages` のみの評価で x86_64-darwin を強制せず検出できなかった）。
> follows を外し hunk 自前の lock（nixpkgs 2026-05-05）を使って解消。nixpkgs が二重になるが影響は eval コストのみ。
> darwin system 全体の `nix build --dry-run` で再発しないことを確認済み。

- [x] 1-7: `git add` 後 `! nrs` で反映し、`hunk --version` と `hunk diff`（daemon 登録）を確認

> **1-7 補足（2026-07-24）**: `hunk --version` = 0.17.3、`~/.config/hunk` の symlink 解決、`hunk session list` の疎通を確認。TUI 起動（daemon 登録）は 2-4 の実機確認に含める。

### Phase 2: 単体レビュー導線（lazygit + herdr キーバインド）

- [x] 2-1: `config/lazygit/config.yml` に `customCommands` を追加（`git.pagers` は不変）

> **予実差異（popup の顛末）**: `type = "popup"` 追加後に「unknown variant `popup`（expected: shell / pane / plugin_action）」の
> config warning が出てキー設定全体が不適用になった。一次対応で「stable 未実装」と誤判定し pane へ後退したが、
> タグのソース確認で **popup は v0.7.4 から実装済み**（`src/config/keybinds.rs` の `Shell / Pane / Popup`）と確定。
> 警告の真因は**常駐 herdr server が更新前の旧バイナリのまま**だったこと（profile symlink は switch で更新されても、
> 起動済みプロセスは旧コードで動き続ける。expected 一覧に popup が無いのは ≤0.7.3 世代の証拠）。
> 対応: popup 設定（90%）を復元し、あわせて herdr input を最新 stable v0.7.5 に bump。**server 再起動 + reload で解消**。
> 教訓: 機能有無はタグのソースで確認し、警告を出しているプロセスのバイナリ世代を疑う。

- [ ] 2-2: lazygit で commits / files context から `H` で Hunk が開くことを確認（`SelectedCommit.Hash` / `output: terminal` の動作と、`scrollLeft` シャドウの許容可否を実機確認）
- [ ] 2-3: `config/herdr/config.toml` に `[[keys.command]]`（`prefix+shift+h` / popup / `hunk diff`）を追加し、reload-config で diagnostics とキー衝突を確認（追加済み・server 再起動後に確認）
- [ ] 2-4: `prefix+shift+h` で hunk が popup で開き、`q` で閉じることを実機確認
- [ ] 2-5: 注釈の寿命を実機確認 — hunk TUI を閉じた後に daemon 側のセッションと注釈が残るか。残らない場合は「閉じたら Claude に `comment apply` を再実行させる」運用で確定

### Phase 3: Claude review 連携（別セッション運用）

- [x] 3-1: `config/claude/skills/hunk-review/SKILL.md` を作成
- [x] 3-2: `config/claude/settings.json` の `permissions.allow` に `hunk` エントリを追加
- [x] 3-3: `git add` 後 `! nrs`（skill / settings の symlink 反映を確認）

> **予実差異**: `nrs` は不要だった。`.claude/skills` / `settings.json` は out-of-store symlink で丸ごとリンク済みのため配置のみで即時反映（skill 一覧への `hunk-review` 出現を確認）。`git add` は実施済み。permissions は新しい Claude セッションから有効。

- [ ] 3-4: E2E 検証 — review 用 Claude に `/hunk-review` 相当で注釈を指示してから `prefix+shift+h` で hunk を開き、`hunk session comment` が画面にライブ反映されることを確認（session 未起動による失敗があれば skill にリトライ手順を足す）
- [ ] 3-5: review Claude が herdr pane 起動により状態可視化されることを確認（主経路は herdr のネイティブ検知。nvim split 補完用の `report-herdr-state.sh` も pane 内でそのまま動く）

### Phase 4: ドキュメント / 撤退性

- [ ] 4-1: `CLAUDE.md`（または関連 README）にレビュー導線（delta=lazygit / Hunk=review + Claude 注釈）を追記
- [ ] 4-2: 撤退手順（flake input / overlay / config / symlink / lazygit・herdr・skill・権限差分の除去で現状復帰）を Plans に残す

---

## 変更対象ファイル一覧

| ファイル                                    | Phase 1                                     | Phase 2                 | Phase 3            | Phase 4  |
| ------------------------------------------- | ------------------------------------------- | ----------------------- | ------------------ | -------- |
| `flake.nix`                                 | hunk input + overlay（+ herdr v0.7.5 bump） | -                       | -                  | -        |
| `nix/home/packages/dev.nix`                 | home.packages に hunk                       | -                       | -                  | -        |
| `config/hunk/config.toml`                   | 新規                                        | -                       | -                  | -        |
| `nix/home/symlinks.nix`                     | config/hunk リンク                          | -                       | -                  | -        |
| `config/lazygit/config.yml`                 | -                                           | customCommands 追加     | -                  | -        |
| `config/herdr/config.toml`                  | -                                           | `[[keys.command]]` 追加 | -                  | -        |
| `config/claude/skills/hunk-review/SKILL.md` | -                                           | -                       | 新規               | -        |
| `config/claude/settings.json`               | -                                           | -                       | allow に hunk 追加 | -        |
| `CLAUDE.md`                                 | -                                           | -                       | -                  | 導線追記 |

---

## 実現可能性レビュー

事前検証済み（2026-07-22 再照合: hunk は v0.17.3 **タグ**の docs と `nix flake show/metadata` の実行結果、lazygit は実機の v0.63.1 タグ docs、herdr は実機 v0.7.4 の稼働実績で裏取り）:

| 懸念                                  | 検証結果                                                                                                                                       | 根拠                                                                                           |
| ------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| hunk は nixpkgs にあるか              | 未収載。flake input で導入する                                                                                                                 | [nix/README](https://github.com/modem-dev/hunk/tree/main/nix)                                  |
| hunk が overlay を export するか      | しない（export は `packages.${system}.{default,hunk}` / `homeManagerModules`）→ `sharedOverlays` にインライン overlay                          | hunk `flake.nix`                                                                               |
| 対応 system（aarch64-darwin build）   | aarch64-darwin を含む 4 system に対応（Bun / `bun2nix`）                                                                                       | hunk `flake.nix`                                                                               |
| daemon の agent 連携経路              | CLI + skill で確定。daemon は HTTP/JSON `/session-api` で MCP プロトコル非対応（`hunk mcp serve` は命名のみ）                                  | [docs/agent-workflows.md](https://github.com/modem-dev/hunk/blob/main/docs/agent-workflows.md) |
| lazygit の template 変数・output      | `SelectedCommit.Hash` + `output: terminal` が現行仕様。`H` は universal `scrollLeft` をシャドウ（許容）                                        | lazygit `Custom_Command_Keybindings.md` / `Config.md`                                          |
| herdr `[[keys.command]]` popup の挙動 | command 終了で閉じる popup（v0.7.4+ 実装をタグのソースで確認。旧バイナリの常駐 server では unknown variant 警告）。注釈の寿命は 2-5 で実機確認 | herdr docs（configuration）                                                                    |
| hunk の theme                         | tokyo-night は無い（github 系 + `auto` + `custom`）→ `auto` を採用                                                                             | hunk README                                                                                    |
