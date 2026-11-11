# 『ぷくぷく！たにくらいふ』プライバシーポリシー公開候補

> **承認待ち・未公開**<br>
> 最終更新: 2026-11-11<br>
> このファイルは公開ページの本文候補です。末尾の「公開前ゲート」をすべて解消し、制定日を確定するまで正式なプライバシーポリシーとして公開しません。

---

# プライバシーポリシー

## 1. 基本情報

オハナ屋農園（以下「運営者」）は、ゲームアプリ『ぷくぷく！たにくらいふ』（以下「本アプリ」）における情報の取扱いについて、次のとおり定めます。

- アプリ名：ぷくぷく！たにくらいふ
- 運営者：オハナ屋農園
- 所在国・地域：日本
- 問い合わせ先：kotaro.hana.0505@gmail.com
- 制定日：［公開承認時に入力］

## 2. 取り扱う情報

### 2.1 リワード広告

iOS版は、任意視聴のリワード広告を提供するため、Google Mobile Ads SDK（Google AdMob）およびGoogle User Messaging Platform SDK（UMP）を使用します。広告の配信、同意管理、効果測定、表示回数の制御、不正利用防止、障害解析およびSDKの品質改善のため、Googleは端末や同意状態等に応じて次の情報を処理する可能性があります。

- IPアドレス、およびIPアドレス等から推定されるおおまかな位置情報
- 広告識別子その他の端末識別子
- 広告の表示、視聴、操作等の広告データ
- アプリの起動、操作、動画視聴等の利用状況
- クラッシュ、性能その他の診断情報
- 同意の要否、同意状態、プライバシー選択に関する情報

本アプリの現行設定は、広告のパーソナライズとパブリッシャーのファーストパーティIDを無効にし、広告コンテンツの最大レーティングを `G` にしています。非パーソナライズ広告でも、広告配信、集計測定、不正利用防止等に必要な情報が処理されることがあります。Googleによる具体的な取扱いは、利用者の地域、端末設定、同意状態、Googleの設定および広告配信状況により異なります。

iOS版は、必要なGoogle UMPの同意処理が完了した後、Google Mobile Ads SDKを初期化する前に、AppleのApp Tracking Transparency（ATT）を通じて追跡の許可を求めます。許可された場合、Google Mobile Ads SDKは広告識別子（IDFA）を広告の表示回数調整、効果測定その他Googleが開示する広告目的に利用する可能性があります。拒否または制限された場合、本アプリはIDFAを利用せずに広告SDKを開始します。ATTの選択にかかわらずゲームは利用でき、リワード広告を最後まで視聴した場合のゲーム内報酬は変わりません。拒否しても、IPアドレス、広告データ、利用状況、診断情報等、IDFA以外の情報の処理がすべて停止するとは限りません。

### 2.2 アプリ内課金

iOS版は、36種類の鉢デザインを永続的に解放する非消耗型アプリ内課金にApple StoreKit 2を使用します。支払い、購入履歴、返金およびApple Accountに関する情報はAppleが処理します。運営者がクレジットカード番号や銀行口座番号等の完全な支払手段情報を直接受け取ることはありません。

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

現行実装には、運営者独自のユーザーアカウント、クラウドセーブ、分析SDKまたは運営者管理サーバーへのゲーム進行送信はありません。

### 2.4 共有機能

利用者が共有操作を行った場合、本アプリは最高記録または寄せ植えの画像を端末内で生成し、iOSの共有シートまたはWeb Share APIを開きます。運営者が共有先を自動的に選択したり、運営者管理サーバーへ自動送信したりすることはありません。利用者が選択した共有先には、その第三者サービスのプライバシーポリシーが適用されます。

### 2.5 通知

現行の通常プレイは、新しいローカル通知を予約せず、リモートプッシュ通知を使用しません。過去のバージョンが予約した可能性のあるローカル通知を取り消す互換処理だけを含みます。

### 2.6 Web版

Web版とその静的素材はGitHub Pagesから配信されます。GitHubは、サイト配信に必要なIPアドレス、ブラウザ・端末情報、アクセス日時、要求URL等を処理する場合があります。

### 2.7 お問い合わせ

メールでお問い合わせいただいた場合、運営者は送信者のメールアドレス、表示名、本文、および利用者が任意に添付したファイルを受け取ることがあります。本アプリがこれらを自動送信することはありません。

## 3. 利用目的

取り扱う情報は、該当する場合に限り、次の目的で利用します。

- ゲーム進行、設定、購入済み機能その他の本アプリ機能の提供
- リワード広告の読込み、表示、視聴完了の確認および報酬の付与
- 広告配信、集計測定、表示回数の制御、不正利用防止および障害解析
- 地域等に応じた同意メッセージの表示とプライバシー選択の反映
- 商品情報と価格の表示、購入処理、購入の復元、返金・利用権変更の反映
- 利用者が選んだ共有先への画像送信
- Web版の配信
- 問い合わせへの回答、追加情報の依頼、対応履歴の管理および紛争対応

## 4. 第三者サービス

本アプリは次の第三者サービスを利用します。各事業者による情報の取扱いは、それぞれのポリシーをご確認ください。

- Google AdMob / Google Mobile Ads SDK / UMP<br>
  <https://policies.google.com/privacy><br>
  <https://developers.google.com/admob/ios/privacy>
- Apple App Store / StoreKit 2<br>
  <https://www.apple.com/legal/privacy/>
- GitHub Pages（Web版のみ）<br>
  <https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement>

これらの事業者による処理は、日本国外で行われる場合があります。

## 5. 広告の同意と選択

本アプリはGoogle UMPを使って同意情報を更新し、利用者の地域等により必要な場合はGoogleが提供する同意フォームを表示します。必要な同意または広告要求の許可を確認できない場合、リワード広告は利用できません。広告を視聴していないのに視聴成功として扱うことはありません。

Google UMPによる同意とApple ATTによる追跡許可は別の仕組みです。本アプリはUMPの必要な処理を先に行い、その後、ATTの状態が未決定の場合だけiOSの追跡許可ダイアログを表示します。ATTが許可、拒否または制限のいずれであっても、ゲーム機能は利用できます。ATTの選択は、iOSの設定画面から後で変更できる場合があります。

Googleがプライバシー設定の再表示を必要と判定した場合は、ゲーム内の設定画面に「プライバシー設定」に相当するボタンを表示する構成です。端末および地域によっては、OSやGoogleが提供する追加の広告・プライバシー設定を利用できます。

## 6. 保持と削除

- 端末内のゲームデータ、利用権キャッシュおよび生成した共有画像は、原則としてアプリ専用領域に保持されます。アプリの削除、オフロード、バックアップおよび復元時の取扱いはiOSと利用者の端末設定に従います。
- 非消耗型購入の取引履歴と利用権はAppleが管理します。再インストール後は本アプリの「購入を復元」から確認できます。
- 問い合わせ情報は、対応、履歴確認および紛争対応に必要な範囲で保持し、法令上または紛争対応上さらに保持する必要がある場合を除き、最終対応日から原則1年以内に削除または匿名化します。

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

---

# Privacy Policy

## 1. Basic Information

オハナ屋農園 (the “Operator”) establishes this Privacy Policy for the game application “Puku Puku! Taniku Life” (the “App”).

- App: Puku Puku! Taniku Life (ぷくぷく！たにくらいふ)
- Operator: オハナ屋農園
- Country or region: Japan
- Contact: kotaro.hana.0505@gmail.com
- Effective date: [enter when publication is approved]

## 2. Information Processed

### 2.1 Rewarded advertising

The iOS version uses Google Mobile Ads SDK (Google AdMob) and Google User Messaging Platform SDK (UMP) to provide optional rewarded ads. Depending on the device, consent status, region, Google settings, and ad availability, Google may process the following information for ad delivery, consent management, measurement, frequency controls, fraud prevention, diagnostics, analytics, and SDK quality:

- IP address and coarse location inferred from an IP address or similar data;
- an advertising identifier or another device identifier;
- ad impressions, views, and interactions;
- app launches, interactions, video views, and similar usage data;
- crash, performance, and other diagnostic data; and
- consent requirements, consent status, and privacy choices.

The current App configuration disables ad personalization and the publisher first-party ID and sets the maximum ad content rating to `G`. Non-personalized ads may still process information required for ad delivery, aggregate measurement, frequency controls, and fraud prevention.

After completing any required Google UMP consent flow and before initializing Google Mobile Ads SDK, the iOS version requests tracking authorization through Apple's App Tracking Transparency (ATT). If authorization is granted, Google Mobile Ads SDK may use the Identifier for Advertisers (IDFA) for ad frequency control, measurement, and other advertising purposes disclosed by Google. If authorization is denied or restricted, the App starts the advertising SDK without using the IDFA. The game remains available regardless of the ATT choice, and the in-game reward for a completed rewarded ad is not reduced. Denying ATT does not necessarily stop processing of non-IDFA information such as IP address, ad data, usage data, or diagnostics.

### 2.2 In-app purchases

The iOS version uses Apple StoreKit 2 for non-consumable purchases that permanently unlock 36 pot designs. Apple processes payment, purchase history, refunds, and Apple Account information. The Operator does not directly receive complete payment credentials such as credit card or bank account numbers.

The App receives product identifiers, StoreKit-provided price displays, transaction states, and whether an entitlement is active. An on-device entitlement cache is stored with game save data to provide purchased functionality.

### 2.3 On-device game data

The App stores story and tutorial progress, discovered varieties and records, catalog progress, in-game currency and items, owned pots, habitat and feature progress, saved arrangements, entitlement caches, settings, and gameplay dates or counters in the App's private on-device storage.

The current implementation has no Operator account system, cloud save, analytics SDK, or code that sends game progress to an Operator-controlled server.

### 2.4 Sharing

When the user chooses to share, the App creates a record or arrangement image on the device and opens the iOS share sheet or Web Share API. The Operator does not automatically choose a recipient or upload the image to an Operator-controlled server. The selected third-party destination applies its own privacy policy.

### 2.5 Notifications

Normal gameplay currently schedules no new local notifications and uses no remote push notifications. The App only retains compatibility code that cancels local notifications that may have been scheduled by an older version.

### 2.6 Web version

The web version and its static assets are delivered through GitHub Pages. GitHub may process IP address, browser or device information, request times, requested URLs, and other connection information needed to deliver the site.

### 2.7 Support inquiries

If a user contacts the Operator by email, the Operator may receive the sender's email address, display name, message, and files voluntarily attached by the user. The App does not send this information automatically.

## 3. Purposes

Information is processed, as applicable, to provide game progress and settings; provide purchased functionality; load and show rewarded ads; verify ad completion and grant a reward; deliver and measure ads; prevent fraud; diagnose failures; manage regional consent choices; display products and prices; process and restore purchases; reflect refunds or entitlement changes; share an image with a user-selected destination; deliver the web version; and respond to support inquiries.

## 4. Third-Party Services

- Google AdMob / Google Mobile Ads SDK / UMP<br>
  <https://policies.google.com/privacy><br>
  <https://developers.google.com/admob/ios/privacy>
- Apple App Store / StoreKit 2<br>
  <https://www.apple.com/legal/privacy/>
- GitHub Pages (web version only)<br>
  <https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement>

These providers may process information outside Japan.

## 5. Advertising Consent and Choices

The App uses Google UMP to update consent information and to display a Google-provided consent form when required based on the user's region or other applicable factors. Rewarded ads remain unavailable when the App cannot confirm the required consent or permission to request ads. The App does not treat an unviewed ad as completed.

Google UMP consent and Apple ATT tracking authorization are separate controls. The App completes the required UMP flow first and then displays the iOS tracking authorization prompt only when the ATT status is not determined. The game remains available whether ATT is authorized, denied, or restricted. The ATT choice may be changeable later in iOS Settings.

When Google reports that privacy options must be made available, the App is designed to show a corresponding Privacy Settings button in its settings screen. Additional advertising or privacy controls may be available through the operating system or Google, depending on the device and region.

## 6. Retention and Deletion

- Game data, entitlement caches, and generated share images are generally retained in the App's private on-device storage. Deletion, offloading, backup, and restoration are governed by iOS and the user's device settings.
- Apple manages non-consumable purchase history and entitlements. The App provides Restore Purchases after reinstallation.
- Support inquiry information is retained only as needed to respond, maintain a support history, and address disputes. Unless a longer period is required by law or for a dispute, it will generally be deleted or anonymized within one year after the last support response.

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

---

## 公開前ゲート（公開ページには含めない）

次を解消するまで、この候補を正式ページへ変換しないでください。

1. 制定日・施行日を確定する。
2. ATT実装を含む次回TestFlight実機で、UMP完了後・Google Mobile Ads初期化前にATTが表示されること、許可・拒否・制限済みの各状態、拒否時の広告と報酬を確認する。最終IPAのPrivacy ReportとGoogle Mobile Ads SDK 12.14.0のPrivacy Manifestを照合し、App PrivacyではDevice IDとトラッキングを実際の最終動作に合わせて申告する。
3. AdMob管理画面のPrivacy & messaging、広告技術プロバイダ、メディエーション、地域、年齢別広告取扱いを確認する。
4. Google Mobile Ads 12.14.0でTFATを利用できない点を踏まえ、年齢不明利用者を旧設定の `UNSPECIFIED` とする運用と、既知の子ども・ティーンへの対応を確認する。
5. UMPのプライバシーオプションがrequiredとなる実機状態で、設定ボタン、フォーム、同意変更、広告再読込を確認する。
6. App Store提出用の最終archiveでPrivacy Reportと全SDKのPrivacy Manifestを確認する。
7. 適用法令上、住所、代表者、個人情報保護責任者等の追加表示が必要か確認する。
8. 公開先を `https://kotaro0505.github.io/puku-puku-taniku/privacy-policy/` とすることを承認し、アプリ内リンクとApp Store ConnectのURLを一致させる。
