# TypeScript Domain Modeling Idioms

patterns.md の概念を TypeScript で実現するための言語機構。構造的型付けと型消去という2つの言語制約への補償策がここに集まる。

## 目次

1. [対応表](#1-対応表)
2. [言語制約と補償戦略](#2-言語制約と補償戦略)
3. [brand の付与](#3-brand-の付与)
4. [Readonly の配置](#4-readonly-の配置)
5. [構築イディオム](#5-構築イディオム)
6. [直和の合成と網羅性](#6-直和の合成と網羅性)
7. [Result への橋](#7-result-への橋)
8. [既定スタック](#8-既定スタック)

## 1. 対応表

| 概念                           | TypeScript での実現                          |
| ------------------------------ | -------------------------------------------- |
| 制約付きの型（値オブジェクト） | schema 同居コンパニオン + `.brand()`         |
| 公称型化                       | branded type（`.brand()` / `z.BRAND` 交差）  |
| 直和型                         | discriminated union + ts-pattern / `switch`  |
| 予期される失敗                 | `Result`（neverthrow）                       |
| 検証の一元化                   | zod schema が正本。静的型は `z.infer` で導出 |
| 状態遷移の型化                 | 状態ごとの型 + 遷移関数                      |
| 不変性                         | `Readonly<...>` + スプレッドによる新値生成   |
| ゼロコスト性                   | brand は実行時に消える                       |

## 2. 言語制約と補償戦略

- 制約は2つ: **構造的型付け**（公称型が無い — 形が合えば通る）と**型消去**（実行時に型が残らない — 検証を型から導出できない）
- 補償の軸は「schema を正本にする」: 制約の唯一の定義を schema（値）に置き、静的型（`z.infer`）・実行時検証（parse）・公称型化（brand）をそこから導出する
- 導出の向きは Rust と逆。Rust は型が実行時まで残りマクロが型を読めるため、型を正本にパーサ（serde）と構築検証（nutype）を導出する（rust.md）。「単一定義から静的型と実行時検証の両方を導出する」原理は共通で、正本の位置が言語制約で決まる

## 3. brand の付与

| 対象                                                   | 付与方法                    | 理由                                                                                               |
| ------------------------------------------------------ | --------------------------- | -------------------------------------------------------------------------------------------------- |
| 値オブジェクト・エンティティ・集約・イベント・コマンド | schema の `.brand()`        | parse がそのまま branded な値を返す                                                                |
| 状態機械の直和                                         | 型導出時に `z.BRAND` を交差 | `z.discriminatedUnion` が branded メンバーを合成できないため。`.brand()` が生成する型と同一で1系統 |

- スプレッド（`{ ...order, ... }`）は brand を型レベルで保存する。遷移・操作関数にキャストは不要
- 裏返しの限界: スプレッドで不変条件を破る書き換えをしても brand は残る。brand が保証するのは無からの偽造と型の取り違えの禁止まで
- `as` が現れてよいのは型レベル brand の付与点（状態直和の初期状態の生成・復元）だけ。schema `.brand()` 系は parse が brand を付けるため `as` 不要
- 状態の家族（`UnpaidOrder | PaidOrder | ...`）は1つの brand を共有する。状態ごとに brand を分けると、遷移のスプレッドが brand を運べなくなりキャストが復活する。イベントは バリアント間の変換が無いためイベントごとに brand を分けてよい

**brand の正体（手書き版）** — `.brand()` は交差型による公称型化の糖衣。同じものを素の TypeScript で示す:

```typescript
import { Result, ok, err } from "neverthrow";

declare const userNameBrand: unique symbol;
type UserName = string & { readonly [userNameBrand]: never };

type UserNameError =
  | Readonly<{ type: "UserNameEmpty" }>
  | Readonly<{ type: "UserNameTooLong"; max: number; actual: number }>;

const UserName = {
  parse(value: string): Result<UserName, UserNameError> {
    const trimmed = value.trim();
    if (trimmed.length === 0) return err({ type: "UserNameEmpty" });
    if (trimmed.length > 50)
      return err({ type: "UserNameTooLong", max: 50, actual: trimmed.length });
    return ok(trimmed as UserName);
  },
} as const;
```

- 公称型化は `unique symbol` の交差型で付与する。実行時には存在しないゼロコスト抽象
- `as` キャストは構築関数の内部だけに限定する（既定形では状態直和の brand 付与まで減る）
- 手書き版が適するのは、依存を増やしたくない場合や、複数値にまたがる制約で schema の表現力が合わない場合

## 4. Readonly の配置

- 複合型の型導出は `Readonly<z.infer<typeof schema>>` — readonly は schema 側でなく導出型に付ける（直和の合成が素の object schema を要求するため、schema を `.readonly()` で包めない）
- `Readonly<...>` は浅い。配列フィールドは schema 側の `.readonly()` で readonly 型にする
- TypeScript の readonly は型レベルのみで、手書きの `Readonly<{...}>` も同じく浅い。ネストの各層で宣言する規律は宣言手段によらず共通

## 5. 構築イディオム

- 失敗しえない構築（branded な部品からの `create`）は throw する `parse` でよい — 失敗はバグであり、バグを Result にしない規律（patterns.md エラー設計）と一致する。失敗しうる生成は `safeParse` → Result
- 構築リテラルには `satisfies z.input<typeof schema>` を付け、キーの typo・欠落を型検査する（brand の検査は引数型が担う）
- 複合型への `as` 直キャストはコンパイラに拒否される（brand プロパティ欠落で「型の重なりが不十分」）。schema の parse で構築するのが正道
- wire を経ると `Date` は ISO 文字列になる。日時は `z.coerce.date()` で受けて `Date` へ持ち上げる

## 6. 直和の合成と網羅性

- 復元パーサの既定は `z.discriminatedUnion` — 判別キーで一発分岐し、エラーが該当バリアントに絞られる
- バリアントに `.refine()` が付く等で合成できない場合は、判別キーで分岐して各バリアント schema の parse に委譲する。規律は復元の入口が1つであることで、合成 API ではない
- 網羅性検査は ts-pattern の `.exhaustive()`。依存を増やしたくない場合は `switch` + default 節の `satisfies never` で同じ保証（式でなく文になる点だけ劣る）

## 7. Result への橋

`safeParse` は zod 独自の結果型を返すため、Result 規約への橋を1つ定義して全境界で使い回す:

```typescript
import { z } from "zod";
import { Result, ok, err } from "neverthrow";

type ParseFailure = Readonly<{
  type: "ParseFailure";
  issues: ReadonlyArray<z.ZodIssue>;
}>;

const parseWith =
  <S extends z.ZodType>(schema: S) =>
  (raw: unknown): Result<z.infer<S>, ParseFailure> => {
    const result = schema.safeParse(raw);
    return result.success
      ? ok(result.data)
      : err({ type: "ParseFailure", issues: result.error.issues });
  };
```

## 8. 既定スタック

| ライブラリ | 役割                     | 備考                                                                                            |
| ---------- | ------------------------ | ----------------------------------------------------------------------------------------------- |
| zod        | schema 定義エンジン      | 同カテゴリの Effect Schema / valibot / ArkType で代替可。Effect 採用時は Schema + Brand + Match |
| neverthrow | `Result` / `ResultAsync` | 全シグネチャに現れる基盤型                                                                      |
| ts-pattern | 網羅的 match（式）       | 任意。`switch` + `satisfies never` で代替可                                                     |
