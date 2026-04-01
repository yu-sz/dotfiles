# home-manager `programs.*` 移行 実装計画

## 概要

CLI ツールを `home.packages` + raw config ファイルから home-manager の `programs.*` モジュールに移行する:

- **パッケージ + 設定 + シェル統合** を一つの宣言にまとめ、宣言的管理を強化
- ツールごとに1ファイルで管理する `nix/home/programs/` ディレクトリを新設
- neovim, wezterm, tmux, yazi 等の独自言語設定は raw config のまま維持

**出典**: [ADR: home-manager programs 移行](../adr/2026-03-31-home-manager-programs-migration.md)

---

## 決定事項

| 項目 | 決定 | 備考 |
|------|------|------|
| ファイル構成 | **ツールごとに1ファイル** (`nix/home/programs/*.nix`) | neovim `plugins/` と同じ設計思想。世間の主要リポジトリと一致 |
| シェル統合 | **`home.shell.enableZshIntegration = false`**（グローバル） | Sheldon + ZDOTDIR を使用。`programs.zsh` 未使用のため HM のシェル統合は不可。`shell.nix` で1箇所設定し、各モジュールの個別設定は不要 |
| delta モジュール | **`programs.delta`**（独立モジュール） | `programs.git.delta` は非推奨パス。`enableGitIntegration = true` で git 連携 |
| git 設定オプション | **`programs.git.settings`** | `extraConfig` はリネーム済み。新規コードでは `settings` を使用 |
| gh version フィールド | **指定しない** | HM が `version = "1"` を自動注入。手動指定すると int/string 型不一致リスク |
| git 秘匿情報 | **`includes` で `~/.config/git/config.local` を参照** | 既存ファイル名を維持。bootstrap.sh の生成先を `~/.config/git/config.local` に変更 |
| gh credential helper | **`gitCredentialHelper.enable = false`** | SSH 認証メイン。HTTPS credential helper 不要 |
| gh 秘匿情報 | **gh CLI が `~/.config/gh/hosts.yml` を自動管理** | `programs.gh` は `config.yml` のみ管理 |
| starship 設定パス | **HM がデフォルト検索パス `~/.config/starship.toml` にファイルを配置** | sheldon 側の `STARSHIP_CONFIG` export は削除。starship が `STARSHIP_CONFIG` 未設定時にデフォルトで `~/.config/starship.toml` を読む。`home.sessionVariables` は本環境では zsh に反映されないため使用しない |

---

## 設計: ファイル構成

```
nix/home/
├── default.nix    ← imports に ./programs 追加、home.packages から対象ツール削除
├── programs/      ← 新規ディレクトリ
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

---

## 設計: 各ツールの Nix 定義

### `nix/home/shell.nix`（変更）

```nix
_: {
  home.shell.enableZshIntegration = false;

  programs.direnv = {
    enable = true;
    silent = true;
    nix-direnv.enable = true;
  };
}
```

### `nix/home/programs/default.nix`

```nix
{
  imports = [
    ./bat.nix
    ./delta.nix
    ./eza.nix
    ./fzf.nix
    ./gh.nix
    ./git.nix
    ./starship.nix
    ./zoxide.nix
  ];
}
```

### `nix/home/programs/bat.nix`

```nix
{ ... }:
{
  programs.bat = {
    enable = true;
    config.style = "header,grid";
  };
}
```

### `nix/home/programs/delta.nix`

```nix
{ ... }:
{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      side-by-side = true;
      line-numbers = true;
      navigate = true;
      plus-style = "syntax #043103";
      minus-style = "syntax #8D3043";
      syntax-theme = "Monokai Extended";
    };
  };
}
```

### `nix/home/programs/eza.nix`

```nix
{ ... }:
{
  programs.eza = {
    enable = true;
    git = true;
    icons = "auto";
  };
}
```

### `nix/home/programs/fzf.nix`

```nix
{ ... }:
{
  programs.fzf = {
    enable = true;
  };
}
```

> fzf の設定（`FZF_DEFAULT_COMMAND` 等）とカスタム関数（`fkill`）は `config/zsh/lazy/fzf.zsh` にそのまま残す。

### `nix/home/programs/gh.nix`

```nix
{ ... }:
{
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = false;
    settings = {
      git_protocol = "https";
      prompt = "enabled";
      prefer_editor_prompt = "disabled";
      spinner = "enabled";
      aliases = {
        co = "pr checkout";
      };
    };
  };
}
```

### `nix/home/programs/git.nix`

```nix
{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      user.useConfigOnly = true;
      ghq.root = "~/Projects";
    };
    ignores = [
      ".DS_Store"
      "._*"
      "node_modules/"
      "*.log"
      ".bundle/"
      "*.local"
      "*.local.*"
    ];
    includes = [
      { path = "~/.config/git/config.local"; }
    ];
  };
}
```

### `nix/home/programs/starship.nix`

```nix
{ ... }:
{
  programs.starship = {
    enable = true;
    settings = {
      format = "[░▒▓](#a3aed2)[  ](bg:#a3aed2 fg:#090c0c)[](bg:#3B6ADB fg:#a3aed2)$directory[](fg:#3B6ADB bg:#394260)$git_branch$git_status$git_state[](fg:#394260 bg:#212736)$nodejs$bun$lua[](fg:#212736 bg:#1d2230)$time[ ](fg:#1d2230)\n$character";
      directory = {
        style = "fg:#e3e5e5 bg:#3B6ADB";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          "Documents" = "󰈙 ";
          "Downloads" = " ";
          "Music" = " ";
          "Pictures" = " ";
        };
      };
      git_branch = {
        symbol = "";
        style = "bg:#394260";
        format = "[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)";
      };
      git_state = {
        disabled = false;
        style = "bg:#394260";
        format = "[[($state )](fg:#769ff0 bg:#394260)]($style)";
        rebase = "󰡒 ";
        merge = " ";
        revert = " ";
        cherry_pick = "🍒";
        bisect = "";
        am = "";
        am_or_rebase = "";
      };
      git_status = {
        style = "bg:#394260";
        format = "[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)";
        conflicted = "⚡️";
        ahead = "";
        behind = "";
        diverged = "";
        up_to_date = "✓";
        untracked = "";
        stashed = "";
        modified = "🔥";
        staged = "";
        renamed = "";
        deleted = "";
      };
      nodejs = {
        symbol = " ";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };
      bun = {
        symbol = "🥟 ";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };
      lua = {
        symbol = "󰢱 ";
        style = "bg:#212736";
        format = "[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)";
      };
      time = {
        disabled = true;
        time_format = "%R";
        style = "bg:#1d2230";
        format = "[[  $time ](fg:#a0a9cb bg:#1d2230)]($style)";
      };
    };
  };
}
```

### `nix/home/programs/zoxide.nix`

```nix
{ ... }:
{
  programs.zoxide = {
    enable = true;
  };
}
```

> zoxide のシェル統合は `config/zsh/sheldon/plugins.toml` の deferred loading にそのまま残す。

---

## 実装チェックリスト

### フェーズ 1: ディレクトリ構造作成 + リスクゼロのツール（bat, eza, delta）

- [x] 1-1: `nix/home/shell.nix` に `home.shell.enableZshIntegration = false` を追加し、`programs.direnv` から `enableZshIntegration = false` を削除
- [x] 1-2: `nix/home/programs/` ディレクトリを作成
- [x] 1-3: `nix/home/programs/default.nix` を作成（bat, eza, delta の imports）
- [x] 1-4: `nix/home/programs/bat.nix` を作成
- [x] 1-5: `nix/home/programs/delta.nix` を作成（`enableGitIntegration` は Phase 2 まで `false` のまま）
- [x] 1-6: `nix/home/programs/eza.nix` を作成
- [x] 1-7: `nix/home/default.nix` の `imports` に `./programs` を追加
- [x] 1-8: `nix/home/default.nix` の `home.packages` から `bat`, `eza`, `delta` を削除
- [x] 1-9: `drs` を実行し正常完了を確認
- [x] 1-10: `which bat`, `which eza`, `which delta` でインストール確認
- [x] 1-11: eza エイリアス（`ls`, `ll`, `lt` 等）が動作することを確認
- [x] 1-12: コミット `074f746`

> **予実差異**: 新規ファイルは `git add` が必要（Nix flake は Git 追跡ファイルのみ参照）。初回 `drs` はパスが見つからずエラー。`git add` 後に再実行で解決。

### フェーズ 2: git + delta 統合

- [x] 2-1: `nix/home/programs/git.nix` を作成
- [x] 2-2: `nix/home/programs/delta.nix` に `enableGitIntegration = true` を追加
- [x] 2-3: `nix/home/programs/default.nix` の imports に `./git.nix` を追加
- [x] 2-4: `nix/home/default.nix` の `home.packages` から `git` を削除
- [x] 2-5: `nix/home/symlinks.nix` から `"git"` エントリを削除
- [x] 2-6: `scripts/bootstrap.sh` の `GIT_CONFIG_LOCAL` パスを `${HOME}/.config/git/config.local` に変更
- [x] 2-6.1: 既存の `${DOTFILES_DIR}/config/git/config.local` を `~/.config/git/config.local` に移動（存在する場合）
- [x] 2-7: `drs` を実行し正常完了を確認
- [x] 2-7.1: `ls -la ~/.config/git/` でシンボリンクからファイルに変わったことを確認
- [x] 2-8: `git config --list` で全設定値が反映されていることを確認
- [x] 2-9: `git diff` で delta の side-by-side 表示が動作することを確認
- [x] 2-10: `~/.config/git/config.local` の user.name/email が反映されていることを確認
- [x] 2-11: `config/git/config`, `config/git/ignore` を削除
- [x] 2-12: コミット `0ee52c8`

> **予実差異**: `~/.config/git` が前世代の HM シンボリンクだったため、`drs` 時に "Existing file would be clobbered" エラー。シンボリンクを手動削除後に再実行で解決。`config.local` は nix store 内に含まれていたため退避→復元の手順が追加で必要だった。

### フェーズ 3: gh

- [x] 3-1: `nix/home/programs/gh.nix` を作成
- [x] 3-2: `nix/home/programs/default.nix` の imports に `./gh.nix` を追加
- [x] 3-3: `nix/home/default.nix` の `home.packages` から `gh` を削除
- [x] 3-4: `nix/home/symlinks.nix` から `"gh"` エントリを削除
- [x] 3-5: `drs` を実行し正常完了を確認
- [x] 3-5.1: `ls -la ~/.config/gh/` でシンボリンクからファイルに変わったことを確認
- [x] 3-6: `gh auth status` で認証状態を確認
- [x] 3-7: `gh alias list` で `co` エイリアスを確認
- [x] 3-8: `config/gh/config.yml` を削除
- [x] 3-9: コミット `580fc6b`

> **予実差異**: git と同様に `~/.config/gh` が HM シンボリンクだったため、シンボリンク削除→ `hosts.yml` 退避→復元の手順が必要だった。

### フェーズ 4: starship

- [x] 4-1: `nix/home/programs/starship.nix` を作成（TOML → Nix 変換）
- [x] 4-2: `nix/home/programs/default.nix` の imports に `./starship.nix` を追加
- [x] 4-3: `nix/home/default.nix` の `home.packages` から `starship` を削除
- [x] 4-4: `nix/home/symlinks.nix` から `"starship"` エントリを削除
- [x] 4-5: `drs` を実行し正常完了を確認
- [x] 4-5.1: `ls -la ~/.config/starship.toml` でシンボリンクからファイルに変わったことを確認
- [x] 4-6: 生成された `~/.config/starship.toml` と旧 `config/starship/config.toml` を diff し内容が一致することを確認
- [x] 4-7: 新しいターミナルを開きプロンプトが正しく表示されることを確認
- [x] 4-8: `config/zsh/sheldon/plugins.toml` の starship プラグインから `STARSHIP_CONFIG` export 行のみ削除（`eval "$(starship init zsh)"` は残す）
- [x] 4-9: `config/starship/config.toml` を削除
- [x] 4-10: コミット `8229a83`

> **予実差異**:
> 1. `STARSHIP_CONFIG` 環境変数削除後、新しいタブでもデフォルト表示のままだった。原因: sheldon のキャッシュ（`~/.cache/sheldon/` と `~/.local/share/sheldon/plugins.lock`）に古い設定が残存。キャッシュ/ロック削除後も解消せず、最終的にはターミナルアプリの完全再起動が必要だった（親プロセスの環境変数が子に継承されていた）。
> 2. Nerd Font PUA 文字（U+E000-U+F4FF 範囲）が10個脱落。原因: Write ツールが Private Use Area の Unicode 文字を正しく書き込めなかった（Nix の TOML シリアライザの問題ではない）。Python スクリプトで `chr()` を使い PUA 文字を直接埋め込んで `starship.nix` を再生成して解決。

### フェーズ 5: fzf, zoxide

- [x] 5-1: `nix/home/programs/fzf.nix` を作成
- [x] 5-2: `nix/home/programs/zoxide.nix` を作成
- [x] 5-3: `nix/home/programs/default.nix` の imports に `./fzf.nix`, `./zoxide.nix` を追加
- [x] 5-4: `nix/home/default.nix` の `home.packages` から `fzf`, `zoxide` を削除
- [x] 5-5: `drs` を実行し正常完了を確認
- [x] 5-6: `Ctrl+T`（fzf ファイル検索）が動作することを確認
- [x] 5-7: `z`（zoxide ディレクトリジャンプ）が動作することを確認
- [x] 5-8: `fkill`（カスタム関数）が動作することを確認
- [x] 5-9: コミット `cefb9bf`

> **予実差異**: 特になし。fzf, zoxide はシェル統合を sheldon 側で管理しているため、`enableZshIntegration = false`（グローバル設定）により HM 側のシェル統合は無効。問題なく完了。

### フェーズ 6: クリーンアップ

- [x] 6-1: 空になった `config/git/`, `config/starship/`, `config/gh/` ディレクトリを削除（秘匿ファイルが残っている場合は `.gitignore` 確認）
- [x] 6-2: `nix flake check` がローカルで成功することを確認
- [x] 6-3: push して CI が緑になることを確認

> **予実差異**: `config/git/config.local`（秘匿）と `config/gh/hosts.yml`（認証トークン）がGit追跡外で残存していた。いずれも `~/.config/` に既にコピー済みだったため安全に削除。コミット `3d4bd89`
> starship の PUA 文字/$変数修正コミット `d52b7aa` も CI 通過確認済み。

---

## 変更対象ファイル一覧

| ファイル | 操作 | フェーズ |
|---------|------|---------|
| `nix/home/shell.nix` | `home.shell.enableZshIntegration = false` 追加、direnv から個別設定削除 | 1 |
| `nix/home/programs/default.nix` | 新規作成 | 1 |
| `nix/home/programs/bat.nix` | 新規作成 | 1 |
| `nix/home/programs/delta.nix` | 新規作成 | 1, 2 で修正 |
| `nix/home/programs/eza.nix` | 新規作成 | 1 |
| `nix/home/programs/git.nix` | 新規作成 | 2 |
| `nix/home/programs/gh.nix` | 新規作成 | 3 |
| `nix/home/programs/starship.nix` | 新規作成 | 4 |
| `nix/home/programs/fzf.nix` | 新規作成 | 5 |
| `nix/home/programs/zoxide.nix` | 新規作成 | 5 |
| `nix/home/default.nix` | imports 追加 + packages 削除 | 1-5 |
| `nix/home/symlinks.nix` | git, starship, gh エントリ削除 | 2, 3, 4 |
| `scripts/bootstrap.sh` | git config.local 生成先パス変更 | 2 |
| `config/zsh/sheldon/plugins.toml` | starship plugin 簡略化 | 4 |
| `config/git/config` | 削除 | 2 |
| `config/git/ignore` | 削除 | 2 |
| `config/starship/config.toml` | 削除 | 4 |
| `config/gh/config.yml` | 削除 | 3 |

---

## 実現可能性レビュー

| 懸念 | 検証結果 | 根拠 |
|------|---------|------|
| `programs.delta` は `programs.git.delta` と別か | 別モジュール。`programs.git.delta` は非推奨（`mkRenamedOptionModule` で後方互換あり） | home-manager ソース `delta.nix` |
| `programs.git.settings` は `extraConfig` の後継か | はい。リネーム済み、後方互換あり | home-manager ソース `git.nix` |
| `programs.gh.settings` に `version` を書くべきか | 書かない。HM が `version = "1"` を自動注入 | home-manager ソース `gh.nix` |
| `enableZshIntegration = false` で HM は zshrc に触らないか | 触らない。`programs.zsh.enable` 未設定なら何も生成しない | home-manager ソース各モジュール |
| starship の設定ファイル出力先 | `$XDG_CONFIG_HOME/starship.toml` | home-manager ソース `starship.nix` |
| `programs.eza.icons` の型 | enum: `null \| true \| false \| "auto" \| "always" \| "never"` | home-manager ソース `eza.nix` |
| `programs.bat.config` の型 | `attrsOf (oneOf [str (listOf str) bool])` | home-manager ソース `bat.nix` |
| `enableGitIntegration` で pager 設定は自動注入されるか | はい。`core.pager = "delta"` と `interactive.diffFilter = "delta --color-only"` が自動設定される | home-manager ソース `delta.nix` |
