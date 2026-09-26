class_name GameLocalizer
extends RefCounted

const LANGUAGE_JA := "ja"
const LANGUAGE_HIRAGANA := "hiragana"
const LANGUAGE_EN := "en"
const SUPPORTED_LANGUAGES := [LANGUAGE_JA, LANGUAGE_HIRAGANA, LANGUAGE_EN]

const TEXT := {
	"ja": {
		"language_name": "日本語",
		"game_title": "ぷくぷく多肉",
		"opening_tap": "タップしてはじめる",
		"opening_story_tap": "タップしてつぎへ",
		"opening_story_1": "ある日、女の子は\n古い倉庫のすみで、\nほこりをかぶった一冊の本を見つけました。\n\n「なんだろう、これ……」",
		"opening_story_2": "ほこりを払い、\nみんなで本を見てみると——\n\nそれは、\n古い植物の本のようでした。",
		"opening_story_3": "ページを開くと、\nそこには見たことのない植物が\nたくさん描かれていました。\n\nぷっくりした葉。\n変わったかたち。\n不思議な色。\n\nそこには、\n「多肉植物」という言葉が。\n\n「こんな植物、本当にあったのかな……」",
		"opening_story_4": "そのころパンダも、\n別の場所で古いタネ袋を見つけていました。\n\n「これ、なんのタネだろう？」\n\n本に描かれた植物を見ながら、\n3人は顔を見合わせました。\n\n「もしかして……\nこの植物のタネかもしれない」\n\nそこで3人は、\nタネを分けて蒔いてみることにしました。",
		"panda_shop_name": "パンダのお店",
		"armadillo_name": "アルマジロ",
		"story_speaker_girl": "女の子",
		"story_speaker_panda": "パンダ",
		"story_speaker_armadillo": "アルマジロ",
		"story_speaker_trio": "3人",
		"jurejure_mouse_name": "ネズミ",
		"jurejure_skunk_name": "スカンク",
		"jurejure_peccary_name": "ペッカリー",
		"next": "つぎへ",
		"daily_seed_gift": "今日も来てくれてありがとう。\nたね袋 ×1 GET",
		"intro_old_seed": "3人で分けた古いたね。\nこれは、きみの分の1粒だよ。蒔いてみよう！",
		"intro_old_seed_get": "古い種 ×1 GET",
		"old_seed_reaction_sprout": "見て！芽が出たよ！",
		"old_seed_reaction_trio": "多肉植物だ！！",
		"old_seed_reaction_girl": "信じられない！",
		"old_seed_reaction_growth": "どんどん大きくなるよ！",
		"story_colorata_1": "本当に多肉植物のタネだったなんて！",
		"story_colorata_2": "この本によると、\nこれは『%s』っていう種類らしいよ！",
		"story_colorata_3": "すごい。\n世界に多肉植物が帰って来てくれたんだ……！",
		"story_trio_1": "聞いて！ ぼくのタネも育ったんだ！\nこの本によると『%s』っていうみたい。",
		"story_trio_2": "僕もだよ！『%s』っていう種類らしい。",
		"story_trio_3": "信じられない。長い間失われていた植物を\nこうして見られるなんて……。",
		"story_trio_4": "とってもきれい。そして、ぷくぷくしてて可愛いね！",
		"story_trio_5": "もう一度、この世界が多肉植物でいっぱいになってほしいね。",
		"story_habitat_found_1": "古い資料を調べていたら、\n昔、多肉が生えていたと言われる場所が分かったんだ！",
		"story_habitat_found_2": "ほんとに！？\n今度みんなで行ってみない？",
		"awakening_empty_1": "記録では、ここで間違いないはずなんだけど……。",
		"awakening_empty_2": "やっぱり何もないね……。",
		"awakening_overharvest": "人間による乱獲も、絶滅の大きな原因だったみたいだ……。",
		"awakening_sow": "最初に見つけた古いたねが、まだ少し残ってる。ここに蒔いてみよう。",
		"awakening_surprise": "なんだ！？",
		"awakening_memory": "……この場所、\n昔ここにあった多肉たちを\n思い出しているように見える……。",
		"awakening_thanks": "素敵な思い出を見せてくれて、ありがとう。",
		"awakening_apology": "昔、私たちの先祖が、\nここにいた多肉たちをたくさん持ち去ってしまって……\nごめんなさい。",
		"awakening_promise_1": "もう同じことはしない。",
		"awakening_promise_2": "これから新しく見つけた品種は、\nここにお返していきます。\nだから、また沢山の可愛い多肉植物を私たちにも見せてください！",
		"awakening_rain_stopping": "……雨、やんできた。",
		"awakening_sprout_look": "見て！",
		"awakening_sprout_panda": "あ、芽が出てる！",
		"seed_pod_story_1": "みて！ 空からなんか降りてきたよ！",
		"seed_pod_story_2": "タネのさや……かな？",
		"seed_pod_story_3": "こっちは……図鑑？",
		"mystery_catalog_prompt": "図鑑を見てみよう！",
		"mystery_catalog_tutorial_1": "見て。この図鑑、さっき育てた多肉が載ってる。",
		"mystery_catalog_tutorial_2": "コロラータたちだ！",
		"mystery_catalog_tutorial_3": "新しく見つけた多肉も、\nここに記録されていくみたいだ。",
		"mystery_catalog_tutorial_4": "不思議な図鑑だ…",
		"seed_origin_1": "不思議なさやの中に、タネができてる。",
		"seed_origin_2": "育てると、さやに光がたまっていくみたいだ。",
		"seed_origin_3": "育てて、また次のタネを受け取ろう！",
		"seed_origin_received": "さやのタネ ×3 GET",
		"special_origin_1": "これ……不思議な図鑑には載ってない。",
		"special_origin_2": "昔の多肉を戻してるだけじゃないんだ……。",
		"special_origin_3": "この原生地、今の世界を見て、\n新しい多肉まで作ってるみたい。",
		"jurejure_intro_panda_1": "あれ……？",
		"jurejure_intro_panda_2": "ここにあった多肉、なくなってない？",
		"jurejure_intro_traces": "地面には、変な足跡と落ちた葉。\n何かを引きずった跡もある。",
		"jurejure_intro_armadillo": "誰か来たのかな……。",
		"jurejure_intro_rustle": "奥で、ガサガサ……。",
		"jurejure_intro_silence": "……。",
		"jurejure_intro_mouse": "見つかったチュー！！",
		"jurejure_intro_skunk": "逃げるスカ！！",
		"jurejure_intro_peccary": "重いっぺーー！！",
		"jurejure_intro_panda_shout": "ちょっとーー！！",
		"jurejure_intro_mouse_return": "また来るチュー！",
		"jurejure_intro_name": "落とした札に『ジュレジュレ団』って書いてある……。",
		"jurejure_target_small": "ジュレジュレ団が%sを狙っています！",
		"jurejure_status_small": "狙われ中・タップで追い払う",
		"jurejure_panda_defend": "こらーー！！",
		"jurejure_taken_small": "%sが\nジュレジュレ団に獲られてしまった！",
		"jurejure_confront_armadillo": "せっかく原生地に多肉が戻ってきたんだ。\n勝手に持っていくなよ。",
		"jurejure_confront_peccary": "せっかく戻ってきたから頂きに来たんだっぺ。",
		"jurejure_confront_girl_1": "あなたたちみたいな人たちのせいで、\n昔、多肉植物は絶滅したのよ！",
		"jurejure_confront_skunk": "でも、ここに生えてるだけじゃ誰にも見てもらえない。\nそれでいいんスカ？",
		"jurejure_confront_mouse_panda": "パンダくん！ キミだって多肉で商売してるっチュー！",
		"jurejure_confront_panda": "……ダメだ。何を言っても通じない。",
		"jurejure_confront_girl_2": "とにかく、今取った多肉を原生地に返してあげて！",
		"jurejure_confront_mouse_battle": "ぷくぷくバトルでキミたちが勝ったら\n考えてあげるチュー！",
		"jurejure_challenge_1": "またキミたちか！\nしつこいやつらでチュー！",
		"jurejure_challenge_2": "ぷくぷくバトルで勝負だチュー！",
		"jurejure_battle_choice_title": "ぷくぷくバトルで勝負する？",
		"jurejure_battle_yes": "バトルする",
		"jurejure_battle_no": "バトルしない",
		"jurejure_battle_sow": "たねをまく",
		"jurejure_battle_enemy_score": "ジュレジュレ団　%.1f cm",
		"jurejure_battle_player_score": "あなた　%.1f cm",
		"jurejure_battle_win": "勝利！",
		"jurejure_battle_loss": "敗北……",
		"jurejure_battle_return": "原生地へ戻る",
		"jurejure_battle_win_mouse": "わかったわかった。\nさっき取ったやつは返すチュー。",
		"jurejure_battle_win_no_reward": "今回はキミたちの勝ちにしてやるチュー！",
		"jurejure_battle_loss_mouse": "ぜーんぶいただくチュー！",
		"jurejure_battle_loss_penalty": "ジュレジュレ団は原生地の多肉を%d株持ち去った。\nぷくコイン -%d",
		"jurejure_battle_loss_penalty_zero": "ジュレジュレ団は原生地の多肉を%d株持ち去った。\nぷくコインは0のまま。",
		"jurejure_mid_peccary": "これ、まだ小さいっぺ……。",
		"jurejure_mid_skunk": "これまで持っていくんスカ？",
		"jurejure_mid_mouse_1": "……。",
		"jurejure_mid_mouse_2": "今日は別のにするチュー！",
		"jurejure_late_skunk": "倒れてる株、起こしておくスカ。",
		"jurejure_late_peccary": "これはここに残すっぺ。",
		"jurejure_late_mouse": "べ、別に守ってるわけじゃないチュー！",
		"original_catalog_complete_4": "最初は何もなかった原生地に、\n今は多肉が生きている。",
		"jurejure_return_assume": "また持っていくつもり……？",
		"jurejure_return_mouse": "……返しに来たんじゃないチュー。\nここにあった方が、もっと増えそうだから置くだけチュー。",
		"jurejure_return_skunk": "最近、ここが寂しくなるの嫌なんスカ！",
		"jurejure_return_peccary": "いっぱい生えてる方が楽しいっぺ。",
		"jurejure_return_narration": "ジュレジュレ団は、持っていた多肉を原生地へ置いていった。",
		"second_awakening_light": "十分に多肉が戻った原生地を、色とりどりの光が走った。",
		"second_awakening_panda": "……これ、図鑑にない。",
		"second_awakening_armadillo": "昔ここにあった植物じゃない……。\n原生地が、今の世界から新しい姿を作り始めたんだ。",
		"second_awakening_mouse": "なんか出てきたチュー……。",
		"second_awakening_future": "原生地は、失われた過去だけでなく、\nまだ存在しなかった未来を芽吹かせ始めた。",
		"objective_title": "つぎの目標",
		"objective_old_seed": "古いたねを育てよう",
		"objective_trio": "3人の原種を確認しよう",
		"objective_find_habitat": "昔の原生地へ行こう",
		"objective_awaken": "原生地を目覚めさせよう",
		"objective_originals": "原種を%d種類復活させよう　%d / %d",
		"objective_size": "どれか1株を%dcmまで育てよう　%.1f / %dcm",
		"objective_complete": "失われた原種がそろいました",
		"objective_second_awakening": "原生地で起きていることを確かめよう",
		"story_complete_1": "全部……そろった。",
		"story_complete_2": "昔の図鑑に残っていた原種が、\n全部この世界に戻ってきたんだ。",
		"story_complete_3": "最初は、絵の中でしか知らなかったのにね。\n今はちゃんと、ここにいる。",
		"story_complete_4": "でも原生地は、まだ新しい多肉を生み続けている。\nこれからも一緒に見つけていこう。",
		"tutorial_normal_sow_1": "ここに蒔けばいいのかな……？",
		"tutorial_normal_sow_2": "やってみよう！",
		"tutorial_normal_sprout": "芽が出た！",
		"tutorial_normal_growth": "どんどん大きくなってる……。",
		"tutorial_normal_jelly": "突然溶けてしまうこともあるって書いてあったよ。\n『ジュレる』って言うみたい。",
		"tutorial_harvest_tap": "育った株をタップで収穫！",
		"main_play": "たねをまく",
		"main_shop": "パンダのお店",
		"main_arrangement": "寄せ植え",
		"main_forest_gacha": "森のガチャ\n1ぷく",
		"main_secret_gacha": "秘密のガチャ",
		"main_secret_gacha_unavailable": "秘密のガチャ\n今は見つからない",
		"main_habitat": "原生地へ",
		"main_greenhouse": "温室へ",
		"settings": "設定",
		"back": "もどる",
		"close": "とじる",
		"continue": "つづける",
		"puku_gauge": "ぷくゲージ",
		"seed_pod_gauge": "さやゲージ",
		"wallet": "所持　%dぷくコイン",
		"forest_gacha": "森のガチャ",
		"secret_gacha": "秘密のガチャ",
		"gacha_spin": "1ぷくコインで回す",
		"gacha_dial_hint": "ダイヤルをタップして回そう",
		"secret_gacha_dial_hint": "重いダイヤルを回そう",
		"gacha_capsule_hint": "カプセルをタップ！",
		"secret_remaining": "あと %d回",
		"secret_unlimited": "いつでも遊べる",
		"get": "GET!",
		"new": "NEW!",
		"original_catalog_new": "NEW！",
		"super_rare": "スーパーレア",
		"tap_to_close": "タップしてとじる",
		"habitat_intro_1": "芽が出た！",
		"habitat_observe_size": "現在 %.1fcm",
		"habitat_observe_note": "自然の中で、ゆっくり育っています。",
		"puku_intro_1": "これからは育てた多肉をうちのお店で買い取るよ！",
		"puku_intro_2": "このゲージが満タンになったら3ぷくコインと交換しよう！",
		"first_habitat_gift_1": "さやの中に、最初のタネができてる！",
		"first_habitat_gift_2": "12粒入りのタネを4袋受け取ったよ。\n育ててみよう！",
		"first_habitat_gift_received": "通常のたね 12粒入り ×4袋 GET",
		"initial_seed_stock_received": "通常のたね 12粒入り ×4袋 GET",
		"seed_pod_glow_1": "さやが光ってる……。",
		"seed_pod_glow_2": "育てると、少しずつ光がたまっていくのかな。",
		"seed_pod_first_reward": "タネができてる！",
		"puku_buyback_1": "これからは育てた多肉をうちのお店で買い取るよ！",
		"puku_buyback_2": "このゲージが満タンになったら3ぷくコインと交換しよう！",
		"pinwheel_received": "ピンウィールを手に入れた！",
		"mystery_seed_owned": "おや、なぞのたねを持っているようだね。",
		"mystery_seed_request": "研究のために、そのたねを預けてもらえないか？",
		"share_prompt": "タニ友に自慢しよう！",
		"share_record": "自己最高記録！",
		"share_harvest": "%.1fcmの%sを収穫！",
		"share_fallback": "共有画像を保存しました",
		"language_heading": "ことば",
		"language_saved": "ことばの設定を保存しました",
		"narration": ""
		,"tutorial_play2": "育てるの、上手だね！\nアルマジロが昔の原生地について調べてくれているよ。"
		,"tutorial_play3": "準備できたよ！多肉の原生地へ行けるようになったよ。\n原生地を見に行ってみよう。"
		,"armadillo_intro_panda_1": "アルマジロから、古い資料の研究報告があるみたいだよ。"
		,"armadillo_intro_panda_2": "昔の植物や古いタネをずっと調べてくれているんだ。"
		,"armadillo_intro_self": "古い記録を調べていたら、気になる原種の手がかりを見つけたんだ。"
		,"armadillo_pinwheel_gift": "記録をたどって復活できたピンウィールだ。\nきみに育ててほしい。"
		,"armadillo_mystery_1": "いま原生地に落ちている『謎のたね』を研究しているんだ。"
		,"armadillo_mystery_2": "もし見つけたら持ってきてくれないか？"
		,"armadillo_seven_panda": "アルマジロ君から、また研究のお話があるみたいだよ。"
		,"armadillo_seven_found": "原生地で、見たことのない不思議な品種を見つけたんだ。"
		,"armadillo_seven_species": "%sという品種だよ。\n君にこの株をプレゼントするね！"
		,"armadillo_seven_catalog": "それから『%s』も一緒に渡すよ。\nこれで仲間を記録できるはずだ。"
		,"armadillo_seven_end": "やっぱり、あの原生地には\n不思議な力があるのかもしれない。\nよーし、まだまだ研究を続けるぞ！"
		,"catalog": "図鑑"
		,"best_record": "最高記録\n%.1f cm"
		,"puku_count": "ぷくコイン ×%d"
		,"puku_gain": "ぷくコイン +%d"
		,"puku_gauge_reward": "ぷくコイン +%d"
		,"seed_pod_gauge_reward": "12粒入りたね袋 +%d"
		,"play_choose_seed": "どのたねをまく？"
		,"seed_remaining": "たね袋\n残り %d粒"
		,"series_seed_remaining": "シリーズ種\n残り %d粒"
		,"play_old_seed": "古いたねをまく　1粒　残り%d袋"
		,"play_normal_seed": "たねをまく　12粒　残り%d袋"
		,"play_volume_seed": "ボリュームパックをまく　36粒　残り%d袋"
		,"play_premium_seed": "プレミアムたねをまく　24粒　残り%d袋"
		,"play_mystery_seed": "謎種パックをまく　5粒　残り%d袋"
		,"old_seed_name": "古いたね"
		,"bags_held": "%s %d袋"
		,"shop_choose_category": "なにを見ますか？"
		,"shop_category_pot": "鉢\n寄せ植え"
		,"shop_category_catalog": "図鑑\n新シリーズ"
		,"shop_category_gacha": "森の\nガチャ"
		,"shop_category_back": "カテゴリへもどる"
		,"shop_seed_info": "通常のタネは、さやゲージが満ちるとできます"
		,"normal_seed_price": "通常のタネは販売していません"
		,"price_tbd": "ぷく価格は準備中"
		,"locked": "未解禁"
		,"buy_bundle": "買う\n3袋  1ぷくコイン"
		,"bought": "購入済み"
		,"buy_puku": "買う　%dぷくコイン"
		,"all_pots_one_puku": "すべての鉢は1ぷくコインです"
		,"result_title": "今回の収穫"
		,"result_notable_title": "目立った収穫株"
		,"result_close": "閉じる / 戻る"
		,"result_total": "収穫サイズ合計　+%scm\nぷくゲージ +%scm　/　ぷくコイン +%d"
		,"result_total_before_items": "収穫サイズ合計　+%scm"
		,"result_count": "収穫株数　%d株"
		,"result_best_update": "最大サイズ更新！\n%.1fcm"
		,"result_max": "最大サイズ　%.1fcm"
		,"result_none": "今回はまだありません"
		,"result_registered": "%sを図鑑登録！"
		,"share_creating": "共有画像を作っています…"
		,"share_failed": "共有画像を作れませんでした"
		,"share_opened": "共有画面を開きました"
		,"share_opening": "共有画面を開いています…"
		,"share_complete": "共有しました"
		,"share_canceled": "共有をキャンセルしました"
		,"share_native_failed": "共有画面を開けませんでした"
		,"share_web_opened": "共有画面を開きました（非対応ブラウザでは画像を保存します）"
		,"encyclopedia_title": "ぷくぷく図鑑"
		,"catalog_cover_preparing": "表紙画像\n準備中"
		,"catalog_locked": "未開放"
		,"catalog_locked_preparing": "未開放\n表紙画像 準備中"
		,"catalog_field": "このシリーズの原生地へ"
		,"catalog_unlock_status": "初めてGETした品種は、不思議な図鑑へ自動で記録されます"
		,"catalog_preparing": "このシリーズは準備中です"
		,"catalog_buy": "初GETで自動記録"
		,"self_best": "自己ベスト  %.1f cm"
		,"self_best_none": "自己ベスト　ー"
		,"undiscovered": "未発見"
		,"list_back": "一覧へ"
		,"harvest_to_gauge": "+%scm\nぷくゲージへ"
		,"record_update": "収穫記録更新！\nNEW RECORD\n%.1f cm"
		,"mystery_seed_get": "謎のたね GET!"
		,"old_catalog_page_get": "新しいシリーズを図鑑に記録した！"
		,"gacha_draw_count": "ガチャ %d回"
		,"gacha_selecting": "森の実りを選んでいます…"
		,"unlock_action": "自動で記録"
		,"later": "あとで"
		,"gacha_return": "ガチャへ戻る"
		,"encountered": "遭遇済み"
		,"locked_series": "未解放シリーズ"
		,"locked_offer": "『%s』の新品種です。\n不思議な図鑑へ記録されます。"
		,"forest_catalog_missing": "この図鑑は見つかりませんでした"
		,"forest_unlock_need5": "新品種は自動で図鑑へ記録されます。"
		,"forest_unlock_complete_one": "『%s』を解放しました！\nこの品種を図鑑に登録しました。"
		,"forest_unlock_complete_many": "『%s』を解放しました！\n遭遇済みの%d品種を登録しました。"
		,"forest_deferred": "この品種は不思議な図鑑へ自動で記録されます。"
		,"secret_turning": "ゴト…ゴトゴト……"
		,"secret_catalog_page_prize": "%sの記録"
		,"secret_prize": "秘密の景品"
		,"arrangement_title": "寄せ植え"
		,"arrangement_complete": "寄せ植え完成！"
		,"arrangement_new": "新しく作る"
		,"arrangement_saved": "保存した寄せ植え"
		,"arrangement_summary": "%d / %d作品　・　購入済みの鉢 %d個"
		,"arrangement_empty": "まだ作品はありません。\n図鑑登録した多肉で、最初の寄せ植えを作ってみよう。"
		,"view": "見る"
		,"choose_pot": "鉢を選ぶ"
		,"owned_pot_hint": "購入済みの鉢から選んでください"
		,"choose": "選ぶ"
		,"arrangement_name": "寄せ植えの名前"
		,"complete": "完成"
		,"add_succulent": "多肉を追加"
		,"size": "大きさ"
		,"rotate": "回転"
		,"rotate_left": "左回り"
		,"rotate_right": "右回り"
		,"send_back": "奥へ"
		,"bring_front": "手前へ"
		,"delete": "削除"
		,"arrangement_editor_hint": "タップで選択・ドラッグで移動・2本指で拡大縮小／回転"
		,"arrangement_pinch_hint": "2本指の動きに合わせて大きさと向きを調整できます"
		,"arrangement_deleted": "株を削除しました"
		,"arrangement_max_plants": "1作品には最大%d株まで置けます"
		,"picker_title": "多肉を選ぶ"
		,"edit_back": "編集へ"
		,"picker_hint": "図鑑登録済みの品種は何度でも使えます"
		,"all": "すべて"
		,"picker_empty": "このシリーズには、まだ使える多肉がありません"
		,"no_record_min": "記録なし・最小サイズ"
		,"max_cm": "最大 %.1fcm"
		,"image_preparing": "画像準備中"
		,"arrangement_added": "%sを追加しました。選択したまま直接ドラッグできます"
		,"viewer_title": "完成した寄せ植え"
		,"pot_shop_title": "寄せ植え用の鉢"
		,"catalog_shop_title": "シリーズ記録"
		,"seed_shop_title": "どうぐ"
		,"catalog_shop_hint": "新しいシリーズは初GET時に自動で記録されます"
		,"product_image_preparing": "商品画像\n準備中"
		,"catalog_page_product": "シリーズ記録"
		,"seed_bag_count": "たね袋\n%d粒"
		,"pot_count": "%s　・　%d株"
		,"arrangement_gesture_transform": "大きさと向きを調整しました"
		,"arrangement_gesture_move": "位置を調整しました"
		,"pot_image_preparing": "鉢画像 準備中"
		,"shop_tab_normal": "普通"
		,"shop_tab_volume": "ボリューム"
		,"shop_tab_premium": "プレミアム"
		,"shop_tab_mystery": "謎種"
		,"shop_category_short": "カテゴリ"
		,"shop_catalog_preparing": "図鑑は初GETで\n自動記録されます"
		,"yes": "はい"
		,"no": "いいえ"
		,"restore": "復元する"
		,"ad_seed": "広告を見て種をもらう"
		,"ad_preparing": "広告を準備中…"
		,"seed_normal_card": "12粒入り×3袋・所持 %d袋\n不思議なさやにできる基本のたね袋"
		,"seed_volume_card": "36粒入り・所持 %d袋\n%s"
		,"seed_premium_card": "24粒入り・所持 %d袋\n%s"
		,"seed_mystery_card": "5粒入り・所持 %d袋\n%s"
		,"seed_series_name": "%sの種"
		,"seed_series_card": "1粒・所持 %d粒\n不思議なさやから入手"
		,"unlock_after_plays": "あと%d回プレイで解禁"
		,"unlock_mystery_species": "謎品種を1種発見で解禁"
		,"not_enough_puku": "ぷくコインが足りません"
		,"seed_series_price_tbd": "タネは不思議なさやから受け取れます"
		,"seed_price_tbd": "タネは不思議なさやから受け取れます"
		,"seed_normal_bought": "普通のたねを%d袋購入しました"
		,"seed_normal_detail": "普通のたね　12粒 × 3袋\n不思議なさやにできる基本のたね。いろんな多肉が育ちます。\n金星1つ10%　金星2つ5%　新品種4%"
		,"seed_volume_detail": "ボリュームパックたね　36粒 / 袋\n原生地のたねをたっぷり袋詰め。じっくり大物を狙えます。\nレア10%　スーパーレア5%　新種 約3%"
		,"seed_premium_detail": "プレミアムたね　24粒 / 袋\n原生地のたねから、パンダが珍しそうな粒を選びました。\nレア30%　スーパーレア10%　新種 約3%"
		,"seed_mystery_detail": "謎種パック　5粒 / 袋\n何が育つかわからない、不思議なたね。\n発見済みのパック対象・謎品種100%"
		,"pot_missing": "この鉢は見つかりませんでした"
		,"pot_owned": "この鉢は購入済みです"
		,"pot_locked": "この鉢はまだ購入できません"
		,"pot_price_tbd": "この鉢のぷく価格は準備中です"
		,"pot_bought": "%sを購入しました"
		,"catalog_bought": "%sを購入しました%s"
		,"catalog_encounters_registered": "（遭遇済み%d品種も登録）"
		,"research_reward_title": "研究のお礼"
		,"research_reward_note": "好きな図鑑を1冊えらんでね"
		,"research_reward_later": "あとで選ぶ"
		,"research_reward_empty": "今、新しく記録できるシリーズはありません。"
		,"research_reward_choose": "%s\nこの図鑑をもらう"
		,"research_reward_claimed": "%sをどうぞ。\n未発見の品種は、図鑑のシルエットを手がかりに探してみてね。"
		,"result_hidden_registered": "%sを図鑑登録！"
		,"mystery_route_best": "100cmなんてすごいね！\nなんだか原生地でも、不思議なことが起きてるみたいだよ。"
		,"mystery_route_default": "不思議な多肉を見つけたね。まだ知らないことがたくさんありそうだよ。"
		,"arrangement_default_name": "寄せ植え %d"
		,"shop_rescue_offer": "タネなくなっちゃった？\n少し分けてあげるよ！"
		,"shop_rescue_success": "はい、どうぞ！大事にまいてみてね。"
		,"shop_chatter_touch": "多肉を触ってみて柔らかくなっていたら水やりのタイミングだよ"
		,"shop_chatter_welcome": "いらっしゃい！"
		,"shop_chatter_edible": "知ってる？食べられる多肉もあるんだって。"
		,"shop_chatter_encounter": "今日はどんな多肉に出会えるかなあ。"
		,"shop_chatter_seasons": "多肉を育ててると、よけいに季節を感じられるって思うんだ。"
		,"shop_chatter_water": "多肉植物は水をあげすぎるとジュレるから気をつけてね！"
		,"shop_chatter_growing": "多肉植物栽培、慣れてきた？"
		,"shop_chatter_world": "古い資料には、ものすごい数の多肉が記録されてるんだって。すごいなあ。"
		,"shop_chatter_leaf": "多肉の葉っぱを土に挿しておくと、根が出て増えるんだ。葉挿しって言うんだよ。"
		,"shop_chatter_affinis": "アフィニスの花って真っ赤なんだって。見てみたいね！"
		,"shop_chatter_browse": "やあ！ゆっくり見てってよ。"
		,"shop_season_new_year": "あけましておめでとう！今年もよろしくね！"
		,"shop_season_autumn": "朝晩が涼しい日が増えてきたね。紅葉が楽しみだね！"
		,"shop_season_summer_heat": "毎日暑いね。熱中症には気をつけてね！"
		,"shop_season_summer_water": "夏の水やりは夕方から夜にやるといいよ！"
		,"shop_season_winter": "毎日寒いけど多肉の色が賑やかな季節だね。"
		,"shop_season_spring": "だんだんと暖かい日が増えてきたね。多肉もどんどん育つね！"
		,"old_page_intro_1": "これ、原生地で拾ったんだ。\n古くて汚れているけど、図鑑のページみたいじゃない？"
		,"old_page_intro_2": "アルマジロ君なら、きっと元の図鑑に復元できると思うよ。"
		,"volume_intro_1": "不思議なさやに、たくさんのタネができたよ！"
		,"volume_intro_2": "36粒入ってるから、普通のたねよりたっぷり楽しめるよ。\nこれなら、じっくりどデカい多肉を育てられるね！"
		,"bustamante_gift": "いつも来てくれてありがとう。\nストリクチフローラ ブスタマンテを1株、君にあげるよ。"
		,"pinwheel_intro_1": "古い資料を調べていたら、育て方の手がかりを見つけたんだ。"
		,"pinwheel_intro_2": "ぼくたちのタネで試してみたら、また一株育てられたよ。"
		,"pinwheel_intro_3": "図鑑で照合すると、ピンウィールという原種らしい。\nきみに託すよ。"
		,"armadillo_idle_1": "また会えたね。ゆっくりしていって！"
		,"armadillo_idle_2": "今日の多肉も元気そうだね。"
		,"armadillo_idle_3": "土の匂いって落ち着くよね。"
		,"research_intro_1": "おや？ そのたね……。\nもしかして、原生地で拾ったのかい？"
		,"research_intro_2": "じつはぼく、この『謎のたね』を研究してるんだ。\nまだ、何の種なのかはわからないんだけどね。"
		,"research_intro_3": "よかったら、そのたねを研究させてもらえないかな？"
		,"research_return_offer": "謎のたねを持ってきてくれたんだね。\n研究のために、まとめて預かってもいいかい？"
		,"restore_offer": "この記録は、不思議な図鑑へ自動で反映されるよ。"
		,"restore_shortage": "この記録は、不思議な図鑑へ自動で反映されるよ。"
		,"restore_success": "復元できたよ！\nこれは『%s』のページだったんだ。\nまだ見つけていない品種も、影から少しずつ調べられそうだね。"
		,"research_status_sprouted": "聞いてよ！\nやっと、たねが発芽したんだ！\n大きくなるのをお楽しみに！"
		,"research_status_growing": "ありがとう。\n順調に育ってるよ！"
		,"research_status_trying": "ありがとう！\n発芽させられるように頑張るから、また持ってきてよ！"
		,"research_status_world": "古い記録にもない姿が、まだ生まれているんだね。\n謎のたねを見つけたら、また持ってきてよ！"
		,"research_status_progress": "ありがとう！\n研究が少しずつ進んでいるよ。\nまた謎のたねを持ってきてくれるとうれしいな！"
		,"research_status_thanks": "ありがとう！\nまた謎のたねを見つけたら、持ってきてくれるとうれしいな！"
		,"research_status_first": "ありがとう！\n謎のたねを%d個受け取ったよ。\nたくさん集まれば、何かわかるかもしれない。\nまた拾ったら、持ってきてくれるとうれしいな！"
		,"research_milestone_catalog": "研究を手伝ってくれたお礼に、好きな図鑑を1冊あげるよ。"
		,"research_milestone_habitat": "原生地に新しい品種が生えてたよ。"
		,"research_milestone_seed_instead": "新しい通常品種は全部見つかっているから、代わりにたねを1袋どうぞ。"
		,"research_milestone_sprout": "研究していた謎のたねが、ついに発芽したよ！"
		,"research_milestone_species": "おどろいたよ。研究してたたねから、こんな多肉が育つなんて……。\n%s、これ君にあげるよ！"
		,"research_milestone_gold": "びっくりだ。金色のラウイ……！？ これ、あげる！"
		,"research_milestone_seed": "研究のお礼に、たねを1袋どうぞ。"
		,"research_transfer": "渡した謎のたね ×%d個"
		,"audio_bgm": "BGM"
		,"audio_bgm_on": "BGM ON"
		,"audio_se": "効果音"
		,"audio_se_on": "効果音 ON"
		,"audio_note": "音源はモード・効果ごとに後から差し替えできます"
		,"unlock_five_puku": "初GETで自動記録"
		,"unlock_restore_page": "初GETで自動記録"
		,"unlock_progress": "ゲームを進めると閲覧可能"
		,"unlock_future": "開放条件は今後追加予定"
		,"jelly_float": "ジュレ"
		,"preview_finished": "プレビュー終了"
		,"preview_jelly": "ジュレ（プレビュー）"
		,"understood": "わかった"
	},
	"hiragana": {
		"language_name": "ひらがな",
		"game_title": "ぷくぷくたにく",
		"opening_tap": "タップして はじめる",
		"opening_story_tap": "タップして つぎへ",
		"opening_story_1": "あるひ、おんなのこは\nふるい そうこの すみで、\nほこりを かぶった いっさつの ほんを みつけました。\n\n「なんだろう、これ……」",
		"opening_story_2": "ほこりを はらい、\nみんなで ほんを みてみると——\n\nそれは、\nふるい しょくぶつの ほんのようでした。",
		"opening_story_3": "ぺーじを ひらくと、\nそこには みたことのない しょくぶつが\nたくさん えがかれていました。\n\nぷっくりした は。\nかわった かたち。\nふしぎな いろ。\n\nそこには、\n「たにくしょくぶつ」という ことばが。\n\n「こんな しょくぶつ、ほんとうに あったのかな……」",
		"opening_story_4": "そのころ ぱんだも、\nべつの ばしょで ふるい たねぶくろを みつけていました。\n\n「これ、なんの たねだろう？」\n\nほんに えがかれた しょくぶつを みながら、\n3にんは かおを みあわせました。\n\n「もしかして……\nこの しょくぶつの たねかもしれない」\n\nそこで3にんは、\nたねを わけて まいてみることに しました。",
		"panda_shop_name": "ぱんだの おみせ",
		"armadillo_name": "あるまじろ",
		"story_speaker_girl": "おんなのこ",
		"story_speaker_panda": "ぱんだ",
		"story_speaker_armadillo": "あるまじろ",
		"story_speaker_trio": "3にん",
		"jurejure_mouse_name": "ねずみ",
		"jurejure_skunk_name": "すかんく",
		"jurejure_peccary_name": "ぺっかりー",
		"next": "つぎへ",
		"daily_seed_gift": "きょうも きてくれて ありがとう。\nたねぶくろを 1ふくろ もらったよ",
		"intro_old_seed": "3にんで わけた ふるい たね。\nこれは、きみのぶんの 1つぶだよ。まいてみよう！",
		"intro_old_seed_get": "ふるい たね ×1 げっと",
		"old_seed_reaction_sprout": "みて！めが でたよ！",
		"old_seed_reaction_trio": "たにくしょくぶつだ！！",
		"old_seed_reaction_girl": "しんじられない！",
		"old_seed_reaction_growth": "どんどん おおきくなるよ！",
		"story_colorata_1": "ほんとうに たにくしょくぶつの たねだったなんて！",
		"story_colorata_2": "この ほんによると、\nこれは『%s』っていう しゅるいらしいよ！",
		"story_colorata_3": "すごい。\nせかいに たにくしょくぶつが かえってきてくれたんだ……！",
		"story_trio_1": "きいて！ ぼくの たねも そだったんだ！\nこの ほんによると『%s』っていうみたい。",
		"story_trio_2": "ぼくもだよ！『%s』っていう しゅるいらしい。",
		"story_trio_3": "しんじられない。ながいあいだ うしなわれていた しょくぶつを\nこうして みられるなんて……。",
		"story_trio_4": "とっても きれい。そして、ぷくぷくしてて かわいいね！",
		"story_trio_5": "もういちど、この せかいが たにくしょくぶつで いっぱいに なってほしいね。",
		"story_habitat_found_1": "ふるい しりょうを しらべていたら、\nむかし、たにくが はえていたと いわれる ばしょが わかったんだ！",
		"story_habitat_found_2": "ほんとに！？\nこんど みんなで いってみない？",
		"awakening_empty_1": "きろくでは、ここで まちがいないはずなんだけど……。",
		"awakening_empty_2": "やっぱり なにも ないね……。",
		"awakening_overharvest": "にんげんによる らんかくも、ぜつめつの おおきな げんいんだったみたいだ……。",
		"awakening_sow": "さいしょに みつけた ふるい たねが、まだ すこし のこってる。ここに まいてみよう。",
		"awakening_surprise": "なんだ！？",
		"awakening_memory": "……この ばしょ、\nむかし ここに あった たにくたちを\nおもいだしているように みえる……。",
		"awakening_thanks": "すてきな おもいでを みせてくれて、ありがとう。",
		"awakening_apology": "むかし、わたしたちの せんぞが、\nここにいた たにくたちを たくさん もちさってしまって……\nごめんなさい。",
		"awakening_promise_1": "もう おなじことは しない。",
		"awakening_promise_2": "これから あたらしく みつけた ひんしゅは、\nここに おかえししていきます。\nだから、また たくさんの かわいい たにくしょくぶつを わたしたちにも みせてください！",
		"awakening_rain_stopping": "……あめ、やんできた。",
		"awakening_sprout_look": "みて！",
		"awakening_sprout_panda": "あ、めが でてる！",
		"seed_pod_story_1": "みて！ そらから なんか ふってきたよ！",
		"seed_pod_story_2": "たねの さや……かな？",
		"seed_pod_story_3": "こっちは……ずかん？",
		"mystery_catalog_prompt": "ずかんを みてみよう！",
		"mystery_catalog_tutorial_1": "みて。この ずかん、さっき そだてた たにくが のってる。",
		"mystery_catalog_tutorial_2": "ころらーたたちだ！",
		"mystery_catalog_tutorial_3": "あたらしく みつけた たにくも、\nここに きろくされていくみたいだ。",
		"mystery_catalog_tutorial_4": "ふしぎな ずかんだ…",
		"seed_origin_1": "ふしぎな さやの なかに、たねが できてる。",
		"seed_origin_2": "そだてると、さやに ひかりが たまっていくみたいだ。",
		"seed_origin_3": "そだてて、また つぎの たねを うけとろう！",
		"seed_origin_received": "さやの たね ×3 げっと",
		"special_origin_1": "これ……ふしぎな ずかんには のってない。",
		"special_origin_2": "むかしの たにくを もどしてるだけじゃないんだ……。",
		"special_origin_3": "この げんせいち、いまの せかいを みて、\nあたらしい たにくまで つくってるみたい。",
		"jurejure_intro_panda_1": "あれ……？",
		"jurejure_intro_panda_2": "ここに あった たにく、なくなってない？",
		"jurejure_intro_traces": "じめんには、へんな あしあとと おちた は。\nなにかを ひきずった あとも ある。",
		"jurejure_intro_armadillo": "だれか きたのかな……。",
		"jurejure_intro_rustle": "おくで、がさがさ……。",
		"jurejure_intro_silence": "……。",
		"jurejure_intro_mouse": "みつかったチュー！！",
		"jurejure_intro_skunk": "にげるスカ！！",
		"jurejure_intro_peccary": "おもいっぺーー！！",
		"jurejure_intro_panda_shout": "ちょっとーー！！",
		"jurejure_intro_mouse_return": "また くるチュー！",
		"jurejure_intro_name": "おとした ふだに『じゅれじゅれだん』って かいてある……。",
		"jurejure_target_small": "じゅれじゅれだんが%sを ねらっています！",
		"jurejure_status_small": "ねらわれちゅう・おして おいはらう",
		"jurejure_panda_defend": "こらーー！！",
		"jurejure_taken_small": "%sが\nじゅれじゅれだんに とられてしまった！",
		"jurejure_confront_armadillo": "せっかく げんせいちに たにくが もどってきたんだ。\nかってに もっていくなよ。",
		"jurejure_confront_peccary": "せっかく もどってきたから いただきに きたんだっぺ。",
		"jurejure_confront_girl_1": "あなたたちみたいな ひとたちの せいで、\nむかし、たにくしょくぶつは ぜつめつしたのよ！",
		"jurejure_confront_skunk": "でも、ここに はえてるだけじゃ だれにも みてもらえない。\nそれで いいんスカ？",
		"jurejure_confront_mouse_panda": "ぱんだくん！ キミだって たにくで しょうばいしてるっチュー！",
		"jurejure_confront_panda": "……だめだ。なにを いっても つうじない。",
		"jurejure_confront_girl_2": "とにかく、いま とった たにくを げんせいちに かえしてあげて！",
		"jurejure_confront_mouse_battle": "ぷくぷくばとるで キミたちが かったら\nかんがえてあげるチュー！",
		"jurejure_challenge_1": "また キミたちか！\nしつこいやつらでチュー！",
		"jurejure_challenge_2": "ぷくぷくばとるで しょうぶだチュー！",
		"jurejure_battle_choice_title": "ぷくぷくばとるで しょうぶする？",
		"jurejure_battle_yes": "ばとるする",
		"jurejure_battle_no": "ばとるしない",
		"jurejure_battle_sow": "たねを まく",
		"jurejure_battle_enemy_score": "じゅれじゅれだん　%.1f cm",
		"jurejure_battle_player_score": "あなた　%.1f cm",
		"jurejure_battle_win": "しょうり！",
		"jurejure_battle_loss": "はいぼく……",
		"jurejure_battle_return": "げんせいちへ もどる",
		"jurejure_battle_win_mouse": "わかった わかった。\nさっき とった やつは かえすチュー。",
		"jurejure_battle_win_no_reward": "こんかいは キミたちの かちに してやるチュー！",
		"jurejure_battle_loss_mouse": "ぜーんぶ いただくチュー！",
		"jurejure_battle_loss_penalty": "じゅれじゅれだんは げんせいちの たにくを%dかぶ もちさった。\nぷくこいん -%d",
		"jurejure_battle_loss_penalty_zero": "じゅれじゅれだんは げんせいちの たにくを%dかぶ もちさった。\nぷくこいんは 0のまま。",
		"jurejure_mid_peccary": "これ、まだ ちいさいっぺ……。",
		"jurejure_mid_skunk": "これまで もっていくんスカ？",
		"jurejure_mid_mouse_1": "……。",
		"jurejure_mid_mouse_2": "きょうは べつのに するチュー！",
		"jurejure_late_skunk": "たおれてる かぶ、おこしておくスカ。",
		"jurejure_late_peccary": "これは ここに のこすっぺ。",
		"jurejure_late_mouse": "べ、べつに まもってる わけじゃないチュー！",
		"original_catalog_complete_4": "さいしょは なにも なかった げんせいちに、\nいまは たにくが いきている。",
		"jurejure_return_assume": "また もっていく つもり……？",
		"jurejure_return_mouse": "……かえしに きたんじゃないチュー。\nここに あったほうが、もっと ふえそうだから おくだけチュー。",
		"jurejure_return_skunk": "さいきん、ここが さびしくなるの いやなんスカ！",
		"jurejure_return_peccary": "いっぱい はえてるほうが たのしいっぺ。",
		"jurejure_return_narration": "じゅれじゅれだんは、もっていた たにくを げんせいちへ おいていった。",
		"second_awakening_light": "たにくが じゅうぶん もどった げんせいちを、いろとりどりの ひかりが はしった。",
		"second_awakening_panda": "……これ、ずかんに ない。",
		"second_awakening_armadillo": "むかし ここに あった しょくぶつじゃない……。\nげんせいちが、いまの せかいから あたらしい すがたを つくりはじめたんだ。",
		"second_awakening_mouse": "なんか でてきたチュー……。",
		"second_awakening_future": "げんせいちは、うしなわれた かこだけでなく、\nまだ そんざいしなかった みらいを めぶかせはじめた。",
		"objective_title": "つぎの もくひょう",
		"objective_old_seed": "ふるい たねを そだてよう",
		"objective_trio": "3にんの げんしゅを たしかめよう",
		"objective_find_habitat": "むかしの げんせいちへ いこう",
		"objective_awaken": "げんせいちを めざめさせよう",
		"objective_originals": "げんしゅを%dしゅるい ふっかつさせよう　%d / %d",
		"objective_size": "どれか1かぶを%dcmまで そだてよう　%.1f / %dcm",
		"objective_complete": "うしなわれた げんしゅが そろいました",
		"objective_second_awakening": "げんせいちで おきていることを たしかめよう",
		"story_complete_1": "ぜんぶ……そろった。",
		"story_complete_2": "むかしの ずかんに のこっていた げんしゅが、\nぜんぶ この せかいに もどってきたんだ。",
		"story_complete_3": "さいしょは、えの なかでしか しらなかったのにね。\nいまは ちゃんと、ここにいる。",
		"story_complete_4": "でも げんせいちは、まだ あたらしい たにくを うみつづけている。\nこれからも いっしょに みつけていこう。",
		"tutorial_normal_sow_1": "ここに まけば いいのかな……？",
		"tutorial_normal_sow_2": "やってみよう！",
		"tutorial_normal_sprout": "めが でた！",
		"tutorial_normal_growth": "どんどん おおきく なってる……。",
		"tutorial_normal_jelly": "とつぜん とけてしまうことも あるって かいてあったよ。\n『じゅれる』って いうみたい。",
		"tutorial_harvest_tap": "そだった かぶを おして しゅうかく！",
		"main_play": "たねをまく",
		"main_shop": "ぱんだの おみせ",
		"main_arrangement": "よせうえ",
		"main_forest_gacha": "もりの がちゃ\n1ぷく",
		"main_secret_gacha": "ひみつの がちゃ",
		"main_secret_gacha_unavailable": "ひみつの がちゃ\nいまは みつからない",
		"main_habitat": "げんせいちへ",
		"main_greenhouse": "おんしつへ",
		"settings": "せってい",
		"back": "もどる",
		"close": "とじる",
		"continue": "つづける",
		"puku_gauge": "ぷくげーじ",
		"seed_pod_gauge": "さやげーじ",
		"wallet": "もっている ぷくこいん　%dまい",
		"forest_gacha": "もりの がちゃ",
		"secret_gacha": "ひみつの がちゃ",
		"gacha_spin": "1ぷくこいんで まわす",
		"gacha_dial_hint": "だいやるを おして まわそう",
		"secret_gacha_dial_hint": "おもい だいやるを まわそう",
		"gacha_capsule_hint": "かぷせるを おしてね！",
		"secret_remaining": "あと %dかい",
		"secret_unlimited": "いつでも あそべる",
		"get": "げっと！",
		"new": "はじめて！",
		"original_catalog_new": "はじめて！",
		"super_rare": "すーぱーれあ",
		"tap_to_close": "おして とじる",
		"habitat_intro_1": "めが でた！",
		"habitat_observe_size": "いまの おおきさ %.1fcm",
		"habitat_observe_note": "しぜんの なかで、ゆっくり そだっています。",
		"puku_intro_1": "これからは そだてた たにくを うちの おみせで かいとるよ！",
		"puku_intro_2": "この げーじが いっぱいに なったら 3ぷくこいんと こうかんしよう！",
		"first_habitat_gift_1": "さやの なかに、さいしょの たねが できてる！",
		"first_habitat_gift_2": "12つぶいりの たねを 4ふくろ うけとったよ。\nそだててみよう！",
		"first_habitat_gift_received": "ふつうの たね 12つぶいり ×4ふくろ げっと",
		"initial_seed_stock_received": "ふつうの たね 12つぶいり ×4ふくろ げっと",
		"seed_pod_glow_1": "さやが ひかってる……。",
		"seed_pod_glow_2": "そだてると、すこしずつ ひかりが たまっていくのかな。",
		"seed_pod_first_reward": "たねが できてる！",
		"puku_buyback_1": "これからは そだてた たにくを うちの おみせで かいとるよ！",
		"puku_buyback_2": "この げーじが いっぱいに なったら 3ぷくこいんと こうかんしよう！",
		"pinwheel_received": "ぴんうぃーるを てにいれた！",
		"mystery_seed_owned": "おや、なぞのたねを もっているようだね。",
		"mystery_seed_request": "けんきゅうのために、そのたねを あずけてもらえないか？",
		"share_prompt": "たにともに じまんしよう！",
		"share_record": "じぶんの さいこうきろく！",
		"share_harvest": "%.1fせんちの%sを しゅうかく！",
		"share_fallback": "きょうゆうがぞうを ほぞんしました",
		"language_heading": "ことば",
		"language_saved": "ことばの せっていを ほぞんしました",
		"narration": ""
		,"tutorial_play2": "そだてるの、じょうずだね！\nあるまじろが むかしの げんせいちを しらべてくれているよ。"
		,"tutorial_play3": "じゅんび できたよ！たにくの げんせいちへ いけるようになったよ。\nげんせいちを みにいってみよう。"
		,"armadillo_intro_panda_1": "あるまじろから、ふるい しりょうの けんきゅうほうこくが あるみたいだよ。"
		,"armadillo_intro_panda_2": "むかしの しょくぶつや ふるい たねを ずっと しらべてくれているんだ。"
		,"armadillo_intro_self": "ふるい きろくを しらべていたら、きになる げんしゅの てがかりを みつけたんだ。"
		,"armadillo_pinwheel_gift": "きろくを たどって ふっかつできた ぴんうぃーるだ。\nきみに そだててほしい。"
		,"armadillo_mystery_1": "いま げんせいちに おちている『なぞのたね』を けんきゅうしているんだ。"
		,"armadillo_mystery_2": "もし みつけたら もってきてくれないか？"
		,"armadillo_seven_panda": "あるまじろくんから、また けんきゅうの おはなしが あるみたいだよ。"
		,"armadillo_seven_found": "げんせいちで、みたことのない ふしぎな ひんしゅを みつけたんだ。"
		,"armadillo_seven_species": "%sという ひんしゅだよ。\nきみに このかぶを ぷれぜんとするね！"
		,"armadillo_seven_catalog": "それから『%s』も いっしょに わたすよ。\nこれで なかまを きろくできるはずだ。"
		,"armadillo_seven_end": "やっぱり、あの げんせいちには\nふしぎな ちからが あるのかもしれない。\nよーし、まだまだ けんきゅうを つづけるぞ！"
		,"catalog": "ずかん"
		,"best_record": "さいこうきろく\n%.1f せんち"
		,"puku_count": "ぷくこいん ×%d"
		,"puku_gain": "ぷくこいん +%d"
		,"puku_gauge_reward": "ぷくこいん +%d"
		,"seed_pod_gauge_reward": "12つぶいり たねぶくろ +%d"
		,"play_choose_seed": "どの たねを まく？"
		,"seed_remaining": "たねぶくろ\nのこり %dつぶ"
		,"series_seed_remaining": "しりーずの たね\nのこり %dつぶ"
		,"play_old_seed": "ふるい たねを まく　1つぶ　のこり%dふくろ"
		,"play_normal_seed": "たねを まく　12つぶ　のこり%dふくろ"
		,"play_volume_seed": "ぼりゅーむぱっくを まく　36つぶ　のこり%dふくろ"
		,"play_premium_seed": "ぷれみあむたねを まく　24つぶ　のこり%dふくろ"
		,"play_mystery_seed": "なぞたねぱっくを まく　5つぶ　のこり%dふくろ"
		,"old_seed_name": "ふるい たね"
		,"bags_held": "%s %dふくろ"
		,"shop_choose_category": "なにを みますか？"
		,"shop_category_pot": "はち\nよせうえ"
		,"shop_category_catalog": "ずかん\nあたらしい しりーず"
		,"shop_category_gacha": "もりの\nがちゃ"
		,"shop_category_back": "ぶんるいへ もどる"
		,"shop_seed_info": "ふつうの たねは、さやげーじが みちると できます"
		,"normal_seed_price": "ふつうの たねは うっていません"
		,"price_tbd": "ぷくの ねだんは じゅんびちゅう"
		,"locked": "まだ つかえません"
		,"buy_bundle": "かう\n3ふくろ  1ぷくこいん"
		,"bought": "かいました"
		,"buy_puku": "かう　%dぷくこいん"
		,"all_pots_one_puku": "はちは ぜんぶ 1ぷくこいんです"
		,"result_title": "こんかいの しゅうかく"
		,"result_notable_title": "めだった しゅうかく"
		,"result_close": "とじる / もどる"
		,"result_total": "しゅうかくした おおきさ　+%sせんち\nぷくげーじ +%sせんち　/　ぷくこいん +%d"
		,"result_total_before_items": "しゅうかくした おおきさ　+%sせんち"
		,"result_count": "しゅうかく　%dかぶ"
		,"result_best_update": "いちばん おおきい きろく！\n%.1fせんち"
		,"result_max": "いちばん おおきい もの　%.1fせんち"
		,"result_none": "こんかいは まだ ありません"
		,"result_registered": "%sを ずかんに とうろく！"
		,"share_creating": "きょうゆうがぞうを つくっています…"
		,"share_failed": "きょうゆうがぞうを つくれませんでした"
		,"share_opened": "きょうゆうがめんを ひらきました"
		,"share_opening": "きょうゆうがめんを ひらいています…"
		,"share_complete": "きょうゆうしました"
		,"share_canceled": "きょうゆうを やめました"
		,"share_native_failed": "きょうゆうがめんを ひらけませんでした"
		,"share_web_opened": "きょうゆうがめんを ひらきました（つかえない ときは がぞうを ほぞんします）"
		,"encyclopedia_title": "ぷくぷくずかん"
		,"catalog_cover_preparing": "ひょうしがぞう\nじゅんびちゅう"
		,"catalog_locked": "まだ ひらいていません"
		,"catalog_locked_preparing": "まだ ひらいていません\nひょうしがぞう じゅんびちゅう"
		,"catalog_field": "この しりーずの げんせいちへ"
		,"catalog_unlock_status": "はじめて げっとした ひんしゅは、ふしぎな ずかんへ じどうで きろくされます"
		,"catalog_preparing": "この しりーずは じゅんびちゅうです"
		,"catalog_buy": "はじめて げっとすると じどうきろく"
		,"self_best": "じぶんの さいこう  %.1f せんち"
		,"self_best_none": "じぶんの さいこう　なし"
		,"undiscovered": "まだ みつけていません"
		,"list_back": "いちらんへ"
		,"harvest_to_gauge": "+%sせんち\nぷくげーじへ"
		,"record_update": "しゅうかく きろくこうしん！\nさいこうきろく\n%.1f せんち"
		,"mystery_seed_get": "なぞの たねを みつけた！"
		,"old_catalog_page_get": "あたらしい しりーずを ずかんに きろくした！"
		,"gacha_draw_count": "がちゃ %dかい"
		,"gacha_selecting": "もりの めぐみを えらんでいます…"
		,"unlock_action": "じどうで きろく"
		,"later": "あとで"
		,"gacha_return": "がちゃへ もどる"
		,"encountered": "であったよ"
		,"locked_series": "まだ ひらいていない しりーず"
		,"locked_offer": "『%s』の あたらしい ひんしゅです。\nふしぎな ずかんへ きろくされます。"
		,"forest_catalog_missing": "この ずかんは みつかりませんでした"
		,"forest_unlock_need5": "あたらしい ひんしゅは じどうで ずかんへ きろくされます。"
		,"forest_unlock_complete_one": "『%s』を ひらきました！\nこの ひんしゅを ずかんに とうろくしました。"
		,"forest_unlock_complete_many": "『%s』を ひらきました！\nであった %dひんしゅを とうろくしました。"
		,"forest_deferred": "この ひんしゅは ふしぎな ずかんへ じどうで きろくされます。"
		,"secret_turning": "ごと…ごとごと……"
		,"secret_catalog_page_prize": "%sの きろく"
		,"secret_prize": "ひみつの けいひん"
		,"arrangement_title": "よせうえ"
		,"arrangement_complete": "よせうえ かんせい！"
		,"arrangement_new": "あたらしく つくる"
		,"arrangement_saved": "ほぞんした よせうえ"
		,"arrangement_summary": "%d / %dさくひん　・　かった はち %dこ"
		,"arrangement_empty": "まだ さくひんは ありません。\nずかんに とうろくした たにくで、はじめての よせうえを つくってみよう。"
		,"view": "みる"
		,"choose_pot": "はちを えらぶ"
		,"owned_pot_hint": "かった はちから えらんでね"
		,"choose": "えらぶ"
		,"arrangement_name": "よせうえの なまえ"
		,"complete": "かんせい"
		,"add_succulent": "たにくを ふやす"
		,"size": "おおきさ"
		,"rotate": "かいてん"
		,"rotate_left": "ひだりまわり"
		,"rotate_right": "みぎまわり"
		,"send_back": "おくへ"
		,"bring_front": "てまえへ"
		,"delete": "けす"
		,"arrangement_editor_hint": "おして えらぶ・ゆびで うごかす・2ほんの ゆびで おおきさと むきを かえる"
		,"arrangement_pinch_hint": "2ほんの ゆびで おおきさと むきを かえられます"
		,"arrangement_deleted": "かぶを けしました"
		,"arrangement_max_plants": "1さくひんには %dかぶまで おけます"
		,"picker_title": "たにくを えらぶ"
		,"edit_back": "へんしゅうへ"
		,"picker_hint": "ずかんに とうろくした ひんしゅは なんどでも つかえます"
		,"all": "ぜんぶ"
		,"picker_empty": "この しりーずには、まだ つかえる たにくが ありません"
		,"no_record_min": "きろくなし・いちばん ちいさい おおきさ"
		,"max_cm": "さいだい %.1fせんち"
		,"image_preparing": "がぞう じゅんびちゅう"
		,"arrangement_added": "%sを ふやしました。そのまま ゆびで うごかせます"
		,"viewer_title": "かんせいした よせうえ"
		,"pot_shop_title": "よせうえようの はち"
		,"catalog_shop_title": "しりーずの きろく"
		,"seed_shop_title": "どうぐ"
		,"catalog_shop_hint": "あたらしい しりーずは はじめての げっとで じどうきろくされます"
		,"product_image_preparing": "しょうひんがぞう\nじゅんびちゅう"
		,"catalog_page_product": "しりーずの きろく"
		,"seed_bag_count": "たねぶくろ\n%dつぶ"
		,"pot_count": "%s　・　%dかぶ"
		,"arrangement_gesture_transform": "おおきさと むきを ちょうせいしたよ"
		,"arrangement_gesture_move": "ばしょを ちょうせいしたよ"
		,"pot_image_preparing": "はちの がぞうを じゅんびちゅう"
		,"shop_tab_normal": "ふつう"
		,"shop_tab_volume": "ぼりゅーむ"
		,"shop_tab_premium": "ぷれみあむ"
		,"shop_tab_mystery": "なぞたね"
		,"shop_category_short": "しゅるい"
		,"shop_catalog_preparing": "ずかんは はじめての げっとで\nじどうきろくされます"
		,"yes": "はい"
		,"no": "いいえ"
		,"restore": "もとにもどす"
		,"ad_seed": "こうこくをみて たねをもらう"
		,"ad_preparing": "こうこくを じゅんびちゅう…"
		,"seed_normal_card": "12つぶいり×3ふくろ・もっているのは%dふくろ\nふしぎな さやに できる きほんの たねぶくろ"
		,"seed_volume_card": "36つぶいり・もっているのは%dふくろ\n%s"
		,"seed_premium_card": "24つぶいり・もっているのは%dふくろ\n%s"
		,"seed_mystery_card": "5つぶいり・もっているのは%dふくろ\n%s"
		,"seed_series_name": "%sの たね"
		,"seed_series_card": "1つぶ・もっているのは%dつぶ\nふしぎな さやから もらえます"
		,"unlock_after_plays": "あと%dかい あそぶと つかえるよ"
		,"unlock_mystery_species": "なぞの ひんしゅを 1しゅるい みつけると つかえるよ"
		,"not_enough_puku": "ぷくこいんが たりません"
		,"seed_series_price_tbd": "たねは ふしぎな さやから もらえます"
		,"seed_price_tbd": "たねは ふしぎな さやから もらえます"
		,"seed_normal_bought": "ふつうの たねを%dふくろ かったよ"
		,"seed_normal_detail": "ふつうの たね　12つぶ × 3ふくろ\nふしぎな さやに できる きほんの たねです。\nきんぼし1つ10%　きんぼし2つ5%　しんひんしゅ4%"
		,"seed_volume_detail": "ぼりゅーむぱっく　36つぶ / ふくろ\nげんせいちの たねを たっぷり ふくろづめ しました。\nれあ10%　すーぱーれあ5%　しんしゅ やく3%"
		,"seed_premium_detail": "ぷれみあむたね　24つぶ / ふくろ\nぱんだが めずらしそうな つぶを えらびました。\nれあ30%　すーぱーれあ10%　しんしゅ やく3%"
		,"seed_mystery_detail": "なぞたねぱっく　5つぶ / ふくろ\nなにが そだつか わからない ふしぎな たねです。\nみつけた なぞの ひんしゅが でます"
		,"pot_missing": "この はちは みつかりませんでした"
		,"pot_owned": "この はちは もう もっています"
		,"pot_locked": "この はちは まだ かえません"
		,"pot_price_tbd": "この はちの ぷくの ねだんは じゅんびちゅうです"
		,"pot_bought": "%sを かったよ"
		,"catalog_bought": "%sを かったよ%s"
		,"catalog_encounters_registered": "（であった%dしゅるいも とうろくしたよ）"
		,"research_reward_title": "けんきゅうの おれい"
		,"research_reward_note": "すきな ずかんを 1さつ えらんでね"
		,"research_reward_later": "あとで えらぶ"
		,"research_reward_empty": "いま、あたらしく きろくできる しりーずは ありません。"
		,"research_reward_choose": "%s\nこの ずかんを もらう"
		,"research_reward_claimed": "%sを どうぞ。\nまだ みつけていない ひんしゅは、ずかんの かげを てがかりに さがしてみてね。"
		,"result_hidden_registered": "%sを ずかんに とうろくしたよ！"
		,"mystery_route_best": "100せんちなんて すごいね！\nげんせいちでも ふしぎなことが おきてるみたいだよ。"
		,"mystery_route_default": "ふしぎな たにくを みつけたね。まだ しらないことが たくさん ありそうだよ。"
		,"arrangement_default_name": "よせうえ %d"
		,"shop_rescue_offer": "たね なくなっちゃった？\nすこし わけてあげるよ！"
		,"shop_rescue_success": "はい、どうぞ！だいじに まいてみてね。"
		,"shop_chatter_touch": "たにくを さわって やわらかくなっていたら、みずやりの たいみんぐだよ"
		,"shop_chatter_welcome": "いらっしゃい！"
		,"shop_chatter_edible": "しってる？たべられる たにくも あるんだって。"
		,"shop_chatter_encounter": "きょうは どんな たにくに であえるかなあ。"
		,"shop_chatter_seasons": "たにくを そだててると、きせつを もっと かんじるよね。"
		,"shop_chatter_water": "たにくは みずを あげすぎると じゅれるから きをつけてね！"
		,"shop_chatter_growing": "たにくを そだてるの、なれてきた？"
		,"shop_chatter_world": "ふるい しりょうには、ものすごい かずの たにくが きろくされてるんだって。すごいなあ。"
		,"shop_chatter_leaf": "たにくの はっぱを つちに さすと、ねが でて ふえるんだ。はざしって いうんだよ。"
		,"shop_chatter_affinis": "あふぃにすの はなって まっかなんだって。みてみたいね！"
		,"shop_chatter_browse": "やあ！ゆっくり みてってよ。"
		,"shop_season_new_year": "あけまして おめでとう！ことしも よろしくね！"
		,"shop_season_autumn": "あさと よるが すずしくなってきたね。こうようが たのしみだね！"
		,"shop_season_summer_heat": "まいにち あついね。あつさには きをつけてね！"
		,"shop_season_summer_water": "なつの みずやりは ゆうがたから よるが いいよ！"
		,"shop_season_winter": "まいにち さむいけど、たにくの いろが にぎやかな きせつだね。"
		,"shop_season_spring": "だんだん あたたかくなってきたね。たにくも どんどん そだつね！"
		,"old_page_intro_1": "これ、げんせいちで ひろったんだ。\nふるくて よごれているけど、ずかんの ぺーじみたいじゃない？"
		,"old_page_intro_2": "あるまじろくんなら、きっと もとの ずかんに もどせると おもうよ。"
		,"volume_intro_1": "ふしぎな さやに、たくさんの たねが できたよ！"
		,"volume_intro_2": "36つぶ はいってるから、ふつうの たねより たっぷり たのしめるよ。\nじっくり おおきな たにくを そだてられるね！"
		,"bustamante_gift": "いつも きてくれて ありがとう。\nすとりくちふろーら ぶすたまんてを 1かぶ、きみに あげるよ。"
		,"pinwheel_intro_1": "ふるい しりょうを しらべていたら、そだてかたの てがかりを みつけたんだ。"
		,"pinwheel_intro_2": "ぼくたちの たねで ためしたら、また ひとかぶ そだてられたよ。"
		,"pinwheel_intro_3": "ずかんで しらべると、ぴんうぃーるという げんしゅらしい。\nきみに あずけるよ。"
		,"armadillo_idle_1": "また あえたね。ゆっくり していって！"
		,"armadillo_idle_2": "きょうの たにくも げんきそうだね。"
		,"armadillo_idle_3": "つちの においって おちつくよね。"
		,"research_intro_1": "おや？ そのたね……。\nもしかして、げんせいちで ひろったのかい？"
		,"research_intro_2": "じつは ぼく、この『なぞのたね』を けんきゅうしてるんだ。\nまだ、なんの たねか わからないんだけどね。"
		,"research_intro_3": "よかったら、そのたねを けんきゅうさせてもらえないかな？"
		,"research_return_offer": "なぞのたねを もってきてくれたんだね。\nけんきゅうのために、まとめて あずかっても いいかい？"
		,"restore_offer": "この きろくは、ふしぎな ずかんへ じどうで はんえいされるよ。"
		,"restore_shortage": "この きろくは、ふしぎな ずかんへ じどうで はんえいされるよ。"
		,"restore_success": "もとにもどせたよ！\nこれは『%s』の ぺーじだったんだ。\nまだ みつけていない ひんしゅも、かげから すこしずつ しらべられそうだね。"
		,"research_status_sprouted": "きいてよ！\nやっと、たねが めをだしたんだ！\nおおきくなるのを おたのしみに！"
		,"research_status_growing": "ありがとう。\nじゅんちょうに そだってるよ！"
		,"research_status_trying": "ありがとう！\nめを だせるように がんばるから、また もってきてよ！"
		,"research_status_world": "ふるい きろくにも ない すがたが、まだ うまれているんだね。\nなぞのたねを みつけたら、また もってきてよ！"
		,"research_status_progress": "ありがとう！\nけんきゅうが すこしずつ すすんでいるよ。\nまた なぞのたねを もってきてくれると うれしいな！"
		,"research_status_thanks": "ありがとう！\nまた なぞのたねを みつけたら、もってきてくれると うれしいな！"
		,"research_status_first": "ありがとう！\nなぞのたねを %dこ うけとったよ。\nたくさん あつまれば、なにか わかるかもしれない。\nまた ひろったら、もってきてくれると うれしいな！"
		,"research_milestone_catalog": "けんきゅうを てつだってくれた おれいに、すきな ずかんを 1さつ あげるよ。"
		,"research_milestone_habitat": "げんせいちに あたらしい ひんしゅが はえてたよ。"
		,"research_milestone_seed_instead": "あたらしい ふつうの ひんしゅは ぜんぶ みつけているから、かわりに たねを 1ふくろ どうぞ。"
		,"research_milestone_sprout": "けんきゅうしていた なぞのたねが、ついに めをだしたよ！"
		,"research_milestone_species": "おどろいたよ。けんきゅうしてた たねから、こんな たにくが そだつなんて……。\n%s、これ きみに あげるよ！"
		,"research_milestone_gold": "びっくりだ。きんいろの らうい……！？ これ、あげる！"
		,"research_milestone_seed": "けんきゅうの おれいに、たねを 1ふくろ どうぞ。"
		,"research_transfer": "わたした なぞのたね ×%dこ"
		,"audio_bgm": "おんがく"
		,"audio_bgm_on": "おんがく ON"
		,"audio_se": "こうかおん"
		,"audio_se_on": "こうかおん ON"
		,"audio_note": "おんがくと おとの おおきさを かえられます"
		,"unlock_five_puku": "はじめて GETで じどうきろく"
		,"unlock_restore_page": "はじめて げっとすると じどうきろく"
		,"unlock_progress": "げーむを すすめると みられます"
		,"unlock_future": "ひらく じょうけんは じゅんびちゅうです"
		,"jelly_float": "じゅれ"
		,"preview_finished": "ぷれびゅー おわり"
		,"preview_jelly": "じゅれ（ぷれびゅー）"
		,"understood": "わかった"
	},
	"en": {
		"language_name": "English",
		"game_title": "Puku Puku Taniku",
		"opening_tap": "Tap to Start",
		"opening_story_tap": "Tap to continue",
		"opening_story_1": "One day, the girl found a dusty old book\nin the corner of an old storeroom.\n\n\"What could this be...?\"",
		"opening_story_2": "They brushed off the dust\nand looked through it together.\n\nIt seemed to be\nan old book about plants.",
		"opening_story_3": "Inside were drawings of plants\nnone of them had ever seen.\n\nPlump leaves. Strange shapes.\nMysterious colors.\n\nThe pages called them \"succulents.\"\n\n\"Did plants like these really exist...?\"",
		"opening_story_4": "Meanwhile, Panda had found an old bag of seeds\nsomewhere else.\n\n\"What kind of seeds are these?\"\n\nLooking at the plants drawn in the book,\nthe three glanced at one another.\n\n\"Maybe... these are seeds from those plants.\"\n\nSo they divided the seeds\nand decided to plant them.",
		"panda_shop_name": "Panda's Shop",
		"armadillo_name": "Armadillo",
		"story_speaker_girl": "Girl",
		"story_speaker_panda": "Panda",
		"story_speaker_armadillo": "Armadillo",
		"story_speaker_trio": "All three",
		"jurejure_mouse_name": "Mouse",
		"jurejure_skunk_name": "Skunk",
		"jurejure_peccary_name": "Peccary",
		"next": "Next",
		"daily_seed_gift": "Thanks for coming back today!\nYou got 1 seed bag.",
		"intro_old_seed": "We divided the old seeds among the three of us.\nThis one is yours. Let's plant it!",
		"intro_old_seed_get": "You got 1 old seed!",
		"old_seed_reaction_sprout": "Look! It sprouted!",
		"old_seed_reaction_trio": "It's a succulent!!",
		"old_seed_reaction_girl": "I can't believe it!",
		"old_seed_reaction_growth": "It's getting bigger and bigger!",
		"story_colorata_1": "Those really were succulent seeds!",
		"story_colorata_2": "According to this book,\nthis species is called '%s'!",
		"story_colorata_3": "Amazing.\nSucculents have returned to the world...!",
		"story_trio_1": "Listen! My seed grew too!\nAccording to this book, it's called '%s'.",
		"story_trio_2": "Mine did too! It seems this species is called '%s'.",
		"story_trio_3": "I can't believe it. We're really seeing plants\nthat were lost for so long...",
		"story_trio_4": "They're so beautiful. And their plump leaves are adorable!",
		"story_trio_5": "I hope this world can be filled with succulents again.",
		"story_habitat_found_1": "I searched the old records and found a place\nwhere succulents were once said to grow!",
		"story_habitat_found_2": "Really?!\nWhy don't we all go there?",
		"awakening_empty_1": "The records say this must be the place...",
		"awakening_empty_2": "There really is nothing here after all...",
		"awakening_overharvest": "It seems human overharvesting was another major cause of their extinction...",
		"awakening_sow": "A few of the old seeds we first found are still left. Let's plant them here.",
		"awakening_surprise": "What is that?!",
		"awakening_memory": "...It looks as though this place\nis remembering the succulents\nthat once grew here...",
		"awakening_thanks": "Thank you for showing us these beautiful memories.",
		"awakening_apology": "Long ago, our ancestors took too many succulents\naway from this place...\nWe are sorry.",
		"awakening_promise_1": "We will never do that again.",
		"awakening_promise_2": "Whenever we discover a new variety,\nwe will return some of it here.\nSo please show us many more adorable succulents!",
		"awakening_rain_stopping": "...The rain is easing up.",
		"awakening_sprout_look": "Look!",
		"awakening_sprout_panda": "Oh, they're sprouting!",
		"seed_pod_story_1": "Look! Something is falling from the sky!",
		"seed_pod_story_2": "Could that be... a seed pod?",
		"seed_pod_story_3": "And this one... is a catalog?",
		"mystery_catalog_prompt": "Let's look at the catalog!",
		"mystery_catalog_tutorial_1": "Look. The succulents we just grew are in this catalog.",
		"mystery_catalog_tutorial_2": "It's Colorata and the others!",
		"mystery_catalog_tutorial_3": "It seems any new succulents we discover\nwill be recorded here too.",
		"mystery_catalog_tutorial_4": "What a mysterious catalog...",
		"seed_origin_1": "A seed has formed inside the mysterious pod.",
		"seed_origin_2": "Growing succulents seems to make light gather in the pod.",
		"seed_origin_3": "Let's grow more and receive the next seed!",
		"seed_origin_received": "You received 3 seeds from the pod!",
		"special_origin_1": "This one... isn't in the mysterious catalog.",
		"special_origin_2": "So the habitat is not only restoring old succulents...",
		"special_origin_3": "It seems to be looking at today's world\nand creating new succulents too.",
		"jurejure_intro_panda_1": "Huh...?",
		"jurejure_intro_panda_2": "Weren't there more succulents here before?",
		"jurejure_intro_traces": "Strange tracks, fallen leaves,\nand marks where something was dragged away.",
		"jurejure_intro_armadillo": "Did someone come through here...?",
		"jurejure_intro_rustle": "Rustle, rustle... from deeper inside.",
		"jurejure_intro_silence": "...",
		"jurejure_intro_mouse": "We've been spotted! Move!",
		"jurejure_intro_skunk": "This is bad! Run!",
		"jurejure_intro_peccary": "This stuff is heavy!",
		"jurejure_intro_panda_shout": "Hey! Wait!",
		"jurejure_intro_mouse_return": "We'll be back!",
		"jurejure_intro_name": "They dropped a tag that says 'JureJure Gang'...",
		"jurejure_target_small": "The JureJure Gang is targeting %s!",
		"jurejure_status_small": "Targeted - tap to chase them off",
		"jurejure_panda_defend": "Hey! Leave it alone!",
		"jurejure_taken_small": "%s was taken\nby the JureJure Gang!",
		"jurejure_confront_armadillo": "The succulents have finally returned here.\nYou cannot just take them.",
		"jurejure_confront_peccary": "They finally came back, so we came to get some!",
		"jurejure_confront_girl_1": "People acting like you are why succulents\nwent extinct long ago!",
		"jurejure_confront_skunk": "But nobody sees them if they only grow here.\nIs that really better?",
		"jurejure_confront_mouse_panda": "Panda! You do business with succulents too!",
		"jurejure_confront_panda": "...This is no use. They will not listen.",
		"jurejure_confront_girl_2": "Just put the succulents you took back where they belong!",
		"jurejure_confront_mouse_battle": "Win a Puku Puku Battle,\nand maybe we will think about it!",
		"jurejure_challenge_1": "You again? You really do not give up!",
		"jurejure_challenge_2": "Settle it with a Puku Puku Battle!",
		"jurejure_battle_choice_title": "Start a Puku Puku Battle?",
		"jurejure_battle_yes": "Battle",
		"jurejure_battle_no": "Not now",
		"jurejure_battle_sow": "Sow Seeds",
		"jurejure_battle_enemy_score": "JureJure Gang  %.1f cm",
		"jurejure_battle_player_score": "You  %.1f cm",
		"jurejure_battle_win": "Victory!",
		"jurejure_battle_loss": "Defeat...",
		"jurejure_battle_return": "Return to Habitat",
		"jurejure_battle_win_mouse": "Fine, fine. We will put back\nwhat we just took.",
		"jurejure_battle_win_no_reward": "We will call this one your win!",
		"jurejure_battle_loss_mouse": "We are taking the whole haul!",
		"jurejure_battle_loss_penalty": "The JureJure Gang carried off %d habitat plants.\nPuku Coins -%d",
		"jurejure_battle_loss_penalty_zero": "The JureJure Gang carried off %d habitat plants.\nYour Puku Coins remain at 0.",
		"jurejure_mid_peccary": "This one's still tiny...",
		"jurejure_mid_skunk": "We're taking even this one?",
		"jurejure_mid_mouse_1": "...",
		"jurejure_mid_mouse_2": "We'll take a different one today!",
		"jurejure_late_skunk": "I'll prop this fallen plant back up.",
		"jurejure_late_peccary": "Let's leave this one here.",
		"jurejure_late_mouse": "D-don't think we're protecting it!",
		"original_catalog_complete_4": "The habitat began empty.\nNow succulents are living here again.",
		"jurejure_return_assume": "Are they here to take more...?",
		"jurejure_return_mouse": "W-we didn't come to return these!\nThey'll multiply faster here, so we're only leaving them for later!",
		"jurejure_return_skunk": "I just don't like seeing this place get lonely!",
		"jurejure_return_peccary": "It's more fun when lots of them grow here.",
		"jurejure_return_narration": "For the first time, the JureJure Gang placed succulents back into the habitat.",
		"second_awakening_light": "Colorful trails of light raced through the habitat, now rich with restored succulents.",
		"second_awakening_panda": "...This isn't in the catalog.",
		"second_awakening_armadillo": "It isn't something that grew here long ago...\nThe habitat is creating a new form from the world it sees now.",
		"second_awakening_mouse": "Something new is coming up...",
		"second_awakening_future": "The habitat began to sprout not only its lost past,\nbut forms that had never existed before.",
		"objective_title": "Next Goal",
		"objective_old_seed": "Grow the old seed",
		"objective_trio": "Identify all three originals",
		"objective_find_habitat": "Visit the historic habitat",
		"objective_awaken": "Awaken the habitat",
		"objective_originals": "Restore %d originals  %d / %d",
		"objective_size": "Grow one plant to %d cm  %.1f / %d cm",
		"objective_complete": "All lost originals restored",
		"objective_second_awakening": "See what is happening in the habitat",
		"story_complete_1": "They're all... here.",
		"story_complete_2": "Every original recorded in the old catalog\nhas returned to this world.",
		"story_complete_3": "At first, we knew them only as drawings.\nNow they're truly here.",
		"story_complete_4": "But the habitat is still creating new succulents.\nLet's keep discovering them together.",
		"tutorial_normal_sow_1": "Do you think we should plant them here...?",
		"tutorial_normal_sow_2": "Let's try it!",
		"tutorial_normal_sprout": "It sprouted!",
		"tutorial_normal_growth": "It's getting bigger and bigger...",
		"tutorial_normal_jelly": "The old book says they can suddenly melt away.\nIt calls that 'turning to jelly.'",
		"tutorial_harvest_tap": "Tap a grown plant to harvest it!",
		"main_play": "Plant Seeds",
		"main_shop": "Panda's Shop",
		"main_arrangement": "Arrangement",
		"main_forest_gacha": "Forest Gacha\n1 Puku",
		"main_secret_gacha": "Secret Gacha",
		"main_secret_gacha_unavailable": "Secret Gacha\nNot available now",
		"main_habitat": "Wild Habitat",
		"main_greenhouse": "Greenhouse",
		"settings": "Settings",
		"back": "Back",
		"close": "Close",
		"continue": "Continue",
		"puku_gauge": "Puku Gauge",
		"seed_pod_gauge": "Pod Gauge",
		"wallet": "%d Puku Coins",
		"forest_gacha": "Forest Gacha",
		"secret_gacha": "Secret Gacha",
		"gacha_spin": "Spin for 1 Puku Coin",
		"gacha_dial_hint": "Tap or turn the dial",
		"secret_gacha_dial_hint": "Turn the heavy dial",
		"gacha_capsule_hint": "Tap the capsule!",
		"secret_remaining": "%d spins left",
		"secret_unlimited": "Always available",
		"get": "GET!",
		"new": "NEW!",
		"original_catalog_new": "NEW!",
		"super_rare": "SUPER RARE",
		"tap_to_close": "Tap to close",
		"habitat_intro_1": "A sprout!",
		"habitat_observe_size": "Current size: %.1f cm",
		"habitat_observe_note": "It is growing slowly in the habitat.",
		"puku_intro_1": "From now on, my shop will buy the succulents you grow!",
		"puku_intro_2": "When this gauge fills up, I'll trade it for 3 Puku Coins!",
		"first_habitat_gift_1": "The first seeds have formed inside the pod!",
		"first_habitat_gift_2": "You received four bags with 12 seeds each.\nLet's grow them!",
		"first_habitat_gift_received": "Normal Seeds · 12 each ×4 bags",
		"initial_seed_stock_received": "Normal Seeds · 12 each ×4 bags",
		"seed_pod_glow_1": "The pod is glowing...",
		"seed_pod_glow_2": "Maybe growing them makes the light build up little by little.",
		"seed_pod_first_reward": "It made seeds!",
		"puku_buyback_1": "From now on, my shop will buy the succulents you grow!",
		"puku_buyback_2": "When this gauge fills up, I'll trade it for 3 Puku Coins!",
		"pinwheel_received": "You got Pinwheel!",
		"mystery_seed_owned": "Oh, I see you already have a mystery seed.",
		"mystery_seed_request": "Would you let me study that seed?",
		"share_prompt": "Show your succulent friends!",
		"share_record": "NEW PERSONAL BEST!",
		"share_harvest": "Harvested a %.1f cm %s!",
		"share_fallback": "The share image was saved",
		"language_heading": "Language",
		"language_saved": "Language setting saved",
		"narration": ""
		,"tutorial_play2": "You are getting good at this!\nArmadillo is studying records about the old habitat."
		,"tutorial_play3": "Everything is ready!\nYou can visit the wild habitat now. Let's go see it."
		,"armadillo_intro_panda_1": "Armadillo has a report from his research into old records."
		,"armadillo_intro_panda_2": "He has been studying lost plants and ancient seeds for us."
		,"armadillo_intro_self": "I found a clue to an original species while studying the old records."
		,"armadillo_pinwheel_gift": "This Pinwheel was restored by following those records.\nI'd like you to grow it."
		,"armadillo_mystery_1": "I'm studying the mystery seeds that fall in the habitat."
		,"armadillo_mystery_2": "Would you bring one to me if you find it?"
		,"armadillo_seven_panda": "Armadillo has another research story for you."
		,"armadillo_seven_found": "I found a strange succulent I had never seen before in the habitat."
		,"armadillo_seven_species": "It is called %s.\nI want you to have this plant!"
		,"armadillo_seven_catalog": "And here is the %s too.\nNow you can record its family."
		,"armadillo_seven_end": "Maybe that habitat really does have a mysterious power.\nAll right—my research continues!"
		,"catalog": "Catalog"
		,"best_record": "Best Record\n%.1f cm"
		,"puku_count": "Puku Coins ×%d"
		,"puku_gain": "Puku Coin +%d"
		,"puku_gauge_reward": "Puku Coins +%d"
		,"seed_pod_gauge_reward": "12-seed bags +%d"
		,"play_choose_seed": "Which seeds will you plant?"
		,"seed_remaining": "Seed Bag\n%d seeds left"
		,"series_seed_remaining": "Series Seed\n%d seeds left"
		,"play_old_seed": "Plant the old seed · 1 seed · %d bags"
		,"play_normal_seed": "Plant seeds · 12 seeds · %d bags"
		,"play_volume_seed": "Plant Volume Pack · 36 seeds · %d bags"
		,"play_premium_seed": "Plant Premium Seeds · 24 seeds · %d bags"
		,"play_mystery_seed": "Plant Mystery Pack · 5 seeds · %d bags"
		,"old_seed_name": "Old Seeds"
		,"bags_held": "%s · %d bags"
		,"shop_choose_category": "What would you like to see?"
		,"shop_category_pot": "Pots\nArrangements"
		,"shop_category_catalog": "Catalogs\nNew Series"
		,"shop_category_gacha": "Forest\nGacha"
		,"shop_category_back": "Back to categories"
		,"shop_seed_info": "Normal seeds form when the Pod Gauge fills up"
		,"normal_seed_price": "Normal seeds are not sold"
		,"price_tbd": "Puku price coming later"
		,"locked": "Locked"
		,"buy_bundle": "Buy\n3 bags · 1 Puku Coin"
		,"bought": "Owned"
		,"buy_puku": "Buy · %d Puku Coins"
		,"all_pots_one_puku": "Every pot costs 1 Puku Coin"
		,"result_title": "Harvest Results"
		,"result_notable_title": "Notable Harvests"
		,"result_close": "Close / Back"
		,"result_total": "Total harvested size +%s cm\nPuku Gauge +%s cm / Puku Coins +%d"
		,"result_total_before_items": "Total harvested size +%s cm"
		,"result_count": "%d plants harvested"
		,"result_best_update": "New Largest Size!\n%.1f cm"
		,"result_max": "Largest size %.1f cm"
		,"result_none": "Nothing yet this time"
		,"result_registered": "Added %s to the catalog!"
		,"share_creating": "Creating your share image…"
		,"share_failed": "The share image could not be created"
		,"share_opened": "Opened the share sheet"
		,"share_opening": "Opening the share sheet…"
		,"share_complete": "Shared"
		,"share_canceled": "Sharing canceled"
		,"share_native_failed": "Could not open the share sheet"
		,"share_web_opened": "Opened sharing; unsupported browsers will download the image"
		,"encyclopedia_title": "Puku Puku Catalog"
		,"catalog_cover_preparing": "Cover image\ncoming soon"
		,"catalog_locked": "Locked"
		,"catalog_locked_preparing": "Locked\nCover image coming soon"
		,"catalog_field": "Visit this series habitat"
		,"catalog_unlock_status": "A species is recorded automatically the first time you GET it"
		,"catalog_preparing": "This series is coming soon"
		,"catalog_buy": "Recorded automatically on first GET"
		,"self_best": "Personal best %.1f cm"
		,"self_best_none": "Personal best —"
		,"undiscovered": "Not discovered"
		,"list_back": "Back to list"
		,"harvest_to_gauge": "+%s cm\nto Puku Gauge"
		,"record_update": "NEW HARVEST RECORD\n%.1f cm"
		,"mystery_seed_get": "Mystery Seed GET!"
		,"old_catalog_page_get": "A new series was recorded in the catalog!"
		,"gacha_draw_count": "Gacha %d"
		,"gacha_selecting": "Choosing a forest gift…"
		,"unlock_action": "Record automatically"
		,"later": "Later"
		,"gacha_return": "Back to Gacha"
		,"encountered": "Encountered"
		,"locked_series": "LOCKED SERIES"
		,"locked_offer": "This is a new species from %s.\nIt will be recorded automatically."
		,"forest_catalog_missing": "That catalog could not be found"
		,"forest_unlock_need5": "New species are recorded automatically."
		,"forest_unlock_complete_one": "Unlocked %s!\nAdded this species to your catalog."
		,"forest_unlock_complete_many": "Unlocked %s!\nAdded %d encountered species."
		,"forest_deferred": "This species is recorded in the mysterious catalog automatically."
		,"secret_turning": "Clunk… rumble…"
		,"secret_catalog_page_prize": "%s record"
		,"secret_prize": "Secret Prize"
		,"arrangement_title": "Arrangements"
		,"arrangement_complete": "Arrangement Complete!"
		,"arrangement_new": "Create New"
		,"arrangement_saved": "Saved Arrangements"
		,"arrangement_summary": "%d / %d creations · %d owned pots"
		,"arrangement_empty": "No creations yet.\nMake your first arrangement with cataloged succulents."
		,"view": "View"
		,"choose_pot": "Choose a Pot"
		,"owned_pot_hint": "Choose from your owned pots"
		,"choose": "Choose"
		,"arrangement_name": "Arrangement name"
		,"complete": "Finish"
		,"add_succulent": "Add Succulent"
		,"size": "Size"
		,"rotate": "Rotate"
		,"rotate_left": "Left"
		,"rotate_right": "Right"
		,"send_back": "Send Back"
		,"bring_front": "Bring Front"
		,"delete": "Delete"
		,"arrangement_editor_hint": "Tap to select, drag to move, or use two fingers to resize and rotate"
		,"arrangement_pinch_hint": "Use two fingers to adjust size and direction"
		,"arrangement_deleted": "Plant removed"
		,"arrangement_max_plants": "You can place up to %d plants in one arrangement"
		,"picker_title": "Choose a Succulent"
		,"edit_back": "Back to Edit"
		,"picker_hint": "Cataloged species can be used as often as you like"
		,"all": "All"
		,"picker_empty": "No usable succulents in this series yet"
		,"no_record_min": "No record · minimum size"
		,"max_cm": "Maximum %.1f cm"
		,"image_preparing": "Image coming soon"
		,"arrangement_added": "Added %s. Drag it directly while selected"
		,"viewer_title": "Finished Arrangement"
		,"pot_shop_title": "Arrangement Pots"
		,"catalog_shop_title": "Series Records"
		,"seed_shop_title": "Tools"
		,"catalog_shop_hint": "New series are recorded automatically on their first GET"
		,"product_image_preparing": "Product image\ncoming soon"
		,"catalog_page_product": "Series record"
		,"seed_bag_count": "Seed Bag\n%d seeds"
		,"pot_count": "%s · %d plants"
		,"arrangement_gesture_transform": "Size and angle adjusted"
		,"arrangement_gesture_move": "Position adjusted"
		,"pot_image_preparing": "Pot image coming soon"
		,"shop_tab_normal": "Normal"
		,"shop_tab_volume": "Volume"
		,"shop_tab_premium": "Premium"
		,"shop_tab_mystery": "Mystery"
		,"shop_category_short": "Categories"
		,"shop_catalog_preparing": "The catalog records\neach first GET automatically"
		,"yes": "Yes"
		,"no": "No"
		,"restore": "Restore"
		,"ad_seed": "Watch an ad for seeds"
		,"ad_preparing": "Preparing ad…"
		,"seed_normal_card": "12 seeds × 3 bags · %d bags owned\nBasic seeds formed in the mysterious pod"
		,"seed_volume_card": "36 seeds · %d bags owned\n%s"
		,"seed_premium_card": "24 seeds · %d bags owned\n%s"
		,"seed_mystery_card": "5 seeds · %d bags owned\n%s"
		,"seed_series_name": "%s Seeds"
		,"seed_series_card": "1 seed · %d owned\nReceived from the mysterious pod"
		,"unlock_after_plays": "Unlocks after %d more plays"
		,"unlock_mystery_species": "Find one mystery species to unlock"
		,"not_enough_puku": "Not enough Puku Coins"
		,"seed_series_price_tbd": "Seeds are received from the mysterious pod"
		,"seed_price_tbd": "Seeds are received from the mysterious pod"
		,"seed_normal_bought": "Bought %d normal seed bags"
		,"seed_normal_detail": "Normal Seeds · 12 seeds × 3 bags\nBasic seeds formed in the mysterious pod; many succulents may grow.\n1 Gold Star 10% · 2 Gold Stars 5% · New species 4%"
		,"seed_volume_detail": "Volume Pack · 36 seeds per bag\nA generous bag of habitat seeds for growing big succulents.\nRare 10% · Super Rare 5% · New species about 3%"
		,"seed_premium_detail": "Premium Seeds · 24 seeds per bag\nHabitat seeds Panda selected because they looked unusual.\nRare 30% · Super Rare 10% · New species about 3%"
		,"seed_mystery_detail": "Mystery Pack · 5 seeds per bag\nMysterious seeds with unknown results.\nDiscovered eligible mystery species only"
		,"pot_missing": "That pot could not be found"
		,"pot_owned": "You already own that pot"
		,"pot_locked": "That pot is not available yet"
		,"pot_price_tbd": "The Puku price for that pot is coming soon"
		,"pot_bought": "Bought %s"
		,"catalog_bought": "Bought %s%s"
		,"catalog_encounters_registered": " (%d encountered species also registered)"
		,"research_reward_title": "Research Reward"
		,"research_reward_note": "Choose one catalog"
		,"research_reward_later": "Choose Later"
		,"research_reward_empty": "There is no new series to record right now."
		,"research_reward_choose": "%s\nChoose this catalog"
		,"research_reward_claimed": "Here is %s.\nUse the silhouettes to look for species you have not found yet."
		,"result_hidden_registered": "%s registered in the catalog!"
		,"mystery_route_best": "100 cm is amazing!\nSomething mysterious seems to be happening in the habitat too."
		,"mystery_route_default": "You found a mysterious succulent. There is still so much we do not know."
		,"arrangement_default_name": "Arrangement %d"
		,"shop_rescue_offer": "Run out of seeds?\nI'll share a bag with you!"
		,"shop_rescue_success": "Here you go! Plant them with care."
		,"shop_chatter_touch": "When a succulent feels soft, it may be time to water it."
		,"shop_chatter_welcome": "Welcome!"
		,"shop_chatter_edible": "Did you know some succulents are edible?"
		,"shop_chatter_encounter": "I wonder which succulent you will meet today."
		,"shop_chatter_seasons": "Growing succulents makes the changing seasons feel even more vivid."
		,"shop_chatter_water": "Too much water can turn a succulent to jelly, so be careful!"
		,"shop_chatter_growing": "Are you getting used to growing succulents?"
		,"shop_chatter_world": "Old records describe an astonishing number of succulent varieties. Amazing!"
		,"shop_chatter_leaf": "A leaf placed in soil can grow roots and make a new plant. That is leaf propagation."
		,"shop_chatter_affinis": "Affinis has bright red flowers. I would love to see them!"
		,"shop_chatter_browse": "Hello! Take your time looking around."
		,"shop_season_new_year": "Happy New Year! I hope we have another wonderful year together!"
		,"shop_season_autumn": "The mornings and evenings are getting cooler. I cannot wait for the autumn colors!"
		,"shop_season_summer_heat": "It is hot every day. Please take care in the heat!"
		,"shop_season_summer_water": "In summer, evening and nighttime are best for watering."
		,"shop_season_winter": "It is cold, but this is such a colorful season for succulents."
		,"shop_season_spring": "The days are getting warmer, and the succulents are growing quickly!"
		,"old_page_intro_1": "I found this in the habitat.\nIt is old and dirty, but does it look like a catalog page to you?"
		,"old_page_intro_2": "I think Armadillo could restore it to its original catalog."
		,"volume_intro_1": "The mysterious pod has grown lots of seeds!"
		,"volume_intro_2": "It contains 36 seeds, so there is more to enjoy than in a normal bag.\nYou can take your time growing a giant succulent!"
		,"bustamante_gift": "Thank you for visiting so often.\nI would like to give you one Strictiflora Bustamante."
		,"pinwheel_intro_1": "I found a clue about growing them while studying some old records."
		,"pinwheel_intro_2": "I tried it with our seeds, and another plant grew."
		,"pinwheel_intro_3": "The catalog identifies it as an original species called Pinwheel.\nI want you to look after it."
		,"armadillo_idle_1": "Good to see you again. Take your time!"
		,"armadillo_idle_2": "Your succulents look healthy today."
		,"armadillo_idle_3": "The smell of soil is so calming."
		,"research_intro_1": "Oh? That seed…\nDid you find it in the habitat?"
		,"research_intro_2": "I have been studying these Mystery Seeds.\nI still do not know what kind of seed they are."
		,"research_intro_3": "Would you let me study that seed?"
		,"research_return_offer": "You brought more Mystery Seeds.\nMay I take them together for my research?"
		,"restore_offer": "This record will be added to the mysterious catalog automatically."
		,"restore_shortage": "This record will be added to the mysterious catalog automatically."
		,"restore_success": "Restoration complete!\nThis page belonged to %s.\nThe silhouettes may help us study species you have not found yet."
		,"research_status_sprouted": "Listen!\nThe seed finally sprouted!\nWait until you see how it grows!"
		,"research_status_growing": "Thank you.\nIt is growing well!"
		,"research_status_trying": "Thank you!\nI will keep trying to make it sprout, so please bring me more."
		,"research_status_world": "New forms that never appeared in the old records are still being born.\nBring me any Mystery Seeds you find!"
		,"research_status_progress": "Thank you!\nThe research is making steady progress.\nI would be happy if you brought me more Mystery Seeds!"
		,"research_status_thanks": "Thank you!\nI would be happy if you brought me any more Mystery Seeds you find!"
		,"research_status_first": "Thank you!\nI received %d Mystery Seeds.\nWith enough of them, we may discover something.\nPlease bring me any others you find!"
		,"research_milestone_catalog": "To thank you for helping my research, I will give you one catalog of your choice."
		,"research_milestone_habitat": "A new species has appeared in the habitat."
		,"research_milestone_seed_instead": "You found every new normal species, so please take a seed bag instead."
		,"research_milestone_sprout": "The Mystery Seed I was studying finally sprouted!"
		,"research_milestone_species": "Incredible. I never expected such a succulent to grow from that seed…\nPlease take %s!"
		,"research_milestone_gold": "A golden Laui… incredible! Please take it!"
		,"research_milestone_seed": "Please take one seed bag as thanks for helping my research."
		,"research_transfer": "Mystery Seeds given: %d"
		,"audio_bgm": "Music"
		,"audio_bgm_on": "Music ON"
		,"audio_se": "Sound Effects"
		,"audio_se_on": "Sound Effects ON"
		,"audio_note": "Music and sound volume can be adjusted here."
		,"unlock_five_puku": "Recorded on first GET"
		,"unlock_restore_page": "Recorded automatically on first GET"
		,"unlock_progress": "Progress through the game to view this series"
		,"unlock_future": "Unlock requirement coming soon"
		,"jelly_float": "Jelly"
		,"preview_finished": "Preview Finished"
		,"preview_jelly": "Jelly (Preview)"
		,"understood": "Got it"
	}
}

const HIRAGANA_NAMES := {
	"pinwheel":"ぴんうぃーる", "colorata":"ころらーた", "laui":"らうい", "kannte":"かんて",
	"transparent_succulent":"とうめいなぞたにく", "glow_colorata":"ちっこうころらーた", "peach_jelly_succulent":"もものぜりーたにく",
	"sweets_strawberry_shortcake":"いちごしょーとたにく", "sweets_matcha_wafer":"まっちゃうえはーす",
	"metal_silver_rosette":"きょうぎんろぜっと", "metal_cobalt_cluster":"るりはがねびーず", "metal_rose_copper":"ばらどうろぜっと",
	"metal_gold_cluster":"おうごんつぶぶーけ", "metal_gunmetal_rosette":"くろがねろぜっと", "metal_iridescent_star":"にじはがねすたー",
	"metal_silver_branch":"はくぎんぶらんち", "metal_obsidian_spike":"くろはがねすぱいく", "metal_sage_silver":"せいじぎんろぜっと", "metal_patina_copper":"ろくしょうどうろぜっと",
	"forest_amber_insect_rosette":"むしいりこはくろぜっと", "forest_amber_capsules":"もりのこはくかぷせる", "forest_amber_stag_rosette":"おじかのこはくもり",
	"forest_amber_moss_orbs":"こけだまあんばー", "forest_amber_fly_rosette":"こはくばえのはな", "forest_amber_moss_fingers":"こもれびもすふぃんがー",
	"forest_amber_dragonfly_rosette":"とんぼこはく", "forest_amber_aqua_rosette":"あおもりあんばー", "forest_amber_lavender_rosette":"むらさきばなあんばー", "forest_amber_owl_rosette":"ふくろうのこはくもり",
	"jelly_green_apple":"あおりんごぜりー", "stone_black_lava_rosette":"くろようがんろぜっと", "stone_serpentine_rosette":"じゃもんせきろぜっと",
	"stone_granite_rosette":"かこうがんろぜっと", "stone_red_lava_rosette":"あかようがんろぜっと", "stone_sandstone_rosette":"さがんろぜっと",
	"stone_slate_rosette":"ねんばんがんろぜっと", "stone_green_schist_rosette":"りょくしょくへんがんろぜっと", "stone_silver_gneiss_rosette":"ぎんへんまがんろぜっと",
	"stone_obsidian_rosette":"こくようせきろぜっと", "stone_white_marble_rosette":"しろだいりせきろぜっと", "sea_seafoam_bubbles":"うみあわばぶる",
	"sea_starlight_lagoon":"ほししおらぐーん", "sea_sandy_lagoon":"すなはまらぐーん"
}

const HIRAGANA_POT_NAMES := {
	"shallow_terracotta":"あさがた すやきばち",
	"classic_terracotta":"すやきばち",
	"black_ceramic":"くろとうきばち",
	"white_ceramic":"しろとうきばち",
	"clear_crystal":"くりすたるばち",
	"amethyst_crystal":"あめじすとばち",
	"glass_bowl":"がらすぼうるばち",
	"tin_bucket":"あんてぃーくぶりきばち"
}

const HIRAGANA_SERIES_NAMES := {
	"base":"げんしゅ", "metal":"きんぞくたにく",
	"jewel":"ほうせきたにく", "jelly":"ぜりー", "sweets":"すいーつたにく", "gummy":"ぐみたにく",
	"stardust":"ほしくずたにく", "glow":"ちっこうたにく", "neon":"ねおんたにく",
	"stone":"すとーん", "sea":"うみ", "yumekawa":"ゆめふわ", "forest_amber":"もりと こはく"
}

static func normalize_language(value:String)->String:
	return value if value in SUPPORTED_LANGUAGES else LANGUAGE_JA

static func text(language:String,key:String,args:Array=[])->String:
	var lang:=normalize_language(language)
	var table:Dictionary=TEXT.get(lang,{})
	var fallback:Dictionary=TEXT.get(LANGUAGE_JA,{})
	var result:=str(table.get(key,fallback.get(key,key)))
	if not args.is_empty():result=result%args
	return result

static func species_name(language:String,entry:Dictionary)->String:
	var species_id:=str(entry.get("species_id",""))
	match normalize_language(language):
		LANGUAGE_HIRAGANA:
			if HIRAGANA_NAMES.has(species_id):return str(HIRAGANA_NAMES[species_id])
			return _katakana_to_hiragana(str(entry.get("name_ja",species_id)))
		LANGUAGE_EN:
			var explicit:=str(entry.get("name_en",""))
			return explicit if not explicit.is_empty() else species_id.replace("_"," ").capitalize()
		_:
			return str(entry.get("name_ja",species_id))

static func species_description(language:String,entry:Dictionary)->String:
	var japanese:=str(entry.get("description_ja",""))
	match normalize_language(language):
		LANGUAGE_EN:
			var explicit:=str(entry.get("description_en",""))
			return explicit if not explicit.is_empty() else "A succulent recorded in your collection."
		LANGUAGE_HIRAGANA:return "この たにくの とくちょうを きろくした せつめいです。"
		_:return japanese

static func series_name(language:String,entry:Dictionary)->String:
	var series_id:=str(entry.get("series_id",""))
	if normalize_language(language)==LANGUAGE_EN:return "Original Species" if series_id=="base" else series_id.replace("_"," ").capitalize()+" Catalog"
	if normalize_language(language)==LANGUAGE_HIRAGANA:return str(HIRAGANA_SERIES_NAMES.get(series_id,_katakana_to_hiragana(str(entry.get("display_name",series_id)))))
	return str(entry.get("display_name",series_id))

static func series_subtitle(language:String,entry:Dictionary)->String:
	if str(entry.get("series_id",""))=="base":
		if normalize_language(language)==LANGUAGE_EN:return "Records of succulents that once lived in nature"
		if normalize_language(language)==LANGUAGE_HIRAGANA:return "かつて しぜんの なかに いきていた たにくたち"
	var name:=series_name(language,entry)
	match normalize_language(language):
		LANGUAGE_EN:return "Discover the %s collection"%name.trim_suffix(" Catalog")
		LANGUAGE_HIRAGANA:return "%sの なかまたち"%name.trim_suffix("ずかん")
		_:return str(entry.get("subtitle",""))

static func series_description(language:String,entry:Dictionary)->String:
	if str(entry.get("series_id",""))=="base":
		if normalize_language(language)==LANGUAGE_EN:return "An old catalog of lost originals. New forms born today are added as the trio's own records."
		if normalize_language(language)==LANGUAGE_HIRAGANA:return "うしなわれた げんしゅを しるした ふるい ずかんです。いま うまれた とくべつな たにくは、3にんが あたらしい きろくとして かきたします。"
	var name:=series_name(language,entry)
	match normalize_language(language):
		LANGUAGE_EN:return "A catalog recording the succulents in the %s collection."%name.trim_suffix(" Catalog")
		LANGUAGE_HIRAGANA:return "%sの たにくを きろくする ずかんです。"%name.trim_suffix("ずかん")
		_:return str(entry.get("description",""))

static func pot_name(language:String,entry:Dictionary)->String:
	var pot_id:=str(entry.get("pot_id",""))
	match normalize_language(language):
		LANGUAGE_EN:return pot_id.replace("_"," ").capitalize()
		LANGUAGE_HIRAGANA:return str(HIRAGANA_POT_NAMES.get(pot_id,_katakana_to_hiragana(str(entry.get("display_name",pot_id)))))
		_:return str(entry.get("display_name",pot_id))

static func seed_name(language:String,seed_type:String,japanese_name:String)->String:
	var names:={
		"normal":{"hiragana":"ふつうの たね","en":"Normal Seeds"},
		"volume":{"hiragana":"ぼりゅーむぱっく","en":"Volume Pack"},
		"premium":{"hiragana":"ぷれみあむたね","en":"Premium Seeds"},
		"mystery":{"hiragana":"なぞたねぱっく","en":"Mystery Pack"}
	}
	if not names.has(seed_type):return japanese_name
	return str(names[seed_type].get(normalize_language(language),japanese_name))

static func _katakana_to_hiragana(value:String)->String:
	var result:=""
	for index in value.length():
		var code:=value.unicode_at(index)
		if code>=0x30A1 and code<=0x30F6:code-=0x60
		result+=String.chr(code)
	return result
