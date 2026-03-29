# ホスト名ベースのマルチマシン対応

Date: 2026-03-29
Status: Accepted

## Context

この dotfiles を複数の Mac（個人用: ユーザー名 `suta-ro`、仕事用: ユーザー名 `<work-username>`）で共有したい。設定内容は完全に同一で、ユーザー名だけが異なる。

### 根本的な制約

Nix flake の pure evaluation では実行時の環境情報（ユーザー名、ホスト名）を取得できない。一方、以下の nix-darwin / home-manager の設定項目にはシステムユーザー名が必須:

- `home-manager.users.${username}`
- `users.users.${username}.home`
- `system.primaryUser`
- `nix-homebrew.user`

### 思想の衝突

- **dotfiles の思想**: リポジトリをクローンすればどのマシンでも同じ環境が再現できる
- **Nix flake の思想**: 全ての入力を明示的に宣言して再現性を保証する

ユーザー名という環境固有の値の扱いで、この2つが根本的に衝突する。

### 追加の制約

- `darwin-rebuild --flake .#name` はドット入りキー名を扱えない（パーサーの正規表現 `[^\#\"]*` が `"` を除外し、`flakeAttr=darwinConfigurations.${flakeAttr}` で単純結合するため）
- 仕事用 Mac のユーザー名が `<work-username>`（ドット入り）
- 仕事用 Mac のホスト名は変更不可（会社管理）
- 将来的にリポジトリをパブリック化する予定
- CI で `nix flake check` を使う予定

## Considered Options

### A. --impure + builtins.getEnv "USER"

```nix
username = builtins.getEnv "USER";
darwinConfigurations.default = mkDarwinConfig { };
```

- ✅ 1エントリ、マシン固有情報ゼロ
- ✅ どのマシンでもクローンするだけで動く
- ✅ ドット入りユーザー名の問題が存在しない
- ❌ `nix flake check` が使えない（CI計画と衝突）
- ❌ `--impure` フラグが毎回必要
- ❌ Nix コミュニティで非推奨

### B. ユーザー名ベタ書き2エントリ

```nix
darwinConfigurations = {
  "suta-ro" = mkDarwinConfig { username = "suta-ro"; };
  "<work-username-sanitized>" = mkDarwinConfig { username = "<work-username>"; };
};
```

- ✅ Pure evaluation、`nix flake check` 可能
- ❌ `darwin-rebuild` のドット制約で `tr '.' '-'` ハックが必要
- ❌ マシン追加時に flake.nix の変更が必要

### C. local.nix + git ハック

```nix
username = import ./nix/local.nix;
```

- ✅ Pure、1エントリ、マシン固有情報が非公開
- ❌ `git add --intent-to-add` + `git update-index --assume-unchanged` が必要
- ❌ `git stash` / `git checkout` で状態が壊れる可能性
- ❌ clone するたびに git ハックの再設定が必要

### D. ホスト名ベース（採用）

```nix
darwinConfigurations = {
  "<hostname>" = mkDarwinConfig { username = "<username>"; };
};
```

- ✅ Pure evaluation、`nix flake check` 可能
- ✅ nix-darwin 公式推奨（`darwin-rebuild` のデフォルト解決が `scutil --get LocalHostName`）
- ✅ `darwin-rebuild switch --flake .` だけで自動解決（`#` 指定不要）
- ✅ ドット入りユーザー名の問題が存在しない（キー名はホスト名）
- ✅ `tr` ハック不要
- ⚠️ マシン追加時に flake.nix の変更が必要（bootstrap.sh で自動追加）
- ⚠️ ホスト名がリポジトリに露出する

## Decision

**D. ホスト名ベースを採用する。**

- nix-darwin の設計思想に沿っており、`darwin-rebuild` との統合が最もスムーズ
- Pure evaluation を維持し、CI での `nix flake check` が可能
- 「マシン追加時に編集が必要」という課題は bootstrap.sh のエントリ自動追加で緩和
- ホスト名の露出は、世間のパブリック dotfiles でも一般的（AlexNabokikh: `"PL-OLX-KCGXHGK3PY"` 等）

## Consequences

- 新しいマシンの追加時は bootstrap.sh が自動でエントリを flake.nix に追加する。コミット・プッシュはユーザーが行う
- `darwin-rebuild switch --flake .` で動作し、`#` 以降の指定は不要
- 会社 Mac のホスト名がリポジトリに載る（許容する）
- `nix flake check` が CI で使用可能
- 将来 Nix が flake への引数渡しをサポートした場合（Issue #2861, #5663）、1エントリ化できる可能性がある
