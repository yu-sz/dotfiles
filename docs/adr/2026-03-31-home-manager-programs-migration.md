# CLI ツールの home-manager `programs.*` モジュール移行

Date: 2026-03-31
Status: Accepted

## Context

現在、CLI ツールは全て `home.packages` でインストールし、設定ファイルは `config/` ディレクトリに raw file として置き、`symlinks.nix` でシンボリックリンクしている。home-manager の `programs.*` モジュールを使えば「パッケージ + 設定 + シェル統合」を一つの宣言にまとめられ、より宣言的な管理が可能になる。

[ADR: Nix によるパッケージ管理](2026-03-28-nix-package-management.md) で掲げた「明示的・宣言的・追跡可能」の方針をツール設定レベルまで拡張する。

## Decision

### 移行対象

key-value 的な設定を持つツールを `programs.*` に移行する。

| ツール | モジュール | 移行内容 |
|--------|----------|---------|
| git | `programs.git` | 設定 + global ignores + includes |
| delta | `programs.delta` | オプション + git 統合 (`enableGitIntegration = true`) |
| bat | `programs.bat` | style 設定 |
| starship | `programs.starship` | プロンプト設定全体（TOML → Nix 式） |
| eza | `programs.eza` | git/icons オプション |
| gh | `programs.gh` | プロトコル・エイリアス設定 |
| fzf | `programs.fzf` | パッケージ管理のみ |
| zoxide | `programs.zoxide` | パッケージ管理のみ |

### 移行しないもの

| ツール | 理由 |
|--------|------|
| neovim | Lua + lazy.nvim。独自プラグインマネージャの設定が `programs.neovim` の範囲外 |
| wezterm | Lua 設定。`programs.*` モジュールが存在しない |
| zsh | Sheldon + zsh-defer による遅延ロード。`programs.zsh` に移行すると既存の仕組みを全面書き直し |
| tmux | TPM + 複雑な tmux.conf 固有構文（popup workflow, Tokyo Night テーマ等） |
| yazi | Lua プラグイン + 大きな TOML 設定 |
| zabrze | nixpkgs に `programs.*` モジュールが存在しない |

判断基準: key-value 的な構造化設定 → `programs.*`、独自言語（Lua/Lisp）の設定や独自プラグインマネージャ → raw config のまま。

### シェル統合

**`home.shell.enableZshIntegration = false` をグローバルに設定する。**

このリポジトリは `programs.zsh` を使わず、Sheldon + カスタム ZDOTDIR (`~/.config/zsh`) で zsh を管理している。home-manager の `enableZshIntegration` は `programs.zsh` が管理する `~/.zshrc` に init コードを追加する仕組みであり、この構成では機能しない。`shell.nix` で1箇所グローバルに無効化することで、各モジュールに個別設定を書く必要がなくなる。

シェル統合は引き続き sheldon プラグインと `config/zsh/lazy/*.zsh` で管理する。

この制約により、fzf と zoxide は `programs.*` に移行しても `enable = true`（パッケージ管理）以外の恩恵は限定的。ただし全移行対象を `programs.*` に統一することで、管理方式の一貫性を保つ。

### 秘匿情報の扱い

| ツール | 秘匿ファイル | 対応 |
|--------|------------|------|
| git | `config.local`（user.name, user.email） | `programs.git.includes` で `~/.config/git/config.local` を参照。`scripts/bootstrap.sh` の生成先パスを変更 |
| gh | `hosts.yml`（認証トークン） | `programs.gh` は `config.yml` のみ管理。`hosts.yml` は gh CLI が `~/.config/gh/` に自動管理 |

### ファイル構成

`nix/home/programs/` ディレクトリを新規作成し、ツールごとに1ファイルで `programs.*` 宣言を管理する。`default.nix` で `imports` により束ねる。neovim の `plugins/` ディレクトリ（プラグインごとに1ファイル）と同じ設計思想。

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

### home-manager オプションに関する注意

- `programs.git.extraConfig` は `programs.git.settings` にリネーム済み。後方互換はあるが新規コードでは `settings` を使う
- `programs.git.delta` は非推奨パス。`programs.delta` を独立モジュールとして使い、`enableGitIntegration = true` で git 連携を設定
- `programs.gh.settings` は `version` フィールドを home-manager が自動注入するため、手動指定しない

## Consequences

- 移行対象ツールの設定が `nix/home/programs/` に一元化され、`config/` ディレクトリと `symlinks.nix` のエントリが減る
- `drs` で設定変更を適用する必要があり、raw config の「即時反映」は失われる。ただし対象ツールは設定変更頻度が低いため実用上の影響は小さい
- 将来の Linux 展開時、`programs.*` の設定がそのまま再利用できる
- Sheldon + ZDOTDIR の制約により、シェル統合は `programs.*` に寄せられない。シェル管理を `programs.zsh` に移行すればこの制約は解消されるが、現時点では移行コストに見合わない
