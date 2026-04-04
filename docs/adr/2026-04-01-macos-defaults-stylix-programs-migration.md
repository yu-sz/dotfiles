# macOS システム設定の宣言的管理

Date: 2026-04-01
Status: Superseded (2026-04-03)

## Context

Dock（右配置、自動非表示）、Finder（カラム表示、パスバー）、キーボード（リピート速度、Press and Hold 無効）等の macOS システム設定は `defaults write` による手動設定に依存している。Mac を買い替えたとき、これらをひとつずつ手動で再設定する必要があり、設定漏れが発生しやすい。

nix-darwin の `system.defaults` を使えば、これらの設定を宣言的に記述し `drs` 一発で再現できる。

## Decision

`nix/hosts/darwin-shared.nix` に `system.defaults` を追加し、現在の Mac の設定を宣言的に管理する。

## Consequences

- Mac を買い替えても `drs` 一発で Dock, Finder, キーボード等のシステム設定が再現可能に
- 設定値が `darwin-shared.nix` に明示されるため、「今の Mac がどう設定されているか」が Git で追跡可能に

---

## Superseded (2026-04-03): system.defaults の全面撤廃

### 経緯

1. **入力デバイス系設定が反映されない**: `com.apple.swipescrolldirection = false` を設定しても、`defaults write` では macOS のスクロール管理プロセスに変更が通知されず、GUI と挙動が乖離する ([nix-darwin#1572](https://github.com/nix-darwin/nix-darwin/issues/1572))
2. **`activateSettings -u` が害になっていた**: 多くの nix-darwin ユーザーが「おまじない」として入れているが、スクロール方向を `drs` のたびにリセットする原因だった。Dock/Finder 等は nix-darwin が個別に反映処理（`killall Dock` 等）を行うため不要
3. **ハードウェア環境への依存**: Dock の位置やサイズ、トラックパッド感度、スクロール速度等はモニタ構成・入力デバイス・デスク環境によって最適値が異なる。複数マシンで共通化しても環境ごとに調整が必要になり、宣言的管理の「一度書けば再現」という前提が成り立ちにくい
4. **残りの設定（Dock/Finder/メニューバー）の費用対効果**: いずれも「一度設定したら変えない」類で、マシン買い替え時に GUI で 30 秒で完了する量。Nix で管理する手間（nix-darwin の制約理解、設定削除不可 [#88](https://github.com/nix-darwin/nix-darwin/issues/88)、予期しない副作用の調査）に見合わない

### 決定

`system.defaults` を全て削除し、macOS システム設定は手動管理とする。
