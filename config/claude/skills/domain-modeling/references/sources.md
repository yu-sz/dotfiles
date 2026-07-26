# Sources

このSkillの根拠となる厳選文献。約250ソースの調査から選定。

## 軸（中心概念の原典）

- [Domain Modeling Made Functional (Scott Wlaschin)](https://pragprog.com/titles/swdddf/domain-modeling-made-functional/) — 本Skillの中心。型でドメインを表現しワークフローを関数合成で表す。邦訳『関数型ドメインモデリング』
- [Domain Driven Design (F# for fun and profit)](https://fsharpforfunandprofit.com/ddd/) — 上記のエッセンスを凝縮した講演ページ。入門の最短経路
- [Designing with types series (Wlaschin)](https://fsharpforfunandprofit.com/series/designing-with-types/) — 型を設計行為の道具にする技法の体系
- [Effective ML Revisited (Yaron Minsky)](https://blog.janestreet.com/effective-ml-revisited/) — "Make illegal states unrepresentable" の原典
- [Parse, don't validate (Alexis King)](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/) — 境界で一度だけ解析し証明を型で運ぶ。[日本語訳](https://zenn.dev/mj2mkt/articles/2024-10-11-parse-dont-validate)
- [Domain-Driven Design Reference (Eric Evans)](https://www.domainlanguage.com/ddd/reference/) — DDD 全パターンの公式定義集
- [Effective Aggregate Design (Vaughn Vernon)](https://www.dddcommunity.org/library/vernon_2011/) — 集約設計の事実上の標準（小さく・ID参照・1Tx1集約・結果整合性）
- [Boundaries (Gary Bernhardt)](https://www.destroyallsoftware.com/talks/boundaries) — Functional Core, Imperative Shell の命名元
- [Impureim sandwich (Mark Seemann)](https://blog.ploeh.dk/2020/03/02/impureim-sandwich/) — 不純→純粋→不純の最小構造
- [Functional architecture is Ports and Adapters (Seemann)](https://blog.ploeh.dk/2016/03/18/functional-architecture-is-ports-and-adapters/) — 純粋関数を守るとヘキサゴナルが自然に成立する
- [Secure by Design (Bergh Johnsson / Deogun / Sawano)](https://www.manning.com/books/secure-by-design) — ドメインプリミティブ・構築時 fail-fast・不変性で「設計によってセキュリティを達成する」。MISU のセキュリティ方言であり、検証順序・機密値パターンの出典。邦訳『セキュア・バイ・デザイン』

## アプリケーションアーキテクチャ

- [Hexagonal Architecture (Alistair Cockburn)](https://alistair.cockburn.us/hexagonal-architecture/) — ポート・アダプタ（入口 = driving / 出口 = driven）の原典
- [DDD, Hexagonal, Onion, Clean, CQRS: How I put it all together (Herberto Graça)](https://herbertograca.com/2017/11/16/explicit-architecture-01-ddd-hexagonal-onion-clean-cqrs-how-i-put-it-all-together/) — 各流派を1枚に統合した Explicit Architecture。共通構造は「ドメイン中心・依存内向き」
- [DDDで実装を始めるのに一番とっつきやすいアーキテクチャ (little-hands)](https://qiita.com/little_hand_s/items/ebb4284afeea0e8cc752) — ヘキサゴナル・オニオン・クリーンは本質的に同一という広く引用される整理
- [Combining DDD, CQRS, and Clean Architecture in Go (Three Dots Labs)](https://threedots.tech/post/ddd-cqrs-clean-architecture-combined/) — 複雑性をドメイン層へ閉じ込め、アプリケーション層はオーケストレーションのみ
- [CQRS Documents (Greg Young, 2010)](https://cqrs.files.wordpress.com/2010/11/cqrs_documents.pdf) — CQRS 原義の一次定義。「書き込みと読み取りで別のモデルを用いる」それだけ
- [Functional Event Sourcing Decider (Jérémie Chassaing)](https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider) — Decider パターン（decide / evolve）の原典
- [Practical Introduction to Event Sourcing (Oskar Dudycz)](https://www.architecture-weekly.com/p/practical-introduction-to-event-sourcing) — decide / evolve 純関数ペア（Decider）への収斂
- [Transactional Outbox (Chris Richardson, microservices.io)](https://microservices.io/patterns/data/transactional-outbox.html) — 保存とイベント記録の原子性。イベント + 結果整合性という統合既定の成立条件
- [Process Manager (Enterprise Integration Patterns, Hohpe & Woolf)](https://www.enterpriseintegrationpatterns.com/patterns/messaging/ProcessManager.html) — Process Manager パターンの原典（2003）。進行状態を持つ購読者が多段プロセスを駆動する
- [Sagas (Hector Garcia-Molina & Kenneth Salem, 1987)](https://www.cs.cornell.edu/andru/cs711/2002fa/reading/sagas.pdf) — Saga の原典。長期トランザクションを補償操作つきの局所トランザクション列に分解する
- [jet/FsCodec](https://github.com/jet/FsCodec) — イベント直和ごとに codec を1つ持つ実践。イベント名 → デコーダの表引きが復元の統一入口
- [RFC 9562: Universally Unique IDentifiers (UUIDs)](https://datatracker.ietf.org/doc/html/rfc9562) — UUIDv7 の規格。時間順ソート可能なアプリ発行 ID の根拠

## TypeScript 実践

- [Functional Domain Driven Design: Simplified (Anthony Manning-Franklin)](https://antman-does-software.com/functional-domain-driven-design-simplified) — classless TS への戦術パターン翻訳。Invariant / Deriver
- [Sairyss/domain-driven-hexagon](https://github.com/Sairyss/domain-driven-hexagon) — TS 最大の DDD 教科書リポジトリ（クラスベースだが原則は移植可能）
- [fraktalio/fmodel-ts](https://github.com/fraktalio/fmodel-ts) — Decider パターン `(command, state) => events` の純関数型実装
- [Making Illegal States Unrepresentable — In TypeScript (Chris Krycho)](https://v5.chriskrycho.com/journal/making-illegal-states-unrepresentable-in-ts/) — Wlaschin の例の忠実な TS 移植
- [Effect: Branded Types](https://effect.website/docs/code-style/branded-types/) / [Effect Solutions: Data Modeling](https://www.effect.solutions/data-modeling) — Brand + Schema による単一情報源戦略
- [neverthrow](https://github.com/supermacro/neverthrow) / [ts-pattern](https://github.com/gvergnaud/ts-pattern) / [zod](https://github.com/colinhacks/zod) — 既定スタックの一次資料
- [ruizb/domain-modeling-ts](https://github.com/ruizb/domain-modeling-ts) — branded type + smart constructor の2手法比較
- [TypeScriptによるcreate関数を使わないドメインモデルの関数型アプローチ](https://zenn.dev/mackay/articles/57267630e47296) — コンパニオンオブジェクトパターン
- [TypeScript の型安全性を高める Branded Types](https://zenn.dev/farstep/articles/typescript-branded-types) — brand 実装の体系的解説
- [TypeScript×関数型×DDDで、ユニットテストが激減（一休・猪股健太郎）](https://levtech.jp/media/article/column/detail_559/) — 型による静的検査最大化の実務実証

## Rust / Go

- [Zero To Production #6: Using Types To Guarantee Domain Invariants (Luca Palmieri)](https://lpalmieri.com/posts/2020-12-11-zero-to-production-6-domain-modelling/) — Rust 型駆動の決定版チュートリアル
- [The Typestate Pattern in Rust (Cliff Biffle)](https://cliffle.com/blog/rust-typestate/) — 状態遷移のコンパイル時検証
- [Make Illegal States Unrepresentable (corrode)](https://corrode.dev/blog/illegal-state/) / [Using Enums to Represent State (corrode)](https://corrode.dev/blog/enums/) — Rust 実務の標準形
- [nutype](https://github.com/greyblake/nutype) — 検証付き newtype の宣言的生成（serde でもバイパス不能）
- [Functional Domain Modeling in Rust (Xebia)](https://xebia.com/blog/functional-domain-modeling-in-rust-part-1/) — DMMF の Rust 展開
- [Rustでドメイン固有型を作る際のコツ (j5ik2o)](https://zenn.dev/j5ik2o/articles/d37bd2c6924446) — 可変性を型シグネチャに明示する設計
- [wild-workouts-go-ddd-example (Three Dots Labs)](https://github.com/ThreeDotsLabs/wild-workouts-go-ddd-example) — Go DDD の標準教材（リファクタリング連載付き）
- [DDD Lite in Go (Three Dots Labs)](https://threedots.tech/post/ddd-lite-in-go-introduction/) — 「常に妥当な状態をメモリに保つ」Go 流の実現
- [The Repository Pattern in Go (Three Dots Labs)](https://threedots.tech/post/repository-pattern-in-go/) — ドメイン型と DB モデルの完全分離。「DB を差し替えられるならリポジトリは正しく実装できている」という判定基準

## 戦略・発見プロセス・日本語圏

- [Bounded Context (Fowler)](https://martinfowler.com/bliki/BoundedContext.html) / [Ubiquitous Language (Fowler)](https://martinfowler.com/bliki/UbiquitousLanguage.html) — 戦略的 DDD の核
- [Core Domain Patterns (Nick Tune)](https://medium.com/nick-tune-tech-strategy-blog/core-domain-patterns-941f89446af5) — 差別化×複雑性での投資判断
- [Introducing Event Storming (Alberto Brandolini)](https://ziobrando.blogspot.com/2013/11/introducing-event-storming.html) / [Event Modeling (Adam Dymitruk)](https://eventmodeling.org/) — イベント中心の発見と設計
- [簡単にできるDDDのモデリング (little-hands / 松岡幸一郎)](https://little-hands.hatenablog.com/entry/2022/06/01/ddd-modeling) — sudo モデリング
- [DDDにおけるドメイン層オブジェクト設計の基本方針 (little-hands)](https://little-hands.hatenablog.com/entry/2022/01/24/domain-object-design) — 知識の凝集と Always-Valid
- [ドメイン駆動設計の集約のわかりにくさの原因 (増田亨)](https://masuda220.hatenablog.com/entry/2021/05/07/142824) — 集約 = ビジネスルール表現の手段
- [古典ドメインモデリングパターンの解脱 (kawasima)](https://scrapbox.io/kawasima/%E5%8F%A4%E5%85%B8%E3%83%89%E3%83%A1%E3%82%A4%E3%83%B3%E3%83%A2%E3%83%87%E3%83%AA%E3%83%B3%E3%82%B0%E3%83%91%E3%82%BF%E3%83%BC%E3%83%B3%E3%81%AE%E8%A7%A3%E8%84%B1_-_%E5%A4%A7%E5%90%89%E7%A5%A5%E5%AF%BA.pm) — 複雑性保存則・モデリングとエンコーディングの分離
- [破壊せよ！データ破壊駆動で考えるドメインモデリング (ミノ駆動)](https://speakerdeck.com/minodriven/data-destroy-driven) — 不変条件の発見手法
- [Eliciting Security Requirements with Misuse Cases (Sindre & Opdahl)](https://link.springer.com/article/10.1007/s00766-004-0194-4) — 「許してはならない機能」の反転による制約導出。データ破壊駆動の学術的系譜
- [State Transition Testing (ISTQB CTFL Syllabus v4.0 §4.2.3)](https://istqb.org/certifications/certified-tester-foundation-level/) — 状態遷移表の空欄 = 無効遷移、の明文出典。全遷移カバレッジの規範
- [Choosing Properties for Property-Based Testing (Scott Wlaschin)](https://fsharpforfunandprofit.com/posts/property-based-testing-2/) — 性質発見の7パターン。「変換をまたいで保存されるものは何か」の問い
- [How to Specify It! (John Hughes)](https://research.chalmers.se/publication/517894/file/517894_Fulltext.pdf) — 性質の5系統。不変条件だけでは仕様として不十分という正典的指摘
- [Alloy: A Lightweight Object Modelling Notation (Daniel Jackson)](https://people.csail.mit.edu/dnj/publications/alloy-journal.pdf) — 最小モデルから反例が示唆する制約を漸進的に追加する分析プロセス
- [Introducing Example Mapping (Matt Wynne)](https://cucumber.io/blog/bdd/example-mapping-introduction/) — ルール（= 制約）と具体例の往復による発見。答えられない問いは疑問カードとして在庫化
- [集約の境界と整合性問題に関する感想 (j5ik2o)](https://qiita.com/j5ik2o/items/ae8a4d3cdaa24afe7599) — 巨大集約アンチパターンと結果整合性
- [ドメインモデリングの設計思想を比較する (seijikohara)](https://zenn.dev/seijikohara/articles/software-design-modeling-comparison) — 10設計思想の俯瞰マップ
- [関数型ドメインモデリング 非公式宣伝サイト (訳者・猪股健太郎)](https://matarillo.com/dmmf/) — 日本語圏の型駆動 DDD 情報ハブ

## バランサー（過剰適用の解毒剤）

- [Constructive vs Predicative Data (Hillel Wayne)](https://www.hillelwayne.com/post/constructive/) — 型での排除と検証関数は対等なトレードオフ
- [Names are not type safety (Alexis King)](https://lexi-lambda.github.io/blog/2020/11/01/names-are-not-type-safety/) — 外在的安全性と内在的安全性の峻別
- [Against Railway-Oriented Programming (Wlaschin)](https://fsharpforfunandprofit.com/posts/against-railway-oriented-programming/) — Result の過剰適用への発案者自身の警告。パニック（バグ）を Result にしない規律の根拠
- [Can types replace validation? (Seemann)](https://blog.ploeh.dk/2022/08/22/can-types-replace-validation/) — 型は検証結果の容れ物
- [STOP doing dogmatic DDD (Derek Comartin)](https://codeopinion.com/stop-doing-dogmatic-domain-driven-design/) — 本質は境界と言語、パターンのカーゴカルト化への警鐘
- [Balancing Coupling in Software Design (Vlad Khononov)](https://www.oreilly.com/library/view/balancing-coupling-in/9780137353514/) — 結合の3次元（Strength / Distance / Volatility）

## モダントレンド

- [Data-Oriented Programming in Java (inside.java)](https://inside.java/2024/05/23/dop-v1-1-introduction/) — MISU が主流言語の公式原則に到達した画期
- [Eric Evans: DDD and LLMs (InfoQ)](https://www.infoq.com/news/2024/03/Evans-ddd-experiment-llm/) — 「学習済み LLM は境界づけられたコンテキスト」
- [LLMs bring new nature of abstraction (Fowler)](https://martinfowler.com/articles/2025-nature-abstraction.html) — 非決定性に対する決定的モデルのガードレール価値
- [Residuality Theory (InfoQ)](https://www.infoq.com/news/2025/10/architectures-residuality-theory/) — 「アーキテクチャは設計でなく訓練」
