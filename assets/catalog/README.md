# Catalog image assets

図鑑・シリーズ専用の画像は `assets/catalog/<series_id>/` に配置します。

- `data/species-v2.json` の `image_path` は `res://assets/catalog/<series_id>/<file>.png` にする
- 透明背景PNGと元の解像度・画質を維持する
- Web exportではこのディレクトリを `index.pck` から除外し、GitHub Pages上の同じ相対パスから必要時に取得する
- ネイティブ版では従来どおり `res://` リソースとして読み込む

この規則に従えば、新シリーズの画像追加数はWeb版の `index.pck` サイズに影響しません。
