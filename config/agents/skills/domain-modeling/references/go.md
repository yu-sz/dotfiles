# Go Domain Modeling Idioms

patterns.md の概念を Go で実現するためのイディオム。直和型がないため、private フィールド + ファクトリ関数 + 振る舞い指向で「常に妥当な状態をメモリに保つ」（Three Dots Labs 流）。

## 目次

1. [対応表](#1-対応表)
2. [値オブジェクト](#2-値オブジェクト)
3. [エンティティ・集約](#3-エンティティ集約)
4. [状態表現](#4-状態表現)

## 1. 対応表

| 概念           | Go での実現                             |
| -------------- | --------------------------------------- |
| 制約付きの型   | private struct + ファクトリ関数         |
| 公称型化       | 型定義（defined type）+ private field   |
| 直和型         | なし — interface か明示的な状態型で近似 |
| 予期される失敗 | `(T, error)`                            |
| 検証の一元化   | コンストラクタ検証のみ                  |
| 状態遷移の型化 | 表現困難 → 実行時検証で補う             |
| 不変性         | private field + 値レシーバ              |
| ゼロコスト性   | struct ラップはほぼゼロコスト           |

## 2. 値オブジェクト

```go
type Email struct {
    value string
}

func NewEmail(raw string) (Email, error) {
    trimmed := strings.TrimSpace(raw)
    if trimmed == "" {
        return Email{}, errors.New("email is empty")
    }
    if !emailPattern.MatchString(trimmed) {
        return Email{}, fmt.Errorf("invalid email: %q", trimmed)
    }
    return Email{value: trimmed}, nil
}

func (e Email) String() string { return e.value }
```

- フィールドを private にし、パッケージ外からは `NewEmail` 経由でしか構築できなくする
- 値レシーバのメソッドのみを持たせ、内部状態を変更しない（イミュータブルな値オブジェクト）
- ゼロ値 `Email{}` が作れてしまう穴は残る。パッケージ境界を信頼境界として運用でカバーする（Go の限界として認識しておく）

## 3. エンティティ・集約

```go
type Order struct {
    id    OrderID
    lines []OrderLine
}

func (o *Order) AddLine(line OrderLine) error {
    if len(o.lines) >= maxLines {
        return ErrTooManyLines
    }
    o.lines = append(o.lines, line)
    return nil
}
```

- setter を作らない。公開するのはユビキタス言語のメソッド（`AddLine` / `Cancel`）だけで、不変条件はメソッド内で守る
- 集約ルート以外のフィールドは公開しない。データではなく振る舞いを公開する
- ドメイン型と DB モデル（sqlc / GORM の構造体）は完全分離し、リポジトリでマッピングする

## 4. 状態表現

- 直和型がないため、状態機械は「状態フィールド + メソッド内ガード」で実行時に守るのが現実解
- 状態ごとに別の型（`UnpaidOrder` / `PaidOrder`）を定義して関数シグネチャで縛る方法もあるが、変換ボイラープレートとのトレードオフで判断する
- interface + 型スイッチで直和型を近似する場合、`default` 節で未知の型を必ずエラーにする（網羅性チェックがないため）
