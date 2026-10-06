# 寄せ植え用の鉢画像

正式な背景透過 PNG をこのフォルダーへ配置します。既存鉢は `data/pots.json`、
追加の買い切り解放鉢は `data/pot-iap-catalog.json` の `image_path` を変更するだけで、
パンダのお店・鉢選択・編集画面・作品表示へ共通反映されます。

画像が存在しない間は、ゲーム内の共通プレースホルダーが表示されます。鉢名や価格は
画像へ描き込まず、Godot UI 側で表示します。

追加鉢の `iap_product_id` は App Store Connect の非消耗型商品IDと一致させます。
リアルマネー価格は画像・JSON・UIへ記載せず、StoreKitの `localized_price` だけを
表示します。買い切り後も実際の鉢個数は `price_puku` 分のぷくコインで購入します。
