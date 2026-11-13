# 『ぷくぷく！たにくらいふ』サポートページ公開原稿

> **正式公開済み**<br>
> 最終更新: 2026-11-13<br>
> 正式URL: `https://kotaro0505.github.io/puku-puku-taniku/support/`<br>
> 公開本文は日本語・英語の各サポート節です。末尾の検証記録は公開HTMLに含めません。

---

# ぷくぷく！たにくらいふ サポート

『ぷくぷく！たにくらいふ』をご利用いただきありがとうございます。

- 運営者：オハナ屋農園
- 所在国・地域：日本
- お問い合わせ：kotaro.hana.0505@gmail.com

## お問い合わせの前に

### ゲームの進行とセーブ

ゲームの進行と設定は、通常はアプリ専用の端末内領域へ保存されます。アプリの削除、端末の初期化、バックアップや復元の状況によっては、ゲーム進行を復元できない場合があります。アプリを削除する前に、必要に応じてAppleが案内する端末バックアップをご確認ください。

### 鉢デザインの購入と復元

鉢デザインは非消耗型アプリ内課金です。購入後、その鉢デザインが永続的に解放され、鉢本体はゲーム内に表示されるぷくコイン価格で購入できます。現金でぷくコインを購入する商品ではありません。

購入済みの鉢デザインが表示されない場合は、購入時と同じApple Accountを使用していることを確認し、「パンダのお店」＞「鉢」画面上部の「購入を復元」をお試しください。請求、返金またはApple Accountに関する事項はAppleのサポートもご確認ください。

### リワード広告

広告は任意視聴です。通信、広告在庫、地域、同意状態、端末設定等により利用できない場合があります。広告を途中で閉じた場合や、SDKから視聴完了が通知されなかった場合は報酬を付与しません。

Googleがプライバシー設定の再表示を必要と判定した場合は、ゲーム内の設定画面にプライバシー設定ボタンが表示されます。

iOSの追跡許可（ATT）はGoogle UMPの同意とは別の設定です。追跡を許可しない場合でもゲームは利用でき、広告が利用可能で最後まで視聴した場合の報酬は変わりません。

### 共有画像

最高記録や寄せ植えの共有は、iOSの共有シートを利用します。共有できない場合は、共有先アプリの状態、端末の空き容量、OSの設定をご確認ください。

## お問い合わせ時にお知らせいただきたい情報

問題の確認に必要な範囲で、次の情報をお知らせください。

- 発生した画面と操作手順
- 表示されたメッセージまたは理由コード
- 発生日時
- iPhone機種とiOSバージョン
- アプリのバージョンとビルド番号
- 再起動後も再現するか

Apple Accountのパスワード、クレジットカード番号、認証コード等は送らないでください。セーブデータや画面画像を送る前に、個人情報が含まれていないことをご確認ください。

お問い合わせ内容とメールアドレスは、返信やその後の対応に必要な間だけ保管し、不要になったものは速やかに削除するよう努めます。削除をご希望の場合は、サポート窓口までご連絡ください。

## プライバシー

プライバシーポリシー：[プライバシーポリシーを開く](../privacy-policy/)

---

# Puku Puku! Taniku Life Support

Thank you for playing Puku Puku! Taniku Life.

- Operator: オハナ屋農園
- Country or region: Japan
- Contact: kotaro.hana.0505@gmail.com

## Before Contacting Support

### Progress and save data

Game progress and settings are normally stored in the App's private on-device storage. Progress may not be recoverable after deleting the App, erasing a device, or depending on backup and restoration status. Before deleting the App, review Apple's device backup guidance if needed.

### Pot design purchases and restoration

Pot designs are non-consumable in-app purchases. A purchase permanently unlocks the selected design; individual pots can then be obtained for the in-game Puku Coin price shown in the catalog. These products do not sell Puku Coins for money.

If a purchased design is missing, confirm that the device uses the Apple Account used for the purchase, then open Panda's Shop > Pots and choose Restore Purchases at the top of the screen. For billing, refunds, or Apple Account issues, please also consult Apple Support.

### Rewarded ads

Rewarded ads are optional. Availability may depend on the network, ad inventory, region, consent status, and device settings. No reward is granted when an ad is closed early or the SDK does not report completion.

When Google reports that privacy options must be available, the App displays a corresponding Privacy Settings button in its settings screen.

Apple's App Tracking Transparency (ATT) authorization is separate from Google UMP consent. The game remains available if tracking is declined, and the reward is unchanged when a rewarded ad is available and completed.

### Shared images

Record and arrangement sharing uses the iOS share sheet. If sharing fails, check the destination app, available device storage, and OS settings.

## Information to Include in an Inquiry

To the extent needed to investigate the issue, please include the following information.

- the screen and steps that caused the issue;
- any displayed message or reason code;
- the date and time;
- iPhone model and iOS version;
- App version and build number; and
- whether the issue remains after restarting the App.

Do not send an Apple Account password, credit card number, authentication code, or another secret. Before sending save data or screenshots, check that they contain no personal information.

We keep your message and email address only for as long as needed to respond to your inquiry and follow up. Once we no longer need this information, we make reasonable efforts to delete it promptly. To request deletion, please contact us at the support email address.

## Privacy

Privacy Policy: [Open the Privacy Policy](../privacy-policy/)

---

## 検証状況と公開前確認（公開ページには含めない）

### 確認済み

1. ソースコード上、「購入を復元」は「パンダのお店」内の鉢ショップ上部に表示され、日本語・ひらがな・英語の文言と復元処理を回帰テストで確認している。
2. リワード広告は任意視聴で、途中終了時は報酬を付与せず、視聴完了時だけ一度付与するコードと回帰テストがある。
3. TestFlight Build 83の実機で、UMP、ATT許可、Google公式テスト広告、視聴完了報酬まで成功している。ATT拒否時はコード・自動テストのみ確認済みで、実機未確認。
4. 問い合わせ窓口 `kotaro.hana.0505@gmail.com` でテストメールを受信できることを確認済み。

### 正式公開時に完了した確認

1. 運営者が日本語・英語本文、運営者名、問い合わせ先、保管・削除方針、および正式URLを最終承認した。
2. App Store ConnectのSupport URLとして `https://kotaro0505.github.io/puku-puku-taniku/support/` を使うことを承認した。
3. 最新Markdownから、下書き表示、`noindex`、作業用注記を含まない公開HTMLを再生成した。
4. サポートページとプライバシーポリシーを相互リンクした。

### App Store審査提出前に必要

1. 最終TestFlightまたは本番候補の実機画面で、「購入を復元」の位置・文言・操作結果を目視確認する。
2. ATT拒否状態でも、広告が利用可能な場合の報酬が変わらないことを実機確認する。
