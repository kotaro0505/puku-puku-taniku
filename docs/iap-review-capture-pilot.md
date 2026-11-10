# IAP審査画像・36商品一括撮影

## 対象と分離

撮影専用ビルドは `pot_unlock_001`〜`pot_unlock_036` の36商品を1回の起動で撮影する。通常版からの分離は次の三つで維持する。

- Export Preset: `iOS IAP Review Capture`
- Feature tag: `puku_app_store_release,puku_iap_review_capture`
- Codemagic workflow: `ios-iap-review-capture`

通常のApp Store用 `iOS` presetは `puku_app_store_release` だけで、撮影処理を含まない。撮影版も開発機能を有効にせず、商品作成、購入、復元、広告初期化、セーブ更新を行わない。

## Apple要件と価格表示

AppleのApp Store Connect Helpは、IAP審査画像について「提供するアイテムまたはサービスが明確に分かるスクリーンショット」とし、アプリが対応するスクリーンショット仕様のいずれかを求めている。審査画像の通貨をJPYへ限定する規定は記載されていない。

StoreKit 2の `Product.displayPrice` は、端末が接続しているストアフロントに応じたローカライズ済み価格表示である。この撮影機能は次を守る。

- `localized_price` を加工せず、購入ボタンへそのまま表示する。
- 数値価格が正の実数、通貨コードとストアフロント国コードがISO形式の3文字であることを確認する。
- `USA` は `USD`、`JPN` は `JPY` であることを追加確認する。
- 36商品すべてで同じストアフロントと通貨が返ることを確認する。
- `true` など数値でない値、空の表示価格、途中で変化したストアフロント／通貨では撮影を停止する。
- USDをJPYへ置換したり、価格文字列を生成したりしない。

したがって、StoreKitが `USA / USD / 0.49 / $0.49` を返した場合は、その実価格を表示した画像を撮影対象として許可する。価格そのものを固定値と比較する処理はない。

公式資料:

- [In-App Purchase information](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information)
- [View and edit In-App Purchase information](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/view-and-edit-in-app-purchase-information)
- [StoreKit Product.displayPrice](https://developer.apple.com/documentation/storekit/product/displayprice)
- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)

## 実機で行う処理

1. 本番と同じBundle IDでStoreKit価格専用APIを36商品へ呼ぶ。購入権利照会と購入APIは呼ばない。
2. `pot_unlock_001`〜`pot_unlock_036` の欠番・重複、鉢ID、画像リソース、商品名、ぷくコイン価格をカタログと照合する。
3. 36商品のStoreKit価格応答がそろい、価格・通貨・ストアフロント検証を通った場合だけ実ショップ画面を開く。
4. 各商品のカードをスクロール領域内へ表示し、鉢画像、正式な日本語名、永続解放表示、ぷくコイン価格、StoreKit実価格を含む購入ボタンをノード単位で検証する。
5. 36商品の購入ボタンは外観を維持したまま入力を無効化する。透明な全画面入力ブロッカーも維持する。
6. 各カードを表示したroot viewportを取得し、RGB8 PNGとして保存する。
7. 各画像についてApple対応iPhone寸法、PNG IHDR、8-bit truecolor、アルファなし、SHA-256、商品IDとファイル名の対応を検証する。
8. 36枚と一括manifestをZIPへ格納し、ZIPを再度開いて欠番・重複・ファイル集合・PNG・SHA-256を再検証する。
9. 既存SharePluginへ `application/zip` として渡し、iOS共有シートを開く。

## 出力

アプリsandboxの `user://iap-review-capture/` に次を作成する。

- `pot_unlock_001-app-review.png`〜`pot_unlock_036-app-review.png`
- `iap-review-capture-manifest.json`
- `puku-iap-review-captures.zip`

ZIPには36枚のPNGと一括manifestだけを格納する。共有シートで「ファイルに保存」を1回選べばまとめて取り出せる。取り出したZIPを展開後、Windowsで次の読み取り専用検証を実行できる。

```powershell
node tools/verify_iap_review_capture.mjs <展開したフォルダー>
```

## セーブ・課金・広告の安全策

撮影専用featureが有効な間は次を強制する。

- 通常のセーブnamespace移行を実行しない。
- `_save()` をno-opにし、既存セーブを更新しない。
- 旧版由来のローカル通知取消処理を実行しない。
- カード表示には空のデザイン解放状態を一時的に渡す。
- 商品購入APIと復元APIを呼ばない。
- Rewarded Ads / UMPを初期化しない。
- 商品ID、StoreKit購入処理、36商品のカタログ、ぷくコイン価格を変更しない。

## 実機検証チェックリスト

- 撮影専用ビルド名が `ぷくぷく 撮影` である。
- 価格取得表示が `0 / 36` から進む。
- 端末の実ストアフロント、通貨、価格が表示され、固定価格へ置換されていない。
- 36商品を順番に自動撮影し、購入シートが一度も開かない。
- 完了画面に36商品の成功が表示される。
- 共有シートで `puku-iap-review-captures.zip` を「ファイルに保存」できる。
- ZIP内に36枚のPNGとmanifestがあり、欠番・重複がない。
- 展開後のローカル検証が `IAP_REVIEW_CAPTURE_VERIFY_OK products=36` で完了する。
- 通常ビルドでは撮影画面が起動しない。

Windows上のGodot回帰テストでは価格検証、36商品ID、PNG構造、ZIPの書込み・再読込み、通常版とのfeature分離まで確認する。StoreKit実応答、iOS実寸viewport、36枚の実画面、共有シートは次回TestFlight実機テストまで未確認とする。
