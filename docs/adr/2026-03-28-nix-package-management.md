# Nixによるパッケージ管理

Date: 2026-03-28
Status: Accepted

## Context

環境管理に求める性質は3つある。**明示的であること、宣言的であること、追跡可能であること**。

Homebrewはパッケージインストーラとしては機能するが、環境管理の仕組みとしてこれらを満たさない。

- Brewfileは「インストールするもののリスト」であり、環境の「あるべき状態」の定義ではない
- 依存関係はBrewfileに現れない。`brew install`時に何が入るかは記述の外にあり、環境の実態は記述から読み取れない
- バージョンロックがない。同じBrewfileから異なるバージョンの環境が生まれる

## Decision

**Nixを採用する。**

Nixは環境管理に必要な性質を言語レベルで持っている。

- **純粋関数的**: ビルドは入力のみに依存し、副作用を持たない。同じ入力から常に同じ出力が得られる。環境の再現可能性がツールの性質として保証される
- **パッケージ間の非依存性**: 各パッケージは`/nix/store/<hash>-name`にハッシュで隔離され、パッケージ間で暗黙の依存やバージョン競合が発生しない。Homebrewでは`/opt/homebrew`配下でパッケージが共有ライブラリを介して暗黙に結合し、あるパッケージの更新が別のパッケージを壊すことがある。Nixではこの問題が構造的に排除される
- **宣言的**: `flake.nix`は「この環境はこうあるべきだ」という定義そのもの。`darwin-rebuild switch`は定義と現実の差分を検出し収束させる操作であり、手順の実行ではない
- **追跡可能**: `flake.lock`が全依存のバージョンを固定する。環境の変更は`git diff`で追跡でき、任意の時点に戻せる

構成:

- **nix-darwin**: macOSシステム設定とHomebrew caskの宣言的管理
- **home-manager**: CLIツール・dotfilesリンクの宣言的管理（nix-darwinモジュールとして統合）

### upstream Nixを選ぶ理由

Determinate Systems版を採用しない。

- **ベンダー非依存**: Determinate Nixは企業がNixをラップした製品。その企業の方針変更・価格設定・機能制限が、自分の環境への暗黙の制約になる。upstream Nixはコミュニティ主導で、特定企業の意思決定に依存しない
- **クロスプラットフォームの一貫性**: upstream NixはmacOS/Linux共通。将来Linux展開時に同じflake、同じツールチェインをそのまま使える。Determinate版はmacOS向けの独自拡張があり、Linux展開時に差異が生まれるリスクがある
- Determinate版の利便性（デフォルトでflakes有効等）は、nix-darwinの設定1行（`nix.settings.experimental-features`）で同等に実現できる

### 既存ツールの維持

mise（ランタイム）、sheldon（Zshプラグイン）、Mason（Neovim LSP）はそれぞれの領域で宣言的管理を実現しており、Nixに置き換える技術的理由がない。これらのツール自体のインストールをNixで管理する。

Homebrew cask（GUIアプリ）はnix-darwin経由で宣言的に管理する。CLI formulaeは段階的にNixへ移行する。

dotfilesリンクは`mkOutOfStoreSymlink`で管理し、mutableな編集ワークフローを維持する。

## Consequences

- 環境のあるべき状態が宣言として存在し、検証・再現・差分検出が可能になる
- Nix言語・flakes・モジュールシステムの学習コストが発生する
- 移行期間中はHomebrewとNixが併存する（段階的移行、既存環境を壊さない）
- 将来のLinux展開時、共通パッケージ定義を再利用できる
