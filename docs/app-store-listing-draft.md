# App Store 掲載情報・審査資料 草案

作成日: 2026-10-26
対象: 『ぷくぷく！たにくらいふ』ストーリー版 iOS 1.0
状態: **App Store Connect へ未登録の草案**。公開、審査提出、ビルド実行は行っていない。

この文書は、現行のゲーム実装と2026-10-26時点のApple公式資料を照合して、帰宅後にApp Store Connectへ転記できる形に整理したものです。「候補」「未確認」とした内容は、最終ビルドまたはApp Store Connect上で確認してから登録してください。

## 1. 確定情報

| 項目 | 内容 |
| --- | --- |
| アプリ名 | ぷくぷく！たにくらいふ |
| 運営者 | オハナ屋農園 |
| 問い合わせ | kotaro.hana.0505@gmail.com |
| 国・地域 | 日本 |
| 公開方針 | 一般向けゲーム |
| Kids Category | 使用しない |
| ログイン | 不要。独自アカウント機能は現行実装にない |
| アプリ内言語 | 日本語、ひらがな、英語 |

## 2. 調査した実装と、正式版で紹介できる内容

### 調査対象

- `scripts/main.gd`: 通常12粒ゲーム、収穫、最高記録、ストーリー、図鑑、ショップ、広告、課金、共有への導線
- `scripts/game_localizer.gd`: 日本語、ひらがな、英語の表示文言
- `scripts/story_progression.gd`、`scripts/habitat_restoration.gd`: ストーリー進行、原生地、復興、エンディング、各機能の解放条件
- `scripts/forest_gacha_system.gd`、`scripts/forest_gacha_ui.gd`: 3ぷくコインのランダムガチャ
- `scripts/fusion_lab_ui.gd`、`data/fusion-recipes.json`、`data/hybrid-species.json`: ハイブリッドラボ
- `scripts/puku_puku_battle.gd`: ジュレジュレ団との育成・収穫スコア対戦
- `scripts/arrangement_ui.gd`、`data/pots.json`: 寄せ植えと鉢ショップ
- `scripts/pot_unlock_iap_service.gd`、`data/pot-iap-catalog.json`: StoreKit 2による36種の鉢デザイン解放
- `scripts/rewarded_ad_service.gd`: AdMobリワード広告、UMP同意、報酬完了判定
- `scripts/build_profile.gd`、`export_presets.cfg`: 開発版とApp Store本番版の分離
- `data/species-v2.json`、`data/series.json`、`data/catalog-progression.json`: 品種、図鑑、シリーズ構成

### 掲載文で紹介できる実装済み機能

- 一度に12粒のたねをまき、成長を見ながら収穫するゲーム
- 収穫サイズと品種ごとの最高記録
- 原種や不思議な多肉との出会い、NEWカード、図鑑への記録
- 女の子、パンダ、アルマジロと進むストーリー
- 原生地の探索、ジュレジュレ団との対決、原生地の復興、エンディングとクリア後
- 3ぷくコインで回すゲーム内ガチャ
- 2つの親株を組み合わせるハイブリッドラボ
- 発見した多肉と鉢を使う寄せ植え
- 最高記録画像と寄せ植え画像のOS共有シートによる共有
- 任意視聴のリワード広告による、ぷくコインまたはたねの救済
- 36種の鉢デザインを永続解放する非消耗型アプリ内課金

### 正式版の特徴として掲載しないもの

- ストーリージャンプ、開発用ガチャ、進行リセット、品種プレビュー、原生地テスト等の開発専用機能
- 開発用スロット画面。`SlotMachineScene` は開発機能で保護されたプレビュー経路からだけ生成され、本番のゲーム進行には接続されていない
- 現行ソースに存在しないジュレジュレ団リベンジ広告、広告削除購入、オンライン対戦、ランキング、ユーザー間チャット
- データ上で将来用または未解禁となっているシリーズ

## 3. Appleの現行文字数制限

| 項目 | Appleの上限 | 本草案の扱い |
| --- | --- | --- |
| App Name | 2〜30文字 | 日英とも上限内 |
| Subtitle | 30文字 | 日英とも上限内 |
| Promotional Text | 170文字 | 日英とも上限内 |
| Description | 4,000文字、プレーンテキスト | 日英とも上限内 |
| Keywords | UTF-8で100バイト、カンマ区切り | 日本語92バイト、英語83バイト |
| IAP Reference Name | 64文字 | 36件すべて上限内 |
| IAP Product ID | 100文字 | 36件すべて上限内 |
| IAP Display Name | 2〜30文字 | 36件・日英とも上限内 |
| IAP Description | 45文字 | 日本語26文字、英語43文字 |
| App Review Notes | 4,000バイト | 日本語候補2,314バイト、英語候補1,846バイト。いずれか1つを転記する |

根拠: [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)、[Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)、[In-App Purchase information](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information/)。Appleの一般向け紹介ページには過去のIAP文字数が残る場合があるため、本草案ではApp Store Connect Helpの30文字／45文字を採用しています。

## 4. 日本語掲載テキスト

### アプリ名（11文字）

```text
ぷくぷく！たにくらいふ
```

### サブタイトル（13文字）

```text
たねから始まる、多肉の物語
```

### プロモーションテキスト（70文字）

```text
12粒のたねから、どんな多肉が育つかな？ 収穫、図鑑、ハイブリッド、寄せ植えを楽しみながら、仲間たちと原生地の未来を取り戻す物語を進めよう。
```

### キーワード（UTF-8で92バイト）

```text
多肉植物,育成ゲーム,コレクション,寄せ植え,ハイブリッド,図鑑収集
```

アプリ名や運営者名はApp Store検索の対象になるため重複させていません。カテゴリ名だけを埋める語も避けています。

### アプリ説明文（540文字）

```text
ぷっくり、ふしぎな多肉植物を育てる物語。

古い倉庫で見つけた植物の本と、一袋の古いたね。
女の子、パンダ、アルマジロの3人は、失われた多肉植物をもう一度この世界に取り戻すため、小さな一歩を踏み出します。

【12粒のたねを育てよう】
たねをまき、成長を見守って、ちょうどいい瞬間に収穫。大きく育てて最高サイズの記録を更新しましょう。育ち方や出会える品種は毎回少しずつ変わります。

【見つけた多肉を図鑑へ】
はじめて出会った品種はNEWカードでお知らせ。原種から不思議な多肉まで、発見した品種が図鑑に記録されます。

【原生地をめぐるストーリー】
仲間たちと原生地を訪れ、ジュレジュレ団との「ぷくぷくバトル」に挑みながら、失われた景色の復興を目指します。結末は、ゲームの中で見届けてください。

【集めた多肉でもっと楽しむ】
・3ぷくコインで回せるゲーム内ガチャ
・2つの親株を選んで新しい品種を生み出すハイブリッドラボ
・お気に入りの多肉と鉢を組み合わせる寄せ植え
・最高記録や寄せ植え画像の共有

日本語・ひらがな・英語に対応。
ログインせずに遊べます。

本アプリには、任意で視聴できるリワード広告と、鉢デザインを永続的にアンロックする非消耗型のアプリ内課金が含まれます。
```

## 5. English listing text

### App Name (22 characters)

```text
Puku Puku! Taniku Life
```

This matches the English title used by the current in-game localization. Availability of the localized name in App Store Connect has not been checked.

### Subtitle (26 characters)

```text
Grow, collect, and restore
```

### Promotional Text (155 characters)

```text
What will grow from 12 tiny seeds? Raise and harvest succulents, fill your catalog, create hybrids, arrange your favorites, and help restore their habitat.
```

### Keywords (83 UTF-8 bytes)

```text
succulent,garden,growing,collection,hybrid,habitat,plants,harvest,arrangement,story
```

### Description (1,302 characters)

```text
A gentle story about growing wonderfully plump, mysterious succulents.

A girl, a panda florist, and an armadillo discover an old plant book and a packet of old seeds. Together, they set out to bring lost succulents back into the world.

GROW 12 SEEDS AT A TIME
Sow your seeds, watch them grow, and harvest at just the right moment. Try to raise bigger plants and set new size records. Each round brings a fresh mix of growth and discoveries.

BUILD YOUR SUCCULENT CATALOG
A NEW card celebrates every variety you discover for the first time. Record everything from long-lost varieties to strange new succulents in your catalog.

RESTORE THE NATIVE HABITAT
Follow the story, visit the succulents' original habitat, and face the Jurejure Gang in Puku Puku Battles as you work to restore a lost landscape. Discover the ending for yourself.

ENJOY YOUR COLLECTION IN NEW WAYS
• Spend 3 Puku Coins earned in the game to use the gacha.
• Choose two parent plants and create new varieties in the Hybrid Lab.
• Combine favorite succulents and pots in your own arrangements.
• Share images of your best records and arrangements.

Available in Japanese, hiragana, and English.
No login is required.

This app includes optional rewarded ads and non-consumable in-app purchases that permanently unlock pot designs.
```

## 6. App Storeカテゴリ候補

Appleはゲームに最大2つのGamesサブカテゴリを設定できます。現行一覧には `Simulation`、`Casual`、`Adventure` 等があります。根拠: [Categories and Discoverability](https://developer.apple.com/app-store/categories/)、[Freemium Games](https://developer.apple.com/app-store/freemium-games/)。

### 推奨

| 設定 | 候補 | 理由 |
| --- | --- | --- |
| Primary Category | Games | 一人用のインタラクティブな育成・収集ゲーム |
| Primary Subcategory | Simulation | たねまき、成長、収穫、記録、コレクション、寄せ植えが中心の継続的な育成体験 |
| Secondary Category | Games | 2つ目のGamesサブカテゴリを指定するため |
| Secondary Subcategory | Casual | 短い操作で遊べる12粒ゲームと親しみやすい表現 |

### 代替案

物語性を検索上より強く出したい場合はSecondaryを `Adventure` にする案があります。ただし、主要操作は探索アクションより育成・収集なので、現時点では `Simulation + Casual` が最も実装に忠実です。最終決定はApp Store Connectで行ってください。Kids Categoryは選択しません。

## 7. 年齢レーティング質問票の回答候補

Appleが質問票の回答から世界共通および地域別のレーティングを計算します。本資料は回答候補であり、レーティングを確定するものではありません。質問と定義は [Age ratings values and definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/) および [Set an app age rating](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/) に基づきます。

### 実装から確認できた重要点

- 「ぷくぷくバトル」は両陣営が多肉を育て、収穫サイズの合計点を競う一人用対戦です。攻撃、負傷、血、武器、死亡表現は確認できません。
- 本番のガチャは3ぷくコインを消費し、カプセルからランダムな品種が必ず出ます。ぷくコインを現金で購入するIAPや、現金への換金は現行実装にありません。
- 有料IAPは特定の鉢デザインを選んで買う固定商品で、ランダム商品ではありません。
- スロット風の専用シーンは開発プレビューだけです。App Store本番では開発機能が無効になり、通常プレイから利用できません。
- リワード動画広告があります。広告コンテンツ最大レーティングをGにする設定でも、質問票の `Advertising` は `Yes` です。
- 共有はOSの共有シートを開くだけで、アプリ内投稿、フィード、チャット、ユーザー間共有サービスはありません。
- 物語には「乱獲」「密猟」「絶滅」と、原生地を利用するジュレジュレ団との倫理的対立が短く登場します。

### 回答候補表

| 質問項目 | 回答候補 | 根拠・確認事項 |
| --- | --- | --- |
| Parental Controls | No | 保護者用の利用制限機能は確認できない |
| Age Assurance | No | 年齢確認、Declared Age Range API等は確認できない |
| Unrestricted Web Access | No | 任意サイトを閲覧できる内蔵ブラウザはない。OS共有シートは該当しない |
| User-Generated Content | No | アプリ内で広く配信されるUGCはない。共有画像は利用者が外部の共有先を選ぶ |
| Social Media | No | フィード、いいね、コメント、拡散機能はない |
| Social Media Disabled for Users Under 13 | No / Not applicable | Social Media自体がない |
| Messaging and Chat | No | ユーザー間通信はない |
| Advertising | **Yes** | AdMobの任意視聴リワード動画広告を実装 |
| Profanity or Crude Humor | None | 調査範囲の台詞に罵り、下品な表現は確認できない |
| Horror/Fear Themes | None | 環境危機の物語はあるが、恐怖・ホラーを目的とした表現は確認できない |
| Alcohol, Tobacco, or Drug Use or References | None | 該当表現を確認できない |
| Medical or Treatment Information | None | 医療助言はない |
| Health or Wellness Topics | None | 多肉育成はゲーム内の架空表現で、利用者の健康助言ではない |
| Mature or Suggestive Themes | **Infrequent（保守的候補）** | 乱獲、密猟、絶滅、環境搾取という現実の犯罪・倫理的題材が短く登場。実際の画面を見て最終回答する |
| Sexual Content or Nudity | None | 該当表現を確認できない |
| Graphic Sexual Content and Nudity | None | 該当表現を確認できない |
| Cartoon or Fantasy Violence | None（候補） | 「バトル」は植物の育成・収穫スコア競争で、物理的な攻撃や危害はない |
| Realistic Violence | None | 該当表現を確認できない |
| Prolonged Graphic or Sadistic Realistic Violence | None | 該当表現を確認できない |
| Guns or Other Weapons | None | 該当する武器を確認できない |
| Gambling | No | 現金または換金可能な通貨による賭けはない |
| Simulated Gambling | None（暫定候補） | 本番に賭けはなく、開発用スロットは本番無効。ガチャはランダム品種の取得であり賭けではないと読めるが、最終画面で再確認する |
| Contests | None（候補） | オンライン対戦、ランキング、ユーザー間コンテストはない。最高記録とNPC戦だけ |
| Loot Boxes | **Yesを保守的候補とし、未確定** | 3ぷくコインでランダム品種入りカプセルを得るため、Appleの「購入するランダムな仮想アイテム容器」に該当する可能性が高い。通貨は現金販売・換金不可だが、定義は購入通貨を現金に限定していない |
| Age Categories and Override | Not Applicable | 一般向けで、Made for Kidsを選ばず、独自の最低年齢も確定していない |

### 想定される影響と最終確認

- `Loot Boxes = Yes` なら、2026年のApple定義では通常地域で9+の要素となり、オーストラリアでは16+として扱われます。地域差が大きいため、ガチャ画面、3ぷくコインの入手経路、現金で通貨を買えないことを確認してから最終回答してください。
- `Mature or Suggestive Themes = Infrequent` も通常地域で9+の要素です。
- `Advertising = Yes` 自体は通常地域の4+に含まれ得ますが、広告クリエイティブがアプリの年齢レーティングに適合することは別途必要です。
- Appleが最終レーティングを自動計算するため、本書では「9+」等を確定値として登録しません。
- App Review Guideline 2.5.18は、不適切または年齢不相応な広告を利用者が報告できる手段も求めています。Google広告画面内の報告導線を含め、実機で未確認です。提出前の確認事項として残します。

## 8. 有料鉢36商品の日英メタデータ

### 共通仕様と登録状態

- 実装上は全36件が `iap_unlock` で、StoreKit entitlementを永続利用権として扱うため、登録タイプは **Non-Consumable** です。
- App Store Connect上のProduct Typeはリポジトリから確認できないため、36件を実際に `Non-Consumable` として作成したことは未確認です。
- 1回のIAPで該当デザインが永続解放されます。その後、同じデザインの鉢本体をゲーム内で1個ずつ **1ぷくコイン** で購入できます。
- 1ぷくコインはApp Store上の現金価格ではありません。
- 現金価格、価格帯、販売地域、税区分は未設定です。ここでは推測しません。
- Reference Nameは内部管理用の候補で、36件すべて一意です。

| Product ID | Reference Name | 日本語Display Name | English Display Name | 日本語Description | English Description | Type |
| --- | --- | --- | --- | --- | --- | --- |
| `pot_unlock_001` | Pot Unlock 001 - Crystal Goblet Pot | クリスタルゴブレット鉢 | Crystal Goblet Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_002` | Pot Unlock 002 - Green Glass Pot | グリーングラス鉢 | Green Glass Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_003` | Pot Unlock 003 - Silver Metal Pot | シルバーメタル鉢 | Silver Metal Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_004` | Pot Unlock 004 - White Bowl Pot | ホワイトボウル鉢 | White Bowl Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_005` | Pot Unlock 005 - Tall Terracotta Pot | テラコッタロング鉢 | Tall Terracotta Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_006` | Pot Unlock 006 - Pearl Pink Pot | パールピンク鉢 | Pearl Pink Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_007` | Pot Unlock 007 - Wood Barrel Pot | ウッドバレル鉢 | Wood Barrel Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_008` | Pot Unlock 008 - Blue Diamond Pot | ブルーダイヤ鉢 | Blue Diamond Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_009` | Pot Unlock 009 - Rock Bowl Pot | ロックボウル鉢 | Rock Bowl Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_010` | Pot Unlock 010 - Rose Gold Glass Pot | ローズゴールドグラス鉢 | Rose Gold Glass Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_011` | Pot Unlock 011 - Gold Jackpot Pot | ゴールドジャックポット鉢 | Gold Jackpot Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_012` | Pot Unlock 012 - Flamingo Resort Pot | フラミンゴリゾート鉢 | Flamingo Resort Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_013` | Pot Unlock 013 - Crown Watch Pot | クラウンウォッチ鉢 | Crown Watch Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_014` | Pot Unlock 014 - Magenta Supercar Pot | マゼンタスーパーカー鉢 | Magenta Supercar Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_015` | Pot Unlock 015 - Shell Coral Pot | シェルコーラル鉢 | Shell Coral Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_016` | Pot Unlock 016 - Weathered Stump Pot | 古木の切り株鉢 | Weathered Stump Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_017` | Pot Unlock 017 - Concrete Round Pot | コンクリートラウンド鉢 | Concrete Round Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_018` | Pot Unlock 018 - Rough Rock Pot | ロックストーン鉢 | Rough Rock Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_019` | Pot Unlock 019 - Stardust Moon Pot | スターダストムーン鉢 | Stardust Moon Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_020` | Pot Unlock 020 - Amber Crystal Pot | アンバークリスタル鉢 | Amber Crystal Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_021` | Pot Unlock 021 - Antique Fleur Pot | アンティークフルール鉢 | Antique Fleur Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_022` | Pot Unlock 022 - Rusty Bucket Pot | ラスティバケツ鉢 | Rusty Bucket Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_023` | Pot Unlock 023 - Aurora Pearl Pot | オーロラパール鉢 | Aurora Pearl Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_024` | Pot Unlock 024 - Neon Crystal Pot | ネオンクリスタル鉢 | Neon Crystal Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_025` | Pot Unlock 025 - King Money Pot | キングマネー鉢 | King Money Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_026` | Pot Unlock 026 - Retro Arcade Pot | レトロアーケード鉢 | Retro Arcade Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_027` | Pot Unlock 027 - Royal Jewel Pot | ロイヤルジュエル鉢 | Royal Jewel Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_028` | Pot Unlock 028 - Jellyfish Aqua Pot | ジェリーフィッシュアクア鉢 | Jellyfish Aqua Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_029` | Pot Unlock 029 - Red Jackpot Pot | レッドジャックポット鉢 | Red Jackpot Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_030` | Pot Unlock 030 - Sleepy Moon Pot | おやすみムーン鉢 | Sleepy Moon Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_031` | Pot Unlock 031 - Disco Mirror Pot | ディスコボール鉢 | Disco Mirror Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_032` | Pot Unlock 032 - UFO Pot | UFO鉢 | UFO Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_033` | Pot Unlock 033 - Forest Stump Pot | 森の切り株鉢 | Forest Stump Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_034` | Pot Unlock 034 - Flower Meadow Pot | 花畑鉢 | Flower Meadow Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_035` | Pot Unlock 035 - Mossy Forest Pot | 苔むす森鉢 | Mossy Forest Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |
| `pot_unlock_036` | Pot Unlock 036 - Ramen Bowl Pot | ラーメン鉢 | Ramen Bowl Pot | デザインを永続解放。以後1ぷくコインで購入できます。 | Permanently unlocks; pots cost 1 Puku Coin. | Non-Consumable |

### IAP審査用の共通説明候補

日本語:

```text
この非消耗型商品は、表示名の鉢デザインを永続的にアンロックします。アンロック後は、同デザインの鉢をゲーム内の1ぷくコインで1個ずつ購入し、寄せ植えに使用できます。ランダム商品ではありません。購入の復元は「パンダのお店」＞「鉢」画面上部の「購入を復元」から行えます。
```

English:

```text
This non-consumable permanently unlocks the pot design named above. After unlocking it, the player can buy individual pots of that design for 1 Puku Coin each and use them in arrangements. This is not a randomized purchase. Restore Purchases is at the top of Panda's Shop > Pots.
```

各商品には、対象カード、StoreKitのローカライズ価格、購入ボタンが同時に見えるReview Screenshotを用意してください。現時点ではスクリーンショットを作成していません。

## 9. App Review Information 草案

### 連絡先

| 欄 | 入力候補・状態 |
| --- | --- |
| Organization / Operator | オハナ屋農園 |
| Country / Region | Japan |
| Email | kotaro.hana.0505@gmail.com |
| Contact First Name / Last Name | **未提供。実在する担当者名が必要** |
| Phone | **未提供。国番号付き電話番号が必要** |
| Sign-in required | No |
| Demo account | 不要。ログイン機能なし |

AppleはApp Review連絡先として担当者名、メール、電話番号を求めます。運営者名を個人名欄へ分解して推測しないでください。

### 日本語版 審査メモ候補

```text
『ぷくぷく！たにくらいふ』は、縦画面で遊ぶ一人用の多肉植物育成・収集ストーリーゲームです。ログインやアカウント登録は不要です。

基本操作:
1. 初回起動後、オープニングと古いたねのチュートリアルを進めます。
2. 通常ゲームでは一度に12粒のたねをまき、成長中の株をタップして収穫します。
3. 初めて取得した品種はNEWカードの後、図鑑へ登録されます。
4. ストーリー進行により、原生地、寄せ植え、ガチャ、ハイブリッドラボ、ジュレジュレ団との育成・収穫スコア対戦が順次解放されます。

広告:
任意視聴のリワード動画広告だけを使用します。通常ゲーム用のぷくコインまたはたねが不足した際に「パンダのお店」でパンダをタップすると、救済の案内が表示されます。「お手伝いする」または「広告を見てたねをもらう」を選ぶと広告を要求します。SDKから視聴完了が通知された場合だけ、1ぷくコインまたはたね1セットを1回付与します。途中終了や読み込み失敗では報酬を付与しません。地域等により必要な場合、初回起動時にGoogle UMPの同意画面が表示されます。

アプリ内課金:
pot_unlock_001〜pot_unlock_036は非消耗型です。購入すると特定の鉢デザインを永続解放し、その後は同じデザインの鉢をゲーム内の1ぷくコインで1個ずつ購入できます。現金でぷくコインを販売する機能や、ランダムな有料IAPはありません。

購入画面への通常導線:
オープニングと初回チュートリアルを完了し、不思議な多肉を3品種取得すると寄せ植えとショップ内の鉢カテゴリが解放されます。6品種取得後はpot_unlock_001〜pot_unlock_014が「パンダのお店」＞「鉢」に表示されます。第三幕の解放後はpot_unlock_015〜pot_unlock_036も表示されます。「購入を復元」は鉢画面上部にあります。

本番ビルドでは、開発用ストーリージャンプ、進行リセット、開発用ガチャ等は無効です。これらを審査操作には使用できません。
```

### English App Review Notes candidate

```text
Puku Puku! Taniku Life is a portrait, single-player succulent growing and collection story game. No login or account registration is required.

Basic flow:
1. On first launch, follow the opening story and the old-seed tutorial.
2. In a normal round, sow 12 seeds and tap growing plants to harvest them.
3. A newly obtained variety is shown on a NEW card and then recorded in the catalog.
4. The native habitat, arrangements, gacha, Hybrid Lab, and the grow-and-harvest score matches against the Jurejure Gang unlock through normal story progress.

Ads:
The app uses optional rewarded video ads only. When the player lacks Puku Coins or playable seeds, open Panda's Shop and tap the panda. Choose "Help at the shop" or "Watch an ad to get seeds" to request an ad. One Puku Coin or one seed set is granted once only after the SDK reports that the reward was earned. Closing early or failing to load grants nothing. A Google UMP consent form may appear on first launch when required for the user's region or consent state.

In-App Purchases:
pot_unlock_001 through pot_unlock_036 are non-consumables. Each purchase permanently unlocks one specific pot design. The player can then buy individual pots of that design for 1 in-game Puku Coin each. The app does not sell Puku Coins for money and has no randomized paid IAP.

Normal route to the purchase screen:
Complete the opening and first tutorial. After discovering 3 fantasy varieties, arrangements and the Pots category unlock. After 6 such discoveries, pot_unlock_001 through pot_unlock_014 appear in Panda's Shop > Pots. pot_unlock_015 through pot_unlock_036 appear after Act III unlocks. Restore Purchases is at the top of the Pots screen.

The production build disables all developer-only story jumps, progress resets, and developer gacha controls. They are not available as review shortcuts.
```

### 審査で確認してほしい操作

1. 新規データでオープニングから通常12粒ゲームまで進める。
2. 収穫とNEWカード、図鑑登録を確認する。
3. 地域またはデバッグ用同意状態に応じたUMP画面と設定内のプライバシー設定導線を確認する。
4. Googleテスト広告または審査環境で、完了時だけ報酬が1回付与され、途中終了では付与されないことを確認する。
5. Sandboxで鉢の購入、キャンセル、購入失敗、再起動後の権利維持、購入の復元を確認する。
6. 購入後、該当鉢が1ぷくコインで購入でき、寄せ植えに使用できることを確認する。

### 通常プレイでは到達に時間がかかる項目への対応案

IAP後半22件は第三幕まで進めないと表示されないため、審査担当者が短時間で直接確認しにくい状態です。開発用ストーリージャンプは本番で使えず、審査メモに使用可能と書いてはいけません。提出前に次を行ってください。

1. 36件それぞれに、対象商品が実際の購入画面に表示されたReview Screenshotを登録する。
2. App Review Informationへ、上記の正確な通常解放条件と、購入・復元を示す短い画面収録を添付する。
3. TestFlight本番Bundle IDでApp Reviewと同じ商品レコードをSandbox確認する。
4. Appleが直接操作できる短縮経路を要求した場合は、隠し開発機能を有効にせず、一般利用者にも説明可能な本番安全設計を別途決定する。今回の資料作成ではゲーム仕様を変更しない。

この「審査到達性」は提出前の未解決事項です。動画だけでIAPの実機審査が代替できるとは断定しません。

## 10. スクリーンショット構成案

Appleはデバイスサイズごとに1〜10枚を受け付け、最初の1〜3枚が検索結果でも重要になります。現行iOS exportは `application/targeted_device_family=0` のiPhone向け設定です。最終Xcode/IPAでもiPhone専用になっていることを確認し、iPad対応になっている場合は13インチiPad画像も追加してください。根拠: [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)、[Upload app previews and screenshots](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/)。

推奨は縦画面9枚です。タイトル画面より、実際の遊びが分かる通常育成を1枚目にします。

| 順番 | 実画面 | 日本語キャッチコピー | English caption | 撮影上の注意 |
| --- | --- | --- | --- | --- |
| 1 | 通常の12粒育成 | 12粒のたねから、どんな多肉が育つ？ | What will grow from 12 tiny seeds? | 複数サイズの株と収穫操作が分かる瞬間 |
| 2 | NEWカード | はじめての出会いをNEWカードで | Celebrate every first discovery | 最新の正式音源・本番UI、ネタバレの少ない序盤品種 |
| 3 | ストーリーと原生地 | 仲間とめぐる、原生地復興の物語 | A story of friends and restoration | 結末や終盤の重要場面は避ける |
| 4 | 図鑑 | 見つけた品種を図鑑に記録 | Fill your catalog with discoveries | 開発用全解放ではなく自然な進行データ |
| 5 | ハイブリッドラボ | 2つの親株から新しい品種へ | Create new varieties from two parents | 親株2つと結果候補が見える画面 |
| 6 | 寄せ植え | お気に入りを自分だけの寄せ植えに | Arrange your favorites your way | 未購入の現金価格を合成しない |
| 7 | ぷくぷくバトル | 育てて収穫！ぷくぷくバトル | Grow, harvest, and win the Puku Puku Battle | 攻撃ゲームに見えない、育成・点数比較の場面 |
| 8 | 森のガチャ | 3ぷくコインで森のガチャ | Try the forest gacha for 3 Puku Coins | 実際のゲーム内価格とカプセルを表示 |
| 9 | タイトル／主要キャラクター | ぷくぷく！たにくらいふ | A tiny succulent story begins | アプリ名、女の子、パンダ、アルマジロを中心にする |

日本語ストアには日本語UIと日本語コピー、英語ストアには英語UIと英語コピーの別画像を用意します。ひらがな表示はアプリ内機能として説明文で案内し、スクリーンショット枠が限られる場合は日本語版の補助画像候補にします。

撮影時は以下を守ります。

- App Store本番プロファイル相当を使用し、開発メニュー、デバッグ表示、ストーリージャンプを写さない
- Googleのテスト広告、端末の個人情報、通知バナー、SandboxのApple IDを写さない
- 架空の現金価格や未提供機能を画像へ追加しない
- 画像は透過なしのPNG/JPEGとし、iPhone Dynamic Island mediumの受理サイズ（例: 1179×2556または1206×2622、縦）で最低1枚を用意する
- 実画面を中心にし、コピーを重ねる場合もUIや操作内容を誤認させない

## 11. App Store Connectへ転記する前の未確定事項

### 必須情報

- App Store上での日本語名と英語ローカライズ名の空き状況
- App Review連絡先の実在する担当者名と、国番号付き電話番号
- Copyrightに入れる取得年と権利者の正式表記
- 正式公開したPrivacy Policy URL
- 実際の問い合わせ情報を掲載するSupport URL
- Primary/Secondaryカテゴリの最終決定
- 年齢質問票の `Mature or Suggestive Themes` と `Loot Boxes` の最終判断
- App Privacy申告と、AdMob/UMP/ATTの実機Privacy Reportとの整合
- 広告内またはアプリ内の「不適切な広告を報告」導線
- 配布国・地域。中国本土、ベトナム、韓国、オーストラリア等のゲーム／年齢関連要件も配布地域に応じて確認する

### 36件のIAP

- App Store Connectで全商品をNon-Consumableとして登録済みか
- 各商品の現金価格、販売地域、税区分、Family Sharing方針
- 日英ローカライズ、Review Notes、36件分のReview Screenshot
- 初回アプリバージョンと同じSubmissionへ36件を追加すること
- Sandbox/TestFlight実機での購入、キャンセル、失敗、復元、再インストール、返金／権利変更
- 後半商品まで審査担当者が確認できる方法

### 掲載素材とストア運用

- 日本語・英語の実機スクリーンショット
- 最終ビルドがiPhone専用か、iPad対応も含むか
- Marketing URL（任意）
- アプリの販売価格、公開日、リリース方式、配布地域
- Digital Services Act trader status、輸出コンプライアンス、Content Rights
- キーワードと名称についての最終的な商標・権利確認

## 12. 転記時の推奨順序

1. Privacy Policy URL、Support URL、App Review担当者名・電話番号を確定する。
2. App Informationで日英名称、カテゴリ、年齢質問票を入力する。Loot Boxesの判断を先送りしない。
3. 36件のIAPをNon-Consumableとして作成し、日英メタデータ、価格、地域、Review Screenshotを登録する。
4. iOSバージョン画面に日英のSubtitle、Description、Keywords、Promotional Text、スクリーンショットを登録する。
5. App Privacy、広告報告導線、UMP/ATT、Sandbox IAPを最終IPAと実機で照合する。
6. App Review Informationへ英語審査メモ、担当者情報、必要な画面収録を登録する。
7. すべての未確定事項が解消するまで、Submit for Reviewを行わない。

## 13. 公式参照先

- [App information（名称、Subtitle、カテゴリ、App Review連絡先）](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
- [Platform version information（Description、Keywords、Promotional Text、Review Notes）](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)
- [Creating Your Product Page](https://developer.apple.com/app-store/product-page/)
- [Categories and Discoverability](https://developer.apple.com/app-store/categories/)
- [Freemium Games（Gamesサブカテゴリ一覧）](https://developer.apple.com/app-store/freemium-games/)
- [Age ratings values and definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions/)
- [Set an app age rating](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/)
- [In-App Purchase information](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information/)
- [Create consumable or non-consumable In-App Purchases](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases)
- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
