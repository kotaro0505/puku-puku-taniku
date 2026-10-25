# 『ぷくぷく！たにくらいふ』プライバシーポリシー草案

> **未公開・未確定の作業用草案（2026年10月25日）**<br>
> この文書は、現行ソースコードと同梱SDKを調査して作成した公開前の草案です。現時点では正式なプライバシーポリシーではありません。角括弧内の情報、子ども向け方針、広告のトラッキング／ATT方針、UMPのプライバシー設定再表示導線、および最終IPAのPrivacy Reportを確定・検証するまで、App Store Connectへ登録したり正式ページとして案内したりしないでください。

## 公開前に必ず確定する項目

- 運営者の正式名称または氏名
- 問い合わせ用メールアドレス
- 運営者の国・地域、および法令上必要な場合の住所・責任者情報
- 公開日・施行日
- 正式なプライバシーポリシーURLとサポートURL
- 本アプリを子ども向けとして提供するか、一般向けとして提供するか
- AdMob管理画面の「プライバシーとメッセージ」、広告配信地域、メディエーション、広告技術プロバイダの最終設定
- Google Mobile Ads SDKのDevice IDに関する「Tracking」宣言と、ATTを使用しない現行実装との整合性
- UMPで同意内容を後から変更できるアプリ内導線
- App Store提出用の署名済み最終IPAから生成したPrivacy Report

---

# 日本語版（公開用本文の草案）

## 1. 基本情報

本プライバシーポリシーは、[運営者の正式名称または氏名]（以下「運営者」といいます）が提供するゲームアプリ『ぷくぷく！たにくらいふ』（以下「本アプリ」といいます）における情報の取扱いについて説明するものです。

- アプリ名：ぷくぷく！たにくらいふ
- 運営者：[運営者の正式名称または氏名を入力]
- 連絡先：[問い合わせ用メールアドレスを入力]
- 運営者の国・地域：[国・地域を入力]
- 施行日：[施行日を入力]

## 2. 取り扱う可能性がある情報

### 2.1 広告配信に伴う情報

本アプリのiOS版は、リワード広告の配信にGoogle Mobile Ads SDK（Google AdMob）およびUser Messaging Platform SDK（UMP）を利用します。Googleの公式資料および同梱されているGoogle Mobile Ads SDK 12.14.0のPrivacy Manifestによれば、広告の配信、効果測定、不正利用防止、分析、SDKの品質改善などのため、次の情報がGoogleによって収集または処理される可能性があります。

- IPアドレス、およびIPアドレス等から推定されるおおよその位置情報
- 広告識別子その他の端末識別子（利用可能な識別子は端末設定、同意状態、SDK設定等によって異なります）
- 表示された広告、広告の視聴、タップなどの広告データ
- アプリの起動、タップ、動画視聴などの製品操作情報
- クラッシュ情報
- 起動時間、ハング率、エネルギー使用量などのパフォーマンス情報
- その他の診断情報
- 同意の要否、同意状態、および同意フォームで選択されたプライバシー設定に関連する情報

本アプリの現行コードでは、広告のパーソナライズを無効にし、パブリッシャーのファーストパーティIDを無効にしています。また、広告コンテンツの上限レーティングを `G` に設定しています。ただし、非パーソナライズ広告であっても、Googleの説明上、フリークエンシーキャップ、集計レポート、不正利用防止などのためにCookie、モバイル広告識別子または他の技術情報が利用される場合があります。

現行コードではAppleのApp Tracking Transparency（ATT）許可ダイアログを表示する処理を無効にしています。一方、同梱SDKのPrivacy ManifestはDevice IDを「ユーザーに関連付けられる」「トラッキングに使用される」データとして宣言しています。この不一致は公開前の確認事項です。最終的な広告設定および実際のデータフローを確認し、トラッキングに該当する処理を行う場合は、Appleの要件に従って事前にATTの許可を取得し、本ポリシーおよびApp Storeの申告を更新します。

### 2.2 アプリ内課金に伴う情報

本アプリは、36種類の鉢の利用権を提供する非消耗型アプリ内課金にAppleのStoreKit 2を利用します。購入、決済、返金、購入履歴およびApple Accountに関する情報はAppleによって処理されます。運営者の現行実装は、クレジットカード番号、銀行口座番号その他の完全な支払手段情報を直接取得しません。

本アプリは、商品の識別子、ローカライズされた価格情報、購入・復元・保留・キャンセル・失敗・返金・期限切れ等の取引状態、および商品の利用権が有効かどうかをStoreKit 2から受け取ります。商品の利用権は、アプリの機能を提供するため、端末内のセーブデータにも真偽値として保存されます。再インストールや別端末での復元時には、AppleのStoreKitを通じて購入済み商品の確認を行います。

### 2.3 端末内に保存するゲームデータ

本アプリは、ゲームの継続と設定の維持のため、主に次の情報を端末内のアプリ専用領域へJSON形式で保存します。

- ストーリー、チュートリアル、イベントの進行状況
- 発見・取得した品種、取得回数、最高記録、図鑑やシリーズの解放状況
- ゲーム内通貨、種、アイテム、鉢などの所持状況
- 原生地、ガチャ、ハイブリッドラボ、ジュレ団等のゲーム進行状況
- 保存した寄せ植えの内容
- アプリ内課金商品の利用権の端末内キャッシュ
- 言語、BGM・効果音、表示設定
- ゲーム進行に必要な日時、回数、識別子など

今回確認した現行実装には、独自のユーザーアカウント、運営者独自のゲームサーバー、クラウドセーブ、またはゲーム進行データを運営者へ送信する処理は見つかっていません。端末内だけで処理され、外部へ送信されない情報は、AppleのApp Privacy上の「収集」には通常該当しません。ただし、将来クラウド同期、分析、問い合わせ送信などを追加する場合は、本ポリシーを更新します。

### 2.4 通知

現行の通常プレイでは、新しいローカル通知を予約する処理や通知許可を要求する処理は使用しておらず、リモートプッシュ通知の権限も無効です。過去のバージョンが端末に残したローカル通知を取り消すための互換処理と、ローカル通知用のネイティブプラグインは残されています。通知機能を再び有効にする場合は、通知の目的、保存する情報および許可の取得方法を本ポリシーへ反映します。

### 2.5 共有機能

本アプリは、最高記録や寄せ植えの画像を端末内で生成し、利用者の操作によってiOSの共有シートまたはWeb Share APIを開きます。運営者が共有先を自動選択したり、生成画像を運営者のサーバーへ自動送信したりする処理はありません。利用者が共有先として選択した第三者のアプリまたはサービスには、その第三者のプライバシーポリシーが適用されます。

生成された共有画像はアプリ専用領域に保存されます。現行実装には生成画像を個別に削除する画面や自動削除処理がないため、通常はアプリの削除またはOSによるアプリデータの消去まで残る可能性があります。Web版では、共有できない環境において利用者の操作により画像をダウンロードします。

### 2.6 Web版の配信に伴う情報

Web版はGitHub Pagesから配信され、一部の図鑑画像を同じGitHub Pagesサイトから追加で読み込みます。Web版へのアクセス時には、配信に必要なIPアドレス、ブラウザ・端末情報、アクセス日時、要求したURL等がホスティング事業者によって処理される場合があります。GitHubによる取扱いはGitHubのプライバシーに関する文書をご確認ください。

## 3. 利用目的

前項の情報は、該当する範囲で次の目的に利用されます。

- ゲームの進行、設定、購入済みコンテンツその他の本アプリ機能を提供するため
- リワード広告を読み込み、表示し、視聴完了を判定して報酬を付与するため
- 広告の配信、効果測定、フリークエンシーキャップ、集計レポートおよび不正利用防止のため
- 広告およびSDKの障害解析、パフォーマンス測定、品質改善のため
- 地域や法令に応じた同意画面を表示し、利用者のプライバシー選択を反映するため
- アプリ内課金の商品情報表示、購入、購入済み商品の復元、返金等による利用権変更の反映のため
- 利用者が選択した共有先へゲーム画像を渡すため
- Web版のコンテンツを配信するため

## 4. 第三者サービス

本アプリは、次のサービスまたはプラットフォーム機能を利用します。

### Google AdMob / Google Mobile Ads SDK / UMP

広告配信、同意管理、広告測定、不正利用防止、分析およびSDK品質改善のために利用します。Googleによる情報の取扱いについては、次の文書をご確認ください。

- [Googleサービスを使用するサイトやアプリから収集した情報のGoogleによる使用](https://policies.google.com/technologies/partner-sites)
- [Googleプライバシーポリシー](https://policies.google.com/privacy)
- [Google Mobile Ads SDKのApp Storeデータ開示](https://developers.google.com/admob/ios/privacy/data-disclosure)

### Apple App Store / StoreKit 2

アプリ内課金の商品情報、決済、購入の復元、返金その他の取引処理に利用します。Appleによる情報の取扱いについては、次の文書をご確認ください。

- [Appleプライバシーポリシー](https://www.apple.com/legal/privacy/)
- [App Storeとプライバシー](https://www.apple.com/legal/privacy/data/en/app-store/)

### GitHub Pages（Web版のみ）

Web版およびその静的素材の配信に利用します。

- [GitHub General Privacy Statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement)

## 5. 広告と同意の管理

本アプリは、Google UMPを通じて同意情報を更新し、対象地域等により同意が必要な場合にGoogleが提供する同意フォームを表示する構成です。同意が取得できない場合、現行実装はリワード広告を利用不可として扱います。

[公開前に実装・確認：Googleがプライバシー設定の再表示を要求する場合に、設定画面からUMPのプライバシーオプションフォームを開ける導線を追加し、その操作方法をここへ記載する。]

端末の広告およびトラッキングに関する設定は、iOSの設定画面から変更できます。広告のパーソナライズを無効にしても、広告配信、集計測定、不正利用防止等に必要な処理がすべて停止するとは限りません。

## 6. 情報の保持と削除

- 端末内のセーブデータ、購入利用権の端末内キャッシュ、および生成した共有画像は、原則としてアプリ専用領域に保持されます。現行実装には本番ユーザー向けの全データ削除ボタンはありません。通常、アプリを削除すると当該端末上のアプリデータも削除されますが、OSのバックアップ、オフロード、復元等の挙動はAppleまたは利用者の端末設定に従います。
- 非消耗型アプリ内課金の購入記録は、購入の復元、返金および権利管理のためAppleが保持します。Appleが保有する情報の削除・訂正等はAppleの手続に従います。
- Googleが広告・同意管理に関連して処理する情報の保持期間と削除方法は、Googleのポリシーおよび利用者のGoogle／端末のプライバシー設定に従います。
- 運営者への問い合わせに伴って利用者が任意に提供した情報については、[問い合わせ対応データの保持期間または判断基準を入力]。法令上の保存義務がある場合は、その期間保持することがあります。

端末内データの削除方法、または本ポリシーに関する質問は、第9項の連絡先へお問い合わせください。ただし、運営者が保有していない端末内データや、AppleまたはGoogleが独自に管理するデータについては、運営者が直接削除できない場合があります。

## 7. 国外での処理

Google、Apple、GitHubその他のサービス提供者が、利用者の居住国・地域以外にあるサーバーまたは事業体を通じて情報を処理する場合があります。具体的な処理地域、保護措置および法的根拠は、各サービス提供者のプライバシーポリシーをご確認ください。

## 8. 子どものプライバシー

**[公開を止める未確定項目]** 本アプリを子ども向けとして提供するか、一般向けとして提供するかは、運営者が対象年齢、App Storeの年齢レーティング、配信地域の法令およびAdMobのポリシーを踏まえて確定する必要があります。広告コンテンツの上限を `G` にしていることだけでは、子ども向けアプリとしての設定や法令対応を満たしたことにはなりません。現行コードでは、AdMobの「子ども向け取扱い」および「同意年齢未満」のタグは未指定です。

[一般向けとして確定する場合の本文案：本アプリは、適用法令で定められた年齢未満の子どもを対象として意図的に提供するものではありません。運営者が、保護者の同意なく子どもの情報を取り扱ったことを把握した場合は、確認のうえ適切に対応します。保護者の方は第9項の連絡先へお問い合わせください。]

[子ども向けとして確定する場合：この文章をそのまま使用せず、対象年齢、保護者同意、AdMobの子ども向け設定、年齢確認、広告制限、適用される児童プライバシー法令を実装・確認したうえで専用の本文に差し替える。]

## 9. お問い合わせ

本ポリシーまたは本アプリにおける情報の取扱いに関するお問い合わせ先は次のとおりです。

- 運営者：[運営者の正式名称または氏名を入力]
- メールアドレス：[問い合わせ用メールアドレスを入力]
- その他法令上必要な連絡先：[必要な場合に入力]

## 10. 本ポリシーの改定

運営者は、機能、利用するSDK、法令またはサービス内容の変更等に応じて本ポリシーを改定することがあります。重要な変更がある場合は、本アプリ内、公式サイトその他適切な方法でお知らせします。改定後のポリシーは、掲載した施行日から適用されます。

- 制定日：[制定日を入力]
- 最終改定日：[最終改定日を入力]

---

# English Version (Draft for Publication)

## 1. Basic Information

This Privacy Policy explains how [enter the operator's legal name] (the “Operator”) handles information in the game application “Puku Puku! Taniku Life” (the “App”).

- App name: Puku Puku! Taniku Life (ぷくぷく！たにくらいふ)
- Operator: [enter the operator's legal name]
- Contact: [enter a contact email address]
- Operator country or region: [enter country or region]
- Effective date: [enter effective date]

## 2. Information That May Be Processed

### 2.1 Information processed for advertising

The iOS version of the App uses the Google Mobile Ads SDK (Google AdMob) and the User Messaging Platform SDK (UMP) to provide rewarded advertisements. According to Google's documentation and the privacy manifest included with Google Mobile Ads SDK 12.14.0, Google may collect or process the following information for ad delivery, measurement, fraud prevention, analytics, and SDK quality improvement:

- IP address and coarse location inferred from an IP address or similar data;
- an advertising identifier or another device identifier, depending on device settings, consent status, and SDK configuration;
- advertising data, including ads shown, ad views, and ad interactions;
- product interaction data, such as app launches, taps, and video views;
- crash data;
- performance data, such as launch time, hang rate, and energy use;
- other diagnostic data; and
- information related to whether consent is required, consent status, and privacy choices made through a consent form.

The current App code disables ad personalization and the publisher first-party ID, and limits the maximum ad content rating to `G`. However, Google's documentation explains that even non-personalized ads may use cookies, mobile ad identifiers, or other technical information for purposes such as frequency capping, aggregated reporting, and fraud prevention.

The current App code does not present Apple's App Tracking Transparency (ATT) authorization prompt. However, the privacy manifest bundled with the SDK declares Device ID as data that is linked to the user and used for tracking. This conflict must be resolved before publication. The Operator will verify the final ad configuration and actual data flows. If any processing constitutes tracking under Apple's rules, the App will obtain ATT authorization before that processing and this Policy and the App Store disclosures will be updated.

### 2.2 Information processed for in-app purchases

The App uses Apple's StoreKit 2 for non-consumable in-app purchases that unlock 36 pot designs. Apple processes payment, transaction, refund, purchase history, and Apple Account information. Under the current implementation, the Operator does not directly receive full payment method information such as a credit card number or bank account number.

The App receives the product identifier, localized price information, transaction states such as purchased, restored, pending, canceled, failed, refunded, or expired, and whether an entitlement is active. To provide purchased functionality, the App also stores a Boolean cache of the entitlement in its on-device save data. When restoring purchases after reinstallation or on another device, the App checks purchased products through Apple's StoreKit service.

### 2.3 On-device game data

To preserve game progress and settings, the App stores the following types of data as JSON in the App's private on-device storage:

- story, tutorial, and event progress;
- discovered and obtained species, obtain counts, records, catalog progress, and unlocked series;
- in-game currency, seeds, items, and owned pots;
- progress related to habitats, gacha, the Hybrid Lab, and the Jure Jure group;
- saved arrangements;
- an on-device cache of in-app purchase entitlements;
- language, music, sound effect, and display settings; and
- dates, counters, and game-generated identifiers needed for gameplay.

The current implementation reviewed for this draft does not include a proprietary user account, an Operator-controlled game server, cloud save, or code that sends game progress to the Operator. Under Apple's App Privacy definition, information processed only on the device and not transmitted off the device is generally not “collected.” If cloud synchronization, analytics, support submission, or a similar feature is added later, this Policy will be updated.

### 2.4 Notifications

Normal gameplay in the current implementation does not schedule new local notifications or request notification permission, and the remote push notification entitlement is disabled. A native local-notification plug-in and compatibility code remain only to cancel local notifications that may have been scheduled by an older version. If notifications are enabled again, this Policy will be updated to describe their purpose, stored information, and permission flow.

### 2.5 Sharing

The App creates images of records or arrangements on the device and, only when the user requests it, opens the iOS share sheet or Web Share API. The Operator does not automatically select a recipient or upload the generated image to an Operator-controlled server. The privacy policy of the third-party app or service selected by the user applies after the user chooses that destination.

Generated images are stored in the App's private storage. The current implementation does not include an individual delete control or automatic cleanup for these generated files, so they may remain until the App or its data is removed by the user or operating system. On the web version, the image is downloaded at the user's request when a share API is unavailable.

### 2.6 Web version delivery

The web version is delivered through GitHub Pages and loads some catalog images from the same GitHub Pages site. The hosting provider may process connection information necessary to deliver the site, such as IP address, browser or device information, request time, and requested URL. Please review GitHub's privacy documentation for details.

## 3. Purposes of Processing

The information described above is used, as applicable, to:

- provide game progress, settings, purchased content, and other App functionality;
- load and show rewarded ads, verify completion, and grant rewards;
- deliver and measure ads, perform frequency capping and aggregated reporting, and prevent fraud and abuse;
- diagnose failures, measure performance, and improve advertising and SDK quality;
- display consent messages required for a user's region and apply the user's privacy choices;
- show in-app purchase products and prices, process purchases, restore purchases, and reflect refunds or entitlement changes;
- send a game image to a destination selected by the user; and
- deliver web-version content.

## 4. Third-Party Services

### Google AdMob / Google Mobile Ads SDK / UMP

These services are used for ad delivery, consent management, ad measurement, fraud prevention, analytics, and SDK quality improvement. See:

- [How Google uses information from sites or apps that use its services](https://policies.google.com/technologies/partner-sites)
- [Google Privacy Policy](https://policies.google.com/privacy)
- [Google Mobile Ads SDK App Store data disclosure](https://developers.google.com/admob/ios/privacy/data-disclosure)

### Apple App Store / StoreKit 2

These services are used for product information, payment, purchase restoration, refunds, and other transaction processing. See:

- [Apple Privacy Policy](https://www.apple.com/legal/privacy/)
- [App Store & Privacy](https://www.apple.com/legal/privacy/data/en/app-store/)

### GitHub Pages (web version only)

GitHub Pages is used to deliver the web version and its static assets. See:

- [GitHub General Privacy Statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement)

## 5. Advertising and Consent Choices

The App updates consent information through Google UMP and is configured to display a Google-provided consent form when consent is required for a user based on region or other applicable factors. Under the current implementation, rewarded ads remain unavailable when the required consent cannot be obtained.

[Before publication: add an in-app settings entry that presents the UMP privacy options form whenever Google reports that a privacy-options entry point is required, and describe the steps here.]

Advertising and tracking controls may also be available in iOS Settings. Disabling personalized advertising does not necessarily stop all processing needed for ad delivery, aggregate measurement, or fraud prevention.

## 6. Retention and Deletion

- On-device save data, the on-device entitlement cache, and generated share images are generally retained in the App's private storage. The current production implementation has no “delete all data” button. Deleting the App will normally remove its local app data, while device backup, offloading, and restoration behavior is controlled by Apple and the user's device settings.
- Apple retains non-consumable purchase records as needed for purchase restoration, refunds, and entitlement management. Requests concerning data held by Apple are governed by Apple's procedures.
- Retention and deletion of information processed by Google for advertising and consent management are governed by Google's policies and the user's Google and device privacy settings.
- Information voluntarily provided to the Operator in a support inquiry will be retained for [enter the support-data retention period or decision criteria], subject to any legal retention obligation.

Questions about local data deletion or this Policy may be sent to the contact in Section 9. The Operator may be unable to directly delete information that remains solely on a user's device or is independently controlled by Apple or Google.

## 7. International Processing

Google, Apple, GitHub, or another service provider may process information through servers or entities located outside the user's country or region. Please review each provider's privacy policy for information about processing locations, safeguards, and legal bases.

## 8. Children's Privacy

**[Publication-blocking decision required]** The Operator must decide whether the App is directed to children or to a general audience after considering its intended audience, App Store age rating, applicable laws in each distribution region, and AdMob policies. Setting the maximum ad content rating to `G` does not by itself make the App compliant as a child-directed app. In the current code, the AdMob child-directed-treatment and under-age-of-consent tags are unspecified.

[Proposed text only if the App is confirmed to be general-audience: The App is not intentionally directed to children below the age defined by applicable law. If the Operator learns that information from a child was processed without required parental consent, the Operator will review the matter and take appropriate action. A parent or guardian may contact the Operator using the details in Section 9.]

[If the App will be child-directed: do not use the paragraph above without change. Replace this section only after implementing and verifying the intended age range, parental consent, AdMob child-directed settings, age handling, advertising restrictions, and all applicable child-privacy requirements.]

## 9. Contact

Questions about this Policy or the App's handling of information may be directed to:

- Operator: [enter the operator's legal name]
- Email: [enter a contact email address]
- Other legally required contact details: [enter if applicable]

## 10. Changes to This Policy

The Operator may revise this Policy when App features, SDKs, laws, or services change. Material changes will be announced in the App, on the official website, or by another appropriate method. A revised policy takes effect on its stated effective date.

- Initial publication date: [enter date]
- Last updated: [enter date]

---

# 実装調査と申告準備メモ（公開ページには含めない）

## 調査範囲

### アプリコード・設定

- `scripts/rewarded_ad_service.gd`
- `addons/AdmobPlugin/Admob.gd`
- `addons/AdmobPlugin/AdmobPlugin.gd`
- `addons/AdmobPlugin/model/AdmobConfig.gd`
- `addons/AdmobPlugin/model/ConsentRequestParameters.gd`
- `addons/AdmobPlugin/VENDORED_VERSION.md`
- `scripts/pot_unlock_iap_service.gd`
- `data/pot-iap-catalog.json`
- `scripts/ci/build_storekit2_plugin.sh`
- `ios/plugins/GodotStoreKit2-LICENSE.txt`
- `scripts/main.gd`（セーブ、共有、設定画面、通知の使用箇所）
- `scripts/endless_greenhouse_experiment.gd`
- `scripts/habitat_notification_service.gd`
- `scripts/catalog_image_loader.gd`
- `ios/plugins/AdmobPlugin.gdip`
- `ios/plugins/NotificationSchedulerPlugin.gdip`
- `ios/plugins/SharePlugin.gdip`
- `project.godot`
- `export_presets.cfg`
- `codemagic.yaml`

### SDK・プラグイン

- Godot Engine 4.7.2（Compatibility renderer）
- Godot AdMob Plugin v7.0
- Google Mobile Ads iOS SDK 12.14.0（Swift Package Manager）
- Google User Messaging Platform（AdMobプラグインのネイティブ実装から利用。最終的に解決されるUMPの版は最終Xcodeアーカイブで要確認）
- GodotStoreKit2 v0.2（Codemagicでビルド）
- NotificationSchedulerPlugin
- SharePlugin v6.0
- Apple StoreKit 2、UserNotifications、UIKit共有シート

### 公式仕様

- [Apple App privacy details](https://developer.apple.com/app-store/app-privacy-details/)
- [Apple App Store Connect: Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
- [Apple Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [Apple: Describing use of required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [Apple User privacy and data use](https://developer.apple.com/app-store/user-privacy-and-data-use/)
- [Google Mobile Ads SDK App Store data disclosure](https://developers.google.com/admob/ios/privacy/data-disclosure)
- [Google UMP setup](https://developers.google.com/admob/ios/privacy)
- [Google iOS privacy strategies](https://developers.google.com/admob/ios/privacy/strategies)
- [Google ad serving modes](https://developers.google.com/admob/ios/privacy/ad-serving-modes)
- [Google partner-sites privacy explanation](https://policies.google.com/technologies/partner-sites)

## コードから確認できた内容

| 項目 | 確認結果 | 根拠・注意 |
| --- | --- | --- |
| 独自アカウント | 見つからない | ログイン、氏名、メール、電話番号等を取得する本番コードは確認できない |
| 独自バックエンド／分析SDK | 見つからない | Firebase、Crashlytics、独自API、独自テレメトリ送信は確認できない。GMPSharedのHTTP処理はGodotエディタ用プラグイン管理機能 |
| AdMob | iOS本番版で有効 | 本番IDはCodemagic Secretからビルド時に生成。ソースには保存しない |
| 広告形式 | リワード広告 | SDKの報酬獲得コールバック時のみ一度報酬を付与する実装 |
| 広告設定 | 非パーソナライズ、first-party ID無効、最大コンテンツレーティングG | 非パーソナライズでも識別子等が全く処理されないとは限らない |
| UMP | 本番で同意情報更新・必要時フォーム表示 | 同意再選択用 `privacyOptionsRequirementStatus` / privacy options formの公開API・アプリ内入口は現行プラグインにない |
| ATT | 現行コードでは無効 | `att_enabled = false`、exportのtrackingもfalse。ただしGMA 12.14.0 manifestはDevice IDのtrackingをtrueと宣言 |
| 子ども向け広告タグ | 未指定 | `child_directed` と `under_age_of_consent` はプラグイン既定のUNSPECIFIED。最大レーティングGとは別問題 |
| StoreKit 2 | 36個の非消耗型商品 | 商品情報、価格、購入、復元、返金／期限切れ等を処理。支払カード情報はアプリへ渡らない |
| セーブ | 端末内JSON | 現在の既定は `user://records_endless_experiment.json`。旧 `records.json` からの移行を維持 |
| クラウドセーブ | 見つからない | 現行コードに外部送信なし |
| 通知 | 通常プレイでは新規予約しない | 旧版のローカル通知取消し互換処理のみ。push entitlementはDisabled |
| 共有 | 利用者操作でiOS共有シート／Web Share | 生成PNGは端末内。運営者サーバーへの自動アップロードなし。自動削除も未実装 |
| Web外部通信 | GitHub Pagesへの同一オリジン画像要求 | `CatalogImageLoader`がWeb版で図鑑画像を追加取得。ホスティングログはGitHubの取扱い |

## Privacy Manifest / Required Reason API

アプリ本体のiOS export設定とCodemagicの署名済みIPA検査は、次のRequired Reason APIを要求しています。

| APIカテゴリ | 理由コード | 現在の用途 |
| --- | --- | --- |
| File Timestamp | `C617.1` | アプリコンテナ内ファイルの管理 |
| System Boot Time | `35F9.1` | 経過時間の算出 |
| Disk Space | `E174.1` | アプリ動作用の空き容量確認 |
| User Defaults | `CA92.1` | 同一アプリの設定保存 |

Google Mobile Ads SDK 12.14.0の実物 `PrivacyInfo.xcprivacy` も確認済みです。SDK manifestが示す申告候補は次のとおりです。

## Apple App Privacy申告候補

以下はApp Store Connectへそのまま転記する最終回答ではありません。Google Mobile Ads SDK 12.14.0のmanifestと公式資料を基にした候補であり、署名済み最終IPAのPrivacy Report、AdMob管理画面、使用する広告ソース、実機通信を確認して確定します。

| Appleデータ種類 | 収集目的候補 | ユーザーとの関連付け | トラッキング | 現在の確度 |
| --- | --- | --- | --- | --- |
| Coarse Location（おおよその位置情報） | Third-Party Advertising、Developer's Advertising or Marketing、Analytics | あり | なし | GMA 12.14.0 manifestで確認 |
| Device ID | Third-Party Advertising、Developer's Advertising or Marketing、Analytics | あり | **あり** | GMA 12.14.0 manifestで確認。ATTとの整合確認が必須 |
| Product Interaction | Third-Party Advertising、Developer's Advertising or Marketing、Analytics | あり | なし | GMA 12.14.0 manifestで確認 |
| Advertising Data | Third-Party Advertising、Developer's Advertising or Marketing、Analytics | あり | なし | GMA 12.14.0 manifestで確認 |
| Crash Data | Analytics | なし | なし | GMA 12.14.0 manifestで確認 |
| Performance Data | Third-Party Advertising、Developer's Advertising or Marketing、Analytics | なし | なし | GMA 12.14.0 manifestで確認 |
| Other Diagnostic Data | Third-Party Advertising、Developer's Advertising or Marketing、Analytics | なし | なし | GMA 12.14.0 manifestで確認 |
| Purchase History | App Functionalityの可能性 | 未確定 | なしの見込み | Appleだけが処理するデータは開発者の申告対象外というApple説明がある。現行アプリは利用権を端末内キャッシュするだけだが、最終StoreKit構成で再確認 |
| Gameplay Content | App Functionalityの可能性 | なしの見込み | なし | セーブは端末内のみのためAppleの「収集」定義上は対象外の見込み。一方、Apple FAQにはgame savesの申告案内があるため、App Store Connect上の設問またはApple Supportで確認 |

### 現時点で収集を確認できなかった種類

氏名、メールアドレス、電話番号、住所、連絡先、正確な位置情報、健康・フィットネス情報、支払カード・銀行口座情報、信用情報、ユーザーの写真・動画、音声、閲覧履歴、検索履歴、独自ユーザーIDについて、アプリ本体が収集・送信する実装は確認できませんでした。共有画像はゲームが生成し、利用者が選んだ共有先へOS機能を通じて渡すもので、カメラや写真ライブラリへのアクセスは確認できませんでした。

## 未確認・公開前の阻害事項

1. **運営者情報が未提供**：正式名称、問い合わせ先、国・地域、必要に応じて住所・責任者を入力する。
2. **子ども向け方針が未決定**：対象年齢を決め、App Store年齢レーティング、AdMobのCOPPA／TFUA設定、配信地域の法令と一致させる。
3. **ATTとDevice ID trackingの不整合**：GMA manifestではtracking=true、アプリではATT=false。実際の本番データフローを確認し、必要ならATTを実装する。確認前に「トラッキングなし」と申告しない。
4. **UMPのプライバシー設定再表示が未実装**：Googleは必要時に表示可能な入口を要求する。現行プラグイン公開APIでは不足している。
5. **AdMob管理画面が未監査**：Privacy & messaging、地域別メッセージ、広告技術プロバイダ、メディエーション、制限付き広告、本番ユニット設定を実アカウントで確認する。
6. **UMPの正確なバージョンとmanifest**：ローカルのGMA 12.14.0配布物ではGMA manifestを確認したが、最終アーカイブ内のUMP frameworkとmanifestは未確認。
7. **最終IPA Privacy Reportが未生成**：Codemagicはアプリ本体とGMA manifestの存在を検査するが、全SDKを含むXcode Privacy Reportは最終署名済みIPA／archiveで確認する。
8. **実機通信が未検証**：同意状態・地域・広告在庫・端末設定別に送信されるフィールドと広告配信モードを実機で確認していない。
9. **保持期間が未確定**：問い合わせ情報の保持期間、法令上の保存方針を運営者が決める。
10. **公開URLとサポートURLが未確定**：HTTPSの正式URLを決め、App Store Connectとアプリ内から同じURLへ到達できるようにする。

## 公開に必要な運営者情報

- App Store ConnectのSeller／Developer情報と整合する正式な運営者名
- 問い合わせを継続して受信できるメールアドレス
- 運営者の国・地域
- 適用法令上必要な場合の住所、代表者または個人情報保護責任者
- 問い合わせ情報の保持期間・削除基準
- 対象年齢と子ども向け方針
- 制定日、施行日、最終改定日
- 正式なプライバシーポリシーURL
- サポートURL
- 必要に応じて、データ削除依頼またはプライバシー選択の専用URL

## GitHub Pagesで正式公開する手順（今回は未実施）

このリポジトリのGitHub Pagesは `main` ブランチのリポジトリルートを公開元とし、正式URLは `https://kotaro0505.github.io/puku-puku-taniku/` です。正式公開時は次の手順を推奨します。

1. この草案の角括弧、警告、調査メモをすべて解消する。
2. 法令・AdMob・Appleの最終設定と文面を運営者または専門家が確認する。
3. 日本語と英語を一つのアクセシブルな静的ページ `privacy/index.html` に整形する。
4. 正式URLを `https://kotaro0505.github.io/puku-puku-taniku/privacy/` とする。
5. 必要なら同ページ内に言語切替と「プライバシー設定」節へのアンカーを設ける。
6. サイトのナビゲーションからリンクし、404でないこと、モバイルで読めること、HTTPSで表示されることを確認する。
7. App Store Connectの **Apps → ぷくぷく！たにくらいふ → App Privacy → Privacy Policy → Edit** に正式URLを入力する。Privacy Choices URLを用意した場合は同画面へ入力する。
8. App Privacy回答を最終IPAおよびAdMob設定に合わせて入力し、正確性を確認してからPublishする。

この草案ファイル自体は正式ページにリンクしません。ただしリポジトリとGitHub Pagesの公開元が公開されているため、`main` へpushした時点でリポジトリソースとして、または直接の静的パスを知る人から閲覧できる可能性があります。正式ポリシーとして案内してはなりません。

## アプリ内リンクの実装方針（今回は未実施）

1. 正式なHTTPS URLをリリース用設定または定数として一か所に定義する。ドラフトURLや空のURLを本番ビルドで許可しないCI検査を追加する。
2. `scripts/main.gd` の `_build_settings()` に、既存レイアウトを崩さない「プライバシーポリシー」ボタンを追加する。
3. `scripts/game_localizer.gd` に日本語、ひらがな、英語の文言を追加する。
4. 押下時にGodotの `OS.shell_open()` で正式HTTPS URLを開く。URLスキームを `https` に限定し、失敗時はローカライズした案内を表示する。
5. Google UMPの `privacyOptionsRequirementStatus` がrequiredの場合だけ表示する「プライバシー設定」ボタンを別途用意する。これは単なるWebポリシーリンクとは別の機能であり、プラグイン側にprivacy options formを表示するネイティブAPIの追加または対応版への更新が必要。
6. 設定画面、3言語、iOS実機、Web、オフライン時、外部ブラウザ復帰、UMP required／not requiredの各状態を回帰テストする。
7. App Store審査前に、App Store ConnectのPrivacy Policy URL、公開ページ、アプリ内リンクが同じ正式文書を指すことを確認する。

## この草案で行っていないこと

- プライバシーポリシーの正式公開
- アプリ内UI・リンクの追加
- 広告SDK、UMP、ATT、StoreKit 2、通知、共有、セーブ処理の変更
- App Store ConnectまたはAdMob管理画面の変更
- App Store審査への提出
