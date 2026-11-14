# 『ぷくぷく！たにくらいふ』プライバシーポリシー公開原稿

> **正式公開済み**<br>
> 最終更新・施行日: 2026-11-14<br>
> 正式URL: `https://kotaro0505.github.io/puku-puku-taniku/privacy-policy/`<br>
> 公開本文は日本語・英語の各「プライバシーポリシー」節です。末尾の検証記録は公開HTMLに含めません。

---

# プライバシーポリシー

## 1. 基本情報

オハナ屋農園（以下「運営者」）は、ゲームアプリ『ぷくぷく！たにくらいふ』（以下「本アプリ」）における情報の取扱いについて、次のとおり定めます。

- アプリ名：ぷくぷく！たにくらいふ
- 運営者：オハナ屋農園
- 所在国・地域：日本
- 問い合わせ先：kotaro.hana.0505@gmail.com
- 施行日：2026年11月14日

## 2. 取り扱う情報

### 2.1 広告

iOS版は、任意視聴のリワード広告と、森のガチャおよびハイブリッドラボで自動表示されるインタースティシャル広告を提供するため、Google Mobile Ads SDK（Google AdMob）およびGoogle User Messaging Platform SDK（UMP）を使用します。広告の配信、同意管理、広告効果の測定（ad measurement）、広告分析、表示回数の制御、不正利用防止、障害解析およびSDKの品質改善のため、Googleは端末や同意状態等に応じて次の情報を処理する可能性があります。

インタースティシャル広告は、森のガチャの正常な抽選またはハイブリッドラボの正常な交配が、それぞれ5回に達するごとに、結果、GETカードおよび関連演出の終了後の安全な画面切り替え時に自動表示される場合があります。広告が準備できていない場合、その回は表示せず、後から突然表示しません。

- IPアドレス、およびIPアドレス等から推定されるおおまかな位置情報
- 広告識別子その他の端末識別子
- 広告の表示、視聴、操作等の広告データ
- アプリの起動、操作、動画視聴等の利用状況
- クラッシュ、性能その他の診断情報
- 同意の要否、同意状態、プライバシー選択に関する情報

本アプリの現行設定は、広告のパーソナライズとパブリッシャーのファーストパーティIDを無効にし、広告コンテンツの最大レーティングを `G` にしています。非パーソナライズ広告でも、広告配信、集計的な広告効果の測定、広告分析、表示回数の制御、不正利用防止等に必要な情報が処理されることがあります。Googleによる具体的な取扱いは、利用者の地域、端末設定、同意状態、Googleの設定および広告配信状況により異なります。

iOS版は、必要なGoogle UMPの処理が完了した後、ATTの状態が未決定の場合に限り、Google Mobile Ads SDKを初期化する前に、AppleのApp Tracking Transparency（ATT）を通じて追跡の許可を求めます。許可された場合、Google Mobile Ads SDKは広告識別子（IDFA）を広告の表示回数調整、広告効果の測定その他Googleが開示する広告目的に利用する可能性があります。拒否または制限された場合、iOSによりIDFAを利用できない状態で広告SDKを開始します。ATTの選択にかかわらずゲームは利用でき、リワード広告を最後まで視聴した場合のゲーム内報酬は変わりません。拒否しても、IPアドレス、広告データ、利用状況、診断情報等、IDFA以外の情報の処理がすべて停止するとは限りません。

### 2.2 アプリ内課金

iOS版は、36種類の鉢デザインと、日本のApp Storeで100円として設定している「広告を削除」を提供するため、計37商品の非消耗型アプリ内課金にApple StoreKit 2を使用します。鉢デザインは永続的に解放されます。「広告を削除」は、森のガチャとハイブリッドラボで自動表示されるインタースティシャル広告だけを永久に削除し、任意視聴のパンダのお手伝いリワード広告は残ります。支払い、購入履歴、返金およびApple Accountに関する情報はAppleが処理します。運営者がクレジットカード番号や銀行口座番号等の完全な支払手段情報を直接受け取ることはありません。

本アプリは、商品ID、StoreKitが提供する価格表示、購入・復元・保留・取消・失敗・返金等の取引状態、および購入利用権が有効かどうかを受け取ります。購入済み機能を提供するため、利用権の端末内キャッシュをセーブデータへ保存します。

### 2.3 端末内のゲームデータ

本アプリは、ゲームの進行と設定を維持するため、次の情報をアプリ専用の端末内領域に保存します。

- ストーリー、チュートリアル、イベントの進行
- 発見・取得した品種、取得回数、最高記録、図鑑進行
- ゲーム内通貨、たね、アイテム、所有する鉢
- 原生地、ガチャ、ハイブリッドラボ、ジュレジュレ団に関する進行
- 保存した寄せ植え
- アプリ内課金の利用権キャッシュ
- 言語、BGM、効果音、表示等の設定
- ゲーム動作に必要な日時、回数およびゲーム内識別子

2.1に記載した広告SDKによる処理を除き、現行実装には、運営者独自のユーザーアカウント、クラウドセーブ、独立したアクセス解析SDK、または運営者管理サーバーへのゲーム進行送信はありません。

### 2.4 共有機能

利用者が共有操作を行った場合、本アプリは最高記録または寄せ植えの画像を端末内で生成し、iOSの共有シートまたはWeb Share APIを開きます。運営者が共有先を自動的に選択したり、運営者管理サーバーへ自動送信したりすることはありません。利用者が選択した共有先には、その第三者サービスのプライバシーポリシーが適用されます。

### 2.5 通知

現行の通常プレイは、新しいローカル通知を予約せず、リモートプッシュ通知を使用しません。過去のバージョンが予約した可能性のあるローカル通知を取り消す互換処理だけを含みます。

### 2.6 GitHub Pagesで配信するページ

Web版ゲーム、サポートページ、プライバシーポリシーおよびこれらの静的素材はGitHub Pagesから配信されます。GitHubは、これらのページを配信するため、IPアドレス、ブラウザ・端末情報、アクセス日時、要求URL等を処理する場合があります。

### 2.7 お問い合わせ

メールでお問い合わせいただいた場合、運営者は送信者のメールアドレス、表示名、本文、および利用者が任意に添付したファイルを受け取ることがあります。本アプリがこれらを自動送信することはありません。

## 3. 利用目的

取り扱う情報は、該当する場合に限り、次の目的で利用します。

- ゲーム進行、設定、購入済み機能その他の本アプリ機能の提供
- リワード広告の読込み、表示、視聴完了の確認および報酬の付与、ならびにインタースティシャル広告の読込みおよび表示
- 広告配信、集計測定、表示回数の制御、不正利用防止および障害解析
- 地域等に応じた同意メッセージの表示とプライバシー選択の反映
- 商品情報と価格の表示、購入処理、購入の復元、返金・利用権変更の反映
- 利用者が選んだ共有先への画像送信
- Web版ゲーム、サポートページおよびプライバシーポリシーの配信
- 問い合わせへの回答、追加情報の依頼およびその後の対応

## 4. 第三者サービス

本アプリは次の第三者サービスを利用します。各事業者による情報の取扱いは、それぞれのポリシーをご確認ください。

- Google AdMob / Google Mobile Ads SDK / UMP<br>
  <https://policies.google.com/privacy><br>
  <https://policies.google.com/technologies/partner-sites><br>
  <https://developers.google.com/admob/ios/privacy><br>
  <https://developers.google.com/admob/ios/privacy/data-disclosure><br>
  <https://developers.google.com/admob/terms><br>
  <https://business.safety.google/adscontrollerterms/>
- Apple App Store / StoreKit 2<br>
  <https://www.apple.com/legal/privacy/><br>
  <https://developer.apple.com/support/terms/apple-developer-program-license-agreement/>
- GitHub Pages（Web版ゲーム、サポートページ、プライバシーポリシー）<br>
  <https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement><br>
  <https://docs.github.com/en/site-policy/github-terms/github-terms-for-additional-products-and-features#pages>

本アプリから情報を受け取る可能性がある第三者は、上記の事業者、広告配信に関与する広告技術プロバイダ、および利用者が共有機能で自ら選択した送信先です。共有先への画像送信は、利用者が共有操作を行い、送信先を選択した場合だけ行われます。

運営者は、本アプリから利用者情報を受け取る第三者サービスを選定・利用する際、各事業者の公開プライバシーポリシー、適用される利用条件およびデータ保護資料を確認し、本ポリシーとApple App Review Guidelines 5.1.1(i)が求めるものと同等以上の保護が提供されることを確認したうえで利用します。その確認ができない第三者サービスまたは機能へ、本アプリから利用者情報を自動送信しません。<br>
<https://developer.apple.com/app-store/review/guidelines/>

これらの事業者による処理は、日本国外で行われる場合があります。

## 5. 広告の同意と選択

本アプリはGoogle UMPを使って同意情報を更新し、利用者の地域等により必要な場合はGoogleが提供する同意フォームを表示します。必要な同意または広告要求の許可を確認できない場合、リワード広告とインタースティシャル広告は読み込まず、表示しません。リワード広告を視聴していないのに視聴成功として扱うことはありません。

「広告を削除」を購入した場合、森のガチャとハイブリッドラボのインタースティシャル広告は表示しません。任意視聴のパンダのお手伝いリワード広告は、購入後も利用できます。

Google UMPによる同意とApple ATTによる追跡許可は別の仕組みです。本アプリは必要なUMP処理を先に行い、その後、ATTの状態が未決定の場合に限り、Google Mobile Ads SDKを初期化する前にiOSの追跡許可ダイアログを表示します。ATTが許可、拒否または制限のいずれであっても、ゲーム機能は利用できます。ATTの選択は、iOSの設定画面から後で変更できる場合があります。

Googleがプライバシー設定の再表示を必要と判定した場合は、ゲーム内の設定画面に「プライバシー設定」に相当するボタンを表示する構成です。端末および地域によっては、OSやGoogleが提供する追加の広告・プライバシー設定を利用できます。

## 6. 保持と削除

- 端末内のゲームデータ、利用権キャッシュおよび生成した共有画像は、原則としてアプリ専用領域に保持されます。アプリの削除、オフロード、バックアップおよび復元時の取扱いはiOSと利用者の端末設定に従います。
- 非消耗型購入の取引履歴と利用権はAppleが管理します。再インストール後は本アプリの「購入を復元」から確認できます。
- Googleによる広告・同意管理情報、およびGitHubによるWeb版ゲーム・サポートページ・プライバシーポリシーの配信情報の保持・削除は、各事業者のポリシーと利用者の端末・サービス設定に従います。
- お問い合わせ内容とメールアドレスは、返信やその後の対応に必要な間だけ保管し、不要になったものは速やかに削除するよう努めます。削除をご希望の場合は、サポート窓口までご連絡ください。

端末内データに関する相談、または運営者が保持する問い合わせ情報の開示・訂正・削除等の相談は、問い合わせ先へご連絡ください。本人確認や法令上の理由により、希望どおり対応できない場合があります。

## 7. 子どものプライバシー

本アプリは一般向けゲームとして提供し、AppleのKids Categoryには登録しません。子ども専用アプリではありませんが、子どもが利用する可能性があることを考慮します。本アプリは利用者の年齢を入力させず、氏名、住所、学校名等をゲーム進行のために求めません。

Kids Categoryを使用しないことだけを理由に、子どもに関する法令やプラットフォーム要件が適用されないとは扱いません。保護者が、子どもから運営者へ情報が提供されたと考える場合は、問い合わせ先へご連絡ください。内容を確認し、適用法令に従って対応します。

## 8. 安全管理

運営者は、取り扱う情報への不正アクセス、漏えい、滅失または毀損を防ぐため、合理的な安全管理に努めます。ただし、インターネット通信または電子的保存の完全な安全性を保証するものではありません。

## 9. 改定

機能、利用するSDK、法令またはサービス内容の変更等に応じて、本ポリシーを改定することがあります。重要な変更がある場合は、本アプリ、公式サイトその他の適切な方法でお知らせします。改定後のポリシーは、掲載した施行日から適用します。

## 10. お問い合わせ

- 運営者：オハナ屋農園
- 所在国・地域：日本
- メール：kotaro.hana.0505@gmail.com
- サポートページ：[サポートページを開く](../support/)

---

# Privacy Policy

## 1. Basic Information

オハナ屋農園 (the “Operator”) establishes this Privacy Policy for the game application “Puku Puku! Taniku Life” (the “App”).

- App: Puku Puku! Taniku Life (ぷくぷく！たにくらいふ)
- Operator: オハナ屋農園
- Country or region: Japan
- Contact: kotaro.hana.0505@gmail.com
- Effective date: November 14, 2026

## 2. Information Processed

### 2.1 Advertising

The iOS version uses Google Mobile Ads SDK (Google AdMob) and Google User Messaging Platform SDK (UMP) to provide optional rewarded ads and automatically displayed interstitial ads in Forest Gacha and Hybrid Lab. Depending on the device, consent status, region, Google settings, and ad availability, Google may process the following information for ad delivery, consent management, ad measurement, advertising analytics, frequency controls, fraud prevention, diagnostics, and SDK quality:

An interstitial ad may be displayed automatically after every five successfully completed Forest Gacha draws or every five successfully completed Hybrid Lab fusions, at a safe screen transition after the result, GET card, and related presentation have ended. If an ad is not ready, the App skips it for that occasion and does not display it unexpectedly later.

- IP address and coarse location inferred from an IP address or similar data;
- an advertising identifier or another device identifier;
- ad impressions, views, and interactions;
- app launches, interactions, video views, and similar usage data;
- crash, performance, and other diagnostic data; and
- consent requirements, consent status, and privacy choices.

The current App configuration disables ad personalization and the publisher first-party ID and sets the maximum ad content rating to `G`. Non-personalized ads may still process information required for ad delivery, aggregate ad measurement, advertising analytics, frequency controls, and fraud prevention. Google's specific processing varies depending on the user's region, device settings, consent status, Google settings, and ad delivery conditions.

After completing any required Google UMP processing and only when the ATT status is not determined, the iOS version requests tracking authorization through Apple's App Tracking Transparency (ATT) before initializing Google Mobile Ads SDK. If authorization is granted, Google Mobile Ads SDK may use the Identifier for Advertisers (IDFA) for ad frequency control, ad measurement, and other advertising purposes disclosed by Google. If authorization is denied or restricted, the App starts the advertising SDK while iOS makes the IDFA unavailable. The game remains available regardless of the ATT choice, and the in-game reward for a completed rewarded ad is not reduced. Denying ATT does not necessarily stop processing of non-IDFA information such as IP address, ad data, usage data, or diagnostics.

### 2.2 In-app purchases

The iOS version uses Apple StoreKit 2 for 37 non-consumable in-app purchases: 36 pot-design products and one “Remove Ads” product configured at ¥100 in the Japanese storefront. Pot designs are permanently unlocked. “Remove Ads” permanently removes only the automatically displayed interstitial ads in Forest Gacha and Hybrid Lab; the optional Panda Help rewarded ad remains available. Apple processes payment, purchase history, refunds, and Apple Account information. The Operator does not directly receive complete payment credentials such as credit card or bank account numbers.

The App receives product identifiers, StoreKit-provided price displays, transaction states such as purchase, restoration, pending, cancellation, failure, and refund, and whether an entitlement is active. An on-device entitlement cache is stored with game save data to provide purchased functionality.

### 2.3 On-device game data

The App stores story and tutorial progress, discovered varieties and records, catalog progress, in-game currency and items, owned pots, habitat and feature progress, saved arrangements, entitlement caches, settings, and gameplay dates or counters in the App's private on-device storage.

Except for the advertising-SDK processing described in Section 2.1, the current implementation has no Operator account system, cloud save, separate standalone analytics SDK, or code that sends game progress to an Operator-controlled server.

### 2.4 Sharing

When the user chooses to share, the App creates a record or arrangement image on the device and opens the iOS share sheet or Web Share API. The Operator does not automatically choose a recipient or upload the image to an Operator-controlled server. The selected third-party destination applies its own privacy policy.

### 2.5 Notifications

Normal gameplay currently schedules no new local notifications and uses no remote push notifications. The App only retains compatibility code that cancels local notifications that may have been scheduled by an older version.

### 2.6 Pages delivered through GitHub Pages

The web game, support page, Privacy Policy, and their static assets are delivered through GitHub Pages. GitHub may process IP address, browser or device information, request times, requested URLs, and other connection information needed to deliver these pages.

### 2.7 Support inquiries

If a user contacts the Operator by email, the Operator may receive the sender's email address, display name, message, and files voluntarily attached by the user. The App does not send this information automatically.

## 3. Purposes

Information is processed, as applicable, for the following purposes:

- providing game progress, settings, purchased functionality, and other App features;
- loading and displaying rewarded ads, verifying completion, and granting rewards, and loading and displaying interstitial ads;
- ad delivery, aggregate ad measurement, advertising analytics, frequency controls, fraud prevention, and diagnostics;
- displaying consent messages based on region or other applicable factors and applying privacy choices;
- displaying product information and prices, processing and restoring purchases, and reflecting refunds or entitlement changes;
- sending an image to a destination selected by the user;
- delivering the web game, support page, and Privacy Policy; and
- responding to support inquiries, requesting additional information, and following up.

## 4. Third-Party Services

The App uses the following third-party services. Please review each provider's privacy policy and official materials for information about its handling of data.

- Google AdMob / Google Mobile Ads SDK / UMP<br>
  <https://policies.google.com/privacy><br>
  <https://policies.google.com/technologies/partner-sites><br>
  <https://developers.google.com/admob/ios/privacy><br>
  <https://developers.google.com/admob/ios/privacy/data-disclosure><br>
  <https://developers.google.com/admob/terms><br>
  <https://business.safety.google/adscontrollerterms/>
- Apple App Store / StoreKit 2<br>
  <https://www.apple.com/legal/privacy/><br>
  <https://developer.apple.com/support/terms/apple-developer-program-license-agreement/>
- GitHub Pages (web game, support page, and Privacy Policy)<br>
  <https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement><br>
  <https://docs.github.com/en/site-policy/github-terms/github-terms-for-additional-products-and-features#pages>

Third parties that may receive information from the App are the providers listed above, advertising technology providers involved in ad delivery, and a destination that the user selects through the sharing feature. An image is sent to a sharing destination only when the user initiates sharing and selects that destination.

When selecting and using a third-party service that receives user information from the App, the Operator reviews the provider's published privacy policy, applicable terms, and data protection materials and confirms, before use, that the service provides the same or equal protection required by this Policy and Apple App Review Guideline 5.1.1(i). The App will not automatically send user information to a third-party service or feature for which the Operator cannot make that confirmation.<br>
<https://developer.apple.com/app-store/review/guidelines/>

These providers may process information outside Japan.

## 5. Advertising Consent and Choices

The App uses Google UMP to update consent information and to display a Google-provided consent form when required based on the user's region or other applicable factors. The App does not load or display rewarded or interstitial ads when it cannot confirm the required consent or permission to request ads. The App does not treat an unviewed rewarded ad as completed.

After “Remove Ads” is purchased, the App does not display interstitial ads in Forest Gacha or Hybrid Lab. The optional Panda Help rewarded ad remains available after the purchase.

Google UMP consent and Apple ATT tracking authorization are separate controls. The App completes any required UMP processing first and then, only when the ATT status is not determined, displays the iOS tracking authorization prompt before initializing Google Mobile Ads SDK. The game remains available whether ATT is authorized, denied, or restricted. The ATT choice may be changeable later in iOS Settings.

When Google reports that privacy options must be made available, the App is designed to show a corresponding Privacy Settings button in its settings screen. Additional advertising or privacy controls may be available through the operating system or Google, depending on the device and region.

## 6. Retention and Deletion

- Game data, entitlement caches, and generated share images are generally retained in the App's private on-device storage. Deletion, offloading, backup, and restoration are governed by iOS and the user's device settings.
- Apple manages non-consumable purchase history and entitlements. The App provides Restore Purchases after reinstallation.
- Retention and deletion of advertising and consent information processed by Google, and delivery information for the web game, support page, and Privacy Policy processed by GitHub, are governed by each provider's policies and the user's device or service settings.
- We keep your message and email address only for as long as needed to respond to your inquiry and follow up. Once we no longer need this information, we make reasonable efforts to delete it promptly. To request deletion, please contact us at the support email address.

Users may contact the Operator about on-device data or to request access, correction, or deletion of inquiry information held by the Operator. A request may be limited where identity verification or applicable law requires it.

## 7. Children's Privacy

The App is offered as a general-audience game and is not listed in Apple's Kids Category. It is not designed exclusively for children, but the Operator recognizes that children may use it. The App does not ask users to enter their age and does not require a name, address, or school name for gameplay.

The Operator does not assume that laws or platform requirements concerning children are inapplicable merely because the App is outside the Kids Category. A parent or guardian who believes a child has provided information to the Operator may contact the Operator for review and action under applicable law.

## 8. Security

The Operator uses reasonable measures intended to protect handled information against unauthorized access, disclosure, loss, or damage. No Internet transmission or electronic storage method can be guaranteed to be completely secure.

## 9. Changes

This Policy may be updated when the App, SDKs, laws, or services change. Material changes will be announced through the App, the official site, or another appropriate method. An updated Policy applies from its posted effective date.

## 10. Contact

- Operator: オハナ屋農園
- Country or region: Japan
- Email: kotaro.hana.0505@gmail.com
- Support page: [Open the support page](../support/)

---

## 検証状況（公開ページには含めない）

### 完了している確認

1. TestFlight Build 83のiPhone実機で、UMP処理、GoogleのIDFA事前説明、ATT許可、Google Mobile Ads初期化、Google公式テスト広告の再生、視聴完了報酬の付与まで成功したことを確認した。
2. 現行コードはGodot AdMob Plugin v7.0、Google Mobile Ads SDK 12.14.0、UMP 3.1.0を固定し、リワード広告とインタースティシャル広告で共通の `UMP -> ATT -> Google Mobile Ads初期化` の順序、非パーソナライズ広告、パブリッシャーのファーストパーティID無効、最大広告レーティング `G` を設定している。
3. ATTの拒否・制限済み状態でもGoogle Mobile Ads初期化へ進むこと、および拒否時も広告再生、報酬の一度だけの付与、次広告の再読込を維持することを自動回帰テストで確認した。
4. コミット `8fe7083` で、AppleのATT用途説明を日本語・英語の `InfoPlist.strings` に分離し、生成Xcodeプロジェクトと署名済みIPAで両言語を検証するCIを追加した。
5. UMPの `privacyOptionsRequirementStatus`、`presentPrivacyOptionsForm`、`canRequestAds` を利用するネイティブブリッジと、required時だけ設定画面に入口を表示するコード・自動テストが存在する。
6. 最新ソースで、鉢36商品と「広告を削除」1商品の計37商品のStoreKit 2利用権処理と購入復元、端末内セーブ、利用者操作時だけ開く共有シート、および通常プレイでは新規通知を予約せず旧通知を取り消すだけの構成を確認した。
7. 森のガチャとハイブリッドラボの独立した5回カウンター、安全な画面切り替え時だけのインタースティシャル広告表示、広告未準備時の単発スキップ、および「広告を削除」購入・復元後の表示抑止をコードと回帰テストで確認した。
8. インタースティシャル広告は既存のGoogle Mobile Ads SDK、UMP、ATTゲートを共用し、別の広告SDKや運営者管理サーバーを追加していない。AppleのApp PrivacyとGoogleのデータ開示資料を再照合し、Device ID、広告データ、利用状況、診断情報等の既存申告候補を広告形式の追加だけを理由に削除しない方針を確認した。最終申告は引き続き提出用archiveのPrivacy Reportと実際のAdMob構成に合わせて確定する。

### 正式公開時に完了した確認

1. 運営者が日本語・英語本文、運営者名、問い合わせ先、保管・削除方針、および公開URLを最終承認した。
2. 最終更新・施行日を日本時間の更新日である2026年11月14日に確定した。
3. Apple App Review Guidelines 5.1.1(i)に関する候補文を含む日英本文を承認した。公開資料だけで確認できない第三者の保護措置を確認済みとは記載していない。
4. 最新Markdownから、下書き表示、`noindex`、作業用注記を含まない公開HTMLを再生成した。
5. 公開先を `https://kotaro0505.github.io/puku-puku-taniku/privacy-policy/` とし、サポートページと相互リンクした。

### App Store審査提出前に必要だが、ポリシーURLの先行公開を妨げない確認

1. `8fe7083` 以降のTestFlight実機で、日本語環境は日本語のみ、英語環境は英語のみのATT用途説明になることを確認する。
2. ATT拒否および可能であれば制限済み状態をiPhone実機で確認し、広告利用と報酬が許可時と同じであることを確認する。現時点ではコード・自動テストのみ確認済み。
3. AdMobのIDFA事前説明メッセージへ日本語を追加し、非パーソナライズ広告と矛盾しない日英本文へ更新・公開したことを確認する。
4. UMPのプライバシーオプションがrequiredとなる実機状態で、設定ボタン、フォーム、同意変更、古い広告の破棄、広告再読込を確認する。
5. AdMob管理画面のPrivacy & messaging、広告技術プロバイダ、メディエーション、地域、年齢別広告取扱いを最終確認する。
6. Google Mobile Ads 12.14.0でTFATを利用できない点を踏まえ、年齢不明利用者を旧設定の `UNSPECIFIED` とする運用と、既知の子ども・ティーンへの対応を確認する。
7. Googleの公開中のデータ開示ページは最新版SDK 13.12.0を説明しているため、App Store提出用の最終archiveで、実際に組み込むGoogle Mobile Ads SDK 12.14.0、UMP 3.1.0および全SDKのPrivacy ManifestとPrivacy Reportを確認し、App PrivacyのDevice ID、トラッキング、広告データ、利用状況、診断情報等の申告を最終動作と一致させる。
8. アプリ内の分かりやすい場所から、正式なプライバシーポリシーURLを開ける導線を実装・実機確認する。Google UMPの「プライバシー設定」ボタンとは別の導線とする。
9. 適用法令上、住所、代表者、個人情報保護責任者等の追加表示が必要か、必要に応じて専門家へ確認する。
