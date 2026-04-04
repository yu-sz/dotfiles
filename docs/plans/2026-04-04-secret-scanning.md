# シークレットスキャン導入 実装計画

## 概要

- pre-commit hook に gitleaks を追加し、認証情報の誤コミットを防止する

**出典**:

- [ADR: シークレットスキャン導入](../adr/2026-04-04-secret-scanning.md)

---

## 決定事項

| 項目             | 決定                                         | 備考                                               |
| ---------------- | -------------------------------------------- | -------------------------------------------------- |
| ツール           | **gitleaks**                                 | 150+ 検出パターン、nixpkgs 収録済み                |
| 統合方法         | **git-hooks.nix のカスタム hook**            | `pass_filenames = false` で staging area をスキャン |
| 偽陽性対策       | **`.gitleaks.toml` を必要に応じて作成**      | 初回全スキャンで偽陽性がなければ不要               |
| CI               | **今回は対象外**                             | 将来 gitleaks-action で拡張可能                    |

---

## 設計: pre-commit hook

```nix
# flake.nix — pre-commit.settings.hooks に追加
gitleaks = {
  enable = true;
  name = "gitleaks";
  description = "Detect secrets in git commits";
  entry = "${pkgs.gitleaks}/bin/gitleaks git --pre-commit --staged --verbose";
  language = "system";
  pass_filenames = false;
};
```

## 設計: .gitleaks.toml（偽陽性が出た場合のみ作成）

```toml
# .gitleaks.toml
[allowlist]
description = "Dotfiles repo allowlist"
paths = [
  '''flake\.lock''',
]
```

---

## 実装手順

### Phase 1: gitleaks pre-commit hook 追加

- [ ] 1-1: `flake.nix` の `pre-commit.settings.hooks` に gitleaks カスタム hook を追加
- [ ] 1-2: `nix flake check` で構文検証
- [ ] 1-3: `nix develop` で devShell 再入場し `gitleaks version` を確認
- [ ] 1-4: `pre-commit run gitleaks --all-files` で既存ファイル全スキャン

### Phase 2: 偽陽性対策（Phase 1 の結果次第）

- [ ] 2-1: 偽陽性があれば `.gitleaks.toml` を作成し allowlist を追記
- [ ] 2-2: 再度 `pre-commit run gitleaks --all-files` で偽陽性が解消されたことを確認

---

## 変更対象ファイル一覧

| ファイル         | Phase 1          | Phase 2              |
| ---------------- | ---------------- | -------------------- |
| `flake.nix`      | hook 追加        | -                    |
| `.gitleaks.toml` | -                | 新設（偽陽性時のみ） |
