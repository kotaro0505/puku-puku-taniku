# プライバシー／サポートページ公開計画

最終更新: 2026-11-13

## 現在の状態

- プライバシーポリシー公開原稿: `docs/privacy-policy-publication-candidate.md`
- サポート公開原稿: `docs/support-page-draft.md`
- 詳細な実装監査: `docs/privacy-policy-draft.md`（一部にATT実装・Build 83より前の検証状況が残るため、公開本文には直接使用せず、最新ソースと本計画で再照合する）
- 正式公開HTML: `privacy-policy/index.html`、`support/index.html`（承認済みMarkdownから再生成）
- プライバシーポリシー施行日: 2026年11月13日（日本時間）
- 既存のゲーム用GitHub Pagesルートファイルは変更していない
- 問い合わせ窓口 `kotaro.hana.0505@gmail.com` へのテストメールは受信確認済み。問い合わせ内容とメールアドレスは対応に必要な間だけ保管し、不要後は速やかな削除に努める方針とし、毎月の点検や問い合わせごとの固定期限管理は前提としない
- 公開HTMLは、ローカルHTTP 200、390×844 CSSピクセル、横はみ出しなし、日英セクション、メールリンク、相互リンクを確認済み
- 公開HTMLに `noindex`、下書き表示、作業用注記、外部スクリプト、アクセス解析、Cookie、問い合わせフォームが含まれないことを確認済み

TestFlight Build 83では、iPhone実機で `UMP -> ATT許可 -> Google Mobile Ads初期化 -> Google公式テスト広告 -> 報酬付与` まで成功している。ATT拒否・制限、UMPプライバシーオプションの再表示、最終release archiveのPrivacy Reportは未確認である。これらはApp Store審査提出前の重要な確認だが、内容が正確に限定されたプライバシーポリシーURLの先行公開とは分離する。AdMobの欧州向けメッセージへURLを設定するには、Googleも公開済みのプライバシーポリシーURLを要求しているため、公開ゲートと広告実機ゲートを循環させない。

2026-11-13にWindows版Godot 4.7.2で、`BUILD_PROFILE_SMOKE_OK`、`RELEASE_GATE_SMOKE_OK`、`REWARDED_AD_SERVICE_SMOKE_OK`、`POT_UNLOCK_IAP_SMOKE_OK`、`IOS_NATIVE_SMOKE_OK` を再実行し、すべて成功した。これはコードと設定の回帰確認であり、上記の実機未確認項目を代替しない。

## 正式公開先

| 用途 | 配置候補 | 完全なURL |
| --- | --- | --- |
| プライバシーポリシー | `privacy-policy/index.html` | `https://kotaro0505.github.io/puku-puku-taniku/privacy-policy/` |
| サポート | `support/index.html` | `https://kotaro0505.github.io/puku-puku-taniku/support/` |

これらはルートWeb版の `index.html`、`index.js`、`index.wasm`、`index.pck` を置き換えません。

## 正式公開時に完了したゲート

1. 運営者が更新後の日本語・英語本文、運営者名、問い合わせ先、保管・削除方針、および2つの公開URLを最終承認した。
2. 日本語と英語が同じ内容であり、現行ソースの広告、課金、セーブ、共有、通知の実装と一致することを再確認した。
3. 施行日を日本時間の公開日である2026年11月13日に確定した。
4. 検証状況、公開前ゲート、下書き表示、`noindex` 等の作業用内容を公開HTMLから除いた。
5. Apple App Review Guidelines 5.1.1(i)の第三者データ保護に関する日英本文を承認した。公開資料だけでは確認できない保護措置を確認済みとは記載していない。
6. `docs/privacy-policy-draft.md` の旧ステータスを公開判断の根拠にせず、公開原稿・最新ソース・最終IPAの確認結果を正として記録する。

App Store ConnectのApp Privacy、最終archiveのPrivacy Report、ATT拒否実機試験、UMP再表示実機試験、アプリ内リンクは審査提出前ゲートとして別に管理する。これらを未確認のままGO判定しないが、AdMob同意メッセージ設定に必要な静的ポリシーURLの公開とは分離する。

## HTML化と公開時の検証

1. 承認済みMarkdownからUTF-8、レスポンシブ表示、十分な文字サイズとコントラストを備えた静的HTMLを再生成する。
2. 外部スクリプト、アクセス解析、Cookie、問い合わせフォームは追加しない。問い合わせは `mailto:` リンクだけにする。
3. プライバシーポリシーとサポートページを相互リンクする。
4. `noindex`、下書き表示、公開前注記が残っていないことを確認する。
5. ローカルでHTML構文、見出し構造、言語属性、スキップリンク、キーボードフォーカス、外部リンク、メールリンク、モバイル幅を確認する。
6. 外部リンク以外の全リンクをローカル巡回し、404がないことを確認する。
7. ルートWeb版の起動と既存PCKを再確認する。
8. `main` へpush後、両URLがHTTPSで200を返し、スマートフォンで読めることを確認する。
9. AdMobのPrivacy & messagingへ正式なPrivacy Policy URLを登録し、IDFA事前説明へ日本語を追加して、非パーソナライズ広告と矛盾しない日英本文を公開する。
10. App Store ConnectのPrivacy Policy URLとSupport URLへ登録する。
11. 本番アプリ内のプライバシーポリシー導線を同じURLへ向ける。Google UMPのプライバシー設定ボタンとは別の導線として扱う。

## 公式要件の参照

- Apple App Privacy（Privacy Policy URLは全アプリで必須）: <https://developer.apple.com/help/app-store-connect/reference/app-information/app-privacy/>
- Apple App Review Guidelines 5.1.1（App Store Connectとアプリ内の分かりやすい場所にプライバシーポリシーを掲載）: <https://developer.apple.com/app-store/review/guidelines/>
- Apple Developer Program License Agreement: <https://developer.apple.com/support/terms/apple-developer-program-license-agreement/>
- Google AdMobのPrivacy Policy URL登録: <https://support.google.com/admob/answer/10113106>
- Google UMP（起動ごとの同意情報更新、`canRequestAds`、プライバシーオプション入口）: <https://developers.google.com/admob/ios/privacy>
- Google Mobile Ads SDKのApp Storeデータ開示: <https://developers.google.com/admob/ios/privacy/data-disclosure>
- Google Ads Controller-Controller Data Protection Terms（通常のAdMobを対象に含む）: <https://business.safety.google/adscontrollerterms/>
- Google Ads Data Protection Termsのサービス区分: <https://business.safety.google/adsservices/>
- GitHub General Privacy Statement: <https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement>
- GitHub Pages追加利用条件: <https://docs.github.com/en/site-policy/github-terms/github-terms-for-additional-products-and-features#pages>

## 正式公開後も別途行うこと

- App Store ConnectへのURL登録
- ゲームUIへのリンク追加
- Google AdMob、UMP、ATTまたはApp Privacy設定の変更
- App Store Connectへの審査提出または一般公開
