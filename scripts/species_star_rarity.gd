class_name SpeciesStarRarity
extends RefCounted

# The 128 non-fusion catalog species are split once, by species ID, into two
# equal groups.  Keeping the IDs here makes the assignment stable across
# sessions, save files, catalog sorting, and future data-file reordering.
const NORMAL_ONE_STAR_IDS := {
	"lutea":true,
	"purpusorum":true,
	"pinwheel":true,
	"affinis":true,
	"kannte":true,
	"golden_kannte":true,
	"transparent_succulent":true,
	"gummy_peach_milk":true,
	"gummy_fruit_punch":true,
	"gummy_strawberry":true,
	"gummy_rainbow":true,
	"glow_emerald_rosette":true,
	"glow_amber_glow":true,
	"glow_ruby_star":true,
	"glow_peach_lantern":true,
	"glow_mint_star":true,
	"glow_aurora_rosette":true,
	"sweets_strawberry_shortcake":true,
	"sweets_citrus_mint":true,
	"sweets_matcha_wafer":true,
	"sweets_raspberry_jewel":true,
	"sweets_caramel_cherry":true,
	"metal_silver_rosette":true,
	"metal_rose_copper":true,
	"metal_gunmetal_rosette":true,
	"metal_silver_branch":true,
	"metal_sage_silver":true,
	"neon_cyan_rosette":true,
	"neon_lime_cluster":true,
	"forest_amber_capsules":true,
	"forest_amber_moss_orbs":true,
	"forest_amber_moss_fingers":true,
	"forest_amber_aqua_rosette":true,
	"forest_amber_owl_rosette":true,
	"jelly_orange":true,
	"jelly_green_apple":true,
	"jelly_peach_milk":true,
	"jelly_strawberry":true,
	"jelly_fruit_mix":true,
	"jewel_emerald_rosette":true,
	"jewel_opal_rosette":true,
	"jewel_rose_quartz_rosette":true,
	"jewel_labradorite_star":true,
	"jewel_turquoise_cluster":true,
	"stone_serpentine_rosette":true,
	"stone_red_lava_rosette":true,
	"stone_slate_rosette":true,
	"stone_silver_gneiss_rosette":true,
	"stone_white_marble_rosette":true,
	"yumekawa_pastel_drops":true,
	"yumekawa_moonlight_rosette":true,
	"yumekawa_mint_milk":true,
	"yumekawa_dream_bouquet":true,
	"yumekawa_tricolor_rosettes":true,
	"sea_sandy_tide":true,
	"sea_jellyfish_rosette":true,
	"sea_starlight_lagoon":true,
	"sea_neon_coral":true,
	"sea_tropical_bubbles":true,
	"jurejure_guilty_burger":true,
	"jurejure_compressed_cash":true,
	"jurejure_crown":true,
	"jurejure_luxury_cruise_ship":true,
	"jurejure_supercar":true,
}

const STAR_SYMBOL := "★"
const STAR_COLOR := Color("#c6a04a")

static func star_count(entry:Dictionary)->int:
	var series_id:=str(entry.get("series_id",""))
	match series_id:
		"hybrid":return 2
		"fusion_tier1":return 3
		"fusion_tier2":return 4
		"fusion_tier3":return 5
	var species_id:=str(entry.get("species_id",""))
	return 1 if NORMAL_ONE_STAR_IDS.has(species_id) else 0

static func apply_to_catalog(catalog:Array)->void:
	for value in catalog:
		if not value is Dictionary:continue
		var entry:Dictionary=value
		var stars:=star_count(entry)
		entry["star_rating"]=stars
		# Keep this established internal key readable by old saves and restoration
		# snapshots.  All new selection/display code uses star_rating.
		entry["gold_star_count"]=stars

static func stars_for(entry:Dictionary)->int:
	return clampi(int(entry.get("star_rating",star_count(entry))),0,5)

static func star_text(entry:Dictionary)->String:
	return STAR_SYMBOL.repeat(stars_for(entry))

static func is_fusion_species(entry:Dictionary)->bool:
	return stars_for(entry)>=2

static func random_source_unlocked(stars:int,unlocks:Dictionary)->bool:
	match stars:
		2:return bool(unlocks.get(2,false))
		3:return bool(unlocks.get(3,false))
		4:return bool(unlocks.get(4,false))
		_:return false
