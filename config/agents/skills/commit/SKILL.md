---
name: commit
description: "Git commit message rules based on Conventional Commits. Use when: creating git commits. MUST load before creating any commit — never commit without this skill."
user-invocable: false
---

# Commit Message Rules

[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) に従う。

## Format

```text
<type>(<scope>): <description>

[body]
```

## Language

- デフォルトは英語（description / body 共に）
- 既存ログが日本語主体ならそれに合わせる（`git log --oneline -20` で確認）
- 1 コミット内で英語と日本語を混在させない

## Types

| type       | 用途                                         |
| ---------- | -------------------------------------------- |
| `feat`     | 新機能・新設定の追加                         |
| `fix`      | バグ修正                                     |
| `refactor` | 動作変更なしのコード再構成                   |
| `docs`     | ドキュメントのみの変更                       |
| `style`    | フォーマット等、意味の変更なし               |
| `chore`    | メンテナンス（依存更新、不要ファイル削除等） |
| `revert`   | 以前のコミットの取り消し                     |
| `ci`       | CI/CD 設定の変更                             |
| `perf`     | パフォーマンス改善                           |

`config/claude/skills/` 配下の SKILL.md は Claude の挙動を規定するため、テキスト変更でも `docs` 扱いせず変更性質に応じた type を使う。

## Scope

- 変更の影響範囲を端的に示す名前を使う（モジュール名、パッケージ名、ディレクトリ名等）
- 複数領域にまたがる場合や自明な場合は省略可
- プロジェクトの既存コミットログの慣習に従う

## Rules

- description: 命令形・小文字開始・末尾ピリオドなし・50 字以下
- body: 既定で書かない（diff から読める情報を重複させないため）。以下のいずれかに該当する場合のみ 72 字折り返しで追加:
  - migration / 削除の背景
  - 技術的トレードオフ
  - バグの根本原因
  - workaround / hack の背景
- 1 コミット = 1 つの論理的変更（description に `and` が出るなら分割）

## Checklist

コミット前に以下をコピーして埋める:

```markdown
Commit checklist:

- [ ] description は命令形・小文字開始・末尾ピリオドなし・50 字以下
- [ ] description に `and` が含まれない（含まれるならコミット分割）
- [ ] type は変更性質を反映している（Types セクションの注記参照）
- [ ] body は既定で書かない。書いた場合 4 条件のいずれかを明示できる
- [ ] body は diff から読める「what」になっていない
- [ ] 言語が既存ログと一致している
```

## Examples

### 短い description / body 無し

Input: 文字列切り詰めのユーティリティを追加した。

```text
feat(utils): add string truncation helper
```

description だけで what が読めるので body 不要。

### body 有り（workaround）

Input: aarch64-darwin で direnv の checkPhase が hang するので doCheck を切った。

```text
fix(nix): skip direnv test on aarch64-darwin

cache.nixos.org serves broken-signed fish/zsh, so direnv's
fish-based test hangs under Gatekeeper. Test-harness issue,
not direnv itself.
```

body は 4 条件中「workaround / hack の背景」に該当。

### `and` 分割

Input: zsh で fpath を direnv の DATA_DIRS から同期し、ついでに fzf-tab を導入した。

description に `and` が出るので 2 commit に分割:

```text
feat(zsh): sync completions via XDG_DATA_DIRS
```

```text
feat(zsh): replace menu-select with fzf-tab
```
