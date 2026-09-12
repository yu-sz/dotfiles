# Domain Patterns Catalog

ドメインモデルを関数型のスタイル（イミュータブル・throw なし・class なし）で表現するパターンカタログ。理論基礎（代数的データ型）から OOP 戦術パターンの関数型再定義まで。各パターンの説明が主体で、サンプルコードは TypeScript で示す。TypeScript の言語機構は typescript.md、Rust / Go への写像は rust.md / go.md。

古典の戦術パターンのうち、Factory は smart constructor（値オブジェクト）に、Domain Service はワークフローとコンパニオン関数に、Application Service はハンドラ（読む → 決める → 書く）に吸収した。Repository は永続化の関心として architecture.md で扱う。

定義スタイルは2つを使い分ける。データの形（値オブジェクト・エンティティ・集約・状態・イベント・契約型）は schema 宣言 — 制約の正本を schema に置き、静的型はそこから導出する。関数型（ワークフロー・ポート）と、内部でのみ構築されるエラー型は素の型合成。

すべてのドメイン型は brand で公称型として扱う。brand の意味は出所の保証 — 値が所有モジュールの構築関数（parse・生成・遷移・復元）を通って生まれたことの証明で、他言語の「公称型 + private コンストラクタ」に相当する。付与方法・キャスト規律・Readonly の配置といった TypeScript の機構は typescript.md。

## 目次

1. [代数的データ型 (Algebraic Data Types)](#1-代数的データ型-algebraic-data-types)
2. [値オブジェクト (Value Object)](#2-値オブジェクト-value-object)
3. [エンティティ (Entity)](#3-エンティティ-entity)
4. [集約 (Aggregate)](#4-集約-aggregate)
5. [状態機械 (State Machine)](#5-状態機械-state-machine)
6. [ワークフロー (Workflow / Decider)](#6-ワークフロー-workflow--decider)
7. [ドメインイベント (Domain Event)](#7-ドメインイベント-domain-event)
8. [エラー設計 (Domain Errors)](#8-エラー設計-domain-errors)
9. [依存注入 (Dependency Injection)](#9-依存注入-dependency-injection)
10. [境界での parse (Trust Boundary)](#10-境界での-parse-trust-boundary)
11. [アンチパターン集](#11-アンチパターン集)

## 1. 代数的データ型 (Algebraic Data Types)

**意図**: ドメインの「取りうる値の集合」を直積と直和の合成で正確に定義する。以降の全パターンの理論的基礎。

- **直積型 (product type)** = `AND`。「A かつ B」— オブジェクト / タプル。表現可能な状態数は各要素の**積**
- **直和型 (sum type)** = `OR`。「A または B」— discriminated union。表現可能な状態数は各選択肢の**和**

```typescript
type CardPayment = Readonly<{ kind: "Card"; cardNumber: CardNumber }>;
type BankPayment = Readonly<{ kind: "Bank"; account: BankAccount }>;
type CashPayment = Readonly<{ kind: "Cash" }>;

type PaymentMethod = CardPayment | BankPayment | CashPayment;
```

- **型設計とは状態空間の設計**。表現可能な状態数を「正当な状態の数」まで絞り込む作業。`{ isPaid: boolean; isShipped: boolean }` は 4 状態（うち1つは不正）、直和 3 ケースならちょうど 3 状態
- 直積に optional を足すのではなく、直和でケースを分ける。「メールか住所の少なくとも一方を持つ」は `EmailOnly | AddressOnly | Both` の 3 ケースで表現し、`{ email?: Email; address?: Address }`（4 状態、うち1つ不正）にしない
- ミニ言語の `AND` / `OR`（process.md）がそのまま直積 / 直和に写る。Rust では struct / enum、Go では直和が欠けるため近似する（rust.md / go.md）
- schema 宣言では `z.object` が直積、`z.discriminatedUnion` が直和に対応する（本節の例は理論説明のため素の型で示した）

## 2. 値オブジェクト (Value Object)

**意図**: 同一性ではなく値で等価判定される、制約付きの不変な値。「検証済みであること」を型で証明する。

**既定形はスキーマ同居コンパニオン** — 値の制約を単一のスキーマ定義として持ち、静的型・実行時検証・公称型化をそこから導出する。TypeScript では定義エンジンとして zod を使い（同カテゴリの Effect Schema / valibot / ArkType で代替可）、スキーマをドメインモジュールに置く:

```typescript
import { z } from "zod";
import { Result, ok, err } from "neverthrow";

const schema = z.string().email().max(254).brand<"Email">();
type Email = z.infer<typeof schema>;

type EmailError = Readonly<{ type: "InvalidEmail"; value: string }>;

const Email = {
  schema,
  parse: (value: string): Result<Email, EmailError> => {
    const result = schema.safeParse(value);
    return result.success
      ? ok(result.data)
      : err({ type: "InvalidEmail", value });
  },
} as const;
```

- **コンパニオンオブジェクトパターン**: 型と値（関数群）に同じ名前を付けて凝集させる。TypeScript では型空間と値空間が分離しているため衝突しない
- **所有権の一元化**: 値の制約の唯一の定義はドメインの schema。すべての境界（HTTP・DB 行・キュー）はこれを合成して再利用し、値の制約を境界側に直書きしない
- **後付けの禁止**: 境界側で `Email.schema` に `.refine()` / `.transform()` を追加しない。定義の乖離が再発する
- schema は `safeParse` → Result でラップし、ZodError をドメイン層の語彙に漏らさない。parse しない限り branded 型が得られないため、Parse, don't validate が構造的に強制される
- **すべてのドメイン型を公称型にする**。brand が禁じるのは無からの偽造と型の取り違えまでで、更新時の正しさは操作関数を通す規律で守る。付与方法（schema `.brand()` / `z.BRAND` 交差）の使い分けは typescript.md

brand の正体（交差型による公称型化）と手書き版（依存を増やしたくない場合・schema の表現力が合わない場合の逃げ道）は typescript.md を参照。

**複合値オブジェクト** — フィールドを跨ぐ制約は、所有者であるドメイン schema の `.refine()` で表す（後付けの禁止が禁じるのは境界側での追加。所有 schema 内の `.refine()` は定義そのもの）:

```typescript
const schema = z
  .object({ start: z.date(), end: z.date() })
  .refine((v) => v.start <= v.end)
  .brand<"DateRange">();

type DateRange = Readonly<z.infer<typeof schema>>;

type DateRangeError = Readonly<{
  type: "InvalidDateRange";
  start: Date;
  end: Date;
}>;

const DateRange = {
  schema,
  parse: (start: Date, end: Date): Result<DateRange, DateRangeError> => {
    const result = schema.safeParse({ start, end });
    return result.success
      ? ok(result.data)
      : err({ type: "InvalidDateRange", start, end });
  },
} as const;
```

- 等価判定は全フィールドの値で行う。ID を持たせない
- Money（amount + currency）も同型。通貨の異なる加算はコンパニオン関数が `Result` で拒否する

**検証の順序**（Secure by Design）— smart constructor 内は安価な検証を先に、高価な検証を後に並べる:

1. **サイズ** — 長さ・要素数の上限。正規表現やパースより必ず先に行う（ReDoS・メモリ枯渇の防止）
2. **字句内容** — 許可する文字種
3. **構文** — 形式の検証（正規表現・パーサ）
4. **意味** — 業務ルールとの整合。他データとの照合が要るもの（重複確認など）は I/O を伴うため smart constructor に入れず、ワークフロー内の判定に分離する

（出所の検証 = 認証・認可はドメインに入る前、シェルで前置する）

**アンチパターン**: 検証ロジックを util 関数（`isValidEmail(s): boolean`）として共通化する。boolean は情報を捨てるため下流で再検証が必要になり、検証が散在する（shotgun parsing）。

### 機密値（パスワード・トークン・個人情報）

ドメインプリミティブの特殊形。「漏れない」ことも型の責務にする。

```typescript
type Sensitive<T> = Readonly<{
  expose: () => T;
  toJSON: () => "[REDACTED]";
  toString: () => "[REDACTED]";
}>;

const Sensitive = {
  of<T>(value: T): Sensitive<T> {
    return {
      expose: () => value,
      toJSON: () => "[REDACTED]",
      toString: () => "[REDACTED]",
    };
  },
} as const;
```

- 機密値を生の `string` で持ち回らない。閉包で包み、ログ出力・`JSON.stringify` に生値が乗らないことを構造で保証する
- 生値の取り出し口（`expose`）は1つに絞り、呼び出し箇所をレビュー可能にする。比較・強度判定など必要な操作はコンパニオン関数として定義し、取り出さずに済ませる
- 完全な read-once（一度使ったら再利用不能）は可変状態を要するため採らず、閉包による遮蔽を既定とする（read-once が言語機能として成立する言語もある — rust.md）

## 3. エンティティ (Entity)

**意図**: ID によって同一性が時間を貫くデータ。属性が変わっても同じ「個体」。

```typescript
const schema = z
  .object({
    id: UserId.schema,
    name: UserName.schema,
    email: Email.schema,
  })
  .brand<"User">();

type User = Readonly<z.infer<typeof schema>>;

const User = {
  schema,
  create(id: UserId, name: UserName, email: Email): User {
    return schema.parse({ id, name, email } satisfies z.input<typeof schema>);
  },
  changeEmail(user: User, email: Email): User {
    return { ...user, email };
  },
  equals(a: User, b: User): boolean {
    return a.id === b.id;
  },
} as const;
```

- 更新 = スプレッドによる新しい値の生成。ミューテーションしない
- 構築経路は `create`（無からの生成）と schema の parse（復元）だけで、どちらも schema を通る。スプレッド更新は brand を型レベルで保存するため、操作関数（`changeEmail`）にキャストは不要
- `create` は throw する `parse` でよい — branded な部品からの構築で失敗はバグであり、バグを Result にしない規律（エラー設計）と一致する。失敗しうる生成は `safeParse` → Result にする
- 構築リテラルの `satisfies z.input<typeof schema>` がキーの typo・欠落を型検査する（brand の検査は引数型が担う）。信頼境界の入口が `unknown` なのとは役割が違う — 境界の値は型的に無知、内部の構築は型で検査できる
- ID も値オブジェクトの既定形で定義する（上のコードでは定義済みとして参照）。公称型化により `UserId` と `PostId` の取り違えがコンパイルエラーになる
- 等価性は ID のみで判定（値オブジェクトとの本質的な違い）

**アンチパターン**: public な getter でデータだけ公開し、ロジックを呼び出し側に書かせる（ドメイン知識の漏れ）。データではなく振る舞い（`changeEmail`）を公開する。

## 4. 集約 (Aggregate)

**意図**: ビジネス上の不変条件を守る最小単位 = トランザクションの単位。データ整理の道具ではなくルール表現の手段。

Vernon の4ルール:

1. **真の不変条件だけで境界を引く** — 「同時に整合していなければ業務が壊れる」データだけを1つの集約に含める
2. **小さく設計する** — 大きい集約はロック競合・性能劣化・モデリング誤りのサイン
3. **他の集約は ID で参照する** — オブジェクト参照を持たない
4. **集約間は結果整合性** — 1トランザクションで更新するのは1集約のみ。またがる整合性はドメインイベント + 非同期で追いつかせる

```typescript
const MAX_LINES = 100;

const schema = z
  .object({
    id: OrderId.schema,
    customerId: CustomerId.schema,
    lines: z.array(OrderLine.schema).min(1).max(MAX_LINES).readonly(),
  })
  .brand<"Order">();

type Order = Readonly<z.infer<typeof schema>>;

type OrderError = Readonly<{ type: "TooManyLines"; max: number }>;

const Order = {
  schema,
  create(id: OrderId, customerId: CustomerId, first: OrderLine): Order {
    return schema.parse({ id, customerId, lines: [first] } satisfies z.input<
      typeof schema
    >);
  },
  addLine(order: Order, line: OrderLine): Result<Order, OrderError> {
    if (order.lines.length >= MAX_LINES)
      return err({ type: "TooManyLines", max: MAX_LINES });
    return ok({ ...order, lines: [...order.lines, line] });
  },
} as const;
```

- `customerId: CustomerId` であって `customer: Customer` ではない（ルール3）
- 不変条件を破る操作は `Result` で拒否する。集約は常に正しい状態でしか存在できない（Always-Valid）
- 形の制約（行数の上限・非空）の正本は schema。操作関数は同じ定数を共有して守り、二重定義にしない
- 集約をまたぐ不変条件を1トランザクションで守ろうと集約を肥大化させるのはアンチパターン。結果整合性を受け入れてビジネス要件と突き合わせて再モデリングする
- この `Order` は状態を持たない最小形。状態を持つ集約は状態機械（次節）の形で状態ごとの型に分ける

## 5. 状態機械 (State Machine)

**意図**: 状態ごとに持てるデータが違うなら、状態ごとに型を分ける。不正な遷移を関数シグネチャで排除する。

```typescript
const unpaidSchema = z.object({
  kind: z.literal("Unpaid"),
  id: OrderId.schema,
  lines: OrderLines.schema,
});
const paidSchema = unpaidSchema.extend({
  kind: z.literal("Paid"),
  paidAt: z.date(),
});
const shippedSchema = paidSchema.extend({
  kind: z.literal("Shipped"),
  trackingId: TrackingId.schema,
});

const orderSchema = z.discriminatedUnion("kind", [
  unpaidSchema,
  paidSchema,
  shippedSchema,
]);

type UnpaidOrder = Readonly<z.infer<typeof unpaidSchema>> & z.BRAND<"Order">;
type PaidOrder = Readonly<z.infer<typeof paidSchema>> & z.BRAND<"Order">;
type ShippedOrder = Readonly<z.infer<typeof shippedSchema>> & z.BRAND<"Order">;
type Order = UnpaidOrder | PaidOrder | ShippedOrder;

const createOrder = (id: OrderId, lines: OrderLines): UnpaidOrder =>
  unpaidSchema.parse({ kind: "Unpaid", id, lines } satisfies z.input<
    typeof unpaidSchema
  >) as UnpaidOrder;

const pay = (order: UnpaidOrder, paidAt: Date): PaidOrder => ({
  ...order,
  kind: "Paid",
  paidAt,
});

const ship = (order: PaidOrder, trackingId: TrackingId): ShippedOrder => ({
  ...order,
  kind: "Shipped",
  trackingId,
});
```

- `ship(unpaidOrder)` はコンパイルエラー。遷移ルールがテスト不要になる
- `paidAt` は `Paid` 以降にしか存在しない。`Date | null` のような「使えるかどうか実行時に確かめる」フィールドが消える
- `orderSchema` が復元の「kind で分岐 → 必須フィールドを検証 → バリアントへ」をそのまま実装する。リポジトリのマッピング層が形変換の後の parse に使う（load = parse、architecture.md）
- 状態の brand は型レベルの交差で家族共有し、付与は初期状態の生成と復元（parse 成功後）のみ。遷移（`pay` / `ship`）はスプレッドが brand を保存するのでキャスト不要（交差にする理由・discriminatedUnion で合成できない場合の代替は typescript.md）
- 分岐には網羅性検査を伴わせ、ケースの追加を分岐漏れとしてコンパイルエラーにする。TypeScript では ts-pattern:

```typescript
import { match } from "ts-pattern";

const describe = (order: Order): string =>
  match(order)
    .with({ kind: "Unpaid" }, () => "支払い待ち")
    .with({ kind: "Paid" }, (o) => `支払い済み: ${o.paidAt.toISOString()}`)
    .with({ kind: "Shipped" }, (o) => `発送済み: ${o.trackingId}`)
    .exhaustive();
```

**アンチパターン**: `{ isPaid: boolean; isShipped: boolean; paidAt?: Date }`。表現可能な状態 4 通りのうち正当なのは 3 通りで、`isPaid: false, isShipped: true` という不正状態が型を通ってしまう。

## 6. ワークフロー (Workflow / Decider)

**意図**: 業務プロセス = 1つの関数。入力はコマンド、出力はイベント（または新しい状態）。決定と実行を分離する。

```typescript
type PlaceOrder = (
  command: PlaceOrderCommand,
  state: OrderState,
) => Result<ReadonlyArray<OrderEvent>, PlaceOrderError>;
```

- ワークフロー関数は純粋。I/O・現在時刻・乱数は引数として外から渡す（`now: Date` を引数に取る）
- シェル側は「読む（リポジトリから状態取得）→ 決める（ワークフロー呼び出し）→ 書く（イベント永続化・通知）」の Impureim Sandwich になる:

```typescript
const placeOrderHandler =
  (deps: Readonly<{ loadOrder: LoadOrder; saveEvents: SaveEvents }>) =>
  (
    command: PlaceOrderCommand,
  ): ResultAsync<void, PlaceOrderError | InfraError> =>
    deps
      .loadOrder(command.orderId)
      .andThen((state) =>
        placeOrder(command, state).asyncAndThen(deps.saveEvents),
      );
```

- ハンドラは parse 済みのコマンド型を要求する。`unknown` を受けるのは入口アダプタ（HTTP ルート定義・キュー購読）だけで、そこで境界スキーマの parse を行う。コマンドの形が変わると、ハンドラ・アダプタ・テストがコンパイルエラーで追従を強制される
- ハンドラのエラー型は業務エラー + インフラエラーのみ。外形エラー（ParseFailure）→ 応答への変換は入口アダプタに一元化される
- ワークフロー単位の垂直スライスでコードを刻む（レイヤ横断の水平分割より変更が局所化する）
- サブステップも `Validated -> Priced -> Placed` のように型で段階を刻み、パイプラインとして合成する

## 7. ドメインイベント (Domain Event)

**意図**: 「何かが起きた」という過去の事実。集約は記録するだけで、後続処理を知らない。

```typescript
const orderPlacedSchema = z
  .object({
    type: z.literal("OrderPlaced"),
    orderId: OrderId.schema,
    at: z.coerce.date(),
  })
  .brand<"OrderPlaced">();
const orderPaidSchema = z
  .object({
    type: z.literal("OrderPaid"),
    orderId: OrderId.schema,
    amount: Money.schema,
    at: z.coerce.date(),
  })
  .brand<"OrderPaid">();
const orderShippedSchema = z
  .object({
    type: z.literal("OrderShipped"),
    orderId: OrderId.schema,
    trackingId: TrackingId.schema,
    at: z.coerce.date(),
  })
  .brand<"OrderShipped">();

type OrderPlaced = Readonly<z.infer<typeof orderPlacedSchema>>;
type OrderPaid = Readonly<z.infer<typeof orderPaidSchema>>;
type OrderShipped = Readonly<z.infer<typeof orderShippedSchema>>;
type OrderEvent = OrderPlaced | OrderPaid | OrderShipped;
```

イベント名 → schema のレジストリが復元の統一入口を作る。家族全体の union schema は持たない:

```typescript
const orderEventSchemas = {
  OrderPlaced: orderPlacedSchema,
  OrderPaid: orderPaidSchema,
  OrderShipped: orderShippedSchema,
} as const;

type InvalidOrderEvent = Readonly<{
  type: "InvalidOrderEvent";
  issues: ReadonlyArray<z.ZodIssue>;
}>;

const eventTypeSchema = z.object({
  type: z.enum(["OrderPlaced", "OrderPaid", "OrderShipped"]),
});

const parseOrderEvent = (
  raw: unknown,
): Result<OrderEvent, InvalidOrderEvent> => {
  const peeked = eventTypeSchema.safeParse(raw);
  if (!peeked.success)
    return err({ type: "InvalidOrderEvent", issues: peeked.error.issues });
  const result = orderEventSchemas[peeked.data.type].safeParse(raw);
  return result.success
    ? ok(result.data)
    : err({ type: "InvalidOrderEvent", issues: result.error.issues });
};
```

- イベント名は過去形。「〜指示」のようなコマンド語彙をイベントにしない
- 集約間の連携はイベント経由にして疎結合化する（集約Aの更新ハンドラが集約Bを直接更新しない）
- 集約内は強整合性、集約間は結果整合性というトランザクション戦略と対応する
- イベントは Outbox への記録と配送で必ず境界を跨ぐため、各イベントの schema が検証の正本になる（配線は architecture.md、境界を跨ぐ契約は bounded-context.md）
- brand はイベント schema に直付けする。状態機械だけが型レベル brand なのは言語機構の都合（typescript.md）
- 生成（decide）も schema の parse で構築する — brand と検証が同時に付き、シェルがイベントを手組みして永続化経路へ流し込めない
- 日時は `z.coerce.date()` で受ける — wire を経ると `Date` は ISO 文字列になるため、`Date` への持ち上げを schema が担う
- トピックで種別が確定している購読は該当イベントの schema で直接 parse する。`parseOrderEvent` が要るのは複数種別が1本で流れ込む購読・リプレイ。エラーは種別の先読みで該当バリアントに絞られるため discriminatedUnion と同等の品質。レジストリは契約のバージョン管理でもそのまま使う表（実践の同型: FsCodec のイベント codec、スキーマレジストリ）
- 命名済みのバリアント型は購読側のシグネチャ（`onOrderPaid(e: OrderPaid)`）がそのまま使う

## 8. エラー設計 (Domain Errors)

**意図**: 予期される業務エラーはドメインモデルの一部。戻り値の型に現し、ドキュメントとして機能させる。

```typescript
type PlaceOrderError =
  | Readonly<{ type: "EmptyOrder" }>
  | Readonly<{
      type: "StockShortage";
      productId: ProductId;
      requested: number;
      available: number;
    }>
  | Readonly<{ type: "CreditLimitExceeded"; limit: Money }>;
```

- エラーは discriminated union。呼び出し側が網羅的に分岐でき、新しいエラー追加がコンパイルエラーとして伝搬する
- **エラーは3分類する**（DMMF: Domain Errors / Infrastructure Errors / Panics）。業務エラーは業務語彙の直和で Result に。インフラエラーはポートの Result に載せ、リトライ・応答変換という呼び出し側の判断を型の合成に含める。バグ（不変条件の内部破れ）だけが throw — 呼び出し側にできることが無く、スタックトレースと共に最外殻で捕捉する
- エラー型はワークフロー単位で定義する。巨大なグローバル `AppError` を作らない
- **fail-fast と全エラー収集を使い分ける** — 境界の検証は全エラー収集（zod は issues に蓄積、neverthrow は `Result.combineWithAllErrors`）: 入力の不備は一度でまとめて返す。ワークフロー内は fail-fast（`andThen` / `Result.combine`）: 前段が失敗した後の判定に意味がない。DMMF では applicative / monadic の区別として扱われる
- **フェイルセキュア**: エラー型は業務語彙で構成し、内部詳細（SQL・ファイルパス・スタックトレース・アカウントの存在有無）を含めない。診断情報はログへ、外部応答への変換はシェルの最外殻で行う

## 9. 依存注入 (Dependency Injection)

**意図**: 依存性逆転に class も DI コンテナも不要。ポート = 関数型。

```typescript
import { ResultAsync } from "neverthrow";

type FindUser = (id: UserId) => ResultAsync<User, FindUserError>;
type SaveUser = (user: User) => ResultAsync<void, SaveUserError>;

const renameUser =
  (deps: Readonly<{ findUser: FindUser; saveUser: SaveUser }>) =>
  (
    id: UserId,
    name: UserName,
  ): ResultAsync<void, FindUserError | SaveUserError> =>
    deps
      .findUser(id)
      .map((user) => User.rename(user, name))
      .andThen(deps.saveUser);
```

- ポートに依存するのはシェル（ハンドラ）だけ。ドメインの純粋関数はポートを知らず、値だけを受け取る。アダプタ（実装）は合成ルートで注入する
- ポートは呼び出し側が所有する — 宣言はスライスの `ports.ts` に置き、実装（infra）がそれに従う。実装側が公開する API を呼ぶのと逆向きで、この所有の向きが依存性逆転の実体
- 「満たす」= シグネチャの一致による代入可能。`implements` 宣言は不要で、型の一致そのものが契約と実装の関係になる
- 粒度は1能力 = 1関数型。メソッド束のインターフェースにせず、ハンドラは必要な能力だけを deps で束ねる
- テストではポートをただの関数で差し替える。モックライブラリ不要
- リポジトリはドメイン型を受け渡しする。DB の行型・ORM のモデルをドメイン層に漏らさない（1モデル1テーブルである必要はない）

## 10. 境界での parse (Trust Boundary)

**意図**: 外部からの入力（HTTP・環境変数・DB の行・外部 API・キューなど）はすべて「信頼できない `unknown`」。境界で一度だけ parse し、内部ではドメイン型のみを扱う。

TypeScript の2つの言語制約 — 構造的型付け（公称型が無い）と型消去（実行時に型が残らない）— は、境界で最も強く現れる: コンパイル時の型は I/O を越えて生き残らず、形が一致することは意味の正しさを保証しない。境界の正しさを作れるのは実行時の parse だけであり、その定義はモデルが正本として持つ schema を合成して組む — 検証ルールを境界側に二重定義しない。手書きの型ガード・型アサーションでの代替は、定義と検証が乖離して shotgun parsing に退化しやすい。schema ライブラリを省く場合は、同等の保証（単一定義からの型導出 + 実行時検証）を自前で担保すること。

信頼境界の全列挙 — 以下すべてに同じ parse 規律を適用する:

- HTTP のボディ / クエリ / パスパラメータ
- 環境変数・設定ファイル
- DB から読んだ行（リポジトリのマッピング層）
- 外部 API の応答
- キュー・イベントのペイロード（コンテキスト間の契約型を含む）

```typescript
import { z } from "zod";

const PlaceOrderCommandSchema = z
  .object({
    orderId: OrderId.schema,
    lines: z
      .array(
        z.object({ productId: ProductId.schema, quantity: Quantity.schema }),
      )
      .min(1),
  })
  .brand<"PlaceOrderCommand">();

type PlaceOrderCommand = Readonly<z.infer<typeof PlaceOrderCommandSchema>>;
```

`safeParse` の結果型から Result への橋は `parseWith` を1つ定義して全境界で使い回す（実装は typescript.md）:

```typescript
const parsePlaceOrderCommand = parseWith(PlaceOrderCommandSchema);
```

- 境界の parse は「外形の検証」。ドメイン固有の不変条件（在庫・与信）はワークフロー内の純粋関数で判定する二層構え
- DB から読んだ値も信頼しない。リポジトリのマッピング層が形変換の後、集約・状態の schema で parse して復元する（load = parse）
- 構築関数の外で `as` キャストや再検証が現れたら、境界の設計が漏れているサイン
- **境界スキーマは形を、値の制約はドメインを** — フィールドにはドメインの schema（`OrderId.schema`）を合成する（§2 の所有権の一元化）
- コマンドも公称型にする — 構築経路が境界 parse だけなので brand のコストはゼロ。ハンドラは検証を通ったコマンドしか受け取れないことが型で言える
- 同じ違反でもエラーの語彙は捕捉した境界で決まる: 境界合成で弾かれれば ParseFailure（外形エラー）、ドメイン経路（DB 行の復元など）なら業務語彙のエラー

## 11. アンチパターン集

| アンチパターン                   | 症状                                                                                          | 処方                                                              |
| -------------------------------- | --------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| Primitive Obsession              | `string` / `number` がドメイン層を素通りする                                                  | branded type + smart constructor                                  |
| Shotgun Parsing                  | 検証 util があちこちから呼ばれる                                                              | 境界で一度だけ parse、証明を型で運ぶ                              |
| bool フラグ状態管理              | `isX: boolean` の組合せ + optional フィールド                                                 | 状態ごとの型 + discriminated union                                |
| ドメイン知識の漏れ               | getter で取ったデータを呼び出し側で加工・判定                                                 | 振る舞いをドメイン関数として公開                                  |
| 巨大集約                         | 1集約に何でも入れてロック競合・遅い保存                                                       | 真の不変条件で境界を引き直し、結果整合性を受容                    |
| Result 汎用化                    | バグまで `Result` で返す                                                                      | バグは throw で最外殻へ。Result は業務・インフラエラー用          |
| 貧血モデル + サービス肥大        | 手続き的な service にロジックが集まりデータ型は素通し                                         | ロジックを型のコンパニオン関数・ワークフローに凝集                |
| DB スキーマ駆動                  | テーブル定義から型を生成してそのままドメインに使う                                            | ドメイン型を先に設計し、リポジトリでマッピング                    |
| 型システムでの曲芸               | 複雑な conditional type でルールを全部型に押し込む                                            | 型で無理な制約は実行時検証（述語的アプローチ）に切り替える        |
| 境界での schema 後付け           | 境界スキーマが `Email.schema` に `.refine()` / `.transform()` を足す                          | 制約は所有ドメインの schema に一元化（後付けの禁止）              |
| 操作関数を迂回するスプレッド更新 | `{ ...order, lines: [...] }` をコンパニオンの外で書く。brand は保存されるため型は通ってしまう | 更新は操作関数経由。形の制約の正本は schema と共有定数            |
| `unknown` を受けるハンドラ       | parse がハンドラに埋まり、コマンドの形が変わっても呼び出し側に伝搬しない                      | parse は入口アダプタへ。ハンドラは parse 済みコマンド型を要求する |
