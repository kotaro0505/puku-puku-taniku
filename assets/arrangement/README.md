# 寄せ植え画像の差し替え場所

- 横長の温室マスター背景: `res://assets/greenhouse_main_extended.png`
- 鉢PNG: `res://assets/arrangement/pots/succulent_arrange_pot_xxx.png`
- 多肉PNG: 既存のspecies画像をそのまま共有します。新種はspeciesデータの画像パスへ `succulent_sprite_xxx.png` を登録してください。

`greenhouse_main_extended.png` が無い間は既存の `greenhouse-main.jpg` を使い、寄せ植え作業台だけを簡易描画します。正式背景を配置すると、通常位置と左側作業台位置の切り替えに自動で使用されます。
