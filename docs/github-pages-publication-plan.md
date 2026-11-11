# プライバシー／サポートページ公開計画

最終更新: 2026-11-11

## 現在の状態

- 公開本文候補: `docs/privacy-policy-publication-candidate.md`
- サポート本文候補: `docs/support-page-draft.md`
- 詳細な実装監査: `docs/privacy-policy-draft.md`
- **正式なHTMLページは未生成・未公開**
- 既存のゲーム用GitHub Pagesルートファイルは変更していない

未確認のATT、App Privacy、年齢別広告取扱い、最終Privacy Reportを確定するまで、公開ページを生成しません。

## 承認後の公開先

| 用途 | 配置候補 | 完全なURL |
| --- | --- | --- |
| プライバシーポリシー | `privacy-policy/index.html` | `https://kotaro0505.github.io/puku-puku-taniku/privacy-policy/` |
| サポート | `support/index.html` | `https://kotaro0505.github.io/puku-puku-taniku/support/` |

これらはルートWeb版の `index.html`、`index.js`、`index.wasm`、`index.pck` を置き換えません。

## 公開ゲート

1. `docs/privacy-policy-publication-candidate.md` 末尾の公開前ゲートをすべて解消する。
2. 日本語と英語が同じ内容であることを再確認する。
3. 制定日・施行日を入力し、作業用注記を公開本文から除く。
4. `docs/support-page-draft.md` の公開前確認を完了する。
5. 運営者が本文と2つのURLを承認する。

## HTML化と公開時の検証

1. UTF-8、レスポンシブ表示、十分な文字サイズとコントラストで静的HTMLを作成する。
2. 外部スクリプト、アクセス解析、Cookie、問い合わせフォームは追加しない。問い合わせは `mailto:` リンクだけにする。
3. プライバシーポリシーとサポートページを相互リンクする。
4. ローカルでHTML構文、リンク、モバイル幅を確認する。
5. ルートWeb版の起動と既存PCKを再確認する。
6. `main` へpush後、両URLがHTTPSで200を返し、スマートフォンで読めることを確認する。
7. App Store ConnectのPrivacy Policy URLとSupport URLへ登録する。
8. 本番アプリ内のプライバシーポリシー導線を同じURLへ向ける。Google UMPのプライバシー設定ボタンとは別の導線として扱う。

## 今回行っていないこと

- 公開用HTMLの作成またはGitHub Pagesへの正式公開
- App Store ConnectへのURL登録
- ゲームUIへのリンク追加
- Google AdMob、UMP、ATTまたはApp Privacy設定の変更
