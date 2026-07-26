---
name: domain-modeling
description: "Functional domain modeling and application architecture best practices for designing a backend end-to-end. Use when: designing backend systems or features (subdomain classification, bounded contexts, context maps, domain models), structuring applications (functional core / imperative shell, ports, vertical slices, repositories), writing or reviewing domain layer code (value objects, entities, aggregates, state machines, workflows, domain errors), or discussing DDD / type-driven design in TypeScript, Rust, or Go."
---

# Functional Domain Modeling

## Core Principles

> ドメインモデリングとは、業務の知識と制約を型と純粋関数の構造としてコードに 1:1 で写し取り、不正な状態・遷移・依存を「表現不能」にする継続的活動である。

軸は Scott Wlaschin『Domain Modeling Made Functional』（邦訳『関数型ドメインモデリング』）— 本 Skill はこの系譜を土台とする。以下の5原則がすべての判断の基礎になる。

1. **Model ≡ Code** — 型定義がそのままドメインドキュメント。型名・関数名はユビキタス言語（業務語彙）と一致させる
2. **Make Illegal States Unrepresentable** — 型は「可能な値の集合」。正当な状態だけを表現可能にし、バグのクラスごとコンパイル時に消す
3. **Parse, don't validate** — 検証（boolean を返す）ではなく解析（構造化された型を返す）を信頼境界で一度だけ行い、「検証済み」の証明を型で運ぶ
4. **Functional Core, Imperative Shell** — 決定（純粋関数）と実行（副作用）を分離する。読む → 決める → 書く
5. **Always immutable, no classes** — 全データはイミュータブルなプレーンオブジェクト。更新は新しい値の生成

型で排除した不正は、テスト対象からも攻撃対象からも消える。テストは smart constructor の境界値と純粋なワークフロー関数の性質検証に集中し、インジェクション・不正遷移・機密値漏洩といった脆弱性クラスは設計段階で排除される。

## Vocabulary

概念は必ずこの名前で呼ぶ。

- 収載基準: ①本文で使用する語 ②設計対話に必須の、業界で通用する語。ローカルな造語は収載しない
- 各語には英語の原語を併記する。対応する英語の原語が無い語は収載しない（ローカル語の検出を兼ねる）。逆に、英語のまま流通している語（branded type / smart constructor / Result 等）には無理に和訳を作らない
- 並びは設計の進行順（Structure Map・Design Workflow と同一の軸）。各群内は概念 → 実装イディオムの順
- 第1群が古典 DDD の戦略的設計に、第3群以降が戦術的設計の関数型再定義に対応する

### 意味と境界

| 用語                                         | 定義                                                                                                |
| -------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| ドメイン (Domain)                            | ソフトウェアが解決しようとする業務領域                                                              |
| サブドメイン (Subdomain)                     | 業務領域の区分。中核 / 支援 / 汎用に分類し、投資量を決める（Strategy Essentials 参照）              |
| ドメインモデル (Domain Model)                | 問題解決のために業務の特定の側面を抽象化した、目的特化の仮説                                        |
| ユビキタス言語 (Ubiquitous Language)         | 開発者と業務側が共有する厳密な語彙。型名・関数名・イベント名と一致させ、型定義が用語集を兼ねる      |
| 境界づけられたコンテキスト (Bounded Context) | 1つのモデルと言語の統一が成立する範囲。実装上はモジュール境界と揃え、跨ぐ場所には明示的な変換を置く |
| コンテキストマップ (Context Map)             | 境界づけられたコンテキスト間の関係と連携パターンを1枚に描いた図。戦略フェーズの成果物               |
| 公開された言語 (Published Language)          | 境界の外へ公開する契約型。後方互換を守って進化させる                                                |
| 腐敗防止層 (Anti-Corruption Layer)           | 上流の契約型を自分のドメイン型へ parse する変換層。受け取る側（下流）が所有する                     |

### Discovery（発見）

| 用語                                 | 定義                                                                                                  |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| イベントストーミング (EventStorming) | ドメインイベントを時系列に並べ、コマンド・アクター・境界を発見する協働手法。本 Skill の発見手順の源流 |
| ミニ言語 (little language)           | `data` / `AND` / `OR` / `->` で業務ルールを記述する中間記法。直積・直和・関数に 1:1 で写る            |

### 値と制約

| 用語                                    | 定義                                                                                                                         |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| 不変条件 (Invariant)                    | 業務上つねに真でなければならない制約。型・smart constructor・集約のいずれかで守る                                            |
| 代数的データ型 (Algebraic Data Types)   | 直積型（AND: オブジェクト / struct）と直和型（OR: discriminated union / enum）の合成で「取りうる値の集合」を定義する型構築法 |
| 値オブジェクト (Value Object)           | 属性値の等価性で比較される、制約付きの不変な値。branded type + smart constructor で表現する                                  |
| ドメインプリミティブ (Domain Primitive) | 自己検証・不変・最小の値型（Secure by Design）。本 Skill では値オブジェクトがこれを兼ね、機密値の遮蔽もここで行う            |
| branded type / newtype                  | 構造が同じでも型システム上は区別される型。意味の取り違えをゼロコストで防ぐ                                                   |
| smart constructor                       | 検証の定義を一元化し、それを通らない値の構築を不能にする構築関数。Result を返す                                              |
| Result                                  | 成功 / 失敗を直和で表す戻り値型。業務エラーとインフラエラー（ポート）を運び、バグ（パニック）には使わず throw に任せる       |

### 状態と振る舞い

| 用語                            | 定義                                                                                                            |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| エンティティ (Entity)           | ID によって同一性が時間を貫くデータ。等価性は ID で判定する                                                     |
| 集約 (Aggregate)                | 不変条件を1トランザクションで守る最小のデータ境界。外部からはルート経由でのみ操作する                           |
| 状態機械 (State Machine)        | 状態ごとに型を分け、遷移関数が遷移元の状態型だけを受け取る構造。直和型 + 網羅的分岐で不正な遷移を表現不能にする |
| コマンド (Command)              | 「〜する」という実行の要求。イベントとは語彙レベルで区別する                                                    |
| ドメインイベント (Domain Event) | 「〜された」という過去形の事実。発生源の集約は購読者を知らない                                                  |
| ワークフロー (Workflow)         | 1つの業務プロセスを表す純粋関数 `(Command, State) -> Result<Event[], DomainError>`                              |

### アーキテクチャ

| 用語                                            | 定義                                                                                                                                                                                                               |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Functional Core, Imperative Shell (FCIS)        | 決定（純粋関数）と実行（副作用）を分離する構造原則                                                                                                                                                                 |
| ポート (Port)                                   | 呼び出し側（ハンドラ）が宣言・所有する境界上の契約。副作用の能力を1つずつ関数型で表し、アダプタ（infra 実装）がこれを満たす                                                                                        |
| アダプタ (Adapter)                              | ポートを満たす具体実装（DB・外部 API クライアント等）。infra に置き、合成ルートで結線される                                                                                                                        |
| 入口アダプタ (Driving Adapter)                  | 外界の入力を受けてハンドラを起動するアダプタ（HTTP ルート定義・キュー購読）。信頼境界の parse と応答への変換を担う                                                                                                 |
| ハンドラ (Command Handler)                      | 1ワークフローを「読む → 決める → 書く」で実行するシェルの単位。parse 済みのコマンド型を受け取り、ロジックを持たない。HTTP フレームワークがハンドラと呼ぶルートコールバックは本 Skill では入口アダプタに当たる      |
| リポジトリ (Repository)                         | ドメインモデルを正本とする永続化の抽象。集約単位の取得（parse による復元）と保存（全体置換）を担うポート群。クエリは持たない                                                                                       |
| 合成ルート (Composition Root)                   | ポートとアダプタを結線する唯一の場所。エントリポイントに1箇所だけ置く                                                                                                                                              |
| 垂直スライス (Vertical Slice)                   | レイヤ横断ではなくワークフロー単位でコードを刻む分割。変更が1スライスに閉じる                                                                                                                                      |
| CQRS (Command Query Responsibility Segregation) | 書き込み用と読み取り用で別のモデルを用いる分離パターン。本 Skill は原義（Greg Young: モデル分離のみ）で規定する。世間では別ストア + プロジェクションを含む本格構成を指して流布しているが、そちらは本規定に含めない |

## Structure Map

設計の進行順に5領域。各領域の詳細は references へ:

| 領域              | 問い             | 要点                                                                                       | 詳細                                                           |
| ----------------- | ---------------- | ------------------------------------------------------------------------------------------ | -------------------------------------------------------------- |
| 境界              | どこに何を作るか | サブドメイン分類で投資先を決め、境界づけられたコンテキスト = モジュールに分割する          | [references/bounded-context.md](references/bounded-context.md) |
| Discovery（発見） | 何が起きる業務か | イベント（過去形の事実）から発見し、ミニ言語で記述してから型に写す                         | [references/process.md](references/process.md)                 |
| モデル            | どう型に写すか   | 代数的データ型 + branded type + smart constructor。状態ごとに型を分け、遷移を関数にする    | [references/patterns.md](references/patterns.md)               |
| アーキテクチャ    | どう動かすか     | Functional Core, Imperative Shell。ポート = 関数型、垂直スライス、リポジトリで永続化を分離 | [references/architecture.md](references/architecture.md)       |
| 規律              | いつやめるか     | 過剰適用の防止。下記 Discipline 参照                                                       | この文書                                                       |

## Design Workflow

バックエンド設計の全工程。**各フェーズの成果物が揃ったとき、設計は完成**:

| フェーズ                  | 問い                 | 作業                                                                                                 | 成果物                                     |
| ------------------------- | -------------------- | ---------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| 1. 戦略                   | どこに投資するか     | サブドメインを列挙し中核 / 支援 / 汎用に分類。境界づけられたコンテキストを切り、関係パターンを決める | サブドメイン分類表・コンテキストマップ     |
| 2. Discovery（発見）      | 何が起きる業務か     | コンテキストごとにイベント列挙 → コマンド対応付け → 不変条件の洗い出し → ミニ言語スケッチ            | イベント列・ミニ言語スケッチ               |
| 3. モデル                 | どう型に写すか       | スケッチを branded type・直和型・関数シグネチャへ 1:1 変換。集約境界を確定                           | ドメイン型定義（= 用語集）・ワークフロー型 |
| 4. Implementation（実装） | どう動かすか         | 垂直スライスに配置。ポート定義 → ハンドラ（読む → 決める → 書く）→ リポジトリ・変換層                | モジュール構成・ポート一覧・エラーカタログ |
| 5. 検証                   | 設計として完成したか | 下記 Checklist で全体レビュー。型で守れない制約のテスト計画を立てる                                  | テスト戦略・レビュー済みの設計一式         |

- 参照先: フェーズ1 = 下記 Strategy Essentials + bounded-context.md / フェーズ2 = process.md / フェーズ3 = patterns.md / フェーズ4 = architecture.md / フェーズ5 = 下記 Checklist + architecture.md のテスト戦略
- フェーズは滝ではない。モデルは仮説であり、3→2 や 4→3 の手戻りはコンパイラの破壊的変更検出が安全に導く。完璧を待たず妥当な成果物を早く出して反復する。ただし境界・語彙の誤りは唯一コンパイラが検出できない誤りであり、フェーズ1への手戻りが最も高くつく

## Strategy Essentials

組織論・詳細な戦略論には踏み込まない。ただし設計の入力となる次の3概念は、フェーズ1の道具として必ず使う。

### サブドメイン分類

業務領域を列挙し3種に分類して投資量を決める。判定軸は「複雑さ × 差別化」:

| 分類              | 定義                                     | 実装方針                              |
| ----------------- | ---------------------------------------- | ------------------------------------- |
| 中核 (Core)       | 複雑 × 事業の差別化の源泉                | 本 Skill の全技法で深くモデリングする |
| 支援 (Supporting) | 必要だが差別化しない                     | 素朴な CRUD で自作する                |
| 汎用 (Generic)    | どの事業でも同じ（認証・決済・通知など） | 既製品・SaaS・ライブラリを使う        |

### 境界づけられたコンテキストとコンテキストマップ

- 境界づけられたコンテキスト = モデルとユビキタス言語の統一範囲 = モジュール。同じ語が境界ごとに違う意味を持つのは正常で、跨ぐ場所には明示的な変換を置く
- コンテキストマップ = 境界間の関係を1枚に描いた成果物。接続ごとに連携パターンを明示的に選び、暗黙の相互依存にしない
- 境界の見つけ方・モジュール実装・連携パターンの定義は [references/bounded-context.md](references/bounded-context.md)

## Architecture Overview

すべてのユースケースを次の一本道に正規化する。ドメインモデル（型 + 純粋関数）が中心、副作用は薄いシェルへ:

```text
入力 (unknown)
  → parse（境界で一度だけ）        … Shell
  → 読む: 状態のロード             … Shell (I/O)
  → 決める: ワークフロー            … Core（純粋関数・単体テスト/PBT）
  → 書く: 永続化・イベント発行      … Shell (I/O)
  → 応答
```

- この一本道は1つの境界づけられたコンテキストの内部構造。システム全体はコンテキスト（モジュール）の集合であり、その関係はコンテキストマップで決める
- 純粋関数を守るだけでヘキサゴナル（依存内向き）が自然に成立する。レイヤ規約ではなく型で強制する
- ポート = 関数型インターフェース。class も DI コンテナも不要。結線は合成ルート1箇所のみ
- コードは業務領域 → ワークフロー単位の垂直スライスで刻む
- ドメインモデルは書き込み（不変条件の保護）の道具。読み取りパスは DTO 直行でよい（CQRS の最小形）

構成・トランザクション・イベント配線・テスト戦略の詳細は [references/architecture.md](references/architecture.md)。

## TypeScript Quick Reference

値オブジェクトの既定形 — スキーマ同居コンパニオン（型とコンパニオンを同名にする。機構の解説と手書き版は patterns.md）:

```typescript
import { z } from "zod";
import { Result, ok, err } from "neverthrow";

// 値の制約の唯一の定義。ここから静的型・実行時検証・brand（公称型化）を導出する
const schema = z.string().email().max(254).brand<"Email">(); // 254 = メールアドレスの実用上限 (RFC 5321)
// 静的型はスキーマから導出する。手書きしないので定義と型が乖離しない
type Email = z.infer<typeof schema>;

// 予期される失敗は業務語彙の直和型で表す
type EmailError = Readonly<{ type: "InvalidEmail"; value: string }>;

// 型と同名のコンパニオンオブジェクト
const Email = {
  // 境界スキーマが合成して再利用する口。所有権はこのドメインモジュール
  schema,
  // smart constructor: これを通らずに Email 型は構築できない
  parse: (value: string): Result<Email, EmailError> => {
    const result = schema.safeParse(value);
    // ZodError はここでドメインの語彙に変換し、外に漏らさない
    return result.success
      ? ok(result.data)
      : err({ type: "InvalidEmail", value });
  },
} as const;
```

- 値オブジェクト = branded type + Result を返す smart constructor。生のプリミティブをドメイン層に流さない
- 状態機械: 状態 = discriminated union、遷移関数は遷移元の状態型だけを受け取る（`pay(order: UnpaidOrder): PaidOrder`）
- 分岐は網羅的に: ts-pattern の `.exhaustive()` または never チェック
- **原則は公称型化と境界の実行時 parse、スキーマライブラリはその最適解**: 構造的型付け + 型消去という TS の制約下で、branded 化と「静的型 = 実行時検証」を単一定義で導出できる手段として既定装備にする
- 既定スタック: zod（境界の parse）+ neverthrow（Result）+ ts-pattern（match）。zod は同カテゴリ（Effect Schema / valibot / ArkType）で代替可。Effect 採用プロジェクトでは Schema + Brand + Match に読み替える

パターン全体（値オブジェクト・集約・ワークフロー・エラー・DI・機密値）とアンチパターンは [references/patterns.md](references/patterns.md)、TypeScript の言語機構は [references/typescript.md](references/typescript.md)、Rust / Go は [references/rust.md](references/rust.md) / [references/go.md](references/go.md) を参照。

## Discipline

やめる判断も体系の一部。以下に該当したら原則より現実を優先する:

| 状況                                       | 判断                                                                               |
| ------------------------------------------ | ---------------------------------------------------------------------------------- |
| 短命・CRUD・支援 / 汎用領域                | 深いモデリングをしない。素朴な実装が正解                                           |
| 制約が否定条件・相互に重なる・頻繁に変わる | 型での排除（構成的）に固執せず、検証関数（述語的）を選ぶ                           |
| バグ（不変条件の内部破れ・パニック）       | Result にしない。throw / panic に任せ最外殻で捕捉。Result は業務・インフラエラー用 |
| すべてを型で表そうとしている               | 型は検証結果の容れ物であり検証の置換ではない。残る制約は実行時検証で守る           |
| パターンを形だけ導入しようとしている       | ユビキタス言語と境界の整理が先。形だけの導入はトランザクションスクリプトに退化する |
| モデルの完成を待って実装が止まっている     | 完璧より妥当なモデルを早く出し、反復で改善する                                     |

## Checklist

設計・レビュー時（Design Workflow フェーズ5）にコピーして使う:

```markdown
Domain modeling checklist:

- [ ] サブドメイン分類表とコンテキストマップが成果物として存在し、投資量（深いモデリング or 素朴な実装）が分類と一致している
- [ ] 境界づけられたコンテキスト = モジュールが一致し、越境 import が仕組みで禁止されている
- [ ] 型名・関数名がユビキタス言語（業務語彙）と一致している
- [ ] 生のプリミティブ（string / number）がドメイン層を流れていない
- [ ] 不正な状態の組合せが型で表現不能（bool フラグの組合せで状態を表していない）
- [ ] 検証は信頼境界で一度だけ行い、「検証済み」が型として下流に伝わる
- [ ] ドメイン層に副作用（I/O・現在時刻・乱数）が混入していない
- [ ] ハンドラが「読む → 決める → 書く」の形で、純粋な決定の途中に I/O がない
- [ ] フレームワーク・ORM の型がドメイン層に import されていない
- [ ] 予期される業務エラーが戻り値の型に現れている（throw していない）
- [ ] エラーが内部詳細を漏らさず、機密値が生の string で持ち回られていない
- [ ] 集約は小さく、他の集約は ID で参照、1トランザクション = 1集約
- [ ] ID はアプリ発行（UUIDv7 / ULID）で、技術 ID と業務 ID が分離されている
- [ ] すべてのデータがイミュータブル（更新 = 新しい値の生成）
```

## References

設計の進行順:

- [references/bounded-context.md](references/bounded-context.md) — 境界づけられたコンテキスト（見つけ方・モジュール実装・関係パターン・腐敗防止層）
- [references/process.md](references/process.md) — Discovery プロセス（イベント発見・ミニ言語記法・集約境界）
- [references/patterns.md](references/patterns.md) — ドメインモデルの型パターンカタログ（TypeScript 実装例・機密値・アンチパターン）
- [references/architecture.md](references/architecture.md) — アプリケーションアーキテクチャ（FCIS・ポート・垂直スライス・永続化・CQRS・テスト戦略）
- [references/typescript.md](references/typescript.md) — TypeScript 実現イディオム（brand の付与・Readonly の配置・構築・既定スタック）
- [references/rust.md](references/rust.md) — Rust イディオム（newtype・enum・typestate・導出の向き）
- [references/go.md](references/go.md) — Go イディオム（直和の近似・private field + ファクトリ関数）
- [references/sources.md](references/sources.md) — 出典・参考文献
