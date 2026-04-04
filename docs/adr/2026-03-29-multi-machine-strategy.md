# ホスト名ベースのマルチマシン対応

Date: 2026-03-29
Status: Accepted

## Context

複数の Mac（個人用 `suta-ro`、仕事用 `<work-username>`）で dotfiles を共有したい。設定内容は同一でユーザー名だけが異なる。

Nix flake の pure evaluation では実行時のユーザー名を取得できないが、nix-darwin / home-manager は以下の箇所でユーザー名を要求する:

- `home-manager.users.${username}` / `users.users.${username}.home`
- `system.primaryUser` / `nix-homebrew.user`

追加制約:

- `darwin-rebuild --flake .#name` はドット入りキーを扱えない（[パーサーの制限](https://github.com/LnL7/nix-darwin/blob/master/pkgs/nix-tools/darwin-rebuild.sh)）
- 仕事用 Mac のユーザー名がドット入り、ホスト名は変更不可
- リポジトリのパブリック化と CI (`nix flake check`) を予定

## Decision

|                        | A. --impure getEnv | B. ユーザー名2エントリ | C. local.nix + git ハック | **D. ホスト名ベース** |
| ---------------------- | :----------------: | :--------------------: | :-----------------------: | :-------------------: |
| Pure evaluation        |         ❌         |           ✅           |            ✅             |          ✅           |
| `nix flake check`      |         ❌         |           ✅           |            ✅             |          ✅           |
| ドット入り名の問題なし |         ✅         |           ❌           |            ✅             |          ✅           |
| clone だけで動く       |         ✅         |           ✅           |            ❌             |          ✅           |
| `#` 指定なしで自動解決 |         ✅         |           ❌           |            ✅             |          ✅           |
| マシン追加時に編集不要 |         ✅         |           ❌           |            ✅             |          ❌           |
| ホスト名の非公開       |         ✅         |           ✅           |            ✅             |          ❌           |

**D. ホスト名ベースを採用。** 根拠:

- nix-darwin の設計思想に沿い、`darwin-rebuild switch --flake .` で `scutil --get LocalHostName` から自動解決
- Pure evaluation を維持し CI で `nix flake check` が使える
- マシン追加時の編集は bootstrap.sh のエントリ自動追加で緩和
- ホスト名の露出はパブリック dotfiles で一般的（例: [AlexNabokikh](https://github.com/AlexNabokikh/nix-config) の `"PL-OLX-KCGXHGK3PY"` 等）

各オプションの実装例:

<details><summary>A. --impure + builtins.getEnv "USER"</summary>

```nix
username = builtins.getEnv "USER";
darwinConfigurations.default = mkDarwinConfig { };
```

</details>

<details><summary>B. ユーザー名ベタ書き2エントリ</summary>

```nix
darwinConfigurations = {
  "suta-ro" = mkDarwinConfig { username = "suta-ro"; };
  "<work-username-sanitized>" = mkDarwinConfig { username = "<work-username>"; };
};
```

`tr '.' '-'` ハックが必要。

</details>

<details><summary>C. local.nix + git ハック</summary>

```nix
username = import ./nix/local.nix;
```

`git add --intent-to-add` + `git update-index --assume-unchanged` が必要。`git stash` / `git checkout` で壊れるリスクあり。

</details>

<details><summary>D. ホスト名ベース（採用）</summary>

```nix
darwinConfigurations = {
  "<hostname>" = mkDarwinConfig { username = "<username>"; };
};
```

</details>

## Consequences

- bootstrap.sh が新マシンのエントリを flake.nix に自動追加する（コミット・プッシュは手動）
- `darwin-rebuild switch --flake .` で動作、`#` 指定不要
- 会社 Mac のホスト名がリポジトリに露出する（許容）
- `nix flake check` が CI で使用可能
- 将来 Nix が flake 引数渡しをサポートした場合（[#2861](https://github.com/NixOS/nix/issues/2861), [#5663](https://github.com/NixOS/nix/issues/5663)）、1エントリ化の可能性あり
