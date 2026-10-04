extends Node

const SEA_FIRST := "sea_pearl_shell"
const SEA_SECOND := "sea_coralline_drops"
const SWEETS_FIRST := "sweets_strawberry_shortcake"
const JEWEL_FIRST := "jewel_opal_rosette"
const SEA_FUSION_FIRST := "hyb_gummy_sea"
const JURE_FUSION_FIRST := "fus1_bonus_time"

func _ready()->void:
	var game=load("res://main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;await get_tree().process_frame
	game._reset_progression_state()
	_test_first_get_and_persistence(game)
	_test_fusion_display_series(game)
	_test_legacy_migration(game)
	_test_cover_request_identity(game)
	print("CATALOG_COVER_SPECIES_SMOKE_OK first_get=fixed fusion=display_series jure=jurejure migration=display_order+listed_entry persistence=true")
	get_tree().quit()

func _test_first_get_and_persistence(game:Node)->void:
	assert(game.catalog_cover_species.is_empty())
	assert(game._series_cover_texture(game._series_entry("sea"))==null)
	# Encounter/catalog visibility without a GET must not establish a cover.
	assert(game._register_species_discovery(SEA_FIRST,false))
	assert(game._species_get_count(SEA_FIRST)==0 and not game.catalog_cover_species.has("sea"))
	assert(game._register_species_discovery(SEA_FIRST,true))
	assert(str(game.catalog_cover_species.get("sea",""))==SEA_FIRST)
	assert(game._series_cover_texture(game._series_entry("sea")).resource_path==str(game._catalog_entry(SEA_FIRST).get("image_path","")))
	assert(game._register_species_discovery(SEA_SECOND,true))
	assert(str(game.catalog_cover_species.get("sea",""))==SEA_FIRST)
	assert(game._register_species_discovery(SWEETS_FIRST,true))
	assert(game._register_species_discovery(JEWEL_FIRST,true))
	assert(str(game.catalog_cover_species.get("sweets",""))==SWEETS_FIRST)
	assert(str(game.catalog_cover_species.get("jewel",""))==JEWEL_FIRST)
	game._save()
	game.catalog_cover_species.clear()
	game._load_save()
	assert(str(game.catalog_cover_species.get("sea",""))==SEA_FIRST)
	assert(str(game.catalog_cover_species.get("sweets",""))==SWEETS_FIRST)
	assert(str(game.catalog_cover_species.get("jewel",""))==JEWEL_FIRST)

func _test_fusion_display_series(game:Node)->void:
	game._reset_progression_state()
	assert(game._register_species_discovery(SEA_FUSION_FIRST,true))
	assert(str(game._catalog_display_series_id_for_entry(game._catalog_entry(SEA_FUSION_FIRST)))=="sea")
	assert(str(game.catalog_cover_species.get("sea",""))==SEA_FUSION_FIRST)
	assert(game._register_species_discovery(SEA_SECOND,true))
	assert(str(game.catalog_cover_species.get("sea",""))==SEA_FUSION_FIRST)
	assert(game._register_species_discovery(JURE_FUSION_FIRST,true))
	assert(str(game._catalog_display_series_id_for_entry(game._catalog_entry(JURE_FUSION_FIRST)))=="jurejure")
	assert(str(game.catalog_cover_species.get("jurejure",""))==JURE_FUSION_FIRST)
	assert(not game.catalog_cover_species.has("hybrid") and not game.catalog_cover_species.has("fusion_tier1"))

func _test_legacy_migration(game:Node)->void:
	game._reset_progression_state()
	# A historical base cover is invalid when that species no longer has a card
	# on the base page, even if its raw species data still says series_id=base.
	game.species_get_counts={"golden_laui":1,"colorata":1}
	game.discovered={"golden_laui":true,"colorata":true}
	game.catalog_cover_species={"base":"golden_laui"}
	assert(game._normalize_catalog_cover_species())
	assert(str(game.catalog_cover_species.get("base",""))=="colorata")
	game.catalog_cover_species.clear()
	assert(not game._remember_catalog_cover_species("golden_laui"))
	assert(not game.catalog_cover_species.has("base"))

	game._reset_progression_state()
	# Deliberately insert the later catalog card first. Migration must use catalog
	# display order rather than Dictionary insertion order or guessed chronology.
	game.species_get_counts={SEA_FIRST:1,SEA_SECOND:2,SEA_FUSION_FIRST:1}
	game.discovered={SEA_FIRST:true,SEA_SECOND:true,SEA_FUSION_FIRST:true}
	game.catalog_cover_species.clear()
	game._save()
	var save_path:String=game._active_save_path()
	var payload=JSON.parse_string(FileAccess.get_file_as_string(save_path))
	assert(payload is Dictionary)
	payload.erase("catalog_cover_species")
	var file:=FileAccess.open(save_path,FileAccess.WRITE);assert(file!=null);file.store_string(JSON.stringify(payload));file.close()
	game.catalog_cover_species={"sea":SEA_FIRST}
	game._load_save()
	assert(game.catalog_cover_migration_dirty)
	assert(str(game.catalog_cover_species.get("sea",""))==SEA_SECOND)
	game._save()
	var migrated=JSON.parse_string(FileAccess.get_file_as_string(save_path))
	assert(migrated is Dictionary and str(migrated.get("catalog_cover_species",{}).get("sea",""))==SEA_SECOND)
	game._register_species_discovery("sea_sandy_tide",true)
	assert(str(game.catalog_cover_species.get("sea",""))==SEA_SECOND)

func _test_cover_request_identity(game:Node)->void:
	game.unlocked_series["sea"]=true;game.unlocked_series["sweets"]=true
	game._register_species_discovery(SWEETS_FIRST,true)
	var owned:Array[Dictionary]=game._owned_series_entries()
	var sea_index:=-1;var sweets_index:=-1
	for index in range(owned.size()):
		var series_id:=str(owned[index].get("series_id",""))
		if series_id=="sea":sea_index=index
		elif series_id=="sweets":sweets_index=index
	assert(sea_index>=0 and sweets_index>=0)
	var card:Dictionary=game.series_carousel_cards[1]
	game._populate_series_card(card,sea_index,owned)
	assert(str(card.container.get_meta("series_id",""))=="sea")
	assert(card.cover_image.texture.resource_path==str(game._catalog_entry(SEA_SECOND).get("image_path","")))
	game._populate_series_card(card,sweets_index,owned)
	assert(str(card.container.get_meta("series_id",""))=="sweets")
	assert(card.cover_image.texture.resource_path==str(game._catalog_entry(SWEETS_FIRST).get("image_path","")))
	assert(str(card.cover_image.get_meta("catalog_request_path",""))=="")
	assert(str(card.cover_image.get_meta("catalog_loaded_path",""))==str(game._catalog_entry(SWEETS_FIRST).get("image_path","")))
