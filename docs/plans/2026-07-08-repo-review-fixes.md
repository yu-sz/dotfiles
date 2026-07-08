# リポジトリレビュー指摘修正 実装計画

## 概要

リポジトリ全体レビュー（2026-07-08 実施、5 領域: Nix / CI・lint / Zsh・スクリプト / Lua 設定 / Claude 設定・ドキュメント）で検出した指摘（高 ≈10 件、中 ≈30 件、低 ≈40 件）を全件修正する。

- セキュリティ: auto-approve フックのバイパス経路封鎖、permission ルールの精密化
- 新規マシン破損系: marketplace 参照切れ、bootstrap ホスト名不一致、絶対パス/相対パス hook の修正
- ADR ドリフト解消: mise を Nix 管理へ復帰（ADR 2026-03-28 準拠）
- 「設定したつもりで効いていない」Lua 設定群の一括修正
- CI の検査漏れ（shellcheck glob、docs lint、キャッシュキー衝突）の解消
- ドキュメントの実態合わせ

**出典**:

- [ADR: Nix パッケージ管理](../adr/2026-03-28-nix-package-management.md) — mise 自体は Nix 管理と決定済み（現状はドリフト）
- [ADR: Linux サポート戦略](../adr/2026-04-11-linux-support-strategy.md) — GUI アプリの OS 別管理方針
- 新規 ADR は作成しない（方針変更を伴う修正がないため）

---

## 決定事項

| 項目                          | 決定                                     | 備考                                                                          |
| ----------------------------- | ---------------------------------------- | ----------------------------------------------------------------------------- |
| 修正範囲                      | **高・中・低の全件**                     | 低は Phase 8-9 に集約                                                         |
| auto-approve フック           | **ガード追加で存続**                     | コマンド置換・リダイレクト含みは手動承認へフォールスルー                      |
| enableAllProjectMcpServers    | **false に変更**                         | 信頼 repo では初回承認が必要になる                                            |
| curl の allow                 | **現状維持**                             | ユーザー判断。deny/ask 化しない                                               |
| mise                          | **Nix 管理へ移行**                       | ADR 2026-03-28 の決定へ復帰。curl インストーラは廃止                          |
| GUI アプリ管理                | **現状維持 + CLAUDE.md に例外明記**      | wezterm cask は CI タイムアウト対策（09cb343）の意図的例外                    |
| `>` / `<` keymap              | **削除しインデント演算子を復活**         | リサイズは導入済みの winresizer に寄せる                                      |
| `<tab>` 競合                  | **sidekick の fallback を `tabnext` に** | sidekick と `:tabnext` を両立                                                 |
| blink-cmp-dictionary          | **provider 登録して有効化**              | 死蔵解消。不要と判断したら削除に切替可                                        |
| nvim-treesitter-textobjects   | **削除**                                 | main ブランチは keymap 必須で未設定=死蔵。必要になったら再導入                |
| lualine / laststatus          | **`options.laststatus = 3` を削除**      | 現状の見た目（globalstatus = false 相当）を維持し dead 設定のみ除去           |
| sketchybar-app-font overlay   | **削除**                                 | pinned nixpkgs に 2.0.62 が存在（overlay は 2.0.60 で新しい upstream を隠蔽） |
| commands/review.md            | **`/review-diff` にリネーム**            | 組み込み `/review` との名前衝突解消                                           |
| 未追跡 ADR/Plans（db-client） | **未着手を明記してコミット**             | docs 全件追跡の慣例に合わせ紛失リスクを解消                                   |

---

## 設計: auto-approve-piped.sh 早期ガード

```bash
# config/claude/hooks/auto-approve-piped.sh
# `[ -z "$COMMAND" ] && exit 0`（:10）の直後に挿入
# コマンド置換・プロセス置換・リダイレクトを含む場合は自動承認せず
# 通常の permission フローに委ねる（exit 0 = フォールスルー）
case "$COMMAND" in
  *'$('* | *'`'* | *'<('* | *'>('* | *'>'*)
    exit 0
    ;;
esac
```

このガードにより既存のリダイレクト除去 sed（:141-142）は不要になるため削除する。

deny/ask リストとの突き合わせも追加する: allow プレフィックス一致後、`~/.claude/settings.json` の deny・ask に一致するステージが 1 つでもあればフォールスルー。

## 設計: permissions（config/claude/settings.json 抜粋）

現在の deny のうち Read 系のみを差し替える（`Bash(rm:*)` 等の Bash / Write ルールは維持）:

```json
{
  "permissions": {
    "deny": [
      "Read(**/id_rsa*)",
      "Read(**/id_ed25519*)",
      "Read(**/*.pem)",
      "Read(**/*.key)",
      "Read(**/*token*.json)",
      "Read(**/.env.*)"
    ]
  },
  "enableAllProjectMcpServers": false
}
```

- 差し替え対象は現 deny の `Read(id_rsa)` / `Read(id_ed25519)` / `Read(**/*token*)` / `Read(**/*key*)` の 4 行
- `Read(**/*key*)` の分解で `keybindings.json` / `keymaps.lua` / `which-key.lua` の誤爆を解消（セルフレビュー中も Read が実際に拒否された）。同型の `Read(**/*token*)` も `tokenizer.ts` 等に誤爆するため併せて分解（具体パターンは実装時に精査）
- fork bomb 検知の正規表現は `rm -rf|dd if=|:\(\)\{ :\|:& \};:` へ修正。settings.json 内の JSON 文字列なのでバックスラッシュは `\\` に二重化する

## 設計: Justfile（shellcheck / ci）

```just
# sh の `**` は `*` 扱いになるため find で全 .sh を列挙する
lint-sh:
    find scripts -name '*.sh' -exec shellcheck -x -e SC1091 {} +

# CI 用チェック（Nix 評価 + lint + dry-run build）
ci: check lint lint-sh
    just ci-{{ if os() == "macos" { "darwin" } else { "linux" } }}
```

`ci` レシピ内にインライン重複していた `nix flake check` は `check` への依存指定に統一する。OS 別 dry-run build（`ci-darwin` / `ci-linux` の呼び分け）は現状どおり維持する。

## 設計: bump-herdr.yml の injection 対策

```yaml
# .github/workflows/bump-herdr.yml（:35-38 の置き換え）
# 外部リポジトリのタグ名を ${{ }} で run: に直接展開しない
# latest / current とも step `latest` の outputs（step `current` は存在しない）
- name: Bump herdr tag in flake.nix
  if: steps.latest.outputs.latest != steps.latest.outputs.current
  env:
    LATEST: ${{ steps.latest.outputs.latest }}
    CURRENT: ${{ steps.latest.outputs.current }}
  run: |
    if [ -z "$LATEST" ] || [ -z "$CURRENT" ]; then
      echo "tag detection failed" >&2
      exit 1
    fi
    sed -i "s|github:ogulcancelik/herdr/$CURRENT|github:ogulcancelik/herdr/$LATEST|" flake.nix
```

`commit-message` / `title` / `body`（:54-62）はアクションの入力値でシェル展開されないため対象外。

## 設計: CI キャッシュキー分離

```yaml
# 4 workflow 共通の変更（例: lua-lint.yml）
with:
  primary-key: nix-${{ github.workflow }}-${{ runner.os }}-${{ hashFiles('flake.lock') }}
  purge-prefixes: nix-${{ github.workflow }}-${{ runner.os }}-
```

## 設計: mise の Nix 管理化

```nix
# nix/home/packages/dev.nix（追加）
home.packages = with pkgs; [
  # ...
  mise
];
```

- `scripts/setup/prepare_env.sh` / `scripts/setup/install_runtimes.sh` から curl インストーラを削除し、Nix 導入済み前提に書き換える
- 既存マシンでは `gomi ~/.local/bin/mise` で旧バイナリを退避
- これにより `.zshrc:13` の「Nix ストア由来なので実パス比較」コメントが実態と一致する（キャッシュ判定ロジック自体は変更不要）

## 設計: sidekick `<tab>` fallback

```lua
-- config/nvim/lua/plugins/sidekick.lua
{
  "<tab>",
  function()
    if not require("sidekick").nes_jump_or_apply() then
      return "<cmd>tabnext<cr>"
    end
  end,
  expr = true,
  desc = "Sidekick NES jump/apply or next tab",
},
```

## 設計: copy-buffer 系の共通化

```lua
-- config/nvim/lua/commands/copy-to-clipboard.lua（新規・module pattern）
local M = {}

---@param expand_fmt string vim.fn.expand に渡すフォーマット（"%:t" / "%:p" 等）
---@param label string 通知に表示する名前
function M.copy_expand(expand_fmt, label)
  local value = vim.fn.expand(expand_fmt)
  vim.fn.setreg("+", value)
  vim.notify(("Copied %s: %s"):format(label, value))
end

return M
```

`vim.fn.has("mac")` の真偽値バグと pbcopy 分岐、print() 使用が同時に解消される。`commands/init.lua` の require（現在は copy-buffer-name / copy-buffer-path を個別 require）も併せて更新する。

---

## 実現可能性レビュー

| 懸念                                                      | 検証結果         | 根拠                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| --------------------------------------------------------- | ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| sketchybar-app-font は nixpkgs 側で足りるか               | 足りる           | pinned nixpkgs（567a49d）で 2.0.62 を eval 確認済み                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| zabrze overlay も削除できるか                             | できない（維持） | pinned nixpkgs に zabrze 属性が存在しないことを eval 確認済み                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `scripts/**/*.sh` が CI で全ファイルに展開されていない件  | 事実             | just デフォルトシェル（sh）で実測、`scripts/setup/*.sh` のみ展開                                                                                                                                                                                                                                                                                                                                                                                                                              |
| noice の skip フィルタが大文字小文字を区別する件          | 事実             | noice.nvim `message/filter.lua:96` の `find` 実装で確認                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| `vim.fn.has("mac")` が Lua で常に真になる件               | 事実             | 実機で number（0/1）返却を確認                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| alias が後続 source の関数定義に焼き込まれる件（rm→gomi） | 事実             | 実機の zsh で検証済み                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| mise は nixpkgs から導入可能か                            | 可能             | pinned nixpkgs で 2026.6.5 を eval 確認済み                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| sidekick fallback 変更は現行 API と整合するか             | 整合             | 実ファイルの `nes_jump_or_apply()` + expr 構造をそのまま流用                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `Read(**/*key*)` が実作業を阻害する件                     | 事実             | セルフレビュー中に keymaps.lua の Read が拒否された                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| cache-nix-action の `1G` / `P7D` は有効な形式か           | 有効（修正不要） | 公式 README で K/M/G suffix と ISO 8601 duration の受理を確認                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| herdr フックはチルダパス化できるか                        | 要実機確認       | 管理コマンド `herdr integration install/uninstall claude` を確認。絶対パスは herdr が書き込むため、手動書き換え後の巻き戻り有無を 2-5 で検証                                                                                                                                                                                                                                                                                                                                                  |
| Phase 2/5-8 の中・低指摘は実在するか                      | 全件実在         | セルフレビューで対象ファイルを全数照合（typo 群 / desc / im-select / hlslens / flash / overlook / mode / lsp/init / luarc / options / autocmd / lualine / blink / treesitter / open-pr / insert-link / copy-buffer / terraform-ls / tab_bar / my_utils / volume / date / workspace / fkill / git.zsh / completion.zsh / config.zsh / path.zsh / alias.zsh / plugins.toml / statusline / report-herdr-state / file-suggestion / bootstrap sed / README / raycast / reviewer.md / drawio 38KB） |

---

## 実装手順

### Phase 1: セキュリティ設定

> **注**: 現在の `Read(**/*key*)` deny により `config/nvim/lua/config/keymaps.lua` 等が Claude Code から読めない（セルフレビュー中に実際に拒否を確認）。Phase 7 / 8 の keymap 系ファイルの編集は Phase 1 完了が前提。

- [x] 1-1: `config/claude/hooks/auto-approve-piped.sh` に置換・リダイレクト検出の早期ガードを追加（`$(` / バッククォート / `<(` / `>(` / `>` を検出、不要になったリダイレクト除去 sed も削除）
- [x] 1-2: 同スクリプトに deny/ask リスト突き合わせのフォールスルーを追加（`matches_blocked` 追加、環境変数除去は `normalize_cmd` に共通化）
- [x] 1-3: `config/claude/settings.json` の `Read(**/*key*)` / `Read(**/*token*)` を具体パターンへ分解（`**/id_rsa*` / `**/id_ed25519*` / `**/*.pem` / `**/*.key` / `**/*.token` / `**/*token*.json` の 6 本に再構成）
- [x] 1-4: `enableAllProjectMcpServers` を false に変更
- [x] 1-5: fork bomb 検知正規表現のエスケープ修正（jq で新旧とも検証。旧版も偶然 match していたため実態は曖昧さの解消）
- [x] 1-6: `.claude/settings.json` の `Bash(nix develop:*)` を `nix develop -c` / `--command` の 2 ルールに限定
- [x] 1-7: 検証 — フック単体テスト 12/12 PASS + settings.json 抽出コマンドの end-to-end 5/5 PASS。`keybindings.json` の Read はセッション再起動なしで即時成功

> **予実差異**: (1) 現行の fork-bomb 正規表現は jq（Oniguruma）では偶然意図どおり match しており「動いていない」という指摘は不正確だった。修正は曖昧さの解消として実施。(2) 検証コマンド自体が同フックの substring 誤爆（`rm -rf` を**データとして**含むだけでブロック）に 2 度遭遇し、テストを scratchpad スクリプトへ退避して回避。誤爆の実害を実演で追認した（単語境界の追加は本 Plans スコープ外、必要なら後続で）。(3) permission 変更はセッション再起動なしで即時反映された。

### Phase 2: 新規マシン破損系

- [x] 2-1: `.claude-plugin/plugins/gopls-lsp/` と `rust-analyzer-lsp/` を README 付きで追加（marketplace.json の参照切れ解消）
- [x] 2-2: ホスト名取得を `hostname -s` に統一（`linux.sh` のみ修正。bootstrap.sh は Darwin=scutil / Linux=-s で既に正しかった）
- [x] 2-3: `scripts/bootstrap.sh` の sed 挿入後に `grep -q` 検証を追加（darwin/linux 両ブロック、`error()` ヘルパー追加、失敗握りつぶしの `if mv` も除去）
- [x] 2-4: `.claude/settings.json` のフックパスを `"$CLAUDE_PROJECT_DIR"/.claude/hooks/format.sh` に変更
- [x] 2-5: **`$HOME` 化は不成立** — herdr はフック行を完全一致で識別するため、書き換えると絶対パス行が二重登録される（`herdr integration install claude` で実証）。herdr 管理の絶対パス行を正に戻し、単一エントリでの冪等性を確認。根治は upstream 要望（チルダ対応 or 等価判定）
  - 調査済み: この行は herdr が起動時に自動インストールする管理行（`herdr integration install/uninstall claude`、バージョン管理付き。現在 v7）。新規マシンでは herdr 初回起動時に自己修復されるが、絶対パス書き込みのため home が異なるマシン間（yu-sz / yuta.suzuki）で settings.json が相互に書き換わり続ける
- [x] 2-6: `config/claude/statusline.sh` の bc 依存を排除（シェル算術でなく既存依存の jq で秒換算）
- [x] 2-7: `config/claude/hooks/report-herdr-state.sh` の PATH に `~/.nix-profile/bin`（standalone HM）を追加
- [x] 2-8: `extraKnownMarketplaces` の `path: "."` を `~/Projects/dotfiles` へ（絶対パスは 2 マシン問題を再導入するため `~` 表記を採用）
- [x] 2-9: `config/claude/file-suggestion.sh` に `${CLAUDE_PROJECT_DIR:-.}` フォールバックと `--exclude .git` を追加

> **予実差異**:
>
> 1. 2-5 は計画の第 1 案（`$HOME` 化）が herdr の完全一致識別により不成立と実証され、フォールバック（herdr 管理行を正とする）へ切替。他マシンでは各マシンの行が並存し、存在しないパス側は無害に失敗する既知制約として受容。upstream への要望（チルダ対応・末尾改行保持）が根治で、ユーザー判断待ち。
> 2. herdr の再書き込みで settings.json 全体がキーソートされたため、この形を正としてコミット。以後の herdr 書き込みで diff が出なくなり、9-2 の churn 解消を前倒しで達成（末尾改行の 1 byte flap のみ残存）。
> 3. 2-2 の bootstrap.sh は指摘と異なり修正不要だった（Darwin は scutil、Linux は `-s` で正しかった）。
> 4. 検証: shellcheck 5 ファイル PASS、statusline / file-suggestion は実データで動作確認。

### Phase 3: mise の Nix 管理化（ADR ドリフト解消）

- [x] 3-1: `nix/home/packages/dev.nix` に `mise` を追加（dry-run で mise-2026.6.13 のキャッシュ取得を確認。`! nrs` は Phase 4 と合わせて下記で依頼）
- [x] 3-2: `install_mise()` と `install.sh` の呼び出しを削除、`install_runtimes.sh` は `~/.local/bin` でなく `~/.nix-profile/bin`（standalone HM）を PATH に追加する形へ書き換え
- [ ] 3-3: 既存マシンの `~/.local/bin/mise` を gomi で退避し、`mise doctor` で動作確認
- [x] 3-4: `config/zsh/eager/path.zsh` の shims 行に `(N-/)` と意図コメントを追加
- [ ] 3-5: 検証 — 新しいシェルで mise キャッシュが再生成され、`mise ls` が正常なこと

### Phase 4: Nix 整理

- [x] 4-1: `nix/overlays/sketchybar-app-font.nix` を削除し `nix/overlays/default.nix` から除去（dry-run で nixpkgs の 2.0.62 取得を確認）
- [x] 4-2: `nix/overlays/default.nix` の `_final:` を規約どおり `_:` に変更
- [x] 4-3: devShell から重複の `prettier` / `selene` と未使用の `shfmt` を削除（`nix develop` 内で selene / prettier が enabledPackages から解決されることを実測）
- [x] 4-4: `nix/home/packages/lsp-tools.nix` のアルファベット順を修正
- [ ] 4-5: 検証 — `nix flake check` は PASS 済み。ユーザーが `! nrs` 後、sketchybar のアプリアイコン表示を確認

### Phase 5: CI / Justfile

- [x] 5-1: Justfile に `lint-sh`（find 方式）を追加し、`ci` を `check lint lint-sh lint-docs` 依存へ統一（OS 別 dry-run build は維持）
- [x] 5-2: 4 workflow のキャッシュ primary-key を workflow ごとに分離（`github.workflow` は名前にスペースを含むためリテラルスラッグ `nix-lua-lint-` 等を採用）
- [x] 5-3: `bump-herdr.yml` を env 経由参照 + 空値ガードへ
- [x] 5-4: nix-build 両 workflow の paths に `**/*.nix` と workflow 自身を追加、darwin に cache-nix-action（`gc-max-store-size-darwin: 2G`）を導入し timeout を 30 分へ
- [x] 5-5: `actions/checkout` を v6 に統一
- [x] 5-6: timeout（lua-lint 15 / nix-lint 20 / update-flake 30 / bump-herdr 15 分）と concurrency を全 workflow に追加（bot 系は cancel-in-progress: false）
- [x] 5-7: `lint-docs` レシピ（`git ls-files` ベースで追跡ファイルのみ）を追加し `just ci` 経由で CI 実行、nix-lint に gitleaks 全履歴スキャン（fetch-depth: 0）を追加
- [x] 5-8: `lua-lint.yml` の paths を `config/**/*.lua` / `nix/**/*.lua` に絞る
- [x] 5-9: cache-nix-action の値形式を確認 → `1G`（K/M/G suffix）も `P7D`（ISO 8601 duration）も公式サポート形式のため**修正不要**（README で確認済み）
- [ ] 5-10: 検証 — PR を作成し全 workflow green、トップレベル scripts の shellcheck が CI ログに現れること

> **予実差異**:
>
> 1. lint-docs 導入で pre-commit 未通過のレガシー docs の違反が顕在化し一括修正（raycast.md、ask.md、lua-standard / writing-adr-plans SKILL、nh-adoption / mason ADR、reviewer.md、gomi config の prettier 整形、markdownlint に details/summary 許可）。raycast.md の lint 修正と karabina typo は 9-7 から前倒し。
> 2. mason ADR 44 行目に**実ファイルの UTF-8 破損バイト**（「得ない」の欠損）を発見し修復。レビューでは検出されていなかった問題。
> 3. reviewer.md に MD041 対応の H1 を追加（agent prompt に見出し 1 行が入るが無害）。
> 4. 5-2 は設計の `${{ github.workflow }}` でなくリテラルスラッグを採用（workflow 名にスペースを含むため）。

### Phase 6: Zsh

- [ ] 6-1: `config/zsh/lazy/function.zsh` の `y()` を `command rm -f --` に変更
- [ ] 6-2: `config/zsh/lazy/repo.zsh` を `command rm` / `builtin cd` に変更
- [ ] 6-3: `.zshrc:54` の glob に `(N)` を付与、eager/lazy ファイル削除時は `sheldon lock` が必要な旨をコメント追記
- [ ] 6-4: `config/zsh/eager/config.zsh` — `HIST_SAVE_NO_DUPS` 削除とコメント整理、履歴除外パターンのデッドエントリ（j/jj/trash）を実 alias に合わせて整理、旧 history 移行コードを削除
- [ ] 6-5: `config/zsh/eager/path.zsh` の `zsh/bin` デッドエントリを削除
- [ ] 6-6: `config/zsh/lazy/completion.zsh` — LS_COLORS 行の削除（または vivid 導入）、`local dir` 追加、古い zcompdump の掃除
- [ ] 6-7: `config/zsh/lazy/repo.zsh` — 補完へ `new`/`r`/`h` 追加、trailing whitespace 削除
- [ ] 6-8: `config/zsh/plugins/workspace/bin/workspace` — 未知サブコマンドは usage + exit 1、repo 解決の grep を `-F` 完全一致へ
- [ ] 6-9: `config/zsh/lazy/git.zsh` のコマンド置換をクォート
- [ ] 6-10: `config/zsh/lazy/fzf.zsh` の `fkill` デフォルトを SIGTERM へ
- [ ] 6-11: `.zshrc` の brew 検出に `/usr/local` フォールバックを追加
- [ ] 6-12: `config/zsh/sheldon/plugins.toml` の fzf-tab コメントを実態（compinit 前でもフォールバックで動作）に修正
- [ ] 6-13: 検証 — `zsh -i` 起動エラーなし、`y` で tmp がゴミ箱に入らないこと、`repo remove` が実削除になること

### Phase 7: Neovim / WezTerm 動作バグ

- [ ] 7-1: `copy-buffer-name.lua` / `copy-buffer-path.lua` を setreg 共通化（設計参照。has("mac") バグ・print 使用も同時解消）
- [ ] 7-2: `config/wezterm/keymaps.lua` — `LEADER+w` の二重定義を解消（タブ閉じ復活、ペイン閉じは `x`）、コメント修正
- [ ] 7-3: `config/wezterm/hooks.lua` のイベント名を `user-var-changed` に変更し zen-mode 連携を復活
- [ ] 7-4: `plugins/sidekick.lua` — fallback を `<cmd>tabnext<cr>` に（設計参照）、`backend = "tmux"` に upstream PR #333 待ちの TODO コメントを追加。冗長になる `config/keymaps.lua` の `<tab>` → `:tabnext` 定義は削除
- [ ] 7-5: `plugins/noice.lua` の skip パターンを実メッセージの大文字表記に修正
- [ ] 7-6: `plugins/blink.cmp.lua` に dictionary provider を登録し blink-cmp-dictionary を有効化
- [ ] 7-7: `plugins/im-select.lua` — `set_previous_events = {}` に修正しコメントと一致させる
- [ ] 7-8: `plugins/nvim-hlslens.lua` — `g*` の二重定義を解消し `vim.keymap.set` に統一
- [ ] 7-9: `commands/open-pr.lua` に commit hash の nil ガードを追加
- [ ] 7-10: `commands/insert-link-to-markdown.lua` — 非 URL 時に `"_dP` フォールバック
- [ ] 7-11: typo による無効設定の修正 — `nvim-autopairs.lua` の `javasctipt`、`snacks.lua:247` の `enable`→`enabled`、`diffview.lua` の `<setab>`→`<s-tab>`
- [ ] 7-12: `markdown-preview.lua` / `overlook.lua` の keys spec を平坦形式に修正（desc/silent 復活）
- [ ] 7-13: `.luarc.json` / `config/nvim/.luarc.json` の `hint.enable` をトップレベルへ移動
- [ ] 7-14: `config/keymaps.lua` の `>` / `<` を削除（インデント演算子復活、リサイズは winresizer）
- [ ] 7-15: `plugins/flash.lua` の o モード `<CR>` 重複を解消（remote を `r` へ）
- [ ] 7-16: `config/options.lua` の dead な `laststatus = 3` を削除
- [ ] 7-17: 検証 — `:checkhealth` クリーン、タブ切替 / zen-mode / dictionary 補完 / `>>` インデントの動作確認

### Phase 8: Lua 規約・リファクタ・typo

- [ ] 8-1: keymap の `desc` を一括追加（`config/keymaps.lua`、`lsp/init.lua`、auto-session / overseer / oil / snacks / zen-mode 等）
- [ ] 8-2: `print()` / `nvim_err_writeln` を `vim.notify` へ置換（diffview 含む）
- [ ] 8-3: LuaCATS アノテーション追加（`config/wezterm/my_utils.lua`、sketchybar helpers、commands）、`sidekick.lua` の `@class` を `@type` へ
- [ ] 8-4: ファイル名リネーム — `nvim-sorround.lua`→`nvim-surround.lua`、`schemaStore.lua`→`schemastore.lua`
- [ ] 8-5: `lsp/init.lua` — コメントアウト済み HACK 約 50 行を削除、`vim.diagnostic.config` を autocmd 外へ移動
- [ ] 8-6: `config/init.lua` の読み込み順を options → keymaps → lazy に変更
- [ ] 8-7: `plugins/mode.lua` の重複カラーテーブルを統合
- [ ] 8-8: `nvim-treesitter.lua` から textobjects 依存を削除（決定事項参照）
- [ ] 8-9: `after/lsp/terraform-ls.lua` を `terraformls` 命名に揃え lspconfig デフォルトを継承
- [ ] 8-10: wezterm — act 形式の統一、`tab_bar.lua` の git 結果キャッシュ追加、コメント / typo 修正
- [ ] 8-11: noice / dial / nvim-autopairs の `opts` と `config` の併存を opts に一本化
- [ ] 8-12: sketchybar — `volume.lua` の同一アイコン分岐修正、`date.lua` のフォントを `settings.font` 参照へ
- [ ] 8-13: `config/autocmd.lua` の matchadd をウィンドウごと一回登録に修正
- [ ] 8-14: `config/options.lua` — no-op の `compatible` 削除、`vim.wo.wrap` を `opt.wrap` へ
- [ ] 8-15: `nvim-hlslens.lua` の `<leader>l` と `keymaps.lua` の `<leader>n` の機能重複を整理
- [ ] 8-16: typo 一括修正（tarminal / floot / Right Terminals / searvh / jamp / snipet / complation / cleenup 等）
- [ ] 8-17: 検証 — `just lint-lua`（selene + stylua）クリーン

### Phase 9: ドキュメント・リポジトリ衛生・Claude 設定の低優先整理

- [ ] 9-1: 未追跡の `docs/{adr,plans}/2026-05-10-neovim-tui-db-client.md` に未着手であることを明記してコミット
- [ ] 9-2: `config/claude/settings.json` の未コミット差分（キー並び替え）を解消、`env.CLAUDE_CODE_EFFORT_LEVEL` と `effortLevel` の二重指定を後者に一本化
- [ ] 9-3: README — mise 手順を「`mise install` を実行」に修正、docs/adr・docs/plans への導線を追加
- [ ] 9-4: CLAUDE.md — symlinks.nix 更新ルールを「`config/` に top-level エントリ追加時」の一般則へ書き換え、GUI アプリ表に wezterm cask の例外理由を明記
- [ ] 9-5: nix-guide — Flake Inputs 表に herdr / nix-claude-code を追加、Module Structure 図を実態に更新
- [ ] 9-6: zsh-guide — mise キャッシュ判定の説明を Phase 3 後の実態に合わせ更新、plugins/（workspace）の節を追加
- [ ] 9-7: `docs/raycast.md` — Warp / Ghostty の棚卸し、karabina typo 修正
- [ ] 9-8: `config/claude/commands/review.md` を `review-diff.md` にリネーム
- [ ] 9-9: `config/claude/agents/reviewer.md` の tools を現行ツール名（Agent）に更新
- [ ] 9-10: drawio SKILL.md の詳細を references/ へ分割、Bash 履歴ログのローテーション追加
- [ ] 9-11: `tmp/` 配下の旧 tmux 前提メモを gomi で整理
- [ ] 9-12: 検証 — markdownlint / prettier がクリーン、`nix develop` 内でコミット

---

## 変更対象ファイル一覧

| ファイル                                                | Phase | 変更内容                                              |
| ------------------------------------------------------- | ----- | ----------------------------------------------------- |
| `config/claude/hooks/auto-approve-piped.sh`             | 1     | 早期ガード + deny/ask 突き合わせ                      |
| `config/claude/settings.json`                           | 1, 9  | permissions 分解、MCP false、正規表現修正、churn 解消 |
| `.claude/settings.json`                                 | 1, 2  | nix develop 限定、フックパス修正                      |
| `.claude-plugin/plugins/`                               | 2     | gopls-lsp / rust-analyzer-lsp 追加                    |
| `scripts/{bootstrap,install}.sh` / `scripts/setup/*.sh` | 2, 3  | hostname 統一、sed 検証、mise インストーラ削除        |
| `config/claude/{statusline,file-suggestion}.sh`         | 2     | bc 排除、フォールバック                               |
| `config/claude/hooks/report-herdr-state.sh`             | 2     | Linux PATH フォールバック                             |
| `nix/home/packages/{dev,lsp-tools}.nix`                 | 3, 4  | mise 追加、整列                                       |
| `nix/overlays/{default,sketchybar-app-font}.nix`        | 4     | overlay 削除・規約準拠                                |
| `flake.nix`                                             | 4     | devShell 整理                                         |
| `Justfile`                                              | 5     | shellcheck find 化、ci 依存整理、lint-docs 追加       |
| `.github/workflows/*.yml`                               | 5     | キャッシュキー、injection 対策、paths、v6 統一 ほか   |
| `config/zsh/**`                                         | 3, 6  | command/builtin 明示、デッドコード削除 ほか           |
| `config/nvim/**`                                        | 7, 8  | 動作バグ修正、規約準拠、リネーム、typo                |
| `config/wezterm/*.lua`                                  | 7, 8  | keymap 重複、イベント名、キャッシュ、形式統一         |
| `config/sketchybar/items/{volume,date}.lua`             | 8     | アイコン分岐、フォント参照                            |
| `.luarc.json` / `config/nvim/.luarc.json`               | 7     | hint 設定のトップレベル化                             |
| `README.md` / `CLAUDE.md` / `.claude/skills/**`         | 9     | 実態合わせ                                            |
| `docs/adr,plans/2026-05-10-neovim-tui-db-client`        | 9     | コミット                                              |
| `docs/raycast.md`                                       | 9     | 棚卸し                                                |
