# ホスト名変更 実装計画

## 概要

- macOS ホスト名をデフォルト命名から `suta-ro` に変更
- dotfiles リポジトリ内の参照を更新

**出典**:

- [ADR: macOS ホスト名を suta-ro に変更](../adr/2026-04-04-hostname-rename.md)

---

## 決定事項

| 項目        | 決定                   | 備考                                                |
| ----------- | ---------------------- | --------------------------------------------------- |
| 新ホスト名  | **`suta-ro`**          | GitHub ユーザー名と統一                             |
| 設計方針    | **ホスト名ベース維持** | nh / nix-darwin / nixd.lua の自動解決をそのまま利用 |
| git history | **クリーニングしない** | 旧名が残るが実害なし                                |

---

## 実装手順

### Phase 1: macOS ホスト名変更

- [x] 1-1: `scutil --set ComputerName/LocalHostName/HostName "suta-ro"` を実行
- [x] 1-2: `dscacheutil -flushcache` でキャッシュクリア
- [x] 1-3: `scutil --get LocalHostName` で `suta-ro` を確認

### Phase 2: dotfiles リポジトリ更新

- [x] 2-1: `flake.nix` の `darwinConfigurations` キーを `"suta-ro"` に変更
- [x] 2-2: `.github/workflows/nix-lint.yml` の dry-run ターゲットを `suta-ro` に変更
- [x] 2-3: `docs/plans/2026-03-30-repo-ops.md` のコード例を更新
- [x] 2-4: `docs/plans/2026-04-03-nix-dev-environment.md` のコード例を更新

### Phase 3: 検証

- [x] 3-1: `nix build .#darwinConfigurations.suta-ro.system --dry-run` 成功
- [x] 3-2: `drs`（`nh darwin switch`）成功

---

## 変更対象ファイル一覧

| ファイル                                       | Phase 2                         |
| ---------------------------------------------- | ------------------------------- |
| `flake.nix`                                    | `darwinConfigurations` キー変更 |
| `.github/workflows/nix-lint.yml`               | dry-run ビルドターゲット変更    |
| `docs/plans/2026-03-30-repo-ops.md`            | コード例のホスト名更新          |
| `docs/plans/2026-04-03-nix-dev-environment.md` | コード例のホスト名更新          |

**変更不要（動的解決）**: `nixd.lua`、`nix.zsh`、`bootstrap.sh`、`darwin.sh`
