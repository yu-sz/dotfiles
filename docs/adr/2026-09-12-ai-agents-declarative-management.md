# AI エージェント設定の宣言的管理

Date: 2026-09-12
Status: Accepted

## Context

Claude Code を `ryoppippi/nix-claude-code` overlay で導入し、`~/.claude/*` を `mkOutOfStoreSymlink` で dotfiles に直リンクしている。ここに Codex CLI と Gemini CLI を加え、skills / MCP / 指示（AGENTS.md）を 3 エージェントで共有しつつ、Nix で宣言的に管理したい。

現状の課題:

- **エージェントの実行時書き込みが repo を汚す**: Claude Code は `/model` `/effort` `enabledPlugins` を `~/.claude/settings.json` に書き戻す。symlink 先が dotfiles の作業ツリーなので、今日も `model` の自動移行で `git status` が dirty になった
- **ローカル層がない**: `settings.json` / `config.toml` にマシン固有値や秘匿値を分離して置く仕組みがなく、Claude Code には user-level の `settings.local.json` も存在しない（[settings](https://code.claude.com/docs/en/settings)）
- **Codex が `config.toml` に実行時書き込みする**: `[projects."…"].trust_level` / `notice` 等を起動時に直接書き込むため（[codex#14601](https://github.com/openai/codex/issues/14601)）、symlink 運用では repo が dirty になる。0.58 の symlink 置換リグレッション（[codex#6646](https://github.com/openai/codex/issues/6646)）は PR#9445 で修正済み
- **共有先がない**: skills は `config/claude/skills` に閉じており、Codex / Gemini から見えない。MCP は `~/.claude/mcp/.mcp.json` を `--mcp-config` で渡す Claude 専用形式
- **パッケージ供給源の偏り**: nix-claude-code は Claude Code 専用で cachix が機能していない（narinfo 404 を確認）。nixpkgs は人手更新で追随が保証されず、`gemini-cli` は 0.47.0 のまま 2026-06 から更新停止（`codex` は本稿時点では同着）

要件: skills / MCP の共有、最新版追従、可能な限り Nix で宣言的、ローカル設定はローカルに置ける、極端な hack をしない、採用ツールの信頼性を裏取りする。

## Decision

### 結果の構成

```text
config/
├── agents/                 # 共有（2 の「共有」に該当するもの）
│   ├── AGENTS.md           #   指示。CLAUDE.md は @import、Codex / Gemini は symlink で読む
│   └── skills/             #   ローカル skills（旧 commands 含む）。外部 skills は flake input。どちらも skill 単位で ~/.agents/skills と ~/.claude/skills へ symlink
├── claude/                 # 固有: CLAUDE.md / settings.json(base) / settings.local.json / agents / hooks / UI 系
├── codex/                  # 固有: config.toml(base) / config.local.toml
├── gemini/                 # 固有: settings.json(base) / settings.local.json
└── zsh/eager/local.zsh     # 秘匿値の export（untracked）
nix/home/agents/
├── default.nix             # 1 供給: pkgs.llm-agents.{claude-code,codex,gemini-cli}
├── skills.nix              # 2 共有 + 3 配布: ローカル（dotfiles）と外部（flake input）の skills を skill 単位で symlink
├── mcp-servers.nix         # 2 共有: MCP 定義（中立スキーマ）。mcp-lib.nix が 3 形式に変換
├── sync.nix                # 3 配布: agents-sync（base ⊕ MCP ⊕ local → 実ファイル）+ activation
└── claude-code.nix / codex.nix / gemini-cli.nix   # 3 配布: symlink と plugin
```

ホーム側の配置、データフロー、所有権表は [Plans](../plans/2026-09-12-ai-agents-declarative-management.md) を参照。

### 決定の軸

管理対象を 6 つに分け、それぞれに対して 4 つの問いに答える。Decision の見出しは問いに 1 対 1 で対応する。

| 対象                           | 1. 供給: どこから取るか | 2. 境界: 共有か固有か | 3. 配布: どの機構で置くか                                                | 4. 分離: ローカル値・秘匿値 |
| ------------------------------ | ----------------------- | --------------------- | ------------------------------------------------------------------------ | --------------------------- |
| バイナリ                       | **llm-agents.nix**      | –                     | `home.packages`                                                          | –                           |
| 指示                           | –                       | **共有**（AGENTS.md） | symlink + Claude は `@import`                                            | –                           |
| skills（commands 含む）        | –                       | **共有**              | skill 単位の symlink（ローカル → dotfiles、外部 → flake input の store） | –                           |
| MCP                            | –                       | **共有**（定義）      | Nix 生成 → Claude plugin / Codex TOML / Gemini JSON                      | 値は env 参照               |
| settings / permissions / hooks | –                       | **固有**              | settings は activation 合成の実ファイル、他は symlink                    | `*.local.*`                 |
| 秘匿値                         | –                       | –                     | –                                                                        | untracked `local.zsh`       |

### 1. 供給: バイナリは `numtide/llm-agents.nix` から取る

| 観点                                            | llm-agents.nix                                                                 | nix-claude-code（現行）     | nixpkgs unstable                                  |
| ----------------------------------------------- | ------------------------------------------------------------------------------ | --------------------------- | ------------------------------------------------- |
| 対象                                            | **claude-code / codex / gemini-cli / opencode 他 200+**                        | Claude Code のみ            | 個別                                              |
| 更新自動化                                      | **cron 4 回/日、上流に数時間〜1 日で追随**                                     | cron 毎時                   | 人手（claude-code は 2〜3 日ごと）                |
| 現在の版（上流最新 2.1.269 / 0.154.0 / 0.59.0） | **2.1.269 / 0.154.0 / 0.59.0**                                                 | 2.1.269 / – / –             | 2.1.266 / 0.154.0 / 0.47.0（gemini-cli は停止中） |
| バイナリキャッシュ                              | **cache.numtide.com（aarch64-darwin / x86_64-linux とも narinfo 200 を確認）** | cachix を謳うが narinfo 404 | cache.nixos.org                                   |
| Stars / メンテナ                                | **1.9k / numtide（claude-code メンテナに ryoppippi も参加）**                  | 71 / 個人                   | –                                                 |

- [numtide/llm-agents.nix](https://github.com/numtide/llm-agents.nix)（旧 nix-ai-tools）。`packages.${system}` を overlay で `pkgs.llm-agents.*` に橋渡しする（`hunk` と同じパターン）
- `inputs.nixpkgs.follows` は**しない**。README が「follows を省略すれば binary cache から取れる（follows すると自前 nixpkgs に対する再ビルドになる）」と明示して省略を推奨。codex は `rustPlatform` のソースビルドのため（パッケージ定義で確認）darwin での影響が特に大きい
- substituter は flake の `nixConfig` では配布**しない**。daemon が信頼しないユーザーでは無視される（本機は `trusted-users = root` で、既存 ryoppippi.cachix の警告実績あり）。nix-darwin の `nix.settings` と CI の `extra_nix_config` で配布する
- llm-agents はパッケージのライセンスを `free = true` で上書きしているため、消費者側の `allowUnfreePredicate` は不要（`allowedUnfree` から `claude` を削除）
- `nix-claude-code` input と `ryoppippi.cachix.org` は削除する

### 2. 境界: 「エージェント横断の標準が存在するもの」だけを共有する

共有の可否は好みではなく、3 エージェントが同じ形式を読めるかで決める。

| 対象                | 横断標準                                            | Claude                        | Codex                        | Gemini                | 判定                       |
| ------------------- | --------------------------------------------------- | ----------------------------- | ---------------------------- | --------------------- | -------------------------- |
| 指示                | AGENTS.md 慣行                                      | ❌ 読まない。`@import` で吸収 | ✅ `~/.codex/AGENTS.md`      | ✅ `context.fileName` | **共有**                   |
| skills              | [Agent Skills](https://agentskills.io/)（SKILL.md） | ✅ `~/.claude/skills`         | ✅ `~/.agents/skills`        | ✅ `~/.agents/skills` | **共有**                   |
| commands            | –                                                   | skills に統合済み             | –                            | –                     | **skills に統合して共有**  |
| MCP                 | [MCP](https://modelcontextprotocol.io/)             | `.mcp.json`                   | `[mcp_servers]` TOML         | `mcpServers` JSON     | **定義を共有、書式は生成** |
| permissions         | なし                                                | ツール名 glob                 | approval + sandbox 境界      | ツール単位の確認      | **固有**                   |
| hooks               | なし（形式は似ている）                              | `ask` あり                    | `ask` 非対応（続行され得る） | –                     | **固有**                   |
| model / effort / UI | なし                                                | ベンダー固有の値              | 同左                         | 同左                  | **固有**                   |

- **指示**: Claude Code は AGENTS.md を読まないが `@import` パターンを公式に推奨（[memory](https://code.claude.com/docs/en/memory#agents-md)）。Codex はネイティブ（`~/.codex/AGENTS.override.md` があればそちらが優先。instructions/mod.rs で確認）、Gemini は `context.fileName` で任意名を読む
- **skills**: `~/.agents/skills` が事実標準。Codex はネイティブに読む（[skills](https://learn.chatgpt.com/codex/skills)。`~/.codex/skills` も deprecated パスとして読み続ける — host_roots.rs で確認）。Gemini は公式には `~/.gemini/skills` が主で `~/.agents/skills` はその alias だが、どちらもネイティブに読み、同名は alias 側が優先されて重複排除される（[skills](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/skills.md)）
  - Claude だけ非対応（[#50778](https://github.com/anthropics/claude-code/issues/50778) は #6235 への重複クローズ・機能は未実装のまま）だが、symlink された skill フォルダを公式サポートする
- **commands**: Claude Code は commands を skills に統合済みで、`disable-model-invocation: true` の skill が command 相当になる（[skills](https://code.claude.com/docs/en/skills)）。skills にすれば他 2 者からも見える
- **permissions / hooks / settings を共有しない根拠**: 調査した全事例（i9wa4 / ryoppippi / p3ac0ck / wimpysworld / yosket / chai0204）が per-agent。permissions の共通化は i9wa4 の deny リストが唯一で、playpark は自動変換を試みて撤退している。標準がないものを共通スキーマにすると最小公倍数のロッシーな変換と escape hatch の二重構造になる
- **hooks**: Codex hooks は Claude と同形式だが `permissionDecision: "ask"` は unsupported 扱いで、hook failure behavior の設定次第でツール実行が続行され得る（[codex#28437](https://github.com/openai/codex/issues/28437)）

### 3. 配布: 「誰が書くか」でファイルを 3 分類し、機構を固定する

| 分類               | 対象                                                                | 機構                                                                                                                 | 反映                       |
| ------------------ | ------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | -------------------------- |
| 人が編集する       | AGENTS.md / CLAUDE.md / skills / hooks / agents                     | dotfiles への out-of-store symlink（現行維持）                                                                       | 保存した瞬間               |
| Nix が計算する     | MCP 定義 → 各エージェント形式、Claude plugin                        | Nix store                                                                                                            | `nrs`                      |
| エージェントが書く | Claude `settings.json`、Codex `config.toml`、Gemini `settings.json` | activation で base ⊕ Nix 生成 ⊕ local を深マージした mode 644 の実ファイル。実行時変更より宣言（base ⊕ local）が優先 | `nrs` / `just agents-sync` |

#### 3a. 可変ファイルは activation 合成にし、home-manager 公式モジュールは採用しない

| 観点                                                               | activation 合成（採用）              | HM `programs.claude-code` / `programs.codex`                                                                                                                                                                                            | 現状 symlink            |
| ------------------------------------------------------------------ | ------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------- |
| 実行時書き込み（`/model` `/effort` `plugin install`、Codex trust） | **✅ 実ファイルなので通る**          | ❌ store への read-only symlink で EROFS（[claude-code#78162](https://github.com/anthropics/claude-code/issues/78162)、[home-manager#9831](https://github.com/nix-community/home-manager/issues/9831) は symlink 自体が削除される事故） | ✅ ただし repo が dirty |
| Codex `config.toml`                                                | **✅**                               | ❌ symlink が実ファイルに置換され HM と衝突（[home-manager#9397](https://github.com/nix-community/home-manager/issues/9397)）                                                                                                           | ❌ 同左                 |
| ローカル層（`*.local.*`）                                          | **✅ 深マージ**                      | ❌ 仕組みなし                                                                                                                                                                                                                           | ❌ 仕組みなし           |
| MCP のツール名                                                     | **不変**                             | plugin 化で `mcp__plugin_claude-code-home-manager_*` になる（長い名前の短縮 rename が permissions を壊す議論、[#9446](https://github.com/nix-community/home-manager/issues/9446)）                                                      | 不変                    |
| 採用実績                                                           | i9wa4（copy）、ryoppippi（jq merge） | HM 公式                                                                                                                                                                                                                                 | –                       |

- 引き継ぎ（keep）の基準: UI 操作で書き戻され、消失が再認証・再 trust・UI リセットを起こすキーのみ既存ファイルから引き継ぐ（Codex `projects` / `notice` / `tui.theme`、Gemini `security.auth` / `ui.theme`）。model / effort / permissions は base 所有で、実行時変更が `nrs` で戻るのは仕様
- keep の取りこぼし（switch 後に意図せず消える設定）は `agents-diff` で特定し、keep か base / local に昇格する
- `~/.claude.json`、`~/.claude/plugins/*`、`~/.codex/auth.json` はエージェント所有として管理対象外のまま

#### 3b. skills はローカル・外部とも skill 単位の symlink で配布し、agent-skills-nix は採用しない

| 種別            | 正                                                  | 配布                                           | 更新                                         |
| --------------- | --------------------------------------------------- | ---------------------------------------------- | -------------------------------------------- |
| ローカル skills | `config/agents/skills/<name>`                       | dotfiles への out-of-store symlink（即時編集） | 保存した瞬間（新規追加は `git add` + `nrs`） |
| 外部 skills     | flake input（`flake = false`）+ リポジトリ内 subdir | store への symlink（`flake.lock` で pin）      | `nix flake update <input>` → `nrs`           |

- 両方を同じ `~/.agents/skills/<name>`（Codex / Gemini）と `~/.claude/skills/<name>`（Claude）に置く。ディレクトリ丸ごとの symlink にすると外部 skills を同居させられないため、最初から skill 単位にする
- ここに置く skill は定義上 3 エージェント共通。`~/.agents/skills` を Codex / Gemini が共有するため片方だけへの配布は構造的に不可能で、特定エージェント専用の skill は下記の固有 marketplace に置く
- 物理的な実体はローカルなら dotfiles、外部なら store の 1 箇所だけでコピーを作らない。同名は Nix の評価エラーで止める（note の silent drift 3 類型を構造的に排除）
- 外部 skill が実行環境を要する場合（例: [coji/natural-japanese](https://github.com/coji/natural-japanese) の lint は `uv run` で sudachipy を解決）は、skill と同じ場所で Nix パッケージを宣言して供給する
- [Kyure-A/agent-skills-nix](https://github.com/Kyure-A/agent-skills-nix)（233★）は同じことを提供するが、ローカル skills も store にコピーされ編集のたびに rebuild が要る（README: "The entire source root is imported into the store"）。供給元が多数になり `subdir` 探索や `rename` が要る段階で乗り換えを再検討する
- エージェント固有の marketplace（Claude `enabledPlugins`、Codex `codex plugin`、Gemini extensions）は「そのエージェントでしか使わない skill」用に残す。3 エージェントで使うものだけ flake input に載せる

#### 3c. MCP は自前レンダラで 3 形式に生成し、Claude には skills-dir plugin で渡す

| 観点                 | 自前レンダラ（採用）    | mcp-servers-nix                                                   |
| -------------------- | ----------------------- | ----------------------------------------------------------------- |
| Gemini 対応          | **✅**                  | ❌ flavor なし                                                    |
| 非パッケージサーバー | **中立スキーマ 1 箇所** | flavor 別の生書き                                                 |
| サーバー本体の pin   | `npx -y`（現状と同じ）  | Nix パッケージ（後からスキーマの `command` に指す形で部分採用可） |

Claude Code は user-level の宣言的 MCP ファイルを持たない（[#32145](https://github.com/anthropics/claude-code/issues/32145) open）ため、配布先を別途選ぶ。

| 候補                                                  | 公式 | 全起動経路                | Claude が書かない     | 判定                                                 |
| ----------------------------------------------------- | ---- | ------------------------- | --------------------- | ---------------------------------------------------- |
| skills-dir plugin `~/.claude/skills/<name>/.mcp.json` | ✅   | ✅                        | ✅                    | **採用**                                             |
| `--mcp-config`（現行）                                | ✅   | ❌ フラグを付けた起動のみ | ✅                    | 起動経路ごとにフラグを配る必要                       |
| `~/.claude.json` user scope                           | ✅   | ✅                        | ❌ 更新時に消える報告 | 不採用                                               |
| `claude` を wrapProgram                               | –    | ✅                        | ✅                    | サブコマンドが `--mcp-config` を拒否（実測）。不成立 |

- plugin は `.claude-plugin/plugin.json` を置くだけで `enabledPlugins` 不要で毎回ロードされる（[plugins-reference](https://code.claude.com/docs/en/plugins-reference)）。home-manager upstream も同じ構成。実機 2.1.269 で自動ロード・`.mcp.json` 内 `${VAR}` 展開・ツール名 `mcp__plugin_<name>_<server>__<tool>` を実測確認済み
- レンダラは [wimpysworld/nix-config](https://github.com/wimpysworld/nix-config/tree/main/home-manager/_mixins/agentic) 方式。[natsukium/mcp-servers-nix](https://github.com/natsukium/mcp-servers-nix)（300★）は Gemini 非対応のため不採用
- MCP + skills + hooks を 1 plugin/extension に束ねる「バンドル化」は見送る。Codex はローカル plugin も cache にコピーし即時編集ができず、Claude の skill 名が `plugin:skill` 形式になる。配布は Nix が担うため可搬性の利点が重複する。他者と共有し始めた時点で `config/agents/` をバンドルのルートに昇格させれば移行できる

### 4. 分離: ローカル値は untracked ファイル、秘匿値は環境変数参照にする

| 観点                     | 環境変数 + untracked local（採用）                         | sops-nix                        | 1Password CLI              |
| ------------------------ | ---------------------------------------------------------- | ------------------------------- | -------------------------- |
| 追加ツール               | **なし**                                                   | sops-nix / age / sops           | 1Password + `op`（未導入） |
| 「ローカルはローカルに」 | **✅ repo に値も暗号文も入らない**                         | ⚠️ 暗号文が repo に入る         | ✅                         |
| 新マシン移行             | 手でコピー                                                 | age 鍵 1 つ                     | ログイン                   |
| 設定側の書式             | 全案共通（`${VAR}` / `env_vars` / `bearer_token_env_var`） | 同左                            | 同左                       |
| 非ターミナル起動         | ⚠️ zsh 経由の起動のみ（`.zshenv` で source）               | ✅ ファイルへ直接レンダリング可 | ✅ helper が実行時取得     |

- 秘匿値の置き場は設定ファイルの外に固定する: Claude `.mcp.json` は `${VAR}` 展開（[mcp](https://code.claude.com/docs/en/mcp)）、Codex は `env_vars` / `bearer_token_env_var`（[config-reference](https://learn.chatgpt.com/docs/config-file/config-reference)）、Gemini は settings.json 全体で `${VAR}` 展開（[configuration](https://github.com/google-gemini/gemini-cli/blob/main/docs/reference/configuration.md)）
- 値は `config/zsh/eager/local.zsh`（`.gitignore` の `local.*` で除外済み）で export し、`.zshenv` から source する。sheldon の eager glob は interactive shell 限定（`.zshrc` 経由）のため、`.zshenv` で読み非インタラクティブ起動でも解決する（export のみで二重 source は冪等）
- zsh を経由しない GUI 直接起動では環境変数が解決されない。その経路が必要になったら `launchctl setenv` か keychain 読み helper に移行する
- ローカル上書きは `config/claude/settings.local.json` / `config/codex/config.local.toml` / `config/gemini/settings.local.json` を深マージする。`.gitignore` に `*.local.*` を追加
- 秘匿値が増えマシンが 3 台以上になり手動コピーが苦になったら sops-nix へ移行する。設定側は env 参照のままなので移行コストは値の供給部分のみ

## Consequences

- Claude Code / Codex / Gemini が同一 input から最新版で入り、`nix flake update` で 3 つ同時に追随する。cache.numtide.com により darwin でも codex のソースビルドを避けられる。追随の実効値は flake.lock の更新頻度（update-flake.yml の週次）に律速され、即時反映は `nix flake update llm-agents` → `nrs`
- 共有の境界が「横断標準の有無」で固定されるため、新しいエージェントを足す時も判断が機械的になる。標準がない設定は固有ディレクトリに置く
- `settings.json` / `config.toml` の実行時変更は次の `nrs` で base に戻る（keep 対象の trust / auth / theme は引き継がれる）。永続化したい変更は `agents-sync --diff` で確認して base か local に移す運用になる
- skills は `config/agents/skills/` に置くだけで 3 エージェントから見える。既存 skill の編集は即時反映だが、**新規 skill の追加（ローカル・外部とも）は per-skill symlink の再評価のため `git add` + `nrs` が要る**。外部 skills の更新は `nix flake update <input>`
- Claude の MCP ツール名が `mcp__plugin_dotfiles-mcp_<server>__<tool>` になる。permissions と hooks matcher の書き換えが必要で、`--mcp-config` を渡していた zabrze snippet / sidekick.lua は素の `claude` に戻る
- plugin `.mcp.json` での `${VAR}` 展開は CLI 2.1.269 の実機で確認済み。Desktop app には未展開の報告（[#40372](https://github.com/anthropics/claude-code/issues/40372)）が残るが、本構成の起動経路は CLI のみ。Phase 3-11 は switch 後の回帰確認
- 動的トークンが要る場合は `headersHelper`（公式機構）を使う。「plugin / project スコープで秘匿系環境変数が helper から除去される」という制約は公式明文を確認できておらず、採用時点で実測する
- 合成スクリプト（jq + Python `tomllib` / `tomli-w`）は自前コードとして保守対象になる。HM 公式モジュールが可変ファイル問題を解決した時点で乗り換えを再検討する
