class_name ArrangementShareBackgrounds
extends RefCounted

const DEFAULT_ID := "greenhouse"

# Share-only background metadata.  The normal arrangement editor and viewer
# deliberately do not render these textures; phase 4 can use crop_mode/focus
# to compose a 9:16 share image without duplicating catalog rules.
const CATALOG := [
	{
		"id": "greenhouse",
		"texture_path": "res://assets/greenhouse-master-horizontal.png",
		"name_key": "share_background_greenhouse",
		"unlock_condition": "always",
		"unlock_text_key": "share_background_available_from_start",
		"crop_mode": "cover",
		"focus": Vector2(0.47, 0.70),
	},
	{
		"id": "puku_members",
		"texture_path": "res://assets/arrangement/share_backgrounds/puku-members.png",
		"name_key": "share_background_puku_members",
		"unlock_condition": "always",
		"unlock_text_key": "share_background_available_from_start",
		"crop_mode": "native_9_16",
		"focus": Vector2(0.50, 0.50),
	},
	{
		"id": "jurejure_gang",
		"texture_path": "res://assets/arrangement/share_backgrounds/jurejure-gang.png",
		"name_key": "share_background_jurejure_gang",
		"unlock_condition": "exploitation_started",
		"unlock_text_key": "share_background_unlock_exploitation",
		"crop_mode": "native_9_16",
		"focus": Vector2(0.50, 0.50),
	},
	{
		"id": "all_characters",
		"texture_path": "res://assets/arrangement/share_backgrounds/all-characters.png",
		"name_key": "share_background_all_characters",
		"unlock_condition": "finale_complete",
		"unlock_text_key": "share_background_unlock_story_clear",
		"crop_mode": "native_9_16",
		"focus": Vector2(0.50, 0.50),
	},
]

static func catalog() -> Array:
	return CATALOG.duplicate(true)

static func entry(background_id: String) -> Dictionary:
	for value in CATALOG:
		if value is Dictionary and str(value.get("id", "")) == background_id:
			return (value as Dictionary).duplicate(true)
	return {}

static func normalize_id(value: Variant) -> String:
	var candidate := str(value)
	return candidate if not entry(candidate).is_empty() else DEFAULT_ID

static func unlock_states(exploitation_started: bool, finale_finished: bool) -> Dictionary:
	return {
		"greenhouse": true,
		"puku_members": true,
		"jurejure_gang": exploitation_started,
		"all_characters": finale_finished,
	}
