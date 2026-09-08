extends Node

const EXPECTED := {
	"glow_emerald_rosette": "エメラルドロゼット",
	"glow_aqua_drops": "アクアドロップ",
	"glow_amber_glow": "アンバーグロウ",
	"glow_lavender_rosette": "ラベンダーロゼット",
	"glow_ruby_star": "ルビースター",
	"glow_lime_fingers": "ライムフィンガー",
	"glow_peach_lantern": "ピーチランタン",
	"glow_sunlight_rosette": "サンライトロゼット",
	"glow_mint_star": "ミントスター",
	"glow_magenta_beads": "マゼンタビーズ",
	"glow_aurora_rosette": "オーロラロゼット",
	"glow_lime_heart": "ライムハート"
}

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game.encyclopedia_unlocked=true;game.unlocked_series={"base":true};game.discovered.clear();game.species_get_counts.clear()
	var glow:Dictionary=game._series_entry("glow")
	assert(str(glow.get("display_name",""))=="蓄光多肉")
	game.formal_play_count=10
	assert(not game._can_browse_series(glow) and not game._is_series_unlocked(glow) and game._catalog_purchase_enabled(glow))
	var entries:Array[Dictionary]=game._series_species_entries("glow")
	assert(entries.size()==12 and glow.get("species_ids",[])==EXPECTED.keys())
	var seen:Dictionary={}
	for entry in entries:
		var species_id:=str(entry.get("species_id",""));var image_path:=str(entry.get("image_path",""))
		assert(EXPECTED.has(species_id) and str(entry.get("name_ja",""))==EXPECTED[species_id] and not seen.has(species_id));seen[species_id]=true
		assert(str(entry.get("series_id",""))=="glow" and bool(entry.get("catalog_only",false)))
		assert(is_zero_approx(float(entry.get("spawn_weight",-1.0))) and is_zero_approx(float(entry.get("series_seed_weight",-1.0))) and not bool(entry.get("series_seed_eligible",true)))
		assert(image_path.begins_with("res://assets/catalog/glow/") and image_path.ends_with(".png") and ResourceLoader.exists(image_path))
		var texture:=load(image_path) as Texture2D;assert(texture!=null and texture.get_size()==Vector2(1280,1280))
		var source_image:=texture.get_image();assert(source_image!=null and source_image.detect_alpha()!=Image.ALPHA_NONE)
		var transparent_samples:=0;var glow_samples:=0;var sample_count:=0
		for y in range(0,1280,8):
			for x in range(0,1280,8):
				var alpha:=source_image.get_pixel(x,y).a;sample_count+=1
				if alpha<=0.001:transparent_samples+=1
				elif alpha<0.98:glow_samples+=1
		assert(transparent_samples>sample_count/4 and glow_samples>sample_count/4)
		var plant:=Succulent.new();add_child(plant);var label:=Label.new();plant.setup(entry,12345,label,label)
		assert(plant.plant_sprite!=null and plant.plant_sprite.texture!=null and plant.plant_sprite.texture.resource_path==image_path)
		plant.queue_free()
		assert(entry not in game.species and not bool(game.greenhouse_available.get(species_id,false)))
	assert(seen.size()==12 and game.mystery_pod_system.eligible_species_for_series("glow").is_empty())
	game.unlocked_series["glow"]=true;game._open_encyclopedia();assert(game._owned_series_entries().size()==2)
	game.current_encyclopedia_series_id="glow";game.encyclopedia_series_page.visible=false;game.encyclopedia_list_page.visible=true;game._refresh_encyclopedia_header();game._refresh_encyclopedia_cards();await get_tree().process_frame;game._update_encyclopedia_visible_textures()
	assert(game.encyclopedia_list_title.text=="蓄光多肉" and not game.encyclopedia_list_progress.visible and not game.encyclopedia_list_get.visible and not game.encyclopedia_field_button.visible and game.encyclopedia_grid.get_child_count()==12)
	assert(not game.encyclopedia_unlock_panel.visible)
	for card in game.encyclopedia_grid.get_children():
		assert(card.disabled)
		var texts:Array[String]=[]
		for label in card.find_children("*","Label",true,false):texts.append(str(label.text))
		assert("？？？" in texts and "未発見" in texts and "GET 0" in texts)
	for image in game.encyclopedia_card_images:
		assert(image.material==null and image.modulate.is_equal_approx(Color(0.12,0.09,0.08,0.82)))
		if image.texture!=null:assert(str(image.texture.resource_path).begins_with("res://assets/catalog/glow/"))
	print("GLOW_SERIES_SMOKE_OK species=",entries.size()," images=",seen.size()," silhouette_cards=",game.encyclopedia_grid.get_child_count()," seed_pool=0 purchase=true")
	get_tree().quit()
