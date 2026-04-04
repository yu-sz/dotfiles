# CLI ツールの home-manager `programs.*` モジュール移行

Date: 2026-03-31
Status: Accepted

## Context

現在 CLI ツールは `home.packages` + `config/` の raw file + `symlinks.nix` で管理している。`programs.*` モジュールに移行すれば「パッケージ + 設定 + シェル統合」を一つの宣言にまとめられる。

[ADR: Nix によるパッケージ管理](2026-03-28-nix-package-management.md) の「明示的・宣言的・追跡可能」方針をツール設定レベルまで拡張する。

## Decision

### 移行対象

key-value 的な設定を持つツールを `programs.*` に移行する。

| ツール   | モジュール          | 移行内容                                              |
| -------- | ------------------- | ----------------------------------------------------- |
| git      | `programs.git`      | 設定 + global ignores + includes                      |
| delta    | `programs.delta`    | オプション + git 統合 (`enableGitIntegration = true`) |
| bat      | `programs.bat`      | style 設定                                            |
| starship | `programs.starship` | プロンプト設定全体（TOML → Nix 式）                   |
| eza      | `programs.eza`      | git/icons オプション                                  |
| gh       | `programs.gh`       | プロトコル・エイリアス設定                            |
| fzf      | `programs.fzf`      | パッケージ管理のみ                                    |
| zoxide   | `programs.zoxide`   | パッケージ管理のみ                                    |

### 移行しないもの

| ツール  | 理由                                                          |
| ------- | ------------------------------------------------------------- |
| neovim  | Lua + lazy.nvim のプラグイン管理が `programs.neovim` の範囲外 |
| wezterm | `programs.*` モジュールが存在しない                           |
| zsh     | Sheldon + zsh-defer の遅延ロード構成を全面書き直しになる      |
| tmux    | TPM + 複雑な固有構文（popup workflow, Tokyo Night テーマ等）  |
| yazi    | Lua プラグイン + 大きな TOML 設定                             |
| zabrze  | `programs.*` モジュールが存在しない                           |

判断基準: key-value 的な構造化設定 → `programs.*`、独自言語（Lua/Lisp）や独自プラグインマネージャ → raw config のまま。

### シェル統合

**`home.shell.enableZshIntegration = false` をグローバルに設定する。**

- Sheldon + ZDOTDIR で zsh 管理中のため init 注入が動作しない
- グローバル無効化で各モジュール個別設定を不要に
- fzf・zoxide は統一性のため `programs.*` に統一（恩恵限定的）

### 秘匿情報の扱い

| ツール | 秘匿ファイル                            | 対応                                                                                                      |
| ------ | --------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| git    | `config.local`（user.name, user.email） | `programs.git.includes` で `~/.config/git/config.local` を参照。`scripts/bootstrap.sh` の生成先パスを変更 |
| gh     | `hosts.yml`（認証トークン）             | `programs.gh` は `config.yml` のみ管理。`hosts.yml` は gh CLI が `~/.config/gh/` に自動管理               |

### ファイル構成

`nix/home/programs/` を新規作成し、ツールごとに1ファイルで管理する。

```
nix/home/
├── default.nix    ← imports に ./programs 追加、home.packages から対象ツール削除
├── programs/      ← 新規
│   ├── default.nix ← imports で各ファイルを束ねる
│   ├── bat.nix
│   ├── delta.nix
│   ├── eza.nix
│   ├── fzf.nix
│   ├── gh.nix
│   ├── git.nix
│   ├── starship.nix
│   └── zoxide.nix
├── shell.nix      ← home.shell.enableZshIntegration = false 追加 + programs.direnv
├── symlinks.nix   ← git, starship, gh のエントリ削除
└── darwin.nix
```

### 実装上の注意

- `programs.git.settings` で `extraConfig` を置き換え
- `programs.delta` は独立モジュール + `enableGitIntegration = true`
- `programs.gh.settings.version` は自動注入のため指定不要

## Consequences

- 移行対象の設定が `nix/home/programs/` に一元化され、`config/` と `symlinks.nix` のエントリが減る
- `drs` での適用が必要になり即時反映は失われるが、対象ツールは設定変更頻度が低く実用上の影響は小さい
- 将来の Linux 展開時に `programs.*` の設定をそのまま再利用できる
- シェル統合は `programs.*` に寄せられない（`programs.zsh` 移行で解消可能だが現時点ではコストに見合わない）
