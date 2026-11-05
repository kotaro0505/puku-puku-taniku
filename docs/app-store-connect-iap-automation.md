# App Store Connect 鉢デザインIAP一括登録

更新日: 2026-11-06

## 現在の状態

- 36商品のローカルカタログ検証と登録予定一覧の生成は完了。
- 新APIキーによる認証付きDry Runと価格・地域の読み取り調査は完了。
- `pot_unlock_001` の不足項目補完と、`pot_unlock_003`〜`pot_unlock_036` の34件一括登録が完了。
- 36/36商品で商品本体、日英メタデータ、日本100円、海外174地域のApple自動価格、全175地域、将来地域ONをAPIで再確認済み。
- 審査提出、公開、Codemagicビルド、App Store提出は実行していない。
- 日本を基準地域、顧客価格100円、現在の全175地域、新規追加地域も自動販売、という方針をローカル設定へ反映済み。
- APIから100円のPrice Pointが一意に選択可能で、海外174地域の自動換算Price Pointが存在することを確認済み。
- 36商品すべて登録済み。不足は各商品の審査用スクリーンショットだけ。
- 審査用スクリーンショットは未配置。`pot_unlock_001` だけを対象とする撮影専用ビルドと検証機構を実装済みで、実機検証待ち。残り35商品の連続撮影は未承認・未実装。

実行ツール:

- `tools/app_store_connect_iap.mjs`
- `tools/app_store_connect_iap.auth.example.json`
- `tools/app_store_connect_iap.config.example.json`
- `tools/app_store_connect_iap.test.mjs`
- `tools/verify_iap_review_capture.mjs`

撮影パイロットの設計と実機チェックリストは `docs/iap-review-capture-pilot.md` を参照する。

## 調査結果

本番Bundle IDは `com.ohanayanouen.pukupukutaniku`。App Store Connect上の数値App IDはリポジトリに保存されていないため、ツールがBundle IDを使って公式APIから一意に特定する。

ゲームのIAP実装は `scripts/pot_unlock_iap_service.gd` のStoreKit 2連携で、次を行う。

- 36件のStoreKit商品情報とAppleのローカライズ価格を取得
- 非消耗型購入による鉢デザインの永続解放
- 購入済み商品の復元
- 返金・失効時の権利反映
- 一度解放したデザインの鉢をゲーム内ぷくコインで繰り返し購入

Codemagic向けドキュメントにはApp Manager権限のApp Store Connect API連携手順があるが、ローカル一括登録用のAPI設定、数値App ID、Key ID、Issuer ID、秘密鍵は存在しなかった。Codemagicに保存済みの秘密情報をこのツールが読み取ることもない。

## 確定したApple側販売方針とAPI調査結果

2026-11-05の試験登録直前の認証付きGET調査結果は次のとおり。

| 項目 | 結果 |
| --- | --- |
| 対象アプリ | `ぷくぷく多肉` / App ID `6807694389` / `com.ohanayanouen.pukupukutaniku` |
| 基準地域 | 日本 (`JPN`) |
| 希望顧客価格 | 100円 |
| JPN Price Point | 801件中、100円が一意に1件存在 |
| 近接価格 | 下側90円、上側110円（100円を設定できるため代替選択は不要） |
| 現在のApp Store地域 | 175地域 |
| 100円からの自動換算 | 日本以外174地域すべてにPrice Pointあり |
| 登録済み商品 | `pot_unlock_001`〜`pot_unlock_036` の36件すべて |
| 全件検証 | `NON_CONSUMABLE`、日英メタデータ、JPN 100円、手動価格JPNのみ、海外自動価格174地域、175地域＋将来地域ON |

価格スケジュールは日本を基準地域としてJPNの100円Price Pointだけを指定する。Appleが税、為替、各地域の価格慣行を使って残り174地域を自動換算する。特定地域を手動上書きすると、その地域はAppleの自動価格調整対象から外れるため、この36商品では地域別上書きを行わない。

販売可能地域は実行時に `GET /v1/territories` で再取得した全IDを指定し、`availableInNewTerritories: true` を設定する。これにより現在の175地域と、Appleが将来追加する地域を対象にする。IAP側を全地域にしても、アプリ本体がその地域で配信されていない、Paid Apps Agreementが有効でない、商品メタデータや審査状態が販売可能条件を満たさない、といった場合は購入できない。利用者に見える地域はApple Accountのストアフロントで決まる。

### `pot_unlock_002` 試験登録の停止と再試行記録

商品作成、`NON_CONSUMABLE`、参照名、Review Note、日本語・英語ローカライズまでは成功した。価格スケジュール作成時、インライン作成リソースのIDが `initial-price` で、Appleが要求する `${local-id}` 形式でなかったため、APIが409 `ENTITY_ERROR.INCLUDED.INVALID_ID` を返した。そこで処理を停止し、販売地域設定へは進まなかった。

ローカルpayloadを `${initial-price}` に修正し、既存商品がなければ作成せず停止するガードと回帰テストを追加した。追加承認後の再試行では、既存 `pot_unlock_002` を再利用してJPN 100円と175地域・将来地域ONを設定できた。この試験再開時点では不足項目は審査画像だけで、`pot_unlock_003`〜`pot_unlock_036` はまだ未登録だった。その後の一括登録結果は次節のとおり。

### 36商品の一括登録結果

追加承認後、既存 `pot_unlock_001` だけを既存必須ガード付きで補完した。続いて `pot_unlock_001` と `pot_unlock_002` を処理対象から明示除外し、`pot_unlock_003`〜`pot_unlock_036` が全件未登録であることを同一実行内で確認して34件を新規作成した。途中エラーはなく34/34件が完了した。

最終の読み取り専用検証では36/36件がすべて次に一致した。

- 商品種別 `NON_CONSUMABLE`
- 正式な日本語・英語の商品名と説明文
- 日本の手動価格は100円、手動価格地域はJPNの1地域だけ
- Apple自動価格は日本以外の174地域
- 販売可能地域は現在の全175地域
- `availableInNewTerritories` はON
- 審査画像、審査提出、公開は未実施

## 36商品の登録元データ

正式なStoreKit商品ID、日英表示名は `data/pot-iap-catalog.json` を唯一の登録元にする。ゲーム内ぷくコイン価格は検証だけを行い、Apple APIへ送信せず、変更もしない。

| # | StoreKit商品ID | 日本語表示名 | 英語表示名 | ゲーム内価格（検証専用） |
|---:|---|---|---|---:|
| 1 | `pot_unlock_001` | クリスタルゴブレット鉢 | Crystal Goblet Pot | 2 |
| 2 | `pot_unlock_002` | グリーングラス鉢 | Green Glass Pot | 2 |
| 3 | `pot_unlock_003` | シルバーメタル鉢 | Silver Metal Pot | 2 |
| 4 | `pot_unlock_004` | ホワイトボウル鉢 | White Bowl Pot | 2 |
| 5 | `pot_unlock_005` | テラコッタロング鉢 | Tall Terracotta Pot | 2 |
| 6 | `pot_unlock_006` | パールピンク鉢 | Pearl Pink Pot | 2 |
| 7 | `pot_unlock_007` | ウッドバレル鉢 | Wood Barrel Pot | 2 |
| 8 | `pot_unlock_008` | ブルーダイヤ鉢 | Blue Diamond Pot | 2 |
| 9 | `pot_unlock_009` | ロックボウル鉢 | Rock Bowl Pot | 2 |
| 10 | `pot_unlock_010` | ローズゴールドグラス鉢 | Rose Gold Glass Pot | 3 |
| 11 | `pot_unlock_011` | ゴールドジャックポット鉢 | Gold Jackpot Pot | 30 |
| 12 | `pot_unlock_012` | フラミンゴリゾート鉢 | Flamingo Resort Pot | 30 |
| 13 | `pot_unlock_013` | クラウンウォッチ鉢 | Crown Watch Pot | 30 |
| 14 | `pot_unlock_014` | マゼンタスーパーカー鉢 | Magenta Supercar Pot | 30 |
| 15 | `pot_unlock_015` | シェルコーラル鉢 | Shell Coral Pot | 5 |
| 16 | `pot_unlock_016` | 古木の切り株鉢 | Weathered Stump Pot | 5 |
| 17 | `pot_unlock_017` | コンクリートラウンド鉢 | Concrete Round Pot | 5 |
| 18 | `pot_unlock_018` | ロックストーン鉢 | Rough Rock Pot | 5 |
| 19 | `pot_unlock_019` | スターダストムーン鉢 | Stardust Moon Pot | 5 |
| 20 | `pot_unlock_020` | アンバークリスタル鉢 | Amber Crystal Pot | 5 |
| 21 | `pot_unlock_021` | アンティークフルール鉢 | Antique Fleur Pot | 5 |
| 22 | `pot_unlock_022` | ラスティバケツ鉢 | Rusty Bucket Pot | 5 |
| 23 | `pot_unlock_023` | オーロラパール鉢 | Aurora Pearl Pot | 5 |
| 24 | `pot_unlock_024` | ネオンクリスタル鉢 | Neon Crystal Pot | 10 |
| 25 | `pot_unlock_025` | キングマネー鉢 | King Money Pot | 10 |
| 26 | `pot_unlock_026` | レトロアーケード鉢 | Retro Arcade Pot | 10 |
| 27 | `pot_unlock_027` | ロイヤルジュエル鉢 | Royal Jewel Pot | 10 |
| 28 | `pot_unlock_028` | ジェリーフィッシュアクア鉢 | Jellyfish Aqua Pot | 10 |
| 29 | `pot_unlock_029` | レッドジャックポット鉢 | Red Jackpot Pot | 10 |
| 30 | `pot_unlock_030` | おやすみムーン鉢 | Sleepy Moon Pot | 10 |
| 31 | `pot_unlock_031` | ディスコボール鉢 | Disco Mirror Pot | 10 |
| 32 | `pot_unlock_032` | UFO鉢 | UFO Pot | 10 |
| 33 | `pot_unlock_033` | 森の切り株鉢 | Forest Stump Pot | 10 |
| 34 | `pot_unlock_034` | 花畑鉢 | Flower Meadow Pot | 10 |
| 35 | `pot_unlock_035` | 苔むす森鉢 | Mossy Forest Pot | 10 |
| 36 | `pot_unlock_036` | ラーメン鉢 | Ramen Bowl Pot | 100 |

全商品で次の共通説明文を使用する。

- 日本語: 「デザインを永続解放。以後ぷくコインで購入できます。」
- 英語: “Unlocks this design. Pots cost Puku Coins.”

## 使用するApple公式API

新規実装はApp Store Connect API 4.4.1以降のバージョン管理方式を使う。

1. `POST /v2/inAppPurchases`: 非消耗型IAPを作成
2. `POST /v1/inAppPurchaseVersions`: 編集可能なIAPバージョンを作成
3. `POST/PATCH /v2/inAppPurchaseLocalizations`: 日英表示名・説明文を登録
4. `GET /v2/inAppPurchases/{id}/pricePoints` と `POST /v1/inAppPurchasePriceSchedules`: Apple側価格を設定
5. `GET /v2/inAppPurchases/{id}/inAppPurchaseAvailability` と `POST /v1/inAppPurchaseAvailabilities`: 販売地域を確認・設定
6. `POST/PATCH/GET /v1/inAppPurchaseAppStoreReviewScreenshots`: 審査用実画面を予約、アップロード、コミット、検証
7. `GET /v1/apps/{id}/inAppPurchasesV2`: 既存商品と登録状態を照合

廃止された `POST /v1/inAppPurchaseLocalizations` と `POST /v1/inAppPurchaseSubmissions` は使わない。

審査提出・公開用エンドポイントはツールに実装していない。Appleの仕様上、最初のIAPはアプリのバイナリと一緒にApp Store ConnectのWeb画面から提出する必要がある。今回のツールはその操作を行わない。

## 自動化できる範囲

認証情報、Apple価格方針、販売地域方針、実画面スクリーンショットが揃えば、次は一括実行できる。

- 登録済み商品を商品IDで検出し、重複作成を回避
- 登録済み36商品の状態再検証と、将来の審査画像アップロード
- 登録済み1商品を含む36商品の参照名・Review Noteの整合
- IAPバージョン方式による日本語・英語メタデータの作成・更新
- 承認済みのJPN顧客価格100円が現在も一意に存在することを実行直前に再確認し、各商品の商品固有Price Pointへ対応付け
- 実行時点のApple全地域を再取得し、全地域と「新しい地域にも自動追加」を設定
- 実際のアプリ画面ファイルのアップロードと処理完了確認
- 商品種類、価格、地域、ローカライズ、画像、状態の再検証
- 途中失敗後の再実行（完成済み項目を再作成せず、未完了項目から再開）

自動化しないもの:

- App Store Connect API利用申請
- APIキーの作成・秘密鍵ダウンロード
- Apple日本円価格や販売地域の方針変更
- 架空画像の生成、実画面ではない画像の作成
- 審査提出、最初のIAPとバイナリの関連付け、公開
- 契約、税務、銀行情報の入力

## 最初に必要なユーザー操作

### 1. API利用を有効にする

App Store Connectの「ユーザとアクセス」→「統合」→「App Store Connect API」を開く。

まだAPI利用が有効でない場合は、Account Holderが「アクセスをリクエスト」を実行する。Apple側の審査が入る場合がある。

### 2. APIキーを作成する

推奨は、この作業専用のTeam Key。

- 名前例: `Codex IAP Registration`
- 権限: `App Manager`
- 控える値: Key ID、Issuer ID
- ダウンロード: `AuthKey_<KEY_ID>.p8`（再ダウンロード不可）

Team Keyの作成画面はAccount HolderまたはAdminが操作し、キーへ `App Manager` ロールを割り当てる。IAP管理APIはAccount Holder、Admin、App Managerのいずれかの権限が必要。秘密鍵は共有チャット、GitHub、ログへ貼らない。

Individual Keyもツール上は利用可能だが、そのユーザーが対象アプリにApp Manager相当の権限を持つ必要がある。

### 3. 秘密鍵をリポジトリ外へ保存する

例:

    C:\Users\<ユーザー名>\.appstoreconnect\AuthKey_<KEY_ID>.p8

`C:\puku-puku-taniku` の中には置かない。ツールはリポジトリ内の秘密鍵を意図的に拒否する。`.gitignore`にも `*.p8` を追加済み。

### 4. ローカル認証設定を作る

Codexから後続コマンドを実行できるよう、Git管理対象外のローカル設定へKey ID、Issuer ID、秘密鍵の絶対パスだけを記す。秘密鍵の内容は記載しない。

    Copy-Item tools\app_store_connect_iap.auth.example.json tools\app_store_connect_iap.auth.local.json

Team Keyの例（JSON内のWindowsパスは `\\` と記述する）:

    {
      "schemaVersion": 1,
      "keyType": "team",
      "keyId": "<Key ID>",
      "issuerId": "<Issuer ID>",
      "privateKeyPath": "C:\\Users\\<ユーザー名>\\.appstoreconnect\\AuthKey_<KEY_ID>.p8",
      "appId": ""
    }

`appId` は原則空欄でよい。Bundle IDで一意に検索できない場合だけ、App Store Connectで確認した数値App IDを設定する。このローカル認証設定は `.gitignore` 対象で、ツールは秘密鍵がリポジトリ内にある場合や相対パスの場合に拒否する。

環境変数を使う場合は、ローカル認証設定より優先される。PowerShellの現在のセッションだけに設定する例:

Team Key:

    $env:ASC_KEY_TYPE = "team"
    $env:ASC_KEY_ID = "<Key ID>"
    $env:ASC_ISSUER_ID = "<Issuer ID>"
    $env:ASC_PRIVATE_KEY_PATH = "C:\Users\<ユーザー名>\.appstoreconnect\AuthKey_<KEY_ID>.p8"

Individual Key:

    $env:ASC_KEY_TYPE = "individual"
    $env:ASC_KEY_ID = "<Key ID>"
    Remove-Item Env:ASC_ISSUER_ID -ErrorAction SilentlyContinue
    $env:ASC_PRIVATE_KEY_PATH = "C:\Users\<ユーザー名>\.appstoreconnect\AuthKey_<KEY_ID>.p8"

数値App IDは原則不要。Bundle IDで一意に検索する。必要な場合だけ、App Store Connectで確認した値を `ASC_APP_ID` に設定できる。

## Dry Run手順

### 1. ローカル設定を作る

    Copy-Item tools\app_store_connect_iap.config.example.json tools\app_store_connect_iap.config.local.json

ローカル設定はGit管理対象外。

### 2. 認証付きDry Runを実行する

    node tools/app_store_connect_iap.mjs dry-run --config tools/app_store_connect_iap.config.local.json

Dry RunはGETだけを実行し、Apple側へ書き込まない。結果には次が表示される。

- 登録済みの商品ID
- 商品種類
- Apple側の現在の日本円価格
- 販売地域数と「新しい地域にも自動追加」のON/OFF
- 審査用スクリーンショット状態
- IAP状態
- 各商品の `CREATE` / `RECONCILE` / `NO_CHANGE`

登録済み商品が1件だけなら価格点検用の参照商品として表示するが、その商品の未設定価格・地域を方針として採用しない。

### 3. 承認済み価格と販売地域方針を記入する

今回の確定方針はGit管理対象外のローカル設定に次のように記入する。

    "baseTerritory": "JPN",
    "desiredCustomerPrice": "100",
    "sellInAllTerritories": true,
    "availableInNewTerritories": true,
    "priceSourceProductId": "",
    "availabilitySourceProductId": "",

価格処理は、100円が現在も一意に選択可能かをAPIで再確認し、対象商品自身のJPN Price Pointから同じ顧客価格を特定する。ゲーム内ぷくコイン価格とは完全に別で、ゲームのカタログ値はAPIへ送信しない。

すでに別のApple価格や販売地域を持つ商品は上書きせず停止する。

## 審査用スクリーンショット

APIによる自動アップロードは可能。ただし画像そのものは、TestFlightの実際のアプリ画面から取得し、対象の鉢デザインと購入導線が明確に見えるものを用意する。

Appleは「アプリが対応するスクリーンショット仕様のいずれか」を満たし、提供対象の商品・サービスが明確に分かる画像を求めている。この画像は審査専用でApp Storeには表示されない。

既存の `artifacts/` を全件確認したところ、18枚はいずれも576×1024で、温室、寄せ植え、ストーリー画面だった。Appleの現行iPhoneスクリーンショット寸法ではなく、対象の有料鉢カードも表示していないため使用しない。`assets/arrangement/pots/` の個別鉢PNGも実画面ではないため使用しない。

商品ごとの取得条件:

1. 本番Bundle IDの撮影専用TestFlightビルドを実機iPhoneで起動する。現在のパイロット対象は `pot_unlock_001` のみ。
2. 日本のSandbox/TestFlightストアフロントからStoreKit価格を取得し、撮影専用機能が実際の「パンダのお店」→「鉢」UIを開く。通常セーブは読み取りのみで、移行・更新しない。
3. 対象鉢のカード全体が見える位置へスクロールする。
4. 対象鉢画像、日英いずれかの実表示名、解放後のぷくコイン価格、StoreKitが返す100円のローカライズ価格、解放ボタンを同時に写す。
5. 開発用UI、ローカルモック価格、画像合成、注釈追加、拡大縮小による寸法変更は行わない。
6. 実機のネイティブPNGを `pot_unlock_001.png`〜`pot_unlock_036.png` として保存する。36商品それぞれを一意に判別できる36枚を用意する。

36商品はすでにStoreKitから価格を取得できる登録状態にある。現在は `pot_unlock_001` の実機撮影成立を先に検証し、成功確認と追加承認の後に残り35商品の連続撮影へ拡張する。ツールの `stage-one` / `stage-all` は審査画像と審査提出を行わない。

ローカル設定へ商品別にパスを追加する。

    "reviewScreenshots": {
      "pot_unlock_001": "tools/app_store_connect_iap_private/pot_unlock_001.png",
      "pot_unlock_002": "tools/app_store_connect_iap_private/pot_unlock_002.png"
    }

`tools/app_store_connect_iap_private/` はGit管理対象外。絶対パスも指定できる。

ツールはPNG/JPEGの実ファイル、バイト数、画像寸法を確認する。画像の生成・加工は行わない。既存の完成済み審査画像は削除・置換せず保持する。

## 段階的な書き込み手順

### 1. 再Dry Run

100円と全地域の再検証結果を確認し、明示的な書き込み承認を得る。現段階ではここまでで停止する。

### 2. 承認後、登録済み `pot_unlock_001` を撮影可能状態へ整合

    node tools/app_store_connect_iap.mjs stage-one --config tools/app_store_connect_iap.config.local.json --product-id pot_unlock_001 --confirm STAGE_WITHOUT_SCREENSHOT:pot_unlock_001

日英メタデータ、100円、全地域だけを整合し、審査画像・審査提出・公開は行わない。TestFlightで実画面を取得後、ローカル設定へ画像パスを追加し、`apply-one` で画像だけを含む不足項目を整合する。

### 3. 未登録1商品だけ試験登録

`pot_unlock_NNN` はDry Runで `CREATE` と表示された商品を選ぶ。

    node tools/app_store_connect_iap.mjs stage-one --config tools/app_store_connect_iap.config.local.json --product-id pot_unlock_NNN --confirm STAGE_WITHOUT_SCREENSHOT:pot_unlock_NNN

この処理は非消耗型作成、日英メタデータ、価格、販売地域までに限定する。TestFlightで対象カードを撮影し、画像パス設定後に次を実行する。

    node tools/app_store_connect_iap.mjs apply-one --config tools/app_store_connect_iap.config.local.json --product-id pot_unlock_NNN --confirm CREATE_OR_RECONCILE:pot_unlock_NNN

どちらも審査提出・公開は行わない。

### 4. 試験結果の確認

    node tools/app_store_connect_iap.mjs dry-run --config tools/app_store_connect_iap.config.local.json

元の1商品と試験登録1商品の合計2商品が検出され、内容が正しいことを確認する。

### 5. 残りを撮影可能状態へ一括登録

試験結果の確認と改めての明示承認後だけ実行する。

    node tools/app_store_connect_iap.mjs stage-all --config tools/app_store_connect_iap.config.local.json --confirm STAGE_ALL_WITHOUT_SCREENSHOTS

TestFlightで残りの実画面を取得して36件の画像パスを設定する。

### 6. 審査画像を含む全36件を整合

36商品分の実画面が揃い、試験結果を確認し、改めて明示承認を得た後だけ実行する。

    node tools/app_store_connect_iap.mjs apply-all --config tools/app_store_connect_iap.config.local.json --confirm RECONCILE_ALL_36_IAPS

一括処理はApp Store Connectに元の1商品と試験1商品が存在しない限り拒否する。途中で失敗した場合は原因を直して同じコマンドを再実行すると、サーバー状態を再取得し、未完了部分から続行する。

## 安全対策

- デフォルトはローカル計画。認証付き `dry-run` もGETのみ。
- 書き込みコマンドは長い確認文字列が完全一致しないと拒否。
- 一括登録は1件試験登録の成功前には拒否。
- 商品IDで既存商品を照合し、重複作成を防止。
- 既存商品の種類が非消耗型でなければ停止。
- Apple価格・販売地域の明示方針が未指定なら停止。
- 100円Price Pointまたは全地域一覧を一意に再検証できなければ、書き込み前に停止。
- 既存の異なる価格・販売地域は上書きせず停止。
- `apply-*` は実画面ファイルが不足していれば、API書き込み前に全件検査で停止。`stage-*` は画像を一切扱わない。
- GET、画像PUT、同一内容PATCHは429/5xxで再試行。
- POSTの結果が不明な通信障害では安全に停止。再実行時にサーバー状態を確認して重複を避ける。
- 秘密鍵の内容、JWT、署名付きアップロードURLはログへ出さない。
- 審査画像を削除しない。
- 審査提出・公開エンドポイントを実装しない。
- `data/pot-iap-catalog.json` を読み取り専用の登録元として扱い、ゲーム価格を変更しない。

## ローカル検証

    node --check tools/app_store_connect_iap.mjs
    node --test tools/app_store_connect_iap.test.mjs
    node tools/app_store_connect_iap.mjs plan

テストは、36商品IDと正式ゲーム内価格、日英説明文、ES256 JWT、最新IAPバージョン方式のpayload、価格・地域payload、審査画像payload、Dry Runの非書き込み性、審査提出APIが存在しないことを検証する。

## Apple公式資料

- [Managing In-App Purchases](https://developer.apple.com/documentation/appstoreconnectapi/managing-in-app-purchases)
- [Working with In-App Purchase versions](https://developer.apple.com/documentation/appstoreconnectapi/working-with-in-app-purchase-versions)
- [Migrating In-App Purchase metadata to v2](https://developer.apple.com/documentation/appstoreconnectapi/migrating-in-app-purchase-metadata-to-v2)
- [Creating API Keys for App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api)
- [Generating Tokens for API Requests](https://developer.apple.com/documentation/appstoreconnectapi/generating-tokens-for-api-requests)
- [In-App Purchase information](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information)
- [Set a price for an In-App Purchase](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-a-price-for-an-in-app-purchase)
- [Set availability for In-App Purchases](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-availability-for-in-app-purchases/)
- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- [Troubleshooting In-App Purchases availability](https://developer.apple.com/documentation/technotes/tn3188-troubleshooting-in-app-purchases-availability-in-the-app-store)
