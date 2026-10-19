class_name ArrangementShareBackgrounds
extends RefCounted

const DEFAULT_ID := "greenhouse"

# Share-preview background metadata.  The finished-work viewer and the PNG
# renderer both consume crop_mode/focus/artwork_rect so their 9:16 composition
# stays identical without duplicating layout rules.
const CATALOG := [
	{
		"id": "greenhouse",
		# Match the live arrangement area: the same greenhouse master image,
		# focused on the table center used by main.gd.
		"texture_path": "res://assets/greenhouse-master-horizontal.png",
		"name_key": "share_background_greenhouse",
		"unlock_condition": "always",
		"unlock_text_key": "share_background_available_from_start",
		"crop_mode": "cover",
		"focus": Vector2(340.0 / 1448.0, 760.0 / 1086.0),
		"artwork_rect": Rect2(0.05, 0.38, 0.90, 0.60),
	},
	{
		"id": "puku_members",
		"texture_path": "res://assets/arrangement/share_backgrounds/puku-members.png",
		"name_key": "share_background_puku_members",
		"unlock_condition": "always",
		"unlock_text_key": "share_background_available_from_start",
		"crop_mode": "native_9_16",
		"focus": Vector2(0.50, 0.50),
		"artwork_rect": Rect2(0.05, 0.38, 0.90, 0.60),
	},
	{
		"id": "jurejure_gang",
		"texture_path": "res://assets/arrangement/share_backgrounds/jurejure-gang.png",
		"name_key": "share_background_jurejure_gang",
		"unlock_condition": "exploitation_started",
		"unlock_text_key": "share_background_unlock_exploitation",
		"crop_mode": "native_9_16",
		"focus": Vector2(0.50, 0.50),
		"artwork_rect": Rect2(0.05, 0.38, 0.90, 0.60),
	},
	{
		"id": "all_characters",
		"texture_path": "res://assets/arrangement/share_backgrounds/all-characters.png",
		"name_key": "share_background_all_characters",
		"unlock_condition": "finale_complete",
		"unlock_text_key": "share_background_unlock_story_clear",
		"crop_mode": "native_9_16",
		"focus": Vector2(0.50, 0.50),
		"artwork_rect": Rect2(0.05, 0.38, 0.90, 0.60),
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
