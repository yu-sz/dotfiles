# 設定ファイルの XDG ベース config/ 集約(home-manager programs.\* 縮小)

Date: 2026-07-07
Status: Accepted

## Context

[ADR: CLI ツールの home-manager programs.\* モジュール移行](./2026-03-31-home-manager-programs-migration.md) で 8 ツールを `programs.*` に移行し、その後 ghostty・lazygit・yazi も追加された。結果、設定管理が `config/`(raw file + symlink)と `nix/home/programs/`(Nix 式)の二重体制になっている。

当時の狙い「パッケージ + 設定 + シェル統合を一つの宣言に」のうち、シェル統合は `home.shell.enableZshIntegration = false` により全面手動管理(`config/zsh`)であり機能していない。実際に:

- fzf・zoxide・starship・direnv の hook は `config/zsh/lazy/` と Sheldon が手動管理している
- `programs.eza` の `git`/`icons` はエイリアス生成(シェル統合)専用オプションのため、無効化環境では何も生成しない死に設定になっている。実エイリアスは `config/zsh/lazy/alias.zsh` に手書き済み
- `programs.*` の設定変更は毎回 `nrs`(macOS では sudo)が必要で、`mkOutOfStoreSymlink` の即時反映と非対称

`programs.*` の実効果が「パッケージ導入 + Nix 式→ネイティブ形式の翻訳」だけに縮退しており、翻訳層のコストに見合わない。

## Decision

### 設定は config/ に集約し、Nix はパッケージと機構の提供に限定する

| 観点                    | A: programs.\* 継続    | B: 全面 raw 化  | C: 役割分担(採用)         |
| ----------------------- | ---------------------- | --------------- | ------------------------- |
| 設定変更の反映          | `nrs`(sudo)必要        | 即時            | **即時**                  |
| 設定の記述形式          | Nix 式への翻訳         | ネイティブ      | **ネイティブ**            |
| シェル統合              | 無効化済みで恩恵なし   | 手動(現状通り)  | 手動(現状通り)            |
| launchd・プラグイン取得 | HM が管理              | ❌ 手動化が必要 | **HM が管理**             |
| 管理場所                | config/ と nix/ の二重 | 一元            | **設定は config/ に一元** |

- シェル統合という `programs.*` 最大の価値を既に手放しており、残る設定生成は翻訳層でしかない(Context 参照)
- git は XDG ネイティブ対応(`$XDG_CONFIG_HOME/git/config`・`ignore` を標準参照。[git-config FILES](https://git-scm.com/docs/git-config#FILES))で、`programs.git` を外しても機能低下がない
- [programs.eza のオプションはエイリアス生成専用](https://github.com/nix-community/home-manager/blob/master/modules/programs/eza.nix)であり、本環境では死に設定
- `mkOutOfStoreSymlink` による即時反映は本 repo の既定戦略(CLAUDE.md「Symlink Strategy」)で、nvim・wezterm・zsh 等の大型設定は既にこの方式

### 線引き基準: Nix が設定ファイル生成以外の機構を提供しているか

| 対象                                             | 扱い                 | 提供機構                               |
| ------------------------------------------------ | -------------------- | -------------------------------------- |
| nh                                               | `programs.*` 残留    | flake パス連携                         |
| direnv                                           | `programs.*` 残留    | nix-direnv 統合                        |
| sketchybar                                       | `programs.*` 残留    | launchd agent + sbarlua + PATH wrapper |
| yazi(plugins / flavors)                          | `programs.*` 残留    | fetchFromGitHub によるプラグインの pin |
| bat / eza / fzf / zoxide / starship              | **home.packages へ** | なし(enable のみ or 死に設定)          |
| git / delta / gh / lazygit / ghostty / yazi 設定 | **config/ へ移行**   | なし(設定生成のみ)                     |

秘匿情報の扱い(`git/config.local`・`gh/hosts.yml` は symlink 対象外)とシェル統合の全面無効化は旧 ADR の決定を維持する。

## Consequences

- ツール設定の調整が保存即反映になり、`nrs`(sudo)が不要になる
- 設定がネイティブ形式になり、公式ドキュメントの例・スキーマ・エディタ支援がそのまま使える。Nix を使わない環境への流用も可能になる
- Nix eval 時の設定検証(オプション名・型チェック)は失われ、誤りはツール起動時に判明する
- gh は `gh config set` 実行時に symlink 経由で repo 内の `config.yml` を直接書き換える(git diff で追跡可能な反面、差分ノイズになり得る)
- ghostty の `command` は Nix store パスから PATH 解決に変わり、GUI 起動時は /bin/zsh(macOS 標準)で起動する
- [ADR: CLI ツールの home-manager programs.\* モジュール移行](./2026-03-31-home-manager-programs-migration.md) は本 ADR により Superseded となる
