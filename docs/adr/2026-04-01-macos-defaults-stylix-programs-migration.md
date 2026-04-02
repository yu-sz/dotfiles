# macOS システム設定の宣言的管理

Date: 2026-04-01
Status: Accepted

## Context

Dock（右配置、自動非表示）、Finder（カラム表示、パスバー）、キーボード（リピート速度、Press and Hold 無効）等の macOS システム設定は `defaults write` による手動設定に依存している。Mac を買い替えたとき、これらをひとつずつ手動で再設定する必要があり、設定漏れが発生しやすい。

nix-darwin の `system.defaults` を使えば、これらの設定を宣言的に記述し `drs` 一発で再現できる。

## Decision

`nix/hosts/darwin-shared.nix` に `system.defaults` を追加し、現在の Mac の設定を宣言的に管理する。設定値は `defaults read` で取得した現在の実際の値をベースにし、開発者向けに推奨される設定（`ApplePressAndHoldEnabled = false`、スマートダッシュ/クォート OFF 等）を追加する。

### 対象設定

| カテゴリ | 設定内容 |
|----------|---------|
| Dock | 自動非表示、遅延ゼロ、右配置、アイコンサイズ 52、最近非表示、デスクトップ順序固定、scale エフェクト |
| Finder | 拡張子表示、カラム表示、パスバー、拡張子変更警告オフ |
| NSGlobalDomain | ダークモード、キーリピート（15/2）、Press and Hold 無効、ナチュラルスクロール無効、自動大文字化 ON、ピリオド自動挿入 ON、スペルチェック OFF、スマートダッシュ OFF、スマートクォート OFF |
| メニューバー時計 | 24時間表示、秒表示 |
| .DS_Store | ネットワーク/USB ドライブに作成しない |

### 即時反映

`system.activationScripts.postUserActivation` で `activateSettings -u` を実行し、`drs` 後にログアウトなしで設定を即時反映する。

## Consequences

- Mac を買い替えても `drs` 一発で Dock, Finder, キーボード等のシステム設定が再現可能に
- 設定値が `darwin-shared.nix` に明示されるため、「今の Mac がどう設定されているか」が Git で追跡可能に
- 一部の設定は `drs` 後にログアウトが必要な場合があるが、`activateSettings -u` で大半は即時反映される
