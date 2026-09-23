# AI エージェント運用ガイド

Claude Code / Codex CLI / Gemini CLI の具体的な運用手順。

## 全体像

| 対象                                       | 置き場所                          | 届き方                                                         | 反映タイミング                  |
| ------------------------------------------ | --------------------------------- | -------------------------------------------------------------- | ------------------------------- |
| 共通指示（AGENTS.md）                      | `config/agents/AGENTS.md`         | symlink（`~/.codex` / `~/.gemini` / Claude は `@import` 経由） | 保存した瞬間                    |
| Claude 固有指示                            | `config/claude/CLAUDE.md`         | symlink                                                        | 保存した瞬間                    |
| skills（3 エージェント共通）               | `config/agents/skills/<name>/`    | skill 単位 symlink（`~/.agents/skills` と `~/.claude/skills`） | 編集は即時・追加削除は `nrs`    |
| MCP サーバー定義                           | `nix/home/agents/mcp-servers.nix` | Nix が 3 形式へ変換して配布                                    | `nrs`                           |
| `settings.json` / `config.toml` の base    | `config/{claude,codex,gemini}/`   | `agents-sync` が深マージして実ファイル生成                     | `nrs` または `just agents-sync` |
| マシン固有設定                             | `config/**/*.local.{json,toml}`   | 同上（untracked、後勝ち）                                      | 同上                            |
| 秘匿値                                     | `config/zsh/eager/local.zsh`      | 環境変数 export（untracked）                                   | 新しいシェルから                |
| パッケージ（claude-code / codex / gemini） | flake input `llm-agents`          | overlay `pkgs.llm-agents.*`                                    | flake.lock 更新 + `nrs`         |

## 日常の操作

### 指示を変える

- 3 エージェント共通: `config/agents/AGENTS.md` を編集。保存した瞬間に反映される
- Claude だけ: `config/claude/CLAUDE.md` の `## Claude Code` 以下に書く
- リポジトリごとの指示: `AGENTS.md` に書く（Claude 2.1.277+ / Codex / Gemini が同じファイルを読む）。CLAUDE.md しか無い既存リポジトリはそのままでよい（Claude は従来どおり、Codex は `project_doc_fallback_filenames` で読める）
- 注意: リポジトリに `CLAUDE.md` / `CLAUDE.local.md` を足すと Claude はそちらを優先して `AGENTS.md` を読まなくなる（併読したい場合は `/config` の Project instructions を `claude-md-and-agents-md` へ）

### skill を追加する

```bash
mkdir config/agents/skills/<name>
$EDITOR config/agents/skills/<name>/SKILL.md   # frontmatter: name / description
git add config/agents/skills/<name>
nrs   # flake は Git 追跡ファイルしか見えないため git add が必須
```

- コマンド相当（`/name` で手動起動のみ）にするなら frontmatter に `disable-model-invocation: true`
- 既存 skill の**編集**は symlink 経由で即時反映（`nrs` 不要）。**削除**は `git rm -r` + `nrs`
- ここに置いた skill は 3 エージェント全てから見える（`~/.agents/skills` を Codex / Gemini が共有するため、エージェント別の絞り込みは不可）。Claude 専用にしたいものは marketplace / plugin で入れる

### 外部 skill を追加・更新する

追加: `flake.nix` に `flake = false` の input を足し、`nix/home/agents/skills.nix` の `external` に登録する。

```nix
# flake.nix
some-skill = {
  url = "github:owner/repo";
  flake = false;
};

# skills.nix の external
some-skill = {
  src = "${inputs.some-skill}/skills/some-skill";  # リポジトリ内の skill ディレクトリ
  packages = [ pkgs.uv ];                          # スクリプトが必要とするツール（任意）
};
```

更新: `nix flake update <input名>` → `nrs`（毎週土曜の flake.lock 自動更新 PR でも追随する）。

### MCP サーバーを追加・削除する

`nix/home/agents/mcp-servers.nix` を編集して `nrs`。3 エージェントへ自動配布される。

```nix
example = {
  type = "http";                    # "stdio" | "http"
  url = "https://example.com/mcp";
  bearerTokenEnv = "EXAMPLE_TOKEN"; # 認証が要る場合（値は local.zsh へ）
  agents = [ "claude" "codex" ];    # 配布先を絞る場合（省略時は全員）
};
```

- Claude のツール名は `mcp__plugin_dotfiles-mcp_<server>__<tool>` 形式。permissions / hooks の matcher もこの形式で書く
- 確認: `claude mcp list` / `codex mcp list` / `gemini mcp list`

### 秘匿値を使う

```zsh
# config/zsh/eager/local.zsh（untracked。無ければ作る）
export EXAMPLE_TOKEN="xxx"
```

設定側にはトークンを書かず、`bearerTokenEnv` / `envVars` で環境変数名だけを参照する。zsh を経由しない GUI 直接起動では解決されない点に注意。

### settings / config を変える

| 変えたいもの             | 編集するファイル                               |
| ------------------------ | ---------------------------------------------- |
| Claude の permissions 等 | `config/claude/settings.json`                  |
| Codex の model / TUI 等  | `config/codex/config.toml`                     |
| Gemini の設定            | `config/gemini/settings.json`                  |
| Codex のコマンド権限     | `config/codex/rules/default.rules`             |
| 共通 hook スクリプト     | `config/agents/hooks/`（配線は各 base に書く） |

- `settings.json` / `config.toml` は編集後に `nrs` か `just agents-sync` で `~/` 側の実ファイルへ反映する（symlink ではないので保存だけでは反映されない）
- rules / hooks スクリプトは symlink なので保存で反映される（起動中のセッションは再起動）
- コマンド権限は Claude の `permissions` を正とし、Codex の rules へ手で写す。検証は `codex execpolicy check --rules config/codex/rules/default.rules -- <command>`

### マシン固有の設定

`*.local.*.sample` をコピーして作る（untracked のまま運用）。

```bash
cp config/claude/settings.local.json.sample config/claude/settings.local.json
```

マージ規則: object は再帰、配列は和集合（順序保持・重複除去）、scalar は local 勝ち。**local で base の要素を削除・置換はできない**。消したいものは base 側を編集する。

### エージェントの実行時変更を確認する

エージェントが `/model` や `/effort` で書き換えた内容は次の `nrs` で base に戻る。何が変わっているかは事前に確認できる。

```bash
just agents-diff   # 生成結果と現在のファイルの差分を表示
just agents-sync   # nrs を待たずに base の状態へ戻す
```

例外として引き継がれるキー（エージェント所有）: Codex の `projects` / `notice` / `tui.model_availability_nux` / `tui.theme`、Gemini の `security.auth` / `ui.theme`。恒久化したい変更が base に戻ってしまう場合は、base か local に書くか、`nix/home/agents/sync.nix` の keep リストへ昇格する。

### Claude plugin を管理する

- SSOT は `config/claude/settings.json` の `extraKnownMarketplaces`（marketplace）と `enabledPlugins`（有効化）
- 新マシンでは `just agents-plugins` を一度実行すると宣言済み plugin が冪等に install される

### パッケージを更新する

- 自動: 毎週土曜の `update-flake.yml` が flake.lock 更新 PR を作る → マージして `nrs`
- 手動: `nix flake update llm-agents` → `nrs`
- codex がソースビルドされ始めたら cache miss を疑う: `nix config show | grep numtide` で substituter を確認

## 新マシンのセットアップ

1. `bootstrap.sh`（Linux は `/etc/nix/nix.conf` へ substituter が自動追記される）
2. 既存マシンからの移行の場合のみ: `trash ~/.claude/skills`（旧世代のディレクトリ symlink が残っていると switch が失敗する）
3. `nrs`
4. `just agents-plugins`
5. 必要に応じて `config/zsh/eager/local.zsh` と `*.local.*` を作成

## トラブルシューティング

| 症状                                       | 対処                                                                                     |
| ------------------------------------------ | ---------------------------------------------------------------------------------------- |
| switch が `mkdir: File exists` で失敗      | 旧 `~/.claude/skills` symlink の残骸。`trash ~/.claude/skills` して再実行                |
| 新しい skill が認識されない                | `git add` 忘れ。flake は Git 追跡ファイルのみ参照                                        |
| terraform MCP が接続失敗                   | docker（OrbStack）が起動していない                                                       |
| gemini の MCP が Disabled                  | フォルダ未 trust。gemini を対話起動して trust する                                       |
| 設定変更が `~/` に反映されない             | base は symlink ではない。`just agents-sync` か `nrs` を実行                             |
| `darwin-rebuild rollback` で設定が戻らない | agents-sync の生成物は rollback 対象外。旧世代の activation を再実行する                 |
| マージ結果がおかしい                       | `nix flake check`（`checks.agents-merge`）で回帰確認。規則は上記「マシン固有の設定」参照 |
