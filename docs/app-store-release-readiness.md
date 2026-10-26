# App Store正式リリース準備記録

最終更新: 2026-10-26

## 現在の判定

**NO GO**。コード内で安全に完了できるリリース対策は進めたが、次の項目は外部アカウント、署名環境、実機、または運営者情報が必要であり、現時点では検証済みではない。

1. AdMob本番アプリ／リワード広告ユニットとCodemagic Secretは用意済み。残るのはUMPメッセージ設定の実アカウント確認、公開、および実機での本番相当テスト
2. ATTとApp Privacyの最終判断。Google Mobile Ads SDKのPrivacy ManifestはDevice IDのTracking利用可能性を宣言しているため、非パーソナライズ設定だけを根拠に「ATT不要」と断定しない
3. UMPの「プライバシー設定を再表示する入口」。3言語UIと安全な機能検出層は追加したが、採用プラグインv7.0のネイティブバイナリには `privacyOptionsRequirementStatus` / `presentPrivacyOptionsForm` / `canRequestAds` の橋渡しがないため、現行ビルドでは入口を非表示にする
4. 一般向け／Kids Category不使用の方針は確定済み。ただし利用者の年齢を把握する仕組みがなく、Google Mobile Ads 12.14.0はTFATを利用できないため、既知の子ども・ティーンをどう判定するかと年齢別広告取扱いの法務・運用判断が未確定
5. App Store Connectでの非消耗型IAP 36商品の登録とSandbox／TestFlight実機購入テスト
6. 公開済みプライバシーポリシーURL、アプリ内からそのURLへ到達できる導線、サポートURL
7. Codemagicでの署名済みIPA生成・署名検証・App Store Connectアップロード
8. 新規データ／既存データ更新の実機テストと、主要iPhone画面サイズでの最終目視確認
9. App Store Connectのメタデータ、スクリーンショット、年齢レーティング、審査情報、契約・税務・銀行情報

上記を終えるまで `ios-app-store-release` は実行しない。このワークフローは成功後にApp Store審査へ自動提出する設定である。

## 2026-10-24 ローカル検証結果

- Godot `4.7.2.stable.official.ed1daf0bf` でCodemagicと同じ回帰テスト38本を連続実行し、38/38 PASS
- 本番／開発ビルドプロファイル検証がともにPASS
- `codemagic.yaml` は3ワークフロー、各12ステップとして解析でき、Codemagic公式JSON Schema検証もPASS
- Web release exportに成功し、更新後の `index.pck` をGodotで直接起動して終了コード0を確認
- Web `index.pck` SHA-256: `7c6faa10eb59ff7ce928310deac5e83f5496d38ccdadf2095139e8451a89b333`

Windows上のローカル検証であり、Codemagic macOS実行、Xcode archive、署名、IPA、App Store Connect、AdMob実機、StoreKit Sandboxの検証を代替しない。

## 2026-10-26 広告プライバシー調査

- Google Mobile Ads SDK 12.14.0はTFAT APIを持たない。`ageRestrictedTreatment` と `CHILD` / `TEEN` / `UNSPECIFIED` が導入されたのは13.3.0で、現在のGodot AdMob Plugin v7.0は旧TFCD／TFUAだけを公開している
- 年齢情報を取得していない現状では、旧2設定を明示的に `UNSPECIFIED` のままとした。これは「成人」を意味せず、特定の年齢処理を申告していない状態である。根拠なく全員をCHILDまたはTEENにはしていない
- UMP公式の要否判定、プライバシーオプションフォーム表示、広告要求可否の3能力を検出するGDScript層と、日本語・ひらがな・英語の設定ボタンを追加した。v7.0ネイティブバイナリでは3能力が不足するためボタンは非表示で、初回同意フォームを代用しない
- 非パーソナライズ、first-party ID無効、最大コンテンツレーティングG、ATTプロンプト無効を維持した。CIは生成設定、export後Info.plist、署名済みIPAに意図しないATT用途説明が入った場合に失敗する
- ただし、上記の静的設定だけではApple定義上のトラッキング不存在を証明しない。最終IPAのPrivacy Report、実機通信、AdMobの広告ソース／メディエーション設定を確認するまでATTとApp PrivacyはNO GOのままである

ローカル検証結果:

- Godot 4.7.2でCodemagic相当の回帰スモーク39本を連続実行し、39/39 PASS
- UMP required／not required／広告要求不可／フォームエラー、同意変更後の広告再読み込み、報酬の一度だけ付与、途中終了時の非付与を自動テストで確認
- 本番／開発ビルドプロファイル検証、AdMob Secret欠落時の失敗、Codemagic公式JSON Schema検証がPASS
- 一時Web release exportをChromiumで起動し、canvas生成とAdMob／privacy-options未対応エラー0件を確認
- これはWindows上のモック／静的検証であり、iOS実機上のUMPフォーム、IDFA、通信、署名済みIPAを検証したものではない

TFATの意味と旧設定との関係:

| TFAT値 | 意味 | GMA 12.14.0の旧設定との関係 |
| --- | --- | --- |
| `CHILD` | その広告要求へ子ども向け保護を適用する | TFCD `true` またはTFUA `true` は移行表上 `CHILD` に対応 |
| `TEEN` | その広告要求へティーン向け保護を適用する | 旧TFCD／TFUAに同等値なし |
| `UNSPECIFIED` | 特定の年齢処理シグナルを適用しない | 旧設定の `false`、未設定、`UNSPECIFIED` に対応。成人であるという表明ではない |

新旧設定を同時に指定するとGoogleは最も保守的な処理を適用する。いずれの値も利用者の実際の年齢・法的区分をアプリ側で正しく判断する責任を置き換えるものではない。

## 実装済みのリリース対策

### ビルドプロファイル

| 用途 | Godot機能タグ | Bundle ID | 開発機能 | 広告 |
| --- | --- | --- | --- | --- |
| GodotローカルDebug | Debug判定 | ローカル | 有効 | 疑似広告 |
| Web開発版 | `puku_development,puku_rewarded_ad_stub` | Web | 有効 | 疑似広告 |
| iPhone開発版 | `puku_development,puku_ios_test_ads` | `com.ohanayanouen.pukupukutaniku.dev` | 有効 | Google公式テスト広告 |
| TestFlight内部版 | `puku_app_store_release` | `com.ohanayanouen.pukupukutaniku` | 無効 | 本番ID必須 |
| App Store版 | `puku_app_store_release` | `com.ohanayanouen.pukupukutaniku` | 無効 | 本番ID必須 |

`scripts/build_profile.gd` が唯一の判定元である。本番タグが存在すると、競合する開発タグが誤って付いていても本番側へ閉じ、CIも競合をエラーにする。`main.gd` の定数を手作業で切り替える運用ではない。

ストーリージャンプ、開発ガチャ、進行リセット、品種プレビュー、原生地／ジュレ化テスト、数値調整、デバッグ表示のソースとテストは削除していない。ローカルDebug、Web開発版、iPhone開発版で従来どおり利用できる。本番版ではメニューを生成せず、進行リセットや原生地デバッグ記録などの危険な内部入口にも追加の本番ガードを入れた。

本番Bundle IDと `user://records.json` の保存方式は変更していないため、既存本番ユーザーの保存領域を維持する。iPhone開発版は別Bundle IDなので別コンテナとなり、本番セーブと混在しない。同じ端末への併存にはApple Developerで開発版Bundle IDを登録し、Development証明書／Provisioning Profileを用意する必要がある。

### 広告

Godot 4.7対応のAdMobプラグインv7.0と、同プラグインが固定するGoogle Mobile Ads SDK 12.14.0を組み込んだ。Googleの公式テストIDは開発版だけに生成し、本番ワークフローは次の暗号化環境変数が欠落、不正形式、またはGoogleサンプルIDの場合に失敗する。

- `ADMOB_IOS_APP_ID`
- `ADMOB_IOS_REWARDED_AD_UNIT_ID`

これらはCodemagicのApplicationまたはTeam environment variablesへSecretとして登録し、Gitへ保存しない。生成される `addons/AdmobPlugin/ios_export.cfg` と `data/mobile-ads.cfg` は `.gitignore` 対象である。

実装済みの広告処理:

- UMP同意情報を起動ごとに更新し、同意が必要な場合はフォームを表示
- 対応する将来のネイティブ橋渡しがある場合だけ、UMPの要否に応じて「プライバシー設定」ボタンを3言語で表示し、変更後は古い広告を破棄して `canRequestAds` を再確認
- 初期化、読み込み、読み込み失敗、指数バックオフ再試行、表示失敗、閉じる、報酬獲得を分離
- SDKの「報酬獲得」コールバック時だけ報酬を付与
- 途中終了時は付与しない
- 同じ広告の重複コールバックでも1回しか付与しない
- 表示失敗後にリクエストロックを解除し、次回読み込みへ復帰
- 広告利用不可時はゲーム内案内を表示
- first-party IDを無効化し、非パーソナライズ広告を指定
- 広告コンテンツ最大レーティングをGに固定
- 年齢を把握していない現状では、旧TFCD／TFUAを明示的に `UNSPECIFIED` とする（成人指定ではない）
- ATSを全面解除せず、Googleが案内するMedia／WebContentの限定例外だけを付与

現在広告を要求する既存仕様は、パンダのお手伝いによる「ぷくコイン救済」および「たね救済」だけである。ジュレ団リベンジ広告と広告削除購入は、現行ソースに仕様・商品・画面が存在しないため独断で追加していない。したがって「広告削除購入」は未実装であり、審査資料で実装済みと説明してはいけない。

残る広告ブロッカー:

- AdMob > Privacy & messagingでEuropean regulations message、対象地域、広告パートナー、プライバシーポリシーURLを確認して公開する（今回は未実施）
- EEA/UK/Switzerland向けの同意撤回入口を実際に動かすには、3つの公式UMP APIを公開するプラグイン更新または検証済みネイティブ拡張が必要
- SDKのPrivacy Reportと実際のAdMob設定を確認し、Trackingを行うならATTを広告読み込み前に実装する。Trackingを行わない方針なら、IDFAが送信されないことを実機／Xcode Privacy Reportで確認する
- GMA 13.3.0以降と対応プラグインへの更新計画を立てる。現行12.14.0にはTFATがなく、旧TFCD／TFUAにはTEEN相当値もない。SDKだけを独断で更新せず、プラグイン互換性と実機回帰を確認する
- 年齢情報を取得しない一般向けアプリでの `UNSPECIFIED` 運用が、配信地域・想定利用者・Googleポリシー・適用法令に照らして十分かを確認する。既知の子ども／ティーンへ動的に切り替えるには、適法で検証可能な年齢シグナルの設計が別途必要
- テスト広告で、完了、途中終了、読み込み失敗、オフライン、連打、復帰を実機確認する
- 本番広告は自分で繰り返し視聴せず、リリース前確認はGoogleテスト広告を使う

参考:

- Google: <https://developers.google.com/admob/ios/privacy>
- Googleの年齢別広告設定と旧設定の対応表: <https://developers.google.com/admob/ios/targeting>
- Google Mobile Ads iOS release notes: <https://developers.google.com/admob/ios/rel-notes>
- Googleの広告配信モード: <https://developers.google.com/admob/ios/privacy/ad-serving-modes>
- GoogleのIDFA／ATT案内: <https://developers.google.com/admob/ios/privacy/idfa>
- GoogleのApp Storeデータ開示: <https://developers.google.com/admob/ios/privacy/data-disclosure>
- GoogleのATS設定: <https://developers.google.com/admob/ios/privacy/app-transport-security>
- AppleのATT／データ利用: <https://developer.apple.com/app-store/user-privacy-and-data-use/>

AdMob管理画面で必要な操作（今回は実行しない）:

1. **Apps → ぷくぷく！たにくらいふ → Blocking controls → Manage ad content rating** を開き、`Match account-level setting` を外してアプリ単位の上限が `G` であることを確認して保存する。
2. **Privacy & messaging → European regulations → Manage** からメッセージを作成または開き、対象をEEA・英国・スイス（または法務判断に基づく範囲）に設定する。広告パートナーと「自社利用目的」を実際の利用に合わせる。
3. 同画面の **Create message → Select apps** またはMessages表のAppリンクから対象アプリを開き、**Privacy policy URL** に正式公開後のHTTPS URLを登録してSave／Confirmする。
4. アプリ内の撤回入口を実機で確認できるまではメッセージを公開しない。確認後、Messages表のPublish切替を使って公開し、反映に最大10分程度を見込む。
5. メディエーションまたは追加広告ソースを使う場合は各SDK、広告パートナー、年齢シグナル転送、App Privacy申告を再監査する。現行ソースからは追加アダプタの利用を確認していない。

### 非消耗型IAP 36商品

StoreKit 2サービスは、商品情報とローカライズ価格の取得、購入成功、キャンセル、失敗、復元、再起動時キャッシュ、再インストール時のStoreKit entitlement再同期、返金／権利喪失時のローカル解除を扱う。購入済み商品の再購入は開始しない。StoreKitが返す価格を表示し、価格をソースへ固定していない。

全36商品は非消耗型である。デザイン解除後に鉢本体を購入するときのゲーム内価格は、仕様どおりすべて **1ぷくコイン** に統一した。これはApp Store上の現金価格とは別である。

| Product ID | 鉢 |
| --- | --- |
| `pot_unlock_001` | クリスタルゴブレット鉢 |
| `pot_unlock_002` | グリーングラス鉢 |
| `pot_unlock_003` | シルバーメタル鉢 |
| `pot_unlock_004` | ホワイトボウル鉢 |
| `pot_unlock_005` | テラコッタロング鉢 |
| `pot_unlock_006` | パールピンク鉢 |
| `pot_unlock_007` | ウッドバレル鉢 |
| `pot_unlock_008` | ブルーダイヤ鉢 |
| `pot_unlock_009` | ロックボウル鉢 |
| `pot_unlock_010` | ローズゴールドグラス鉢 |
| `pot_unlock_011` | ゴールドジャックポット鉢 |
| `pot_unlock_012` | フラミンゴリゾート鉢 |
| `pot_unlock_013` | クラウンウォッチ鉢 |
| `pot_unlock_014` | マゼンタスーパーカー鉢 |
| `pot_unlock_015` | シェルコーラル鉢 |
| `pot_unlock_016` | 古木の切り株鉢 |
| `pot_unlock_017` | コンクリートラウンド鉢 |
| `pot_unlock_018` | ロックストーン鉢 |
| `pot_unlock_019` | スターダストムーン鉢 |
| `pot_unlock_020` | アンバークリスタル鉢 |
| `pot_unlock_021` | アンティークフルール鉢 |
| `pot_unlock_022` | ラスティバケツ鉢 |
| `pot_unlock_023` | オーロラパール鉢 |
| `pot_unlock_024` | ネオンクリスタル鉢 |
| `pot_unlock_025` | キングマネー鉢 |
| `pot_unlock_026` | レトロアーケード鉢 |
| `pot_unlock_027` | ロイヤルジュエル鉢 |
| `pot_unlock_028` | ジェリーフィッシュアクア鉢 |
| `pot_unlock_029` | レッドジャックポット鉢 |
| `pot_unlock_030` | おやすみムーン鉢 |
| `pot_unlock_031` | ディスコボール鉢 |
| `pot_unlock_032` | UFO鉢 |
| `pot_unlock_033` | 森の切り株鉢 |
| `pot_unlock_034` | 花畑鉢 |
| `pot_unlock_035` | 苔むす森鉢 |
| `pot_unlock_036` | ラーメン鉢 |

App Store Connectで各商品に必要な操作:

1. Apps > 対象アプリ > Monetization > In-App Purchases > `+`
2. TypeをNon-Consumableにし、上記Product IDを完全一致で登録
3. Reference Name、各言語のDisplay Name／Descriptionを登録
4. Price Schedule、販売地域、Tax Categoryを運営判断で設定
5. Review Notesと、ゲーム内購入画面が分かるReview Screenshotを追加
6. 36件すべてを初回アプリバージョンと同じ審査Submissionへ追加
7. Sandbox Testerを用意し、購入、キャンセル、失敗、復元、再起動、再インストール、返金／権利変更を実機検証

現金価格、販売地域、商品説明は提供されていないため設定していない。App Store Connect未接続のローカルモックテストだけを根拠に「購入検証済み」とはしない。別Bundle IDの開発版には本番アプリのIAP商品を共有できないため、IAP実機確認は本番Bundle IDのSandbox／TestFlightビルドで行う。

参考:

- AppleのIAP作成手順: <https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases>
- 初回IAPの審査提出: <https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase>

### Privacy Manifest / Required Reason API

GodotのiOS export設定で、次の承認理由をアプリ本体の `PrivacyInfo.xcprivacy` へ生成する。

| Category | Reason | 用途 |
| --- | --- | --- |
| File Timestamp | `C617.1` | アプリコンテナ内ファイルの管理 |
| System Boot Time | `35F9.1` | 経過時間の算出 |
| Disk Space | `E174.1` | アプリ動作用の空き容量確認 |
| User Defaults | `CA92.1` | 同一アプリからの設定読み書き |

Google Mobile Ads SDK 12.14.0自身のPrivacy Manifestも最終IPAへ含める。CIは、アプリ本体の4理由、Google SDK manifestの存在、Privacy plistの妥当性を、署名済みIPAを展開して検査する。

ただし、まだCodemagicで最終IPAを生成していないため「アーカイブ内で確認済み」ではない。Google SDKのmanifestと公式説明から、少なくともIPアドレス由来のおおまかな位置、クラッシュ、性能、Device ID、広告データ、製品操作が収集候補になる。App Store Connect > App Privacyでは、SDKを含む実際のビルドのXcode Privacy ReportとAdMob設定を照合し、第三者広告・Analytics・Trackingの用途、ユーザーへのリンク有無を過不足なく申告する。

プライバシーポリシーには最低限、運営者／連絡先、収集項目、利用目的、Google/AdMobへの提供、広告と同意、追跡の有無、IAPはAppleが処理すること、端末内セーブ、保持期間、削除・問い合わせ方法、対象地域、子どもに関する方針、改定日を記載する。内容を確定してHTTPSで公開し、App Store Connectとアプリ内の両方からリンクする。運営者名・連絡先・公開ドメインが未提供のため、架空情報を入れたポリシーは作成していない。

参考:

- Apple Privacy Manifest: <https://developer.apple.com/documentation/bundleresources/privacy-manifest-files>
- Apple Required Reason API: <https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api>
- Apple App Privacy: <https://developer.apple.com/app-store/app-privacy-details/>

### Codemagic

| Workflow | 目的 | 署名 | 公開動作 |
| --- | --- | --- | --- |
| `ios-development` | 同一iPhoneへ併存できる開発版 | Development / `.dev` Bundle ID | アーティファクトのみ |
| `ios-testflight` | 本番ゲートの内部実機確認 | App Store Distribution / 本番Bundle ID / internal-only | App Store Connectへアップロード、外部Beta審査は行わない |
| `ios-app-store-release` | 本審査提出 | App Store Distribution / 本番Bundle ID | App Store Reviewへ自動提出、承認後は手動リリース |

全ワークフローはCodemagicで利用可能な安定版Xcode 26.5を指定し、実行時にもXcode major 26以上／iPhoneOS SDK 26以上を検査する。App Store本番ワークフローでは `testFlightInternalTestingOnly` を使わない。内部TestFlight用ワークフローだけが同オプションを保持する。

CIは次を行う。

- ビルドプロファイル、Bundle ID、Team ID、秘密情報非コミットを検査
- AdMob本番ID／テストIDを秘密環境変数から生成
- Godot 4.7.2と対応iOS templateをchecksum検証して導入
- Godot 4.7.2対応StoreKit 2プラグインを再現ビルド
- 回帰smoke testsを実行
- Codemagic build numberを `CFBundleVersion` に適用
- Xcode project export後、Bundle ID、version、deployment target、native plugins、ATS、Privacy Manifestを検査
- 署名済みIPAを生成し、`codesign --verify --deep --strict` と展開後監査を実行

現時点ではCodemagicを実行していない。したがって、IPA生成、Apple Distribution署名、App Store Connectアップロードはいずれも**未確認**である。

Codemagic側で必要な事前設定:

1. Team integrations > Developer Portalに、App Manager権限のApp Store Connect API keyを `Codemagic` 名で接続
2. Production bundle `com.ohanayanouen.pukupukutaniku` のDistribution certificate/profileを用意
3. 開発版を使う場合は `com.ohanayanouen.pukupukutaniku.dev` をIdentifiersへ登録し、Development certificate/profileを用意
4. `ADMOB_IOS_APP_ID` と `ADMOB_IOS_REWARDED_AD_UNIT_ID` をSecret登録
5. 最初に `ios-development`、次に `ios-testflight` を手動実行
6. App Store Connectの全項目と実機試験が完了した最後にだけ `ios-app-store-release` を実行

Appleは2026-04-28以降、Xcode 26以降とiOS 26 SDK以降を要求している。参考: <https://developer.apple.com/news/upcoming-requirements/?id=02032026a>

## App Store Connectで必要な操作

### 優先度P0: ビルド前

1. Business > AgreementsでPaid Apps AgreementをActiveにする。Account Holderによる同意が必要
2. Business > Tax FormsとBank Accountsを完了する
3. AdMobアプリ、Rewarded unit、Privacy & messagingを設定し、Secret IDをCodemagicへ登録
4. Apps > 対象アプリ > Monetization > In-App Purchasesで36商品を登録
5. App PrivacyでPrivacy Policy URLを登録し、Google SDKを含むデータ収集を申告
6. 公開Support URLを用意する

### 優先度P1: 提出レコード

Apps > 対象アプリで次を設定する。提供されていない文言やURLは推測で埋めない。

| 項目 | 現状 |
| --- | --- |
| Name | `ぷくぷく！たにくらいふ`。最終的なストア名の空き状況は未確認 |
| Subtitle | 未提供 |
| Description / Promotional Text | 未提供 |
| Keywords | 未提供 |
| Primary / Secondary Category | 未指定 |
| Privacy Policy URL | 未提供・必須 |
| Support URL | 未提供・必須 |
| Marketing URL | 未提供・任意 |
| App icon | `assets/ios/app-icon-1024.png`、1024×1024・不透明をCI検査 |
| Copyright | 未提供 |
| Age Rating | 未回答。ガチャ／スロット等のchance-based activityを実装どおり申告する |
| Screenshots | 未作成。iPhone Dynamic Island mediumを最低1枚、最大10枚。日本語／英語の必要範囲を用意 |
| Export Compliance | `ITSAppUsesNonExemptEncryption` はexportで設定されるが、最終回答は運営者が実際の暗号利用を確認して行う |
| Availability / Price | 未指定 |
| Review Contact | 未提供 |

年齢レーティングは General > App Information > Set Up Age Ratings から2026年版質問に回答する。ゲーム内ガチャが現金購入可能なランダム商品ではないか、スロット表現がsimulated gamblingに該当するかを実際の仕様に基づいて回答し、安易に「None」にしない。

スクリーンショットはiPhone縦画面の実機またはSimulatorで、タイトル、通常12粒ゲーム、NEWカード、図鑑、ハイブリッドラボ、寄せ植え、ストーリーを候補にする。開発UI、テスト広告、個人情報、架空の購入価格を写さない。

### 優先度P2: 審査情報

Apps > 対象バージョン > App Review Informationに、連絡先、審査メモ、必要なら動画を登録する。ログインは現行実装に存在しないためDemo Accountは不要だが、次を審査メモに正確に案内する。

- 縦画面のストーリーゲームであること
- パンダのお手伝い広告は任意視聴で、完了時のみゲーム内救済を1回付与すること
- 有料鉢は非消耗型で、購入後に1ぷくコインでゲーム内購入できること
- Restore Purchasesの場所と操作
- IAP画面に通常進行で到達する手順
- 通知を利用する場合の用途
- 広告／同意画面の確認手順

最初の非消耗型IAPはアプリバージョンと同じSubmissionへ追加する。36件すべてのReview Screenshotと説明を確認してからSubmit for Reviewする。

## 回帰テスト方針

自動テストはストーリー進行、初回チュートリアル、原生地、ジュレ団、通常ゲーム、NEWカード、図鑑、ガチャ、ハイブリッドラボ、寄せ植え、共有、ローカライズ、セーブ、IAPモック、ビルドゲート、広告報酬を対象にする。ただし自動smoke testは実機審査の代替ではない。

提出前に次の実機マトリクスを完了する。

- 新規インストールでオープニングからエンディング／クリア後まで通常進行
- 開発版のストーリージャンプで各幕と分岐を再確認
- 既存リリース相当セーブを入れた上書き更新。図鑑、取得履歴、ストーリー、鉢、寄せ植えが保持されること
- Sandbox IAPの成功、キャンセル、失敗、復元、再インストール、返金
- Googleテスト広告の完了、途中終了、オフライン、再読み込み、連打
- iPhone SE系、Dynamic Island medium、大画面で日本語／ひらがな／英語を目視
- BGM、効果音、NEWカード、共有画像、ローカル通知

## 今後の更新時の手順

1. 通常開発はGodot DebugまたはWeb presetで行う。ストーリージャンプ等は保持される
2. iPhone開発版が必要なら `ios-development` を実行する。本番アプリと別セーブで併存する
3. リリース候補は `ios-testflight` を実行する。これは本番ゲート、本番Bundle ID、本番広告IDを使うが内部テスト専用である
4. 実機、Sandbox IAP、広告、プライバシー、セーブ移行、メタデータを確認する
5. バージョンは `APP_VERSION` とGodot export presetを一致させ、Codemagic build numberは自動採番する
6. 最終承認後にのみ `ios-app-store-release` を実行する
7. App Store Connectでprocessing、IAP添付、審査Submission、承認後の手動リリースを確認する

本番版の開発機能を一時的に有効化したり、本番Bundle IDを開発用途へ変更したりしない。
