# IAP審査画像・実機撮影パイロット

## 対象と範囲

第1段階は `pot_unlock_001`（クリスタルゴブレット鉢）だけを対象にする。`pot_unlock_002` 以降を順番に撮影する機能は含めない。通常の `iOS` / `iOS Development` ビルドでは撮影処理は起動しない。

撮影専用ビルドは次の三つで通常ビルドから分離する。

- Export Preset: `iOS IAP Review Capture`
- Feature tag: `puku_app_store_release,puku_iap_review_capture`
- Codemagic workflow: `ios-iap-review-capture`

通常のApp Store用 `iOS` presetのfeature tagは従来どおり `puku_app_store_release` だけである。CI検証は、このpresetに撮影用tagが混入した場合に失敗する。

Godot 4.7.2のiOS exporterは、表示名をexport presetの `application/name` ではなくProjectSettingsの `application/config/name` から生成する。撮影専用名 `ぷくぷく 撮影` は `project.godot` の `config/name.puku_iap_review_capture` で上書きし、通常ビルドの `ぷくぷく！たにくらいふ` には影響させない。生成後のXcode projectではDebug/Release両方の `INFOPLIST_KEY_CFBundleDisplayName` を期待値と照合する。

## 実機で行う処理

1. 本番と同じbundle IDでStoreKitの商品情報を取得する。
2. `pot_unlock_001` が `available` で、日本向けのローカライズ済み価格が100円表示であることを確認する。
3. 実ゲームの `パンダのお店 > 鉢` で使う `ArrangementUI` を開き、クリスタルゴブレット鉢のカード全体が見える位置までスクロールする。
4. 鉢画像、正式な日本語名、永続解放表示、2ぷくコイン表示、StoreKitの100円アンロックボタンをノード単位で検証する。
5. 購入ボタンの外観は保ったまま入力だけを無効化し、購入処理が起動しない状態にする。
6. root viewportを1フレーム待って取得し、`RGB8` に変換してPNGで保存する。
7. 解像度がAppleの対応するiPhone screenshot sizeであること、PNG IHDRが8-bit truecolor（color type 2、アルファなし）であることを再読込して検証する。
8. PNGと検証manifestを `user://iap-review-capture/` に保存する。
9. iOSの共有シートを開く。端末では「ファイルに保存」またはAirDrop等を選び、PNGを取り出す。

100円表示を取得するには、実機のSandbox/TestFlight購入用Apple Accountのストアフロントが日本である必要がある。日本以外のストアフロント価格が返った場合は撮影を停止し、別通貨の画像を保存しない。

出力名は次のとおり。

- `pot_unlock_001-app-review.png`
- `pot_unlock_001-app-review.json`

manifestには商品ID、表示名、StoreKit表示価格、ぷくコイン価格、画像寸法、PNG color type、SHA-256、各表示要素の検証結果を記録する。秘密情報や購入履歴は記録しない。

取り出したPNGは、同じフォルダーにmanifestを置いて次の読み取り専用コマンドでも再検証できる。

```powershell
node tools/verify_iap_review_capture.mjs pot_unlock_001-app-review.png
```

## iOS権限とGodot連携

撮影はiOSのスクリーンレコーディングAPIや写真ライブラリへ直接保存する方式ではない。Godotが自分のroot viewportを読み、アプリsandboxへ書き込むため、カメラ、マイク、写真ライブラリ、ReplayKitの追加権限は不要である。

取り出しには既存の `SharePlugin` が `UIActivityViewController` を開く。保存先はユーザーが共有シートで選択するため、アプリ側で写真ライブラリ権限を要求しない。共有シートを閉じてもPNGはその起動中のsandboxに残るため、画面の「PNGを共有」ボタンから再試行できる。

## セーブ・課金・広告の安全策

撮影専用featureが有効な間は、次を強制する。

- 通常のセーブnamespace移行を実行しない。
- `_save()` をno-opにし、既存セーブを更新しない。
- 旧版由来のローカル通知取消処理も実行せず、端末の通知状態を変更しない。
- 既存セーブは画面構築のため読み取りのみ可能だが、カード表示には空のデザイン解放状態を一時的に渡す。
- 商品購入APIを呼ばない。撮影前に購入ボタンの入力を無効化する。
- Rewarded Ads / UMPを初期化しない。
- 商品ID、StoreKit処理、ぷくコイン価格、カタログデータを変更しない。

## Codemagic

`ios-iap-review-capture` はGodot 4.7.2で専用Xcode projectと署名済みIPAを生成する。Xcode projectとIPAの出力先は `build/ios-iap-capture/` で、通常の `build/ios/` と分離される。

Codemagic CLIの `xcode-project build-ipa` は、`--ipa-directory` を省略するとXcode projectの場所に関係なく `build/ios/ipa` を使う。workflowの `IPA_DIR` はCLIが自動参照する変数ではないため、buildコマンドへ `--ipa-directory "$CM_BUILD_DIR/$IPA_DIR"` を明示する。生成後の存在確認、IPA情報表示、展開、署名検証は、この同じディレクトリから解決した唯一のIPAだけを使用する。0件なら `IOS_IPA_NOT_FOUND`、複数なら `IOS_IPA_AMBIGUOUS` で停止する。artifact収集も同じ `build/ios-iap-capture/ipa/*.ipa` を参照する。

このworkflowの `publishing` は空である。IPAをartifactとして作るだけで、TestFlightへのアップロード、App Storeへの提出、公開を自動実行しない。実機配布には、追加承認後にこのIPAを明示的にTestFlightへアップロードするか、許可された端末へ別途インストールする必要がある。

## カメラ・写真・マイク用途説明の警告

Godot 4.7.2のApple Embedded用Info.plistテンプレートは、`NSCameraUsageDescription`、`NSPhotoLibraryUsageDescription`、`NSMicrophoneUsageDescription` の3キーを常に出力する。現在のexport presetは `modules/camera=false` で、3種類の用途説明も設定していないため、生成値は空文字列になり、Xcodeのexport検証で警告される。

撮影機能はroot viewportをアプリsandbox内のPNGへ保存し、既存の `UIActivityViewController` で共有するだけである。カメラ、写真ライブラリ、マイク、ReplayKitのAPIは呼ばず、これらの権限プロンプトも要求しない。したがって、この警告はIPAパス不一致による今回の終了コード1とは別件であり、archiveまたはIPA生成を失敗させたものではない。

未使用権限に架空の用途説明を追加するのは適切ではない。警告を解消する場合は、Godotが生成したplistから空の未使用キーだけを除外する処理を、署名・archive前かつ全iOS workflowで一貫して検証する必要がある。今回は撮影用workflowのIPAパス修正に範囲を限定し、本番用plistや権限宣言は変更しない。

## 実機検証チェックリスト

- 撮影専用ビルド名が `ぷくぷく 撮影` である。
- 起動後、StoreKit価格取得中の専用画面が表示される。
- 実際の鉢ショップ画面に自動遷移する。
- クリスタルゴブレット鉢のカード全体、鉢画像、商品名、永久アンロック文、2ぷくコイン、100円ボタンが同時に写る。
- 購入シートが開かない。
- 共有シートからPNGを取り出せる。
- manifestの `product_id` が `pot_unlock_001`、`expected_japan_price_yen` が100である。
- PNG寸法が実機のApple対応寸法と一致する。
- PNGがRGB、8-bit、アルファなしである。
- 通常ビルドでは撮影画面が一切起動しない。
- 起動前後で通常セーブファイルの内容・更新日時が変わらない。

実機で上記を完了するまでは「撮影成功」と判定しない。残り35商品の連続撮影機能は追加承認後に実装する。
