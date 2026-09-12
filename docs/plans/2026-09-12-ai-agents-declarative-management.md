# AI エージェント設定の宣言的管理 実装計画

## 概要

- パッケージ供給源を `numtide/llm-agents.nix` に統一し、Claude Code / Codex CLI / Gemini CLI を最新版で導入する
- `config/agents/` を単一の正として AGENTS.md / skills / MCP 定義を置き、3 エージェントの公式な入口へ配布する
- エージェントが実行時に書き換える `settings.json` / `config.toml` は activation で base ⊕ MCP ⊕ local を合成した実ファイルにする
- 秘匿値は環境変数参照 + untracked `local.zsh`、ローカル上書きは `*.local.*` ファイルで分離する

**出典**:

- [ADR: AI エージェント設定の宣言的管理](../adr/2026-09-12-ai-agents-declarative-management.md)

---

## 決定事項

| 項目                           | 決定                                                                                                                           | 備考                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| パッケージ                     | **`inputs.llm-agents.packages.${system}` を overlay で `pkgs.llm-agents.*` に橋渡し**                                          | `follows` しない。`nix-claude-code` は削除                                                                                                                                                                                                                                                                                                                                                                                                                        |
| substituter                    | **`darwin-shared.nix` の `nix.settings` + CI の `extra_nix_config` で cache.numtide.com を配布**                               | flake `nixConfig` は trusted-users 制約で無視されるため補助扱い。Linux 実機は `bootstrap.sh` で `/etc/nix/nix.conf` に追記                                                                                                                                                                                                                                                                                                                                        |
| マージ検証                     | **`perSystem.checks.agents-merge` で merge.jq / merge-toml.py を fixtures 検証**                                               | `just check` / CI で毎回実行。jq は値束縛（`$a; $b`）必須 — フィルタ束縛はネスト配列マージが壊れる（実測）                                                                                                                                                                                                                                                                                                                                                        |
| 静的ファイル                   | **`mkOutOfStoreSymlink` 維持**                                                                                                 | CLAUDE.md / AGENTS.md / skills / agents / hooks                                                                                                                                                                                                                                                                                                                                                                                                                   |
| 可変ファイル                   | **`agents-sync` が base ⊕ MCP ⊕ local を深マージし mode 644 の実ファイルへ**                                                   | Claude `~/.claude/settings.json`、Codex `~/.codex/config.toml`、Gemini `~/.gemini/settings.json`                                                                                                                                                                                                                                                                                                                                                                  |
| 深マージ規則                   | **object は再帰、array は `a + (b - a)`（順序保持・重複除去）、scalar は後勝ち**                                               | local で配列要素の削除・置換はできない（hooks は同一 matcher でも和集合で両方残る。上書きは base を編集）                                                                                                                                                                                                                                                                                                                                                         |
| 引き継ぎキー                   | **Codex `projects` / `notice` / `tui.model_availability_nux` / `tui.theme`、Gemini `security.auth` / `ui.theme`**              | 基準: UI 操作で書き戻され、消失が再認証・再 trust・UI リセットを起こすキー。Codex が実行時に書くキーの全量は edit.rs で確認済み（`model` / `model_reasoning_effort` / `service_tier` / `notice.*` / `mcp_servers` / `tool_suggest.disabled_tools` / `skills.config` / `tui.{theme,pet,status_line,model_availability_nux}` 等）。keep 外が `nrs` で base に戻るのは仕様。取りこぼしは `agents-diff` で発見し keep か base / local に昇格。Claude は base 完全勝ち |
| skills                         | **ローカル（dotfiles）と外部（flake input）を skill 単位で `~/.agents/skills/<name>` と `~/.claude/skills/<name>` へ symlink** | `skills.nix`。ローカルは `readDir` で列挙、外部は `inputs.<name>` + `subdir`。同名は評価エラー。skill は 3 エージェント共通（`~/.agents/skills` 共有のため per-agent 配布は不可）。新規追加は `git add` + `nrs`                                                                                                                                                                                                                                                   |
| MCP 定義                       | **`nix/home/agents/mcp-servers.nix` の中立 attrset**                                                                           | `type` / `command` / `args` / `url` / `env` / `envVars` / `bearerTokenEnv` / `headers` / `agents`                                                                                                                                                                                                                                                                                                                                                                 |
| Claude MCP                     | **skills-dir plugin `~/.claude/skills/dotfiles-mcp/`（store 生成）**                                                           | ツール名 `mcp__plugin_dotfiles-mcp_<server>__<tool>`（実セッションで形式を実測済み）。`--mcp-config` は撤去                                                                                                                                                                                                                                                                                                                                                       |
| Codex MCP                      | **`config.toml [mcp_servers]` を Nix 生成 TOML で合成**                                                                        | `env_vars` / `bearer_token_env_var` に変換                                                                                                                                                                                                                                                                                                                                                                                                                        |
| Gemini MCP                     | **`settings.json mcpServers` を Nix 生成 JSON で合成**                                                                         | `httpUrl` / `${VAR}`                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| 指示                           | **`config/agents/AGENTS.md` が正**                                                                                             | CLAUDE.md は `@~/.config/agents/AGENTS.md` + Claude 固有。`rules/tools.md` の内容は AGENTS.md へ統合し `rules/` は廃止                                                                                                                                                                                                                                                                                                                                            |
| ローカル層                     | **`config/{claude/settings,codex/config,gemini/settings}.local.{json,toml}`**                                                  | `.gitignore` に `*.local.*` と `!*.local.*.sample`                                                                                                                                                                                                                                                                                                                                                                                                                |
| 秘匿値                         | **`config/zsh/eager/local.zsh` で export**                                                                                     | 設定側は `${VAR}` / `env_vars` / `bearer_token_env_var` 参照のみ。`.zshenv` から source し zsh 経由の全起動で有効（GUI 直接起動は対象外）                                                                                                                                                                                                                                                                                                                         |
| just                           | **`agents-sync` / `agents-diff` / `agents-plugins`**                                                                           | 合成の単体実行、実行時変更の差分、新マシンでの plugin install                                                                                                                                                                                                                                                                                                                                                                                                     |
| commands                       | **skills に統合**                                                                                                              | `disable-model-invocation: true` で command 相当。Codex / Gemini からも skill として見える                                                                                                                                                                                                                                                                                                                                                                        |
| settings / permissions / hooks | **エージェント固有のまま**                                                                                                     | 世間の全事例が per-agent。共通スキーマ化は自前変換になるため行わない                                                                                                                                                                                                                                                                                                                                                                                              |
| Codex / Gemini の hooks        | **今回は導入しない**                                                                                                           | Codex は `ask` 非対応（unsupported 扱いで続行され得る）。必要時に別途                                                                                                                                                                                                                                                                                                                                                                                             |

---

## 設計: 完成形の構成

### リポジトリ側

```text
dotfiles/
├── config/
│   ├── agents/                      # 3 エージェント共通の正（SSOT）
│   │   ├── AGENTS.md                #   共通指示（旧 CLAUDE.md の共通部 + rules/tools.md）
│   │   └── skills/<name>/SKILL.md   #   ローカル skills（旧 config/claude/skills + commands）。外部 skills は flake input
│   ├── claude/                      # Claude 固有
│   │   ├── CLAUDE.md                #   `@~/.config/agents/AGENTS.md` + Claude 固有（LSP 等）
│   │   ├── settings.json            #   base（tracked）
│   │   ├── settings.local.json      #   local（untracked）
│   │   └── agents/ hooks/ keybindings.json statusline.sh file-suggestion.sh
│   ├── codex/
│   │   ├── config.toml              #   base（tracked。mcp_servers は含まない）
│   │   └── config.local.toml        #   local（untracked）
│   ├── gemini/
│   │   ├── settings.json            #   base（tracked。mcpServers は含まない）
│   │   └── settings.local.json      #   local（untracked）
│   └── zsh/eager/local.zsh          #   秘匿値の export（untracked）
└── nix/home/
    ├── symlinks.nix                 # config/agents → ~/.config/agents
    └── agents/
        ├── default.nix              # packages（pkgs.llm-agents.*）+ imports
        ├── skills.nix               # ローカル + 外部 skills を skill 単位で ~/.agents/skills と ~/.claude/skills へ symlink
        ├── mcp-servers.nix          # MCP 定義（中立スキーマ、データのみ）
        ├── mcp-lib.nix              # toClaude / toCodex / toGemini（純関数）
        ├── sync.nix                 # agents-sync（base ⊕ MCP ⊕ local → 実ファイル）+ activation
        ├── merge.jq                 # JSON 深マージ（sync と tests が共用）
        ├── merge-toml.py            # TOML 深マージ（sync と tests が共用）
        ├── tests/                   # merge の fixtures + run.sh（perSystem.checks.agents-merge）
        ├── claude-code.nix          # ~/.claude/* の symlink、per-skill symlink、dotfiles-mcp plugin
        ├── codex.nix                # ~/.codex/AGENTS.md
        └── gemini-cli.nix           # ~/.gemini/AGENTS.md
```

### ホーム側

凡例: `→dot` = dotfiles への out-of-store symlink（即時編集）、`→store` = Nix store への symlink（`nrs` で更新）、`gen` = agents-sync が生成する実ファイル（mode 644）、`agent` = エージェント所有・管理対象外

```text
~/.config/agents/            →dot  config/agents/            共有の正の写し
~/.agents/skills/            実ディレクトリ（Codex / Gemini がネイティブに読む）
├── <name>/                  →dot  config/agents/skills/<name>        ローカル skill
└── <ext>/                   →store inputs.<ext>/<subdir>              外部 skill（flake.lock で pin）

~/.claude/
├── CLAUDE.md                →dot  config/claude/CLAUDE.md   import 経由で AGENTS.md を読む
├── settings.json            gen   base ⊕ local              /model 等の実行時変更は次の nrs で base に戻る
├── skills/                  実ディレクトリ
│   ├── <name>/              →dot  config/agents/skills/<name>        ローカル skill
│   ├── <ext>/               →store inputs.<ext>/<subdir>              外部 skill
│   └── dotfiles-mcp/        →store {.claude-plugin/plugin.json, .mcp.json}
├── agents/ hooks/ keybindings.json statusline.sh file-suggestion.sh   →dot
└── plugins/ projects/ …     agent
~/.claude.json               agent  認証・履歴・プラグイン状態

~/.codex/
├── AGENTS.md                →dot  config/agents/AGENTS.md
├── config.toml              gen   base ⊕ mcp(Nix) ⊕ local   projects / notice / tui.theme は既存から引き継ぐ
└── auth.json, sessions/     agent

~/.gemini/
├── AGENTS.md                →dot  config/agents/AGENTS.md   context.fileName で読む
├── settings.json            gen   base ⊕ mcp(Nix) ⊕ local   security.auth / ui.theme は既存から引き継ぐ
└── (skills/ は作らない。公式は ~/.gemini/skills が主・~/.agents/skills が alias で、
     どちらも読まれ同名は alias 優先。単一配置なら二重ロードなし)
```

### データの流れ

```text
正（tracked）                              配布機構                              到達先
config/agents/AGENTS.md ──symlink────────────────────────────────────▶ ~/.codex/AGENTS.md, ~/.gemini/AGENTS.md
                        ──symlink──▶ ~/.config/agents/ ──@import──────▶ ~/.claude/CLAUDE.md
config/agents/skills/   ──readDir → per-skill symlink────────────────▶ ~/.agents/skills/<n>, ~/.claude/skills/<n>
inputs.<ext>（flake.lock）──subdir → per-skill symlink─────────────────▶ 同上（外部 skill）
mcp-servers.nix         ──toClaude──▶ store plugin ──symlink──────────▶ ~/.claude/skills/dotfiles-mcp/.mcp.json
                        ──toCodex ──▶ store toml  ──┐
                        ──toGemini──▶ store json  ──┤ agents-sync（activation / just agents-sync）
config/claude/settings.json ────────────────────────┼──深マージ──────▶ ~/.claude/settings.json
config/codex/config.toml    ────────────────────────┼──深マージ──────▶ ~/.codex/config.toml
config/gemini/settings.json ────────────────────────┘──深マージ──────▶ ~/.gemini/settings.json
*.local.{json,toml}（untracked）────────────────────┘（後勝ち）
zsh/eager/local.zsh（untracked）──export──▶ 環境変数 ──▶ ${VAR} / env_vars / bearer_token_env_var を実行時に解決
```

マージ順序は `base → Nix 生成 MCP → local → 引き継ぎキー（既存ファイル）`。後のものが勝ち、配列は順序を保って和集合。

### 所有権マトリクス

| ファイル                                                                                                                  | 所有者           | 機構                 | 更新のタイミング                   | Nix 追跡                                        |
| ------------------------------------------------------------------------------------------------------------------------- | ---------------- | -------------------- | ---------------------------------- | ----------------------------------------------- |
| AGENTS.md / CLAUDE.md / ローカル skills / agents / hooks                                                                  | 人               | out-of-store symlink | 保存した瞬間                       | 参照のみ（新規 skill 追加時だけ git add + nrs） |
| 外部 skills（flake input）                                                                                                | 上流             | store symlink        | `nix flake update <input>` → `nrs` | 完全                                            |
| MCP 定義（`mcp-servers.nix`）                                                                                             | 人               | Nix 評価 → store     | `nrs`                              | 完全                                            |
| Claude plugin `dotfiles-mcp`                                                                                              | Nix              | store symlink        | `nrs`                              | 完全                                            |
| `settings.json` / `config.toml` の base                                                                                   | 人               | agents-sync 深マージ | `nrs` または `just agents-sync`    | 参照のみ                                        |
| `*.local.*` / `local.zsh`                                                                                                 | 人（マシン固有） | 同上 / zsh source    | 同上 / 新シェル                    | なし（gitignore）                               |
| `~/.claude/settings.json` 等の生成物                                                                                      | Nix（base 優先） | 実ファイル           | `nrs` で base に戻る               | 生成物                                          |
| `~/.claude.json`、`plugins/`、`auth.json`、Codex `projects` / `notice` / `tui.theme`、Gemini `security.auth` / `ui.theme` | エージェント     | 管理外 / 引き継ぎ    | エージェント任意                   | なし                                            |

全ファイルは「人が編集するものは symlink で即時反映」「Nix が計算するものは store」「エージェントが書くものは実ファイルで受け止めて base が優先」の 3 分類に収まる。

---

## 設計: flake.nix

```nix
# flake.nix（差分のみ）
inputs = {
  # ...
  # nixpkgs は follows しない: codex は Rust ソースビルドで、follows すると
  # cache.numtide.com のヒットが nixpkgs rev 一致時に限られ darwin でフルビルドになる
  llm-agents.url = "github:numtide/llm-agents.nix";
  # nix-claude-code は削除

  # 外部 skills（flake = false で pin。skills.nix の external から参照）
  natural-japanese = {
    url = "github:coji/natural-japanese";
    flake = false;
  };
};

# home-manager モジュールへ inputs を渡す（mkDarwinConfig / mkHomeConfig の両方）
extraSpecialArgs = {
  inherit inputs username;
  dotfilesRelPath = "Projects/dotfiles";
};

# nixConfig は「他者がこの flake を使う場合」への案内として更新するが、
# 本機では効かない（daemon の trusted-users = root のため無視される。ryoppippi.cachix で警告実績）。
# 実効的な配布は darwin-shared.nix の nix.settings と CI の extra_nix_config（下記）
nixConfig = {
  extra-substituters = [ "https://cache.numtide.com" ];
  extra-trusted-public-keys = [
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
  ];
};

# flake = let ...
sharedOverlays = [
  (import ./nix/overlays)
  (_: prev: {
    hunk = inputs.hunk.packages.${prev.stdenv.hostPlatform.system}.hunk;
    # llm-agents は packages.${system} を直接参照する（overlay 経由だと自前 nixpkgs で再ビルドされキャッシュが効かない）
    llm-agents = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system};
  })
];

allowedUnfree = [
  "copilot-language-server"
  "vscode"
];

# perSystem.checks: merge ロジックの回帰テスト（just check / CI で毎回実行）
checks.agents-merge = pkgs.callPackage ./nix/home/agents/tests { };
```

---

## 設計: substituter の配布（flake.nix 以外）

flake の `nixConfig` は daemon が信頼しないユーザーでは無視される（本機は `trusted-users = root`）。実効的な配布先は以下の 3 箇所。

```nix
# nix/hosts/darwin-shared.nix（ryoppippi.cachix.org の 2 行を置き換え）
nix.settings = {
  extra-substituters = [ "https://cache.numtide.com" ];
  extra-trusted-public-keys = [
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
  ];
};
```

```yaml
# .github/workflows/nix-build-darwin.yml / nix-build-linux.yml
- uses: cachix/install-nix-action@v31
  with:
    extra_nix_config: |
      access-tokens = github.com=${{ github.token }}
      extra-substituters = https://cache.numtide.com
      extra-trusted-public-keys = niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=
```

Linux 実機（standalone home-manager）は daemon 設定を HM から書けないため、`scripts/bootstrap.sh` で `/etc/nix/nix.conf` に同じ 2 行を追記する。

---

## 設計: nix/home/agents/default.nix

```nix
# nix/home/agents/default.nix
{ pkgs, ... }:
{
  imports = [
    ./claude-code.nix
    ./codex.nix
    ./gemini-cli.nix
    ./sync.nix
  ];

  home.packages = with pkgs.llm-agents; [
    claude-code
    codex
    gemini-cli
  ];
}
```

`nix/home/default.nix` の `imports` に `./agents` を追加し、`nix/home/packages/editor.nix` から `claude-code` を削除する。

---

## 設計: nix/home/agents/mcp-servers.nix

```nix
# nix/home/agents/mcp-servers.nix
# 中立スキーマ。各エージェント形式への変換は mcp-lib.nix が行う
#   type          : "stdio" | "http"
#   command/args  : stdio
#   url/headers   : http
#   env           : リテラルの環境変数（秘匿値は書かない）
#   envVars       : 親環境から転送する環境変数名（値は local.zsh で export）
#   bearerTokenEnv: Authorization: Bearer に使う環境変数名
#   agents        : 配布先（省略時は全エージェント）
{
  context7 = {
    type = "stdio";
    command = "npx";
    args = [ "-y" "@upstash/context7-mcp" ];
  };
  playwright = {
    type = "stdio";
    command = "npx";
    args = [ "-y" "@playwright/mcp@latest" ];
  };
  terraform = {
    type = "stdio";
    command = "docker";
    args = [ "run" "-i" "--rm" "hashicorp/terraform-mcp-server" ];
  };
  aws-knowledge = {
    type = "http";
    url = "https://knowledge-mcp.global.api.aws";
  };
  sentry = {
    type = "http";
    url = "https://mcp.sentry.dev/mcp";
  };
}
```

---

## 設計: nix/home/agents/mcp-lib.nix

```nix
# nix/home/agents/mcp-lib.nix
{ lib }:
let
  allAgents = [ "claude" "codex" "gemini" ];
  forAgent = agent: lib.filterAttrs (_: s: builtins.elem agent (s.agents or allAgents));
  compact = lib.filterAttrs (_: v: v != { } && v != [ ] && v != null);
  envRef = name: "\${${name}}";
  envAttrs = s: (s.env or { }) // lib.genAttrs (s.envVars or [ ]) envRef;
  bearer = s: lib.optionalAttrs (s ? bearerTokenEnv) { Authorization = "Bearer ${envRef s.bearerTokenEnv}"; };
in
{
  # Claude Code: plugin .mcp.json（${VAR} 展開）
  toClaude = servers: {
    mcpServers = lib.mapAttrs (
      _: s:
      compact (
        if s.type == "http" then
          {
            type = "http";
            url = s.url;
            headers = (s.headers or { }) // bearer s;
          }
        else
          {
            type = "stdio";
            command = s.command;
            args = s.args or [ ];
            env = envAttrs s;
          }
      )
    ) (forAgent "claude" servers);
  };

  # Gemini CLI: settings.json mcpServers（settings.json 全体で ${VAR} 展開）
  toGemini = servers: {
    mcpServers = lib.mapAttrs (
      _: s:
      compact (
        if s.type == "http" then
          {
            httpUrl = s.url;
            headers = (s.headers or { }) // bearer s;
          }
        else
          {
            command = s.command;
            args = s.args or [ ];
            env = envAttrs s;
          }
      )
    ) (forAgent "gemini" servers);
  };

  # Codex: config.toml [mcp_servers]（env_vars / bearer_token_env_var で env 参照）
  toCodex = servers: {
    mcp_servers = lib.mapAttrs (
      _: s:
      compact (
        if s.type == "http" then
          {
            url = s.url;
            http_headers = s.headers or { };
            bearer_token_env_var = s.bearerTokenEnv or null;
          }
        else
          {
            command = s.command;
            args = s.args or [ ];
            env = s.env or { };
            env_vars = s.envVars or [ ];
          }
      )
    ) (forAgent "codex" servers);
  };
}
```

---

## 設計: nix/home/agents/sync.nix

```nix
# nix/home/agents/sync.nix
{
  config,
  lib,
  pkgs,
  dotfilesRelPath,
  ...
}:
let
  dotfiles = "${config.home.homeDirectory}/${dotfilesRelPath}";
  mcpLib = import ./mcp-lib.nix { inherit lib; };
  servers = import ./mcp-servers.nix;
  toml = pkgs.formats.toml { };

  mcpGeminiJson = pkgs.writeText "mcp.gemini.json" (builtins.toJSON (mcpLib.toGemini servers));
  mcpCodexToml = toml.generate "mcp.codex.toml" (mcpLib.toCodex servers);

  python = pkgs.python3.withPackages (ps: [ ps.tomli-w ]);

  agentsSync = pkgs.writeShellApplication {
    name = "agents-sync";
    runtimeInputs = [
      pkgs.jq
      python
    ];
    text = ''
      # 使い方: agents-sync [--diff]
      #   tracked base ⊕ Nix 生成 MCP ⊕ untracked local を深マージし、実ファイルとして配置する。
      #   --diff は書き込まず現在のファイルとの差分を表示する（実行時変更の確認用）
      mode="''${1:-sync}"

      existing_sources() {
        for f in "$@"; do
          [ -f "$f" ] && printf '%s\n' "$f"
        done
      }

      # merge_json <keep(dotted,comma)> <existing> <sources...>
      merge_json() {
        local keep="$1" existing="$2"
        shift 2
        jq -n --arg keep "$keep" --slurpfile existing "$existing" -f ${./merge.jq} "$@"
      }

      # emit <format:json|toml> <target> <keep> <base> <sources...>
      emit() {
        local format="$1" target="$2" keep="$3"
        shift 3
        # 第 1 ソース = tracked base は必須。不在は dotfilesRelPath の誤設定なので即エラー
        [ -f "$1" ] || { echo "agents-sync: base not found: $1" >&2; exit 1; }
        local existing tmp
        existing="$(mktemp)"
        tmp="$(mktemp)"
        # target 不在時は existing を空のまま使う。空は JSON（slurpfile → []）/ TOML（{}）双方で
        # 有効な「existing なし」になる。'{}' を書くと TOML として不正でパースが落ちる
        if [ -f "$target" ]; then cat "$target" > "$existing"; fi
        local -a srcs=()
        while IFS= read -r f; do srcs+=("$f"); done < <(existing_sources "$@")
        case "$format" in
          # </dev/null: srcs が空だと jq の inputs が stdin を読みに行きハングする
          json) merge_json "$keep" "$existing" "''${srcs[@]}" < /dev/null > "$tmp" ;;
          toml) python ${./merge-toml.py} "$existing" "$keep" "''${srcs[@]}" > "$tmp" ;;
        esac
        if [ "$mode" = "--diff" ]; then
          echo "== $target"
          diff -u "$target" "$tmp" || true
        else
          mkdir -p "$(dirname "$target")"
          [ -L "$target" ] && rm -f "$target"
          install -m 644 "$tmp" "$target"
        fi
        rm -f "$existing" "$tmp"
      }

      emit json "$HOME/.claude/settings.json" "" \
        "${dotfiles}/config/claude/settings.json" \
        "${dotfiles}/config/claude/settings.local.json"

      emit json "$HOME/.gemini/settings.json" "security.auth,ui.theme" \
        "${dotfiles}/config/gemini/settings.json" \
        "${mcpGeminiJson}" \
        "${dotfiles}/config/gemini/settings.local.json"

      emit toml "$HOME/.codex/config.toml" "projects,notice,tui.model_availability_nux,tui.theme" \
        "${dotfiles}/config/codex/config.toml" \
        "${mcpCodexToml}" \
        "${dotfiles}/config/codex/config.local.toml"
    '';
  };
in
{
  home.packages = [ agentsSync ];

  # linkGeneration の後に固定する。entryAfter [ "writeBoundary" ] だと同順位の実行順が
  # 名前順になり agentsSync が先に走るため、移行 switch で旧 symlink の掃除と競合する
  home.activation.agentsSync = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${agentsSync}/bin/agents-sync
  '';
}
```

```jq
# nix/home/agents/merge.jq
# 使い方: jq -n --arg keep <dotted,comma> --slurpfile existing <file> -f merge.jq <sources...>
# 注意: 引数は必ず値束縛（$a; $b）にする。フィルタ束縛（a; b）は reduce 文脈で
# 評価コンテキストがずれ、ネスト配列のマージで左辺の要素が消える（実測で確認済み）
def deepmerge($a; $b):
  if ($a | type) == "object" and ($b | type) == "object" then
    reduce ($b | keys_unsorted[]) as $k ($a; .[$k] = deepmerge($a[$k]; $b[$k]))
  elif ($a | type) == "array" and ($b | type) == "array" then $a + ($b - $a)
  else $b end;
(reduce inputs as $s ({}; deepmerge(.; $s))) as $merged
| reduce ($keep | split(",") | map(select(length > 0) | split(".")) | .[]) as $p
    ($merged;
     ($existing[0] | try getpath($p) catch null) as $v
     | if $v != null then setpath($p; $v) else . end)
```

```python
# nix/home/agents/merge-toml.py
# 使い方: merge-toml.py <existing> <keep(dotted,comma)> <sources...>
# sources を順に深マージし、keep で指定したキーは existing の値で上書きして TOML を stdout に出す
import sys
import tomllib
from pathlib import Path

import tomli_w


def deep_merge(a, b):
    if isinstance(a, dict) and isinstance(b, dict):
        out = dict(a)
        for k, v in b.items():
            out[k] = deep_merge(a[k], v) if k in a else v
        return out
    if isinstance(a, list) and isinstance(b, list):
        return a + [x for x in b if x not in a]
    return b


def get_path(d, path):
    for k in path:
        if not isinstance(d, dict) or k not in d:
            return None
        d = d[k]
    return d


def set_path(d, path, value):
    for k in path[:-1]:
        d = d.setdefault(k, {})
    d[path[-1]] = value


def load(p):
    path = Path(p)
    return tomllib.loads(path.read_text()) if path.exists() else {}


existing_file, keep, *sources = sys.argv[1:]
merged = {}
for src in sources:
    merged = deep_merge(merged, load(src))
existing = load(existing_file)
for key in filter(None, keep.split(",")):
    path = key.split(".")
    value = get_path(existing, path)
    if value is not None:
        set_path(merged, path, value)
sys.stdout.write(tomli_w.dumps(merged))
```

---

## 設計: nix/home/agents/tests（merge の回帰テスト）

自前コードは外部仕様と同じく検証対象にする（今回のレビューで jq のフィルタ束縛バグが計画の検証をすり抜けた反省）。fixtures は 4 ケース（existing 不在の新マシン系を含む）。

```nix
# nix/home/agents/tests/default.nix
{
  jq,
  python3,
  runCommand,
}:
runCommand "agents-merge-test"
  {
    nativeBuildInputs = [
      jq
      (python3.withPackages (ps: [ ps.tomli-w ]))
    ];
  }
  ''
    cd ${./.}
    # 1. ネスト配列の和集合: base.permissions.allow ⊕ local が順序保持で合併すること
    jq -n --arg keep "" --slurpfile existing empty.json -f ${../merge.jq} base.json local.json \
      | jq -e '.permissions.allow == ["Bash(git:*)", "Read", "Bash(local:*)"]'
    # 2. keep: existing の security.auth が保持され、他のランタイムキーは落ちること
    jq -n --arg keep "security.auth" --slurpfile existing existing.json -f ${../merge.jq} base.json \
      | jq -e '.security.auth.type == "oauth" and (has("feedbackSurveyState") | not)'
    # 3. TOML: projects / notice の carry-over と base 優先（tui.notifications = true）
    python3 ${../merge-toml.py} codex-existing.toml "projects,notice" codex-base.toml codex-local.toml \
      | python3 -c 'import sys,tomllib; d=tomllib.loads(sys.stdin.read()); assert d["projects"] and d["tui"]["notifications"] is True'
    # 4. existing 不在（新マシン）: 空ファイルが JSON / TOML 双方で有効な existing になること
    #    （sync.nix の emit は target 不在時に空の existing を渡す。'{}' は TOML 不正）
    jq -n --arg keep "security.auth" --slurpfile existing empty.json -f ${../merge.jq} base.json > /dev/null
    python3 ${../merge-toml.py} empty.json "projects,notice" codex-base.toml \
      | python3 -c 'import sys,tomllib; tomllib.loads(sys.stdin.read())'
    touch $out
  ''
```

fixtures（`tests/` 直下。`empty.json` は 0 バイトで作る）:

```text
# base.json
{"permissions":{"allow":["Bash(git:*)","Read"]}}

# local.json
{"permissions":{"allow":["Bash(local:*)","Read"]}}

# existing.json
{"security":{"auth":{"type":"oauth"}},"feedbackSurveyState":{"x":1}}

# empty.json — 0 バイト（touch のみ）

# codex-base.toml
[tui]
notifications = true

# codex-local.toml
model_reasoning_effort = "high"

# codex-existing.toml
[projects."/tmp/x"]
trust_level = "trusted"
[notice]
seen = true
[tui]
notifications = false
```

`perSystem.checks.agents-merge` に登録（flake.nix の項参照）し、`just check`（`nix flake check`）と CI で毎回実行される。

---

## 設計: nix/home/agents/skills.nix

```nix
# nix/home/agents/skills.nix
# ローカル skills（dotfiles、即時編集）と外部 skills（flake input、flake.lock で pin）を
# skill 単位で ~/.agents/skills（Codex / Gemini）と ~/.claude/skills（Claude）へ symlink する。
# 両ディレクトリは実ディレクトリになる（~/.claude/skills は dotfiles-mcp plugin と同居）。
# ~/.agents/skills を Codex / Gemini が共有するため per-agent の絞り込みは構造的に不可能。
# ここに置く skill は 3 エージェント共通が前提で、特定エージェント専用は marketplace / extensions に置く
{
  config,
  inputs,
  lib,
  pkgs,
  dotfilesRelPath,
  ...
}:
let
  dotfiles = "${config.home.homeDirectory}/${dotfilesRelPath}";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";

  # ローカル: flake は Git 追跡ファイルしか見えないので、新規 skill は git add + nrs が必要
  local = lib.mapAttrs (name: _: { src = mkLink "config/agents/skills/${name}"; }) (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../../../config/agents/skills)
  );

  # 外部: src は store パス（リポジトリ内の subdir を指す）。packages は skill のスクリプトが要する実行環境
  external = {
    natural-japanese = {
      src = "${inputs.natural-japanese}/skills/natural-japanese";
      packages = [ pkgs.uv ]; # scripts/*.py は uv run で依存を自己解決する
    };
  };

  # 同名はビルド時に検出する（silent drift の名前衝突を実行時に持ち込まない）
  skills = lib.attrsets.unionOfDisjoint local external;

  linksInto = dir: lib.concatMapAttrs (name: s: { "${dir}/${name}".source = s.src; }) skills;
in
{
  home.file = linksInto ".agents/skills" // linksInto ".claude/skills";

  home.packages = lib.concatMap (s: s.packages or [ ]) (builtins.attrValues skills);
}
```

外部 skill の更新は `nix flake update natural-japanese` → `nrs`。Claude 専用の skill は従来通り `enabledPlugins`（marketplace）で入れ、3 エージェントで使うものだけ `external` に載せる。

---

## 設計: nix/home/agents/claude-code.nix

```nix
# nix/home/agents/claude-code.nix
{
  config,
  lib,
  pkgs,
  dotfilesRelPath,
  ...
}:
let
  dotfiles = "${config.home.homeDirectory}/${dotfilesRelPath}";
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
  mcpLib = import ./mcp-lib.nix { inherit lib; };
  servers = import ./mcp-servers.nix;

  # skills-dir plugin: ~/.claude/skills/<name>/.claude-plugin/plugin.json があれば
  # enabledPlugins なしで毎セッション自動ロードされる。MCP だけを載せる
  mcpPlugin = pkgs.runCommand "claude-dotfiles-mcp-plugin" { } ''
    mkdir -p "$out/.claude-plugin"
    cp ${pkgs.writeText "plugin.json" (
      builtins.toJSON {
        # MCP ツール名 mcp__plugin_dotfiles-mcp_<server>__<tool> はこの name 由来
        # （ディレクトリ名ではない）。変更すると permissions / hooks matcher が壊れる
        name = "dotfiles-mcp";
        description = "MCP servers shared across agents (generated by Nix)";
        version = "1.0.0";
      }
    )} "$out/.claude-plugin/plugin.json"
    cp ${pkgs.writeText "mcp.json" (builtins.toJSON (mcpLib.toClaude servers))} "$out/.mcp.json"
  '';

in
{
  # skills の per-skill symlink は skills.nix が担当する。ここは plugin と静的ファイルのみ
  home.file = {
    ".claude/skills/dotfiles-mcp".source = mcpPlugin;
    ".claude/CLAUDE.md".source = mkLink "config/claude/CLAUDE.md";
    ".claude/agents".source = mkLink "config/claude/agents";
    ".claude/hooks".source = mkLink "config/claude/hooks";
    ".claude/keybindings.json".source = mkLink "config/claude/keybindings.json";
    ".claude/file-suggestion.sh".source = mkLink "config/claude/file-suggestion.sh";
    ".claude/statusline.sh".source = mkLink "config/claude/statusline.sh";
  };
}
```

`nix/home/symlinks.nix` からは `.claude/*` の全エントリを削除する（`settings.json` は agents-sync が、`skills` / `mcp` / `rules` は本モジュールが置き換える）。

---

## 設計: nix/home/agents/codex.nix と gemini-cli.nix

```nix
# nix/home/agents/codex.nix
{
  config,
  dotfilesRelPath,
  ...
}:
let
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${dotfilesRelPath}/${path}";
in
{
  # config.toml は agents-sync が実ファイルとして生成する（Codex は symlink を実ファイルに置換するため）
  home.file.".codex/AGENTS.md".source = mkLink "config/agents/AGENTS.md";
}
```

```nix
# nix/home/agents/gemini-cli.nix
{
  config,
  dotfilesRelPath,
  ...
}:
let
  mkLink = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/${dotfilesRelPath}/${path}";
in
{
  # settings.json は agents-sync が実ファイルとして生成する
  home.file.".gemini/AGENTS.md".source = mkLink "config/agents/AGENTS.md";
}
```

---

## 設計: nix/home/symlinks.nix（追加分）

```nix
# nix/home/symlinks.nix
xdg.configFile = {
  # ...
  "agents".source = mkLink "config/agents";
};

home.file = {
  # ~/.agents/skills と ~/.claude/skills は skills.nix が skill 単位で管理する（ここでは触らない）
  ".zshenv".source = mkLink "config/zsh/.zshenv";
};
```

---

## 設計: config/agents/AGENTS.md と config/claude/CLAUDE.md

```markdown
<!-- config/agents/AGENTS.md -->

# AGENTS.md

## Conversation Guidelines

- Always respond in Japanese
- When asked to generate code, explain and present only the changed parts clearly
- When unsure about facts or behavior, verify before asserting.

## Editing Rules

- Always read the target file before editing it.
- Check related files (tests, type definitions, callers) before editing.
- Prefer diff-style edits over rewriting whole files.

## Code Style Guidelines

- Do not write obvious code comments
- Remove unnecessary whitespace
- Always add a trailing newline when creating new files

## Preferred Tools

Use these tools instead of their standard alternatives:

| Tool        | Replaces | Description         |
| ----------- | -------- | ------------------- |
| `zsh`       | bash     | Shell               |
| `rg`        | grep     | Fast search         |
| `fd`        | find     | File finder         |
| `bat`       | cat      | Syntax highlighting |
| `eza`       | ls       | Git-aware listing   |
| `trash`     | rm       | Trash CLI (macOS)   |
| `trash-put` | rm       | Trash CLI (Linux)   |
| `jq`        | -        | JSON processor      |
| `gh`        | git      | GitHub CLI          |
```

```markdown
<!-- config/claude/CLAUDE.md -->

@~/.config/agents/AGENTS.md

## Claude Code

<!-- Edit 優先の規則は AGENTS.md の "Prefer diff-style edits" に統合済み。ここは Claude 固有のみ -->

### Code Navigation

- Use LSP tools (goToDefinition, findReferences, documentSymbol, workspaceSymbol) for symbol search and reference lookup
- Before renaming or changing a function signature, use findReferences to find all call sites first
- Use Grep only for plain text search or when LSP is unavailable for the file type
```

---

## 設計: config/codex/config.toml と config/gemini/settings.json

```toml
# config/codex/config.toml（base。mcp_servers は Nix 生成、秘匿値・マシン固有値は config.local.toml へ）
model_reasoning_effort = "high"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
# AGENTS.md がないリポジトリでは CLAUDE.md を読む
project_doc_fallback_filenames = ["CLAUDE.md"]

[tui]
notifications = true
```

```json
{
  "$comment": "config/gemini/settings.json（base。mcpServers は Nix 生成）",
  "context": {
    "fileName": ["AGENTS.md", "GEMINI.md"]
  }
}
```

サンプル（`.gitignore` の `!*.local.*.sample` で追跡）:

```json
{
  "$comment": "config/claude/settings.local.json.sample — コピーして settings.local.json に。base と深マージされる",
  "permissions": {
    "allow": ["Bash(some-local-tool:*)"]
  }
}
```

```toml
# config/codex/config.local.toml.sample — コピーして config.local.toml に
# model = "gpt-5.5"
```

---

## 設計: 秘匿値の供給と MCP からの参照

```zsh
# config/zsh/eager/local.zsh（untracked。.gitignore の local.* で除外済み）
export GITHUB_TOKEN="ghp_xxx"
```

```zsh
# config/zsh/.zshenv（末尾に追加）
# GLOBAL_RCS 無効でも .zshenv は全 zsh 起動で読まれるため、zsh -c 等の非インタラクティブ起動でも
# ${VAR} / env_vars が解決される。sheldon の eager glob と二重 source になるが export のみで冪等。
# zsh を経由しない GUI 直接起動では解決されない（必要になったら launchctl setenv / keychain helper へ移行）
[[ -f "$XDG_CONFIG_HOME/zsh/eager/local.zsh" ]] && source "$XDG_CONFIG_HOME/zsh/eager/local.zsh"
```

```nix
# nix/home/agents/mcp-servers.nix（HTTP サーバーに bearer を渡す例）
github = {
  type = "http";
  url = "https://api.githubcopilot.com/mcp/";
  bearerTokenEnv = "GITHUB_TOKEN";
};
```

生成結果: Claude `"Authorization": "Bearer ${GITHUB_TOKEN}"`、Codex `bearer_token_env_var = "GITHUB_TOKEN"`、Gemini `"Authorization": "Bearer ${GITHUB_TOKEN}"`。

---

## 設計: 起動経路と permissions の更新

```toml
# config/zabrze/config.toml
[[snippets]]
name = "claude"
trigger = "cl"
snippet = "claude"

[[snippets]]
name = "claude yolo mode (skip command permission)"
trigger = "cly"
snippet = "claude --dangerously-skip-permissions"
```

```lua
-- config/nvim/lua/plugins/sidekick.lua: tools.claude の cmd 上書きを削除（既定の "claude" で MCP plugin が読まれる）
```

```json
// .claude/settings.json（プロジェクト）permissions.allow
"mcp__plugin_dotfiles-mcp_context7__resolve-library-id",
"mcp__plugin_dotfiles-mcp_context7__query-docs"
```

---

## 設計: Justfile と .gitignore

```just
# エージェント設定（settings.json / config.toml）を base ⊕ local から再生成
agents-sync:
    agents-sync

# 生成結果と現在のファイルの差分を表示（エージェントの実行時変更を確認）
agents-diff:
    agents-sync --diff

# settings.json で有効化した Claude plugin を新マシンに導入。
# marketplace の SSOT は settings.json の extraKnownMarketplaces。source スキーマは現 settings.json で実測確定:
#   github 型 {"source":{"source":"github","repo":"owner/repo"}} / directory 型 {"source":{"source":"directory","path":"~/…"}}
# 登録先の ~/.claude.json は agent 所有のため冪等 add する。
# 2.1.195 以降、外部ソースの plugin は宣言だけでは自動 install されない（公式明文）。
# user スコープの enabledPlugins が新マシンでどう扱われるかのみ Phase 4-5 で実測。install は既定で user スコープ
agents-plugins:
    jq -r '.extraKnownMarketplaces // {} | to_entries[] | .value.source | .repo // .path' config/claude/settings.json \
      | xargs -I{} sh -c 'claude plugin marketplace add "{}" || true'
    jq -r '.enabledPlugins | to_entries[] | select(.value) | .key' config/claude/settings.json \
      | xargs -I{} sh -c 'claude plugin install "{}" || true'
```

```gitignore
### Local settings ###
*.local
local.*
*.local.*
!local.*.sample
!*.local.*.sample
```

---

## 実装手順

### Phase 1: substituter とパッケージ供給源の移行

- [x] 1-0: substituter を先行適用する: `darwin-shared.nix` の `nix.settings` を cache.numtide.com に置き換え、`nix-build-{darwin,linux}.yml` の `extra_nix_config` に substituter + 鍵を追加、`bootstrap.sh` に Linux 向け `/etc/nix/nix.conf` 追記を追加 → `! nrs` で daemon 設定を反映（llm-agents 導入と同時にやると初回 switch がフルビルドになる）（daemon への反映確認済み）
- [x] 1-1: `flake.nix` に `llm-agents` input を追加、`nixConfig` を cache.numtide.com に更新（補助扱い）、`nix-claude-code` input / overlay を削除
- [x] 1-2: `sharedOverlays` に `llm-agents = inputs.llm-agents.packages.${system}` の橋渡しを追加、`allowedUnfree` から `claude` を削除（llm-agents は license を `free = true` で上書きしているため不要）
- [x] 1-3: `nix/home/agents/default.nix` を作成（`home.packages` に `claude-code` / `codex` / `gemini-cli`）、`nix/home/default.nix` の imports に追加
- [x] 1-4: `nix/home/packages/editor.nix` から `claude-code` を削除
- [x] 1-5: `git add` → `nix flake lock` → `just check` → `! nrs`
- [x] 1-6: `claude --version` / `codex --version` / `gemini --version` で 2.1.269 / 0.154.0 / 0.59.0 以上を確認。`nix log` で codex がキャッシュから来ていることを確認（3 つとも要件どおり。codex のビルドログが cache.numtide.com 由来 = substitute 成功）

> **予実差異**: なし。全タスクが計画どおり完了（バージョン: claude-code 2.1.269 / codex 0.154.0 / gemini-cli 0.59.0、いずれも cache.numtide.com から substitute）。

### Phase 2: 共有レイアウト

- [x] 2-1: `config/agents/AGENTS.md` を作成（現 CLAUDE.md の共通部分 + `rules/tools.md` の内容）
- [x] 2-2: `git mv config/claude/skills config/agents/skills`、未追跡の 3 skill（backend-auth-design / hono-best-practices / security-best-practices）を `git add`
- [x] 2-3: `config/claude/commands/{ask,review-diff}.md` と `lua/review.md` を `config/agents/skills/{ask,review-diff,lua-review}/SKILL.md` に変換（frontmatter に `name` / `description` / `disable-model-invocation: true`）し、`config/claude/commands/` を削除
- [x] 2-4: `config/claude/CLAUDE.md` を `@~/.config/agents/AGENTS.md` + Claude 固有セクションに書き換え、`config/claude/rules/` を削除
- [x] 2-5: `nix/home/symlinks.nix` に `xdg.configFile."agents"` を追加し、`.claude/*` エントリを **`settings.json` を残して**削除（settings.json は Phase 3 で agents-sync の生成に同一 switch で引き継ぐ。先に消すと Phase 3 まで user settings が失効する）
- [x] 2-6: `flake.nix` の `extraSpecialArgs` に `inputs` を追加し、`natural-japanese` を `flake = false` の input として追加
- [x] 2-7: `nix/home/agents/skills.nix`（ローカル + 外部の per-skill symlink）、`claude-code.nix`（静的ファイル symlink。plugin は Phase 3）、`codex.nix`、`gemini-cli.nix` を作成（default.nix の imports に 4 モジュールを追加）
- [x] 2-8: `git add` → `nix flake lock` → `just check` → `! nrs`（初回 switch は失敗 → 下記予実差異のとおり旧 symlink を手動削除して再実行で成功）
- [x] 2-9: Claude で `/context` に AGENTS.md と skills が出ること、`/ask` が skill として呼べること、`codex` で `/skills` に共有 skills が出ること、`gemini` で `/skills list` に出ることを確認（Claude はセッションの skill 一覧に反映、gemini は `gemini skills list` で 12 skill Enabled を確認。codex は非対話コマンドがないため対話 `/skills` の目視確認のみ残）
- [x] 2-10: 外部 skill の検証: 3 エージェントで `natural-japanese` が見えること、`uv run ~/.agents/skills/natural-japanese/scripts/lint.py <md>` が store 上の読み取り専用パスで動くことを確認（README.md に対し lint 実行、依存解決・実行とも成功）
- [x] 2-11: `~/.codex/skills` が存在すれば退避・削除する（存在しなかったため対応不要）

> **予実差異**: 2-8 の switch が初回失敗。旧世代の `~/.claude/skills`（ディレクトリ全体への out-of-store symlink）が、新世代では実ディレクトリ + per-skill symlink になるため、HM の orphan 掃除が「新世代に同パスが存在する」と判断して旧 symlink を削除せず、`mkdir` が File exists で失敗した。dangling symlink を手動削除（`trash ~/.claude/skills`）して再実行で解決。**4-6 の 2 台目ホスト適用時も同じ手動削除が必要**。

### Phase 3: MCP 定義と可変ファイル合成

- [ ] 3-1: `nix/home/agents/mcp-servers.nix`（現 `.mcp.json` の 5 サーバー）と `mcp-lib.nix` を作成
- [ ] 3-2: `merge.jq` / `merge-toml.py` / `sync.nix` / `tests/`（fixtures + default.nix）を作成、`default.nix` の imports と `perSystem.checks.agents-merge` に追加。`nix flake check` で agents-merge が通ることを確認
- [ ] 3-3: `claude-code.nix` に `dotfiles-mcp` plugin を追加
- [ ] 3-4: `config/codex/config.toml`、`config/gemini/settings.json`、`*.local.*.sample` を作成、`.gitignore` を更新、`config/zsh/.zshenv` に `eager/local.zsh` の source を追加
- [ ] 3-5: `config/claude/mcp/` を削除、zabrze snippet と sidekick.lua から `--mcp-config` を撤去、`symlinks.nix` から `.claude/settings.json` を削除（同一 switch で agents-sync の生成へ引き継がれる）
- [ ] 3-6: `.claude/settings.json`（プロジェクト）の `mcp__context7__*` を `mcp__plugin_dotfiles-mcp_context7__*` に変更し、untracked の `.claude/settings.local.json`（`mcp__aws-knowledge__*` / `mcp__playwright__*`）も手動で同様に変更。`rg 'mcp__(context7|aws-knowledge|playwright)__'` で旧形式の残存がないことを確認
- [ ] 3-7: `git add` → `just check` → `! nrs`
- [ ] 3-8: `~/.claude/settings.json` が mode 644 の実ファイルで内容が base と一致、`~/.codex/config.toml` に `[mcp_servers.*]`、`~/.gemini/settings.json` に `mcpServers` があることを確認。各エージェントを一度起動・終了しても `git status` が clean のままであること（= dirty 問題解消の受け入れテスト）を確認
- [ ] 3-9: Claude で `/mcp` に `plugin:dotfiles-mcp:*` が Connected、`codex mcp list` と `gemini mcp list` に 5 サーバーが出ることを確認
- [ ] 3-10: Claude で `/effort` を変更 → `just agents-diff` に差分が出る → `! nrs` で base に戻ることを確認
- [ ] 3-11: `${VAR}` 展開の回帰確認: 事前検証（2.1.269、隔離 `CLAUDE_CONFIG_DIR`）で plugin の自動ロードと `.mcp.json` URL 内 `${VAR}` 展開は実測済み。switch 後の実環境でも `bearerTokenEnv` 付き HTTP サーバーを一時追加し `/mcp` で header 展開を確認する。万一不可なら `headersHelper` に切り替える（「plugin スコープで秘匿系環境変数が helper から除去される」は公式明文を確認できておらず、採用時点で実測）

### Phase 4: 運用導線とドキュメント

- [ ] 4-1: `Justfile` に `agents-sync` / `agents-diff` / `agents-plugins`（marketplace は `extraKnownMarketplaces` から導出して冪等 add）を追加
- [ ] 4-2: `CLAUDE.md`（repo）の Symlink Strategy に `config/agents/skills` → `~/.agents/skills` の特例、「`config/{claude,codex,gemini}` の base は agents-sync が合成する」旨、ロールバック注意（`darwin-rebuild rollback` では agents-sync の生成物は戻らず、旧世代の activation 再実行で戻る）を追記
- [ ] 4-3: `README.md` に AI エージェント管理の節を追加（ADR へのリンク）
- [ ] 4-4: `just ci` を通す。`docs/plans` の予実差異を追記
- [ ] 4-5: 新マシン相当の検証: `~/.claude.json` を退避した状態で `just agents-plugins` → plugin が有効化されることを確認（user スコープの enabledPlugins が 2.1.195 以降どう扱われるかの実測。結果を予実差異に記録）。`extraKnownMarketplaces` の `source` スキーマは現 settings.json の実測で確定済み（github 型 `source.repo` / directory 型 `source.path`）のため `agents-plugins` の jq は変更不要
- [ ] 4-6: 2 台目 darwin ホスト（`yutasuzukinoMacBook-Pro`）で `nrs` を適用し、Phase 1-6 / 3-8 / 3-9 相当の確認を行う

---

## 変更対象ファイル一覧

| ファイル                                                     | Phase 1                                                                                                                        | Phase 2                                                 | Phase 3                          | Phase 4      |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------- | -------------------------------- | ------------ |
| `flake.nix`                                                  | llm-agents input / overlay / nixConfig、nix-claude-code 削除（Phase 2 で `extraSpecialArgs` に inputs、外部 skill input 追加） | -                                                       | `checks.agents-merge` 追加       | -            |
| `flake.lock`                                                 | 更新                                                                                                                           | -                                                       | -                                | -            |
| `nix/hosts/darwin-shared.nix`                                | `nix.settings` の substituter を cache.numtide.com に置換                                                                      | -                                                       | -                                | -            |
| `.github/workflows/nix-build-{darwin,linux}.yml`             | `extra_nix_config` に substituter + 鍵を追加                                                                                   | -                                                       | -                                | -            |
| `scripts/bootstrap.sh`                                       | Linux 向け `/etc/nix/nix.conf` 追記を追加                                                                                      | -                                                       | -                                | -            |
| `nix/home/default.nix`                                       | `./agents` を import                                                                                                           | -                                                       | -                                | -            |
| `nix/home/packages/editor.nix`                               | `claude-code` 削除                                                                                                             | -                                                       | -                                | -            |
| `nix/home/agents/default.nix`                                | 新規（packages）                                                                                                               | imports 追加                                            | `./sync.nix` 追加                | -            |
| `nix/home/agents/claude-code.nix`                            | -                                                                                                                              | 新規（skill links + 静的 symlink）                      | plugin 追加                      | -            |
| `nix/home/agents/codex.nix`                                  | -                                                                                                                              | 新規                                                    | -                                | -            |
| `nix/home/agents/gemini-cli.nix`                             | -                                                                                                                              | 新規                                                    | -                                | -            |
| `nix/home/agents/mcp-servers.nix`                            | -                                                                                                                              | -                                                       | 新規                             | -            |
| `nix/home/agents/skills.nix`                                 | -                                                                                                                              | 新規                                                    | -                                | -            |
| `nix/home/agents/mcp-lib.nix`                                | -                                                                                                                              | -                                                       | 新規                             | -            |
| `nix/home/agents/sync.nix`                                   | -                                                                                                                              | -                                                       | 新規                             | -            |
| `nix/home/agents/merge.jq`                                   | -                                                                                                                              | -                                                       | 新規                             | -            |
| `nix/home/agents/merge-toml.py`                              | -                                                                                                                              | -                                                       | 新規                             | -            |
| `nix/home/agents/tests/`                                     | -                                                                                                                              | -                                                       | 新規                             | -            |
| `nix/home/symlinks.nix`                                      | -                                                                                                                              | `.claude/*` 削除（settings.json は残す）、`agents` 追加 | settings.json 削除               | -            |
| `config/agents/AGENTS.md`                                    | -                                                                                                                              | 新規                                                    | -                                | -            |
| `config/agents/skills/`                                      | -                                                                                                                              | `config/claude/skills` から移動                         | -                                | -            |
| `config/claude/CLAUDE.md`                                    | -                                                                                                                              | import 形式へ                                           | -                                | -            |
| `config/claude/rules/`                                       | -                                                                                                                              | 削除                                                    | -                                | -            |
| `config/claude/commands/`                                    | -                                                                                                                              | skills へ変換して削除                                   | -                                | -            |
| `config/claude/mcp/`                                         | -                                                                                                                              | -                                                       | 削除                             | -            |
| `config/claude/settings.local.json.sample`                   | -                                                                                                                              | -                                                       | 新規                             | -            |
| `config/codex/config.toml` / `config.local.toml.sample`      | -                                                                                                                              | -                                                       | 新規                             | -            |
| `config/gemini/settings.json` / `settings.local.json.sample` | -                                                                                                                              | -                                                       | 新規                             | -            |
| `config/zsh/.zshenv`                                         | -                                                                                                                              | -                                                       | `eager/local.zsh` の source 追加 | -            |
| `config/zabrze/config.toml`                                  | -                                                                                                                              | -                                                       | `--mcp-config` 撤去              | -            |
| `config/nvim/lua/plugins/sidekick.lua`                       | -                                                                                                                              | -                                                       | `cmd` 上書き削除                 | -            |
| `.claude/settings.json`                                      | -                                                                                                                              | -                                                       | MCP ツール名変更                 | -            |
| `.gitignore`                                                 | -                                                                                                                              | -                                                       | `*.local.*` 追加                 | -            |
| `Justfile`                                                   | -                                                                                                                              | -                                                       | -                                | recipes 追加 |
| `CLAUDE.md` / `README.md`                                    | -                                                                                                                              | -                                                       | -                                | 追記         |

---

## 実現可能性レビュー

2026-09-13 に主張を総ざらいで実測・裏取りした（外部仕様は公式 docs / ソース / GitHub issue、ローカルは scratchpad での実走。実測時のバージョン: claude-code 2.1.269 / codex 0.154.0 / gemini-cli 0.59.0）。

| 懸念                                                                                            | 検証結果         | 根拠                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ----------------------------------------------------------------------------------------------- | ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| llm-agents.nix に 3 パッケージがあり darwin でキャッシュが効くか                                | 動く（実測）     | `nix eval` で claude-code 2.1.269 / codex 0.154.0 / gemini-cli 0.59.0（gh api の上流最新と同着）。cache.numtide.com の narinfo は aarch64-darwin / x86_64-linux の 3 パッケージ全てで 200。update.yml の cron は `0 0,4,18,21 * * *`（4 回/日）。license は `free = true` 上書きを `nix eval .meta.license` で確認（`allowedUnfree` から `claude` を外せる）                                                                 |
| `builtins.readDir ../../../config/agents/skills` は pure eval で動くか                          | 動く（実測）     | mini flake（tracked / untracked の 2 skill）で実測: `nix eval` は tracked のみ列挙し、未追跡ディレクトリは見えない                                                                                                                                                                                                                                                                                                           |
| skills-dir plugin の自動ロード（enabledPlugins なし・store symlink ルート）                     | **動く（実測）** | 隔離 `CLAUDE_CONFIG_DIR` に `.claude-plugin/plugin.json` + `.mcp.json` を置き、`claude mcp list` で `plugin:dotfiles-mcp:aws-knowledge ✔ Connected` を確認。symlink された skills ディレクトリ経由（実環境）でも動作。ツール名は実セッションで `mcp__plugin_<plugin名>_<server>__<tool>` 形式を確認（plugin 名は plugin.json の `name` 由来）                                                                                |
| plugin `.mcp.json` の `${VAR}` 展開                                                             | **動く（実測）** | 2.1.269 CLI で URL 内 `${VAR}` が展開されて接続に使われることを実測。Desktop app には未展開報告（[#40372](https://github.com/anthropics/claude-code/issues/40372)）が残るが本構成は CLI 起動のみ。`headersHelper` の「秘匿系環境変数が除去される」制約は公式明文を確認できず（採用時に実測）                                                                                                                                 |
| flake `nixConfig` の substituter が本機で効くか                                                 | **効かない**     | 実測: `nix config show` で `trusted-users = root`・`trusted-substituters` 空。既存 ryoppippi.cachix も flake 側は警告付きで無視され、効いているのは `darwin-shared.nix` の `nix.settings`。よって配布は nix.settings + CI `extra_nix_config`（Phase 1-0）                                                                                                                                                                    |
| 自前 merge スクリプト（merge.jq / merge-toml.py / emit）の正しさ                                | 実走で PASS      | 計画記載のコードそのままを実走: 4 fixtures + hooks 同一 matcher の和集合 + keep ネストキー（`tui.theme`）+ MCP テーブル合成が全て期待値。emit は統合テストで新マシン（target 不在）・移行（symlink → 実ファイル置換、symlink 先は無傷）・`--diff`・base 不在エラーの 4 シナリオを bash 5.x で確認。jq のフィルタ束縛バグと `'{}'` TOML 不正・stdin ハングの各対策も実測どおり。回帰は `perSystem.checks.agents-merge` で担保 |
| mcp-lib.nix の 3 形式変換                                                                       | 動く（実測）     | `nix eval` で 5 サーバー + bearer 付き http + `agents = ["claude"]` 限定サーバーを変換し、Claude / Codex / Gemini の期待キー（`type` / `bearer_token_env_var` / `httpUrl` 等）・絞り込み・null / 空の除去を確認。`pkgs.formats.toml` の生成 TOML は tomllib で往復パースを確認                                                                                                                                               |
| Codex が `config.toml` に書く trust 情報を switch 後も保てるか                                  | 保てる           | edit.rs の実行時書き込みキー全量をソースで確認し、keep（`projects` / `notice` / `tui.model_availability_nux` / `tui.theme`）を carry-over。[codex#14601](https://github.com/openai/codex/issues/14601) は open、symlink 置換リグレッション [codex#6646](https://github.com/openai/codex/issues/6646) は PR #9445（2026-01 マージ）で修正済み                                                                                 |
| `python3Packages.tomli-w` の存在                                                                | ある（実測）     | nixpkgs unstable で 1.2.0。`python3.withPackages` を実 build して import を確認（現 unstable の python3 は 3.14、`tomllib` は 3.11+ 標準ライブラリ）                                                                                                                                                                                                                                                                         |
| `claude mcp list` 等のサブコマンドが `--mcp-config` を拒否する                                  | 確認済み（実測） | 2.1.269 で再実測し `error: unknown option '--mcp-config'`。wrapProgram 案の不採用理由                                                                                                                                                                                                                                                                                                                                        |
| Gemini が `~/.agents/skills` と `~/.gemini/skills` を二重ロードしないか                         | しない           | 公式 docs で確認（正確には `~/.gemini/skills` が主・`~/.agents/skills` が alias。どちらも読まれ、同名は alias 優先で重複排除）。`~/.gemini/skills` を作らない本構成では単一ロード                                                                                                                                                                                                                                            |
| 外部 skill をリポジトリの subdir から取れるか（natural-japanese は `skills/natural-japanese/`） | 取れる（実測）   | `nix flake prefetch` した store パスに `skills/natural-japanese/{SKILL.md,references,scripts,assets}` が揃っていることを確認                                                                                                                                                                                                                                                                                                 |
| store 上（読み取り専用）の skill スクリプトが動くか                                             | **動く（実測）** | store の読み取り専用パスで `uv run …/scripts/lint.py fixtures/ai-smelly.md` を実行し、インライン依存（sudachipy）が解決されて lint 結果が出力されることを確認。Phase 2-10 は switch 後の回帰確認                                                                                                                                                                                                                             |
| 同名 skill の衝突検出（`lib.attrsets.unionOfDisjoint`）                                         | 止まる（実測）   | `nix eval` で `error: unionOfDisjoint: collision on <name>` の評価エラーを確認                                                                                                                                                                                                                                                                                                                                               |
| activation の順序アンカー `linkGeneration`                                                      | ある             | home-manager（flake.lock の rev）の modules/files.nix に `home.activation.linkGeneration = entryAfter [ "writeBoundary" ]` を確認。`entryAfter [ "linkGeneration" ]` は有効                                                                                                                                                                                                                                                  |
| `extraKnownMarketplaces` の source スキーマ                                                     | 確定（実測）     | 現行 settings.json で github 型 `{"source":{"source":"github","repo":"…"}}` / directory 型 `{"source":{"source":"directory","path":"…"}}` を確認。`agents-plugins` の jq（`.repo // .path`）はこのままでよい                                                                                                                                                                                                                 |
| Codex の設定キー名（`project_doc_fallback_filenames` / MCP の `env_vars` 等）                   | 正しい           | config.schema.json と `codex-rs/config/src/mcp_types.rs` で確認（http 側は `url` / `http_headers` / `bearer_token_env_var`。ほかに `env_http_headers` / `http_headers_helper` も存在）                                                                                                                                                                                                                                       |
