# Rust Domain Modeling Idioms

patterns.md の概念を Rust で実現するためのイディオム。型によるドメイン制約の表現が言語ネイティブで、newtype・enum・typestate・parse-don't-validate の4本柱。

## 目次

1. [対応表](#1-対応表)
2. [導出の向き](#2-導出の向き)
3. [Newtype（値オブジェクト）](#3-newtype値オブジェクト)
4. [Enum（状態機械）](#4-enum状態機械)
5. [Typestate（遷移の型化）](#5-typestate遷移の型化)
6. [エラー](#6-エラー)
7. [機密値](#7-機密値)

## 1. 対応表

| 概念           | Rust での実現                                                 |
| -------------- | ------------------------------------------------------------- |
| 制約付きの型   | newtype（private field + `parse()`）/ nutype                  |
| 公称型化       | 言語機能（全型が公称。private field で構築を封鎖）            |
| 直和型         | `enum` + `match`（網羅性は言語組込）                          |
| 予期される失敗 | `Result<T, E>`（言語組込）                                    |
| 検証の一元化   | 型が正本 — derive がパーサ（serde）と構築検証（nutype）を導出 |
| 状態遷移の型化 | 状態ごとの型 + 遷移関数、または typestate（self を消費）      |
| 不変性         | デフォルト不変（`&mut` が型に現れる）                         |
| ゼロコスト性   | newtype はゼロコスト抽象                                      |

## 2. 導出の向き

TypeScript は型が実行時に消えるため、schema（値）を正本にして型を導出する（typescript.md）。Rust は型が実行時まで残りマクロが型を読めるため、**型を正本に**パーサ（serde の derive）と構築検証（nutype）を導出する。「単一定義から静的型と実行時検証の両方を導出する」原理は共通で、正本の位置が言語制約で決まる。

TypeScript の brand に相当する公称性・構築の封鎖は言語機能（newtype + private field）なので、補償策そのものが不要。

## 3. Newtype（値オブジェクト）

```rust
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SubscriberName(String);

#[derive(Debug, thiserror::Error)]
pub enum NameError {
    #[error("name is empty")]
    Empty,
    #[error("name is too long: {0} > 256")]
    TooLong(usize),
}

impl SubscriberName {
    pub fn parse(s: String) -> Result<Self, NameError> {
        let trimmed = s.trim();
        if trimmed.is_empty() {
            return Err(NameError::Empty);
        }
        if trimmed.chars().count() > 256 {
            return Err(NameError::TooLong(trimmed.chars().count()));
        }
        Ok(Self(trimmed.to_string()))
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}
```

- フィールドは private。`parse()` 経由でしか構築できず、`SubscriberName` の存在自体が検証済みの証明になる
- ボイラープレートが増えたら [nutype](https://github.com/greyblake/nutype) で宣言的に:

```rust
#[nutype(
    sanitize(trim),
    validate(not_empty, len_char_max = 256),
    derive(Debug, Clone, PartialEq)
)]
pub struct SubscriberName(String);
```

nutype は serde のデシリアライズ経由でも検証をバイパスできない（TS における zod `.brand()` と同じ構造的強制）。

## 4. Enum（状態機械）

```rust
pub enum Order {
    Unpaid { id: OrderId, lines: OrderLines },
    Paid { id: OrderId, lines: OrderLines, paid_at: DateTime<Utc> },
    Shipped { id: OrderId, lines: OrderLines, paid_at: DateTime<Utc>, tracking_id: TrackingId },
}
```

- bool フラグの組合せではなく enum。`match` の網羅性チェックで遷移の処理漏れをコンパイラが検出する
- 状態ごとに持てるデータが違うことをバリアントのフィールドで直接表現できる

## 5. Typestate（遷移の型化）

```rust
use std::marker::PhantomData;

pub struct Unpaid;
pub struct Paid;

pub struct Order<State> {
    id: OrderId,
    lines: OrderLines,
    _state: PhantomData<State>,
}

impl Order<Unpaid> {
    pub fn pay(self) -> Order<Paid> {
        Order { id: self.id, lines: self.lines, _state: PhantomData }
    }
}
```

- `pay(self)` が self を消費（move）するため、支払い後に古い `Order<Unpaid>` を触るコードはコンパイルエラー
- 「閉じたファイルへの書き込み」「未認証接続でのクエリ」類の遷移違反を型で消す。状態が増えて煩雑になるなら enum + 実行時検証に切り替える

## 6. エラー

- ドメインエラーは `thiserror` で enum として定義し `Result<T, DomainError>` で返す
- インフラエラーもポートの `Result` に載せる — リトライ・応答変換という呼び出し側の判断を型の合成に含める
- 回復不能なバグだけが `panic!`（エラーの3分類は patterns.md エラー設計）

## 7. 機密値

- `fn into_inner(self) -> String` のように self を消費するメソッドで read-once（一度使ったら再利用不能）が言語機能として成立する（typestate と同根）。TypeScript では可変状態を要するため閉包による遮蔽が既定（patterns.md 機密値）
