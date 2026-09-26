class_name StoryProgression
extends RefCounted

# Older saves may still contain an integer `main_story_stage`. Keep only its
# numeric bounds for tolerant deserialization; it is never consulted to decide
# current progression.
const LEGACY_STAGE_MIN := 0
const LEGACY_STAGE_MAX := 10

# v24+ story progression is expressed only by independent act flags.
const ACT_1 := 1
const ACT_2 := 2
const ACT_3 := 3
const ACT_FINALE := 4

static func act_stage(act2_unlocked:bool,act3_unlocked:bool,finale_complete:bool)->int:
	if finale_complete:return ACT_FINALE
	if act3_unlocked:return ACT_3
	if act2_unlocked:return ACT_2
	return ACT_1

const REMOVED_COMMON_SPECIES_IDS := [
	"momotaro", "lola", "black_prince", "perle_von_nurnberg", "shirobotan",
	"shurei", "bronze_hime", "nijinotama", "pink_pretty", "prolidety"
]

const MAIN_STORY_ORIGINAL_IDS := [
	"colorata", "lutea", "hyalina_san_luis_de_la_paz", "purpusorum",
	"shaviana", "pinwheel", "juliana", "affinis", "laui", "kannte",
	"tovarensis_tovar", "strictiflora_bustamante"
]

static func original_count(discovered: Dictionary) -> int:
	var count := 0
	for species_id in MAIN_STORY_ORIGINAL_IDS:
		if bool(discovered.get(species_id, false)):
			count += 1
	return count

static func originals_complete(discovered: Dictionary) -> bool:
	return original_count(discovered) >= MAIN_STORY_ORIGINAL_IDS.size()

static func is_removed_species(species_id: String) -> bool:
	return species_id in REMOVED_COMMON_SPECIES_IDS
