class_name StoryProgression
extends RefCounted

const STAGE_OLD_SEED := 0
const STAGE_TRIO := 1
const STAGE_FIND_HABITAT := 2
const STAGE_AWAKEN_HABITAT := 3
const STAGE_ORIGINALS_5 := 4
const STAGE_SIZE_50 := 5
const STAGE_ORIGINALS_8 := 6
const STAGE_SIZE_100 := 7
const STAGE_ORIGINALS_12 := 8
const STAGE_SECOND_AWAKENING := 9
const STAGE_COMPLETE := 10

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

static func best_size(bests: Dictionary) -> float:
	var result := 0.0
	for value in bests.values():
		result = maxf(result, float(value))
	return result

static func infer_stage(
		first_colorata_confirmed: bool,
		trio_originals_confirmed: bool,
		habitat_unlocked: bool,
	habitat_arrival_started: bool,
	habitat_awakened: bool,
	discovered: Dictionary,
	bests: Dictionary,
	habitat_second_awakened: bool = false
	) -> int:
	if not first_colorata_confirmed:
		return STAGE_OLD_SEED
	if not trio_originals_confirmed:
		return STAGE_TRIO
	if not habitat_unlocked or not habitat_arrival_started:
		return STAGE_FIND_HABITAT
	if not habitat_awakened:
		return STAGE_AWAKEN_HABITAT
	var restored := original_count(discovered)
	var record := best_size(bests)
	if restored < 5:
		return STAGE_ORIGINALS_5
	if record < 50.0:
		return STAGE_SIZE_50
	if restored < 8:
		return STAGE_ORIGINALS_8
	if record < 100.0:
		return STAGE_SIZE_100
	if restored < MAIN_STORY_ORIGINAL_IDS.size():
		return STAGE_ORIGINALS_12
	if not habitat_second_awakened:
		return STAGE_SECOND_AWAKENING
	return STAGE_COMPLETE

static func is_removed_species(species_id: String) -> bool:
	return species_id in REMOVED_COMMON_SPECIES_IDS
