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

const COMPLETE_SUBJECT_SIZE := 1254
const SUBJECT_PADDING := 141
const TRANSPARENT_EDGE_MARGIN := 24
const EXPECTED_IMAGE_SIZE := COMPLETE_SUBJECT_SIZE + SUBJECT_PADDING * 2

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game.encyclopedia_unlocked=true;game.unlocked_series={"common":true};game.discovered.clear();game.species_get_counts.clear()
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
		var texture:=load(image_path) as Texture2D;assert(texture!=null and texture.get_size()==Vector2(EXPECTED_IMAGE_SIZE,EXPECTED_IMAGE_SIZE))
		var source_image:=texture.get_image();assert(source_image!=null and source_image.detect_alpha()!=Image.ALPHA_NONE)
		_assert_soft_glow(source_image,species_id)
		var used:=source_image.get_used_rect();var width:=source_image.get_width();var height:=source_image.get_height()
		assert(source_image.get_pixel(0,0).a<.001 and source_image.get_pixel(width-1,0).a<.001 and source_image.get_pixel(0,height-1).a<.001 and source_image.get_pixel(width-1,height-1).a<.001)
		assert(used.position.x>TRANSPARENT_EDGE_MARGIN and used.position.y>TRANSPARENT_EDGE_MARGIN and used.end.x<width-TRANSPARENT_EDGE_MARGIN and used.end.y<height-TRANSPARENT_EDGE_MARGIN, "%s image is clipped: %s in %sx%s"%[species_id,used,width,height])
		var plant:=Succulent.new();add_child(plant);var label:=Label.new();plant.setup(entry,12345,label,label)
		assert(plant.plant_sprite!=null and plant.plant_sprite.texture!=null and plant.plant_sprite.texture.resource_path==image_path)
		plant.queue_free()
		assert(entry not in game.species and not bool(game.greenhouse_available.get(species_id,false)))
	assert(seen.size()==12 and entries.all(func(entry:Dictionary)->bool:return not bool(entry.get("series_seed_eligible",true))))
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
	# The unlocked encyclopedia list must render the restored source textures in
	# full color instead of replacing their alpha gradient with a silhouette.
	for species_id in EXPECTED.keys():
		game.discovered[species_id]=true;game.species_get_counts[species_id]=1
	game._refresh_encyclopedia_cards();await get_tree().process_frame;game._update_encyclopedia_visible_textures();await get_tree().process_frame
	assert(game.encyclopedia_card_images.size()==12)
	for i in range(game.encyclopedia_card_images.size()):
		game._request_species_texture(game.encyclopedia_card_entries[i],game.encyclopedia_card_images[i],true)
	for frame in range(20):await get_tree().process_frame
	for image in game.encyclopedia_card_images:
		assert(image.material==null and image.modulate.is_equal_approx(Color.WHITE) and image.texture!=null)
		_assert_soft_glow(image.texture.get_image(),"encyclopedia_list")
	# The arrangement editor uses the exact same texture with alpha blending and
	# must not flatten or cut away the soft outer glow.
	game._sync_arrangement_ui();var arrangement=game.arrangement_ui
	arrangement.current_arrangement={"arrangement_id":"glow_alpha_test","name":"蓄光確認","pot_id":"shallow_terracotta","created_at":"test","completed":false,"plants":[{"species_id":"glow_aurora_rosette","x":268.0,"y":310.0,"scale":1.0,"rotation":0.0,"z_index":0}]}
	arrangement._show_page(arrangement.editor_page);arrangement._load_editor_from_current();await get_tree().process_frame;await get_tree().process_frame
	assert(arrangement.editor_plant_nodes.size()==1)
	var arrangement_image:=arrangement.editor_plant_nodes[0].get_node("PlantImage") as TextureRect
	assert(arrangement_image!=null and arrangement_image.texture!=null and arrangement_image.material is ShaderMaterial)
	assert(str(arrangement_image.texture.resource_path)=="res://assets/catalog/glow/glow-aurora-rosette.png")
	_assert_soft_glow(arrangement_image.texture.get_image(),"arrangement_editor")
	print("GLOW_SERIES_SMOKE_OK species=",entries.size()," images=",seen.size()," alpha_gradient=true subject_padding=",SUBJECT_PADDING," transparent_edge=",TRANSPARENT_EDGE_MARGIN," encyclopedia=true arrangement=true seed_pool=0 purchase=true")
	get_tree().quit()

func _assert_soft_glow(image:Image,context:String)->void:
	assert(image!=null and image.get_size()==Vector2i(EXPECTED_IMAGE_SIZE,EXPECTED_IMAGE_SIZE),context)
	var transparent_samples:=0;var glow_samples:=0;var soft_glow_samples:=0;var sample_count:=0;var alpha_levels:Dictionary={}
	for y in range(0,image.get_height(),8):
		for x in range(0,image.get_width(),8):
			var alpha:=image.get_pixel(x,y).a;sample_count+=1;alpha_levels[roundi(alpha*255.0)]=true
			if alpha<=.001:transparent_samples+=1
			elif alpha<.98:glow_samples+=1
			if alpha>.001 and alpha<.75:soft_glow_samples+=1
	# The dedicated edge-margin assertion above is the clipping guard. Keep this
	# threshold lower so a deliberately broad halo is not mistaken for a crop.
	assert(transparent_samples>sample_count/10,"%s lacks transparent canvas"%context)
	assert(glow_samples>sample_count/4,"%s lost the semi-transparent glow"%context)
	assert(soft_glow_samples>sample_count/8,"%s lost the soft outer glow"%context)
	assert(alpha_levels.size()>80,"%s alpha was quantized: %d levels"%[context,alpha_levels.size()])
