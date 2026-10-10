extends Node

signal rescue_reward_ad_requested(reward_context:String)

const SucculentClass = preload("res://scripts/succulent.gd")
const AudioManagerClass = preload("res://scripts/audio_manager.gd")
const JellyBalanceClass = preload("res://scripts/jelly_balance.gd")
const ArrangementUIClass = preload("res://scripts/arrangement_ui.gd")
const ArrangementShareBackgroundsClass = preload("res://scripts/arrangement_share_backgrounds.gd")
const ArrangementNavigationHintClass = preload("res://scripts/arrangement_navigation_hint.gd")
const PotUnlockIAPServiceClass = preload("res://scripts/pot_unlock_iap_service.gd")
const CatalogPreviewDevClass = preload("res://scripts/catalog_preview_dev.gd")
const ForestGachaSystemClass = preload("res://scripts/forest_gacha_system.gd")
const ForestGachaUIClass = preload("res://scripts/forest_gacha_ui.gd")
const SpeciesGetOverlayClass = preload("res://scripts/species_get_overlay.gd")
const CatalogSeriesUnlockOverlayClass = preload("res://scripts/catalog_series_unlock_overlay.gd")
const FusionSystemClass = preload("res://scripts/fusion_system.gd")
const FusionLabUIClass = preload("res://scripts/fusion_lab_ui.gd")
const Localizer = preload("res://scripts/game_localizer.gd")
const DialoguePortraitsClass = preload("res://scripts/dialogue_portraits.gd")
const UISymbolIconClass = preload("res://scripts/ui_symbol_icon.gd")
const HabitatWildSystemClass = preload("res://scripts/habitat_wild_system.gd")
const HabitatNotificationServiceClass = preload("res://scripts/habitat_notification_service.gd")
const HabitatPlantPanelClass = preload("res://scripts/habitat_plant_panel.gd")
const HabitatDevPanelClass = preload("res://scripts/habitat_dev_panel.gd")
const StoryDevPresetsClass = preload("res://scripts/story_dev_presets.gd")
const StoryDevPanelClass = preload("res://scripts/story_dev_panel.gd")
const OpeningStoryOverlayClass = preload("res://scripts/opening_story_overlay.gd")
const HabitatAwakeningOverlayClass = preload("res://scripts/habitat_awakening_overlay.gd")
const SeedPodStoryOverlayClass = preload("res://scripts/seed_pod_story_overlay.gd")
const StoryProgressionClass = preload("res://scripts/story_progression.gd")
const JureJureSystemClass = preload("res://scripts/jurejure_system.gd")
const JureJureFirstEncounterOverlayClass = preload("res://scripts/jurejure_first_encounter_overlay.gd")
const PukuPukuBattleClass = preload("res://scripts/puku_puku_battle.gd")
const HabitatSecondAwakeningOverlayClass = preload("res://scripts/habitat_second_awakening_overlay.gd")
const HabitatCrisisAtmosphereClass = preload("res://scripts/habitat_crisis_atmosphere.gd")
const HabitatRestorationClass = preload("res://scripts/habitat_restoration.gd")
const HabitatRestorationUIClass = preload("res://scripts/habitat_restoration_ui.gd")
const EndlessGreenhouseExperimentClass = preload("res://scripts/endless_greenhouse_experiment.gd")
const SlotMachineScene = preload("res://scenes/slot_machine.tscn")
# Master release gate for every development-only UI and action. Keep this true
# for Web, Codemagic iOS, and native development builds. The App Store release
# can disable the whole group by changing this single value to false.
const TRIAL_DEV_CONTROLS_ENABLED := true
# Kept as a compatibility alias for existing tests/callers. Catalog preview is
# deliberately governed by the same release gate instead of a second switch.
const DEVELOPMENT_CATALOG_PREVIEW_ENABLED := TRIAL_DEV_CONTROLS_ENABLED
const PROGRESSION_VERSION := 28
const RETIRED_CONTENT_VERSION := 1
const NORMAL_SAVE_PATH := EndlessGreenhouseExperimentClass.NORMAL_SAVE_PATH
const ENDLESS_EXPERIMENT_SAVE_PATH := EndlessGreenhouseExperimentClass.EXPERIMENT_SAVE_PATH
const LEGACY_HABITAT_REGENERATION_VERSION := 17
const INITIAL_SERIES_ID := "base"
const ORIGINAL_SERIES_ID := "base"
const FIRST_STORY_SPECIES_ID := "colorata"
const FIRST_STORY_COLORATA_GROWTH_MULTIPLIER := 1.3
const PANDA_STORY_SPECIES_ID := "affinis"
const ARMADILLO_STORY_SPECIES_ID := "shaviana"
const FOREST_GACHA_SPIN_COST := 1
const TRIAL_DEV_GACHA_WALLET := 9999
const LEGACY_COMBINED_GAUGE_TARGET_CM := 600.0
const SEED_POD_GAUGE_TARGET_CM := 750.0
const SEED_POD_GAUGE_REWARD_BAGS := 3
const PUKU_UNITS_PER_PUKU := 1000
const NORMAL_ROUND_COST_UNITS := 1000
const PUKU_GAUGE_FINISH_SPEED_SCALE := 0.5
const FIRST_GET_MIN_REWARD_UNITS := 200
const INITIAL_PUKU_CAPITAL_UNITS := 5000
const LEGACY_PUKU_GAUGE_TARGET_CM := 500.0
const LEGACY_PUKU_GAUGE_REWARD_UNITS := 3000
const HARVEST_PUKU_REWARD_ANCHORS := [
	Vector2(0.0,0.0),Vector2(20.0,50.0),Vector2(30.0,120.0),
	Vector2(40.0,220.0),Vector2(50.0,400.0),Vector2(60.0,650.0),
	Vector2(70.0,1050.0),Vector2(80.0,1650.0),Vector2(90.0,2500.0),
	Vector2(100.0,3750.0),Vector2(110.0,5500.0),Vector2(120.0,8000.0),
	Vector2(130.0,11000.0),Vector2(140.0,14000.0),Vector2(150.0,17000.0),
]
const HARVEST_PUKU_POST_150_UNITS_PER_10_CM := 3000.0
const ENDLESS_AUTO_SOW_TUTORIAL_STEP := "endless_auto_sow_prompt_seen"
const HABITAT_TIME_MULTIPLIERS := [1, 60, 3600, 21600, 86400]
const DEFAULT_POT_ID := "shallow_terracotta"
const POT_PRICE_PUKU := 1
const NORMAL_GERMINATION_COUNT := 12
const VOLUME_GERMINATION_COUNT := 36
const PREMIUM_GERMINATION_COUNT := 24
const MYSTERY_GERMINATION_COUNT := 5
const OLD_SEED_GERMINATION_COUNT := 1
const TUTORIAL_HARVEST_CM := 25.0
const OLD_SEED_REACTION_SPROUT_CM := 2.2
const OLD_SEED_REACTION_GROWTH_CM := 12.0
const PLAY_INITIAL_MIN_PLANTS := 9
const PLAY_INITIAL_MAX_PLANTS := 12
const ENDLESS_NORMAL_MIN_PLANTS := 7
const ENDLESS_NORMAL_MAX_PLANTS := 10
const GREENHOUSE_MASTER_PATH := "res://assets/greenhouse-master-horizontal.png"
const GREENHOUSE_MASTER_SOURCE_SIZE := Vector2(1448.0,1086.0)
const SOIL_SOURCE_CENTER := Vector2(1060.0,600.0)
const SOIL_SOURCE_RADII := Vector2(300.0,150.0)
const SPAWN_SPRITE_MARGIN_SOURCE_PX := 40.0
const GREENHOUSE_DRAG_SCALE := 0.30
const GREENHOUSE_DRAG_DEAD_ZONE := 3.0
const GREENHOUSE_PAN_FOLLOW_SECONDS := 0.075
const ARRANGEMENT_TRANSITION_SECONDS := 0.28
const GREENHOUSE_AREA_DRAG_DEAD_ZONE := 14.0
const GREENHOUSE_AREA_DRAG_HORIZONTAL_BIAS := 1.15
const GREENHOUSE_AREA_FLICK_THRESHOLD := 650.0
const ARRANGEMENT_TABLE_SOURCE_CENTER := Vector2(340.0,760.0)
const ARRANGEMENT_TABLE_SCREEN_TARGET_RATIO := Vector2(0.50,760.0/1086.0)
const ARRANGEMENT_POT_ANCHOR := Vector2(0.50,760.0/1086.0)
const ARRANGEMENT_SHARE_TEXTURE_TIMEOUT_MSEC := 8000
const HABITAT_DRAG_SCALE := 0.055
const HABITAT_LOOKAROUND_DURATION_SECONDS := 8.0
const HABITAT_ARRIVAL_LOOKAROUND_DURATION_SECONDS := 4.0
const HABITAT_ARRIVAL_LOOKAROUND_DEGREES := 180.0
const HABITAT_ITEM_RADIUS := 9.0
const NORMAL_SEED_UNLOCKED_NEW_RATE := 0.03
const NORMAL_SEED_LOCKED_NEW_RATE := 0.01
const NORMAL_SEED_NO_STAR_RATE := 0.81
const NORMAL_SEED_ONE_STAR_RATE := 0.10
const NORMAL_SEED_TWO_STAR_RATE := 0.05
const NORMAL_SEED_ONE_STAR_START := 0.85
const NORMAL_SEED_TWO_STAR_START := 0.95
const SEED_PACK_CONFIG := {
	"normal":{"count":12,"rare":0.10,"super":0.05,"new":NORMAL_SEED_UNLOCKED_NEW_RATE+NORMAL_SEED_LOCKED_NEW_RATE},
	"volume":{"count":36,"rare":0.10,"super":0.05,"new":0.03},
	"premium":{"count":24,"rare":0.30,"super":0.10,"new":0.03},
	"mystery":{"count":5,"rare":0.0,"super":0.0,"new":0.0}
}
const RESCUE_REWARD_SEED_TYPE := "normal"
const RESCUE_REWARD_SEED_BAGS := 1
const REWARDED_AD_DEVELOPMENT_STUB_ENABLED := true
const HIDDEN_PINWHEEL_ID := "pinwheel"
const HIDDEN_TOVAR_ID := "tovarensis_tovar"
const HIDDEN_BUSTAMANTE_ID := "strictiflora_bustamante"
const MYSTERY_RESEARCH_TRANSPARENT_ID := "transparent_succulent"
const BEST_UNLOCK_HYALINA_ID := "hyalina_san_luis_de_la_paz"
const BEST_UNLOCK_PURPUSORUM_ID := "purpusorum"
const BEST_UNLOCK_HYALINA_CM := 40.0
const BEST_UNLOCK_PURPUSORUM_CM := 60.0
const BEST_UNLOCK_PURPUSORUM_SPECIES_COUNT := 3
const TOVAR_FIRST_PLAY := 6
const FANTASY_SERIES_IDS := [
	"gummy", "metal", "sweets", "glow", "jewel", "jelly", "stardust",
	"stone", "sea", "yumekawa", "forest_amber", "neon"
]
const FANTASY_SIX_REQUIRED_SERIES := ["jelly", "yumekawa", "stone", "jewel"]
const JUREJURE_STORY_GROUP := "jurejure"
const JUREJURE_SERIES_ID := "jurejure"
const SHOP_CHATTER_KEYS := [
	"shop_chatter_today","shop_chatter_share","shop_chatter_welcome",
	"shop_chatter_living_jewel","shop_chatter_puku_help"
]
const HABITAT_SAFE_PLANT_POINTS := [Vector2(70,400),Vector2(155,410),Vector2(245,400),Vector2(335,420),Vector2(430,405),Vector2(535,415),Vector2(705,430),Vector2(820,410),Vector2(920,395),Vector2(1025,420),Vector2(1130,400),Vector2(1220,415)]
const HABITAT_SAFE_SEED_POINTS := [Vector2(45,430),Vector2(115,445),Vector2(190,430),Vector2(275,445),Vector2(360,440),Vector2(455,435),Vector2(545,445),Vector2(625,455),Vector2(715,450),Vector2(805,440),Vector2(895,430),Vector2(980,445),Vector2(1060,435),Vector2(1140,445),Vector2(1210,435),Vector2(1260,455)]
const UI_CREAM := Color("#fff1d2")
const UI_BROWN := Color("#4a2618")
const UI_GOLD := Color("#e8aa35")
const FIRST_PLAY_TUTORIAL_MESSAGE_KEYS := ["tutorial_normal_sprout","tutorial_normal_growth","tutorial_normal_jelly"]
const FIRST_PLAY_TUTORIAL_SPEAKERS := ["panda","girl","armadillo"]
const FIRST_PLAY_TUTORIAL_INITIAL_DELAY := 0.65
const FIRST_PLAY_TUTORIAL_GROWTH_DIALOG_CM := 9.0
const FIRST_PLAY_TUTORIAL_JELLY_DIALOG_CM := 18.0
const FIRST_PLAY_TUTORIAL_JELLY_OBSERVE_SECONDS := 0.55
const FIRST_PLAY_TUTORIAL_NEW_OBSERVE_SECONDS := 3.0
const FIRST_PLAY_TUTORIAL_FRONT_SPAWN_MIN_Z := 0.75
const SERIES_CAROUSEL_TRACK_ORIGIN := Vector2(48,0)
const SERIES_CAROUSEL_CARD_SIZE := Vector2(480,590)
const SERIES_CAROUSEL_SPACING := 420.0
const SERIES_CAROUSEL_SWIPE_THRESHOLD := 78.0
const SERIES_CAROUSEL_SLIDE_SECONDS := 0.28
const COLLECTION_COMPLETE_FADE_OUT_SECONDS := 0.55
const COLLECTION_COMPLETE_FADE_IN_SECONDS := 1.0
const COLLECTION_COMPLETE_SILHOUETTE_SECONDS := 0.72
const COLLECTION_COMPLETE_REVEAL_SECONDS := 0.56
const COLLECTION_COMPLETE_LIGHT_SECONDS := 0.9
const ENDING_BGM_FADE_IN_SECONDS := 2.5
const ENDING_BGM_FADE_OUT_SECONDS := 1.25

var rng := RandomNumberGenerator.new()
var endless_greenhouse := EndlessGreenhouseExperimentClass.new()
var catalog_preview_rng := RandomNumberGenerator.new()
var forest_gacha_rng := RandomNumberGenerator.new()
var species: Array = []
var catalog_species: Array = []
var opening_species: Array = []
var plants: Array = []
var recent_vacated_slots: Array[Vector3] = []
var pending_seed_positions: Array[Vector3] = []
var camera: Camera3D
var world_root: Node3D
var pot_root: Node3D
var greenhouse_layer: CanvasLayer
var greenhouse_backdrop: TextureRect
var greenhouse_pan_x := 0.0
var greenhouse_pan_target_x := 0.0
var greenhouse_pan_limit := 0.0
var greenhouse_world_pan_x := 0.0
var greenhouse_main_position_x := 0.0
var greenhouse_arrangement_position_x := 0.0
var greenhouse_background_position_x := 0.0
var arrangement_transition_x := 0.0
var arrangement_transition_target_x := 0.0
var saved_greenhouse_pan_x := 0.0
var arrangement_scene_active := false
var arrangement_transitioning := false
var arrangement_transition_tween: Tween
var greenhouse_area_drag_tracking := false
var greenhouse_area_drag_started := false
var greenhouse_area_drag_from_arrangement := false
var greenhouse_area_drag_start_position := Vector2.ZERO
var greenhouse_area_drag_last_position := Vector2.ZERO
var greenhouse_area_drag_start_transition_x := 0.0
var greenhouse_area_drag_velocity_x := 0.0
var greenhouse_area_drag_last_ticks_msec := 0
var habitat_env: WorldEnvironment
var habitat_environment: Environment
var habitat_background_mode := "current"
var habitat_panorama_mesh: MeshInstance3D
var habitat_items_root: Node3D
var habitat_pickups: Array = []
var pending_habitat_species: Array = []
var completed_unlock_conditions: Dictionary = {}
var unlock_rules: Array = []
var total_play_count := 0
var normal_play_count := 0
var formal_play_count := 0
var shop_visit_count := 0
var hidden_species_acquired: Dictionary = {}
var tovar_next_play := TOVAR_FIRST_PLAY
var tovar_attempt_count := 0
var tovar_event_active := false
var tovar_harvested_this_play := false
var intro_story_complete := false
var opening_story_complete := false
var first_colorata_confirmed := false
var trio_originals_confirmed := false
var habitat_arrival_started := false
var habitat_awakened := false
var habitat_awakening_event_complete := false
var seed_shop_open := false
var mystery_items_acquired := false
var mystery_catalog_tutorial_complete := false
var habitat_returned_species: Dictionary = {}
var special_series_explanation_seen := false
var pending_special_series_explanation := false
var main_story_stage := StoryProgressionClass.ACT_1
var main_story_complete := false
var main_story_completion_seen := false
var act2_unlocked := false
var story_progression_state: Dictionary = StoryProgressionClass.default_runtime_state()
var forest_gacha_unlocked := false
var forest_gacha_intro_seen := false
var fantasy_first_discovery_seen := false
var fantasy_realization_seen := false
var act3_unlocked := false
var act3_intro_pending := false
var act3_intro_seen := false
var jurejure_pool_unlocked := false
var jurejure_species_unlocked: Dictionary = {}
var jurejure_species_first_seen := false
var habitat_crisis_pending := false
var habitat_crisis_started := false
var finale_complete := false
var habitat_return_dialog_seen := false
var original_catalog_complete_event_seen := false
var habitat_tutorial_returned_to_greenhouse := false
var jurejure_intro_complete := false
var jurejure_enabled := false
var jurejure_growth_stage := JureJureSystemClass.GROWTH_EARLY
var jurejure_growth_event_mask := 0
var active_jurejure_event: Dictionary = {}
var jurejure_next_check_unix := 0.0
var jurejure_cooldown_until_unix := 0.0
var jurejure_return_event_complete := false
var jurejure_waiting_for_seed_pod_reward := false
var jurejure_battle_count := 0
var jurejure_battle_win_count := 0
var jurejure_habitat_visit_point := Vector2(-1.0,-1.0)
var jurejure_pending_reward_species_id := ""
var jurejure_pending_reward_is_new := false
var jurejure_last_battle_result: Dictionary = {}
var habitat_second_awakened := false
var habitat_second_awakening_complete := false
var jurejure_update_accumulator := 0.0
var encyclopedia_unlocked := false
var habitat_unlocked := false
var tutorial_steps: Dictionary = {}
var mode_button: Button
var shop_button: Button
var arrangement_button: Button
var forest_gacha_button: Button
var shop_forest_gacha_button: Button
var fusion_lab_button: Button
var settings_button:Button
var current_mode := "greenhouse"
var labels_layer: Control
var main_status_hud: Control
var mission_panel: PanelContainer
var mission_title_label: Label
var mission_text_label: Label
var effects_layer: Control
var best_panel: PanelContainer
var best_label: Label
var puku_gauge_label: Label
var puku_gauge_area: Control
var puku_gauge_meter: ProgressBar
var puku_gauge_glow: Panel
var puku_gauge_glow_style: StyleBoxFlat
var puku_gauge_fill_style: StyleBoxFlat
var puku_gauge_glow_tween: Tween
var puku_point_label: Label
var puku_gain_label: Label
var puku_gain_tween: Tween
var puku_combo_label: Label
var puku_combo_tween: Tween
var puku_gauge_combo_count := 0
var puku_gauge_display_units := 0.0
var puku_points_display := 0
var puku_gauge_animation_queue: Array[Dictionary] = []
var puku_gauge_animation_running := false
var puku_gauge_animation_speed_scale := 1.0
var puku_gauge_threshold_flash_count := 0
var puku_gauge_animation_generation := 0
var puku_gauge_active_tween: Tween
var seed_pod_gauge_label: Label
var seed_pod_gauge_area: Control
var seed_pod_gauge_meter: ProgressBar
var seed_pod_gauge_fill_style: StyleBoxFlat
var seed_pod_gauge_glow: Panel
var seed_pod_gauge_glow_style: StyleBoxFlat
var seed_pod_reward_tween: Tween
var record_card: PanelContainer
var record_text: Label
var encyclopedia_overlay: Control
var encyclopedia_series_page: Control
var encyclopedia_list_page: Control
var encyclopedia_detail_page: Control
var encyclopedia_grid: GridContainer
var encyclopedia_scroll: ScrollContainer
var encyclopedia_card_images: Array[TextureRect] = []
var encyclopedia_card_entries: Array[Dictionary] = []
var encyclopedia_silhouette_material: ShaderMaterial
var series_catalog: Array = []
var species_picker_series_catalog: Array = []
var catalog_progression: Dictionary = {}
var selected_series_index := 0
var current_encyclopedia_series_id := INITIAL_SERIES_ID
var series_title_label: Label
var series_subtitle_label: Label
var series_description_label: Label
var series_cover_image: TextureRect
var series_cover_placeholder: Label
var series_lock_label: Label
var series_carousel_track: Control
var series_carousel_cards: Array[Dictionary] = []
var series_carousel_offset := 0.0
var series_carousel_animating := false
var series_carousel_tween: Tween
var series_progress_label: Label
var series_get_label: Label
var all_series_get_label: Label
var series_position_label: Label
var series_previous_button: Button
var series_next_button: Button
var series_swipe_start := Vector2.ZERO
var series_swipe_tracking := false
var series_swipe_axis := 0
var encyclopedia_list_title: Label
var encyclopedia_list_progress: Label
var encyclopedia_list_get: Label
var encyclopedia_unlock_panel: PanelContainer
var encyclopedia_unlock_status: Label
var encyclopedia_unlock_puku_button: Button
var encyclopedia_complete_badge_label: Label
var collection_complete_versions: Dictionary = {}
var collection_complete_species_ids_cache: Array[String] = []
var collection_complete_species_membership_cache: Dictionary = {}
var collection_complete_species_ids_cache_ready := false
var collection_complete_pending_species_id := ""
var collection_complete_resume_context := ""
var collection_complete_resume_shop_visible := false
var collection_complete_presentation_active := false
var collection_complete_presentation_phase := ""
var collection_complete_catalog_ready_before_fade_in := false
var collection_complete_prepared_series_id := ""
var collection_complete_prepared_species_id := ""
var collection_complete_prepared_scroll := 0
var collection_complete_target_image: TextureRect
var collection_complete_silhouette_image: TextureRect
var collection_complete_overlay: Control
var collection_complete_effect_layer: Control
var collection_complete_card: PanelContainer
var collection_complete_title_label: Label
var collection_complete_message_label: Label
var collection_complete_version_label: Label
var collection_complete_continue_button: Button
var collection_complete_animation_speed_scale := 1.0
var habitat_status_label: Label
var seed_bag_panel: PanelContainer
var play_timer_label: Label
var play_open_button: Button
var play_overlay: Control
var play_bag_summary: Label
var normal_play_button: Button
var volume_play_button: Button
var premium_play_button: Button
var mystery_play_button: Button
var old_seed_play_button: Button
var shop_overlay: Control
var shop_background: TextureRect
var armadillo_tap_button: Button
var armadillo_present := false
var mystery_seed_count := 0
var armadillo_research_total := 0
var armadillo_research_rewards: Dictionary = {}
var armadillo_research_intro_seen := false
var research_catalog_reward_pending := false
var research_catalog_reward_overlay: Control
var research_catalog_reward_grid: VBoxContainer
var armadillo_dialog_mode := ""
var shop_wallet_label: Label
var shop_bag_label: Label
var shop_message: Label
var shop_premium_buy_button: Button
var shop_volume_buy_button: Button
var shop_mystery_buy_button: Button
var shop_product_tabs: Dictionary = {}
var shop_product_detail_label: Label
var shop_selected_buy_button: Button
var shop_buy_glow: Panel
var shop_selected_seed_type := "normal"
var shop_buy_pulse_tween: Tween
var shop_purchase_controls: Array[Control] = []
var shop_category_controls: Array[Control] = []
var shop_catalog_controls: Array[Control] = []
var shop_category_back_button: Button
var shop_catalog_message: Label
var shop_current_page := "categories"
var shop_purchase_ui_enabled := true
var shop_chatter_bubble: PanelContainer
var shop_chatter_portrait: TextureRect
var shop_chatter_label: Label
var shop_chatter_action_button: Button
var shop_chatter_decline_button: Button
var shop_transfer_notice: Label
var shop_pot_button: Button
var shop_chatter_pages: Array[String] = []
var shop_chatter_page_index := 0
var shop_chatter_sequence_kind := ""
var shop_chatter_sequence_speaker := "panda"
var last_shop_chatter := ""
var rescue_reward_in_progress := false
var rescue_reward_context := ""
var intro_overlay: Control
var intro_dialog_panel: PanelContainer
var intro_dialogue_label: Label
var intro_continue_button: Button
var intro_speaker_label: Label
var intro_panda_portrait: TextureRect
var intro_portrait_slot: Control
var intro_trio_portraits: Control
var intro_fullscreen_continue_button: Button
var intro_story_step := 0
var intro_is_daily_gift := false
var tutorial_dialog_kind := ""
var scripted_dialog_kind := ""
var scripted_dialog_pages: Array[Dictionary] = []
var scripted_dialog_index := -1
var scripted_dialog_shop_context := false
var tutorial_guide_overlay: Control
var tutorial_guide_shade: ColorRect
var tutorial_guide_button: Button
var tutorial_highlight_tween: Tween
var tutorial_guide_message: Label
var tutorial_panda_portrait: TextureRect
var tutorial_dialog_panel: PanelContainer
var tutorial_cost_note_panel: PanelContainer
var tutorial_cost_note_label: Label
var tutorial_habitat_item: Dictionary = {}
var tutorial_harvest_plant: Node
var first_play_tutorial_active := false
var first_play_tutorial_dialog_visible := false
var first_play_tutorial_message_index := 0
var first_play_tutorial_wait_remaining := 0.0
var first_play_tutorial_sequence_complete := false
var first_play_tutorial_phase := ""
var first_play_tutorial_reserved_seed_pending := false
var first_play_tutorial_reserved_species_id := ""
var first_play_tutorial_reserved_plant: Node
var first_play_tutorial_forced_jelly_plant: Node
var first_play_tutorial_observe_remaining := 0.0
var first_play_harvest_guide_active := false
var old_seed_harvest_guide_active := false
var first_play_has_harvested := false
var first_seed_pod_reward_event_active := false
var old_seed_reaction_stage := 0
var first_tutorial_species_id := ""
var first_play_harvest_spotlight_material: ShaderMaterial
var normal_play_tutorial_complete := false
var seed_pod_gauge_discovery_complete := false
var seed_pod_first_reward_seen := false
var initial_seed_stock_notice_complete := false
var puku_buyback_tutorial_complete := false
var puku_buyback_tutorial_active := false
var puku_buyback_tutorial_index := 0
var habitat_scroll_tutorial_active := false
var puku_gauge_intro_complete := false
var settings_overlay: Control
var settings_title_label:Label
var settings_language_heading:Label
var settings_close_button:Button
var settings_language_status:Label
var language_buttons:Dictionary={}
var harvest_sound_test_variant:=0
var harvest_sound_test_buttons:Array[Button]=[]
var harvest_sound_test_status:Label
var progression_dev_labels:Dictionary={}
var endless_economy_debug_label:Label
var jelly_dev_overlay: Control
var jelly_dev_labels:Dictionary={}
var jelly_dev_total_label:Label
var jelly_trait_toggle_button:Button
var jelly_trait_display_enabled:=false
var dev_jelly_test_active:=false
var catalog_preview_ui
var catalog_preview_settings_button:Button
var catalog_preview_mode_active:=false
var forest_gacha_system
var forest_gacha_ui
var forest_gacha_draw_count:=0
var forest_gacha_encountered:Dictionary={}
var forest_gacha_preview_mode:=false
var forest_gacha_trial_dev_mode:=false
var forest_gacha_preview_puku_points:=10
var forest_gacha_preview_draw_count:=0
var forest_gacha_preview_discovered:Dictionary={FIRST_STORY_SPECIES_ID:true}
var forest_gacha_preview_encountered:Dictionary={}
var trial_dev_gacha_button:Button
var series_seed_inventory:Dictionary={}
var active_series_seed_id:=""
var species_get_overlay
var species_get_queue:Array[Dictionary]=[]
var species_get_active_context:=""
var species_get_active_series_id:=""
var species_get_active_species_id:=""
var catalog_series_unlock_overlay
var catalog_series_unlock_active_id:=""
var fusion_system
var fusion_lab_ui
var fusion_parent_a_id:=""
var fusion_parent_b_id:=""
var fusion_in_progress:=false
var fusion_return_pending:=false
var language_code:="ja"
var language_selected:=false
var save_file_present_on_boot:=false
var first_habitat_gift_claimed:=false
var old_catalog_pages:=0
var old_catalog_page_inventory:Dictionary={}
var old_catalog_intro_seen:=false
var old_catalog_intro_pending:=false
var habitat_old_catalog_page_pending:=false
var habitat_old_catalog_page_series_id:=""
var habitat_old_catalog_page_point:=Vector2(905,452)
var old_catalog_page_roll_play_count:=-1
var last_jelly_claim_msec:=-1000000000
var audio_manager: Node
var audio_settings: Dictionary = {"bgm_enabled":true,"se_enabled":true,"bgm_volume":0.65,"se_volume":0.62}
var habitat_glow_tween: Tween
var habitat_sparkle: Control
var rain_visual: Control
var rain_drops: Array = []
var result_overlay: Control
var result_card: PanelContainer
var result_total_label: Label
var result_count_label: Label
var result_max_label: Label
var result_notable_label: Label
var result_new_species_label: Label
var result_share_button: Button
var result_share_status: Label
var result_new_species_pulse_tween: Tween
var result_confetti_layer: Control
var result_record_pulse_tween: Tween
var encyclopedia_icon_button: Button
var external_navigation_controls: Array[Control] = []
var encyclopedia_navigation_controls: Array[Control] = []
var puku_gauge_cm := 0.0
var puku_balance_units := 0
var normal_round_free_plays := 0
var puku_points:int:
	get:
		return maxi(0,floori(float(puku_balance_units)/float(PUKU_UNITS_PER_PUKU)))
	set(value):
		puku_balance_units=maxi(0,value)*PUKU_UNITS_PER_PUKU
var bests: Dictionary = {}
var discovered: Dictionary = {}
var species_get_counts: Dictionary = {}
var unlocked_series: Dictionary = {INITIAL_SERIES_ID:true}
var catalog_cover_species: Dictionary = {}
var get_counts_migration_dirty := false
var puku_balance_migration_dirty := false
var catalog_cover_migration_dirty := false
var collection_completion_migration_dirty := false
var pot_inventory_migration_dirty := false
var retired_content_migration_dirty := false
var pot_catalog: Array = []
var owned_pots: Dictionary = {DEFAULT_POT_ID:1}
var pot_design_unlocks: Dictionary = {}
var pot_unlock_iap_service
var saved_arrangements: Array = []
var arrangement_save_capacity := 20
var arrangement_ui
var arrangement_navigation_hint
var unlocked_species: Dictionary = {}
var greenhouse_available: Dictionary = {}
var best_spawn_unlocks_dirty := false
var habitat_seed_date := ""
var habitat_seeds_collected := 0
var habitat_mystery_seeds_pending := 0
var habitat_wild_plants: Array[Dictionary] = []
var habitat_wild_initialized := false
var habitat_wild_next_spawn_unix := 0.0
var legacy_habitat_migration_dirty := false
var legacy_habitat_notification_ids_to_cancel: Array[String] = []
var habitat_tutorial_started := false
var habitat_tutorial_complete := false
var habitat_tutorial_species_id := ""
var original_catalog_gifted := false
var panda_beacon_unlocked := false
var panda_beacon_count := 0
var panda_beacon_unread_log: Array[Dictionary] = []
var habitat_notification_service
var habitat_plant_panel
var habitat_dev_panel
var habitat_dev_open_button: Button
var story_dev_panel
var habitat_debug_enabled := false
var habitat_time_multiplier := 1
var habitat_simulation_unix := 0.0
var habitat_debug_log: Array[String] = []
var habitat_wild_update_accumulator := 0.0
var habitat_wild_save_accumulator := 0.0
var normal_seed_bags := 0
var volume_seed_bags := 0
var premium_seed_bags := 0
var mystery_seed_bags := 0
var old_seed_bags := 0
var volume_seed_unlocked := false
var volume_seed_intro_seen := false
var premium_seed_unlocked := false
var mystery_seed_pack_unlocked := false
var result_new_species_queue: Array[String] = []
var result_deferred_species_queue: Array[String] = []
var pending_round_new_species_ids: Array[String] = []
var round_result_species_finalize_queue: Array[Dictionary] = []
var round_result_species_finalize_active := false
var round_result_species_save_pending := false
var get_close_profile_enabled := OS.is_debug_build()
var get_close_profile_active := false
var get_close_profile_events: Dictionary = {}
var get_close_profile_event_order: Array[String] = []
var get_close_profile_total_msec := -1
var get_close_profile_slow_sections: Array[String] = []
var get_close_profile_save_count := 0
var get_close_profile_run_id := 0
var catalog_series_unlock_notice_queue: Array[String] = []
var catalog_series_unlock_notice_ready: Dictionary = {}
var shop_chatter_acquired_species: Array[String] = []
var rain_completion_count := 0
var best_100_achieved := false
var login_bonus_date := ""
var play_active := false
var play_time_remaining := 0.0
var active_seed_type := "normal"
var play_modal_open := false
var play_harvest_cm_total := 0.0
var play_puku_reward_units_total := 0
var play_harvest_count := 0
var play_max_size := 0.0
var play_previous_global_best := 0.0
var play_updated_global_best := false
var last_forest_gacha_persist_started_msec := -1
var last_forest_gacha_persist_ended_msec := -1
var last_forest_gacha_persist_duration_msec := -1
var last_forest_gacha_registration_duration_msec := -1
var last_forest_gacha_save_duration_msec := -1
var last_forest_gacha_ui_update_duration_msec := -1
var forest_gacha_pending_commit: Dictionary = {}
var gacha_capsule_profile_enabled := OS.is_debug_build()
var gacha_capsule_profile_active := false
var gacha_capsule_profile_events: Dictionary = {}
var gacha_capsule_profile_event_order: Array[String] = []
var gacha_capsule_profile_slow_sections: Array[String] = []
var gacha_capsule_profile_total_msec := -1
var gacha_capsule_profile_run_id := 0
var gacha_capsule_profile_decode_count_start := 0
var gacha_capsule_profile_decode_total_start := 0
var gacha_capsule_profile_started_with_placeholder := false
var old_colorata_profile_enabled := OS.is_debug_build()
var old_colorata_profile_active := false
var old_colorata_profile_events: Dictionary = {}
var old_colorata_profile_event_order: Array[String] = []
var old_colorata_profile_slow_sections: Array[String] = []
var old_colorata_profile_run_id := 0
var old_colorata_profile_save_count := 0
var old_colorata_profile_tap_to_first_visual_msec := -1
var old_colorata_profile_tap_to_get_start_msec := -1
var last_harvest_input_msec := -1
var last_harvest_feedback_msec := -1
var last_harvest_feedback_latency_msec := -1
var last_harvest_presented_msec := -1
var last_harvest_presented_latency_msec := -1
var harvest_commit_count := 0
var play_share_record:Dictionary={}
var native_share_context:=""
var play_notable_species: Dictionary = {}
var play_hidden_species_unlocked := ""
var current_target_count := NORMAL_GERMINATION_COUNT
var play_seeds_remaining := 0
var play_spawn_queue := 0
var play_seed_animations_pending := 0
var play_spawn_timer := 0.0
var play_concurrent_target := PLAY_INITIAL_MAX_PLANTS
var endless_economy_start_units := 0
var endless_economy_seed_count := 0
var endless_economy_seed_cost_units := 0
var endless_economy_harvest_reward_units := 0
var endless_economy_jelly_count := 0
var endless_economy_harvest_count := 0
var endless_economy_max_harvest_cm := 0.0
var greenhouse_finish_attempt_count := 0
var greenhouse_finish_completed_count := 0
var greenhouse_finish_last_block_reason := ""
var greenhouse_finish_last_snapshot:Dictionary={}
var rain_bag_count := 0
var rain_event_pending := false
var rain_bonus_in_progress := false
var rain_bonus_active := false
var rain_time_remaining := 0.0
var rain_spawn_queue := 0
var rain_spawn_timer := 0.0
var rain_last_saved_second := -1
var rain_intro_normal_bags := 0
var rain_draws_unlocked := false
var armadillo_intro_event_3_completed := false
var armadillo_series_event_7_completed := false
var pending_armadillo_story_event := ""
var armadillo_gift_series_id := ""
var armadillo_gift_species_id := ""
var forced_golden_done := false
var view_yaw := 0.0
var view_pitch := -3.0
var habitat_target_yaw := 0.0
var habitat_target_pitch := -3.0
var habitat_lookaround_active := false
var habitat_lookaround_elapsed := 0.0
var habitat_lookaround_start_yaw := 0.0
var habitat_lookaround_end_yaw := 0.0
var habitat_lookaround_start_pitch := -3.0
var habitat_lookaround_context := ""
var habitat_texture_mode := "full"
var habitat_texture_build_active := false
var habitat_full_texture_loads_during_build := 0
var habitat_texture_count := 0
var habitat_texture_max_size := Vector2i.ZERO
var habitat_texture_estimated_bytes := 0
var habitat_build_texture_paths: Dictionary = {}
var pointer_down := false
var pointer_start := Vector2.ZERO
var pointer_last := Vector2.ZERO
var pointer_travel := 0.0
var greenhouse_drag_accumulator := 0.0
var greenhouse_drag_started := false
var opening_overlay: Control
var opening_prompt: TextureRect
var opening_prompt_localized: PanelContainer
var opening_prompt_localized_label: Label
var opening_prompt_tween: Tween
var opening_finished := false
var opening_tap_area: Button
var opening_language_panel: PanelContainer
var opening_story_overlay: OpeningStoryOverlay
var habitat_awakening_overlay: Control
var seed_pod_story_overlay: Control
var habitat_second_awakening_overlay: Control
var habitat_crisis_atmosphere: Control
var habitat_restoration_ui: HabitatRestorationUI
var pending_restoration_snapshot: Dictionary = {}
var jurejure_first_encounter_overlay: Control
var puku_puku_battle: Control
var scene_transition_fade: ColorRect
var jurejure_first_encounter_active := false
var jurejure_intro_camera_active := false
var jurejure_intro_camera_elapsed := 0.0
var jurejure_intro_camera_start_yaw := 0.0
var jurejure_intro_camera_target_yaw := 0.0
var jurejure_camera_focus_context := ""
var habitat_visit_id := 0
var jurejure_focused_habitat_visit_id := -1
var act3_intro_eligible_visit_id := 0
var habitat_crisis_eligible_visit_id := 0

func _ready() -> void:
	if _slot_preview_requested():
		set_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)
		add_child(SlotMachineScene.instantiate())
		return
	endless_greenhouse.configure(EndlessGreenhouseExperimentClass.requested_by_runtime())
	var endless_save_setup:=endless_greenhouse.prepare_save_namespace()
	if int(endless_save_setup.get("error",OK))!=OK:
		push_error("ENDLESS save namespace setup failed: %s"%error_string(int(endless_save_setup.get("error",FAILED))))
	print("ENDLESS_GREENHOUSE_BOOT enabled=",endless_greenhouse.enabled," save_path=",endless_greenhouse.active_save_path()," copied_normal_save=",bool(endless_save_setup.get("copied",false)))
	habitat_debug_enabled=_habitat_debug_requested()
	_configure_habitat_texture_ab()
	_configure_habitat_background_ab()
	rng.randomize()
	catalog_preview_rng.randomize()
	forest_gacha_rng.randomize()
	_load_species()
	_load_series_data()
	_load_collection_rarity()
	# This catalog-derived set is immutable during play. Build it while the game
	# is loading so the first gacha NEW registration cannot block capsule input.
	_ensure_collection_complete_species_cache()
	fusion_system=FusionSystemClass.new();fusion_system.configure(catalog_species)
	forest_gacha_system=ForestGachaSystemClass.new();forest_gacha_system.configure(series_catalog,catalog_species,catalog_progression)
	_load_pot_data()
	_load_save()
	_setup_pot_unlock_iap()
	habitat_simulation_unix=Time.get_unix_time_from_system()
	var recovered_forest_encounters:=_register_encountered_species_for_unlocked_series()
	_apply_saved_unlocks()
	audio_manager=AudioManagerClass.new();add_child(audio_manager);audio_manager.apply_settings(audio_settings)
	# The retired Panda Beacon may have left native notifications on an upgraded
	# device.  Create the legacy service only long enough to cancel those IDs;
	# normal play never schedules habitat notifications anymore.
	if not legacy_habitat_notification_ids_to_cancel.is_empty():
		habitat_notification_service=HabitatNotificationServiceClass.new();add_child(habitat_notification_service)
		habitat_notification_service.cancel_all(legacy_habitat_notification_ids_to_cancel);legacy_habitat_notification_ids_to_cancel.clear()
	if best_spawn_unlocks_dirty or get_counts_migration_dirty or puku_balance_migration_dirty or catalog_cover_migration_dirty or collection_completion_migration_dirty or pot_inventory_migration_dirty or retired_content_migration_dirty or recovered_forest_encounters:
		# A true cold start must reach the language choice before creating its
		# first save.  The selected language then persists all initialized state.
		if save_file_present_on_boot or language_selected:_save()
		best_spawn_unlocks_dirty=false;get_counts_migration_dirty=false;puku_balance_migration_dirty=false;catalog_cover_migration_dirty=false;collection_completion_migration_dirty=false;pot_inventory_migration_dirty=false;retired_content_migration_dirty=false
	_build_world()
	_build_ui()
	if habitat_awakened and (habitat_wild_initialized or habitat_unlocked):_ensure_habitat_wild_state(Time.get_unix_time_from_system(),true)
	if legacy_habitat_migration_dirty:_save();legacy_habitat_migration_dirty=false
	_build_habitat_items()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_wire_ui_sounds(self)
	_update_main_story_progress(false)
	if _opening_story_preview_requested():call_deferred("_open_opening_story_preview")
	elif _seed_pod_story_preview_requested():call_deferred("_open_seed_pod_story_preview")
	elif _arrangement_test_preview_requested():call_deferred("_open_arrangement_test_preview")
	elif _forest_gacha_preview_requested():call_deferred("_open_forest_gacha_preview")
	elif _jurejure_habitat_preview_requested():call_deferred("_open_jurejure_habitat_preview")
	elif _puku_puku_battle_preview_requested():call_deferred("_open_puku_puku_battle_preview")
	elif _habitat_test_preview_requested():call_deferred("_open_habitat_test_preview")

func _habitat_debug_requested()->bool:
	if not _trial_dev_controls_enabled():return false
	if OS.is_debug_build():return true
	if OS.has_feature("web"):
		var requested=JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('habitat_debug')",true)
		var screen=JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('screen')",true)
		return str(requested)=="1" or str(screen)=="habitat-test"
	return "--habitat-debug" in OS.get_cmdline_user_args()

func _habitat_test_preview_requested()->bool:
	if not _trial_dev_controls_enabled():return false
	if OS.has_feature("web"):
		var requested=JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('screen')",true)
		return str(requested)=="habitat-test"
	return "--habitat-test-preview" in OS.get_cmdline_user_args()

func _opening_story_preview_requested()->bool:
	if not _trial_dev_controls_enabled():return false
	if OS.has_feature("web"):
		var requested=JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('screen')",true)
		return str(requested)=="opening-story"
	return "--opening-story-preview" in OS.get_cmdline_user_args()

func _seed_pod_story_preview_requested()->bool:
	if not _trial_dev_controls_enabled():return false
	if OS.has_feature("web"):
		var requested=JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('screen')",true)
		return str(requested)=="seed-pod-story"
	return "--seed-pod-story-preview" in OS.get_cmdline_user_args()

func _slot_preview_requested() -> bool:
	if not _trial_dev_controls_enabled():return false
	if OS.has_feature("web"):
		var requested = JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('screen')", true)
		return str(requested) == "slot"
	return "--slot-preview" in OS.get_cmdline_user_args()

func _arrangement_test_preview_requested()->bool:
	if not _trial_dev_controls_enabled():return false
	if OS.has_feature("web"):
		var requested=JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('screen')",true)
		return str(requested)=="arrangement-test"
	return "--arrangement-test-preview" in OS.get_cmdline_user_args()

func _forest_gacha_preview_requested()->bool:
	if not _trial_dev_controls_enabled():return false
	if OS.has_feature("web"):
		var requested=JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('screen')",true)
		return str(requested)=="forest-gacha"
	return "--forest-gacha-preview" in OS.get_cmdline_user_args()

func _jurejure_habitat_preview_requested()->bool:
	if not _trial_dev_controls_enabled():return false
	if OS.has_feature("web"):
		var requested=JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('screen')",true)
		return str(requested)=="jurejure-habitat"
	return "--jurejure-habitat-preview" in OS.get_cmdline_user_args()

func _puku_puku_battle_preview_requested()->bool:
	if not _trial_dev_controls_enabled():return false
	if OS.has_feature("web"):
		var requested=JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('screen')",true)
		return str(requested)=="puku-puku-battle"
	return "--puku-puku-battle-preview" in OS.get_cmdline_user_args()

func _configure_habitat_texture_ab()->void:
	if not _trial_dev_controls_enabled():return
	if OS.has_feature("web"):
		var requested=JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('habitat_texture')",true)
		habitat_texture_mode="thumb" if str(requested)=="thumb" else "full"
	print("HABITAT_TEXTURE_AB mode=",habitat_texture_mode)

func _configure_habitat_background_ab()->void:
	if not _trial_dev_controls_enabled():return
	if OS.has_feature("web"):
		var requested=JavaScriptBridge.eval("new URLSearchParams(window.location.search).get('habitat_background')",true)
		habitat_background_mode=str(requested) if str(requested) in ["no_sky","panorama_mesh"] else "current"
	print("HABITAT_BACKGROUND_AB mode=",habitat_background_mode)

func _continue_after_opening()->void:
	if not opening_story_complete:call_deferred("_start_opening_story")
	elif not intro_story_complete:call_deferred("_start_intro_story")
	elif habitat_tutorial_complete and not mystery_items_acquired:call_deferred("_start_seed_pod_story")
	elif mystery_items_acquired and not mystery_catalog_tutorial_complete:call_deferred("_start_mystery_catalog_tutorial")
	elif mystery_items_acquired and mystery_catalog_tutorial_complete and not normal_play_tutorial_complete:call_deferred("_start_initial_seed_stock_notice")
	elif _daily_seed_gift_due():call_deferred("_start_daily_seed_gift")
	else:
		audio_manager.play_bgm("greenhouse")
		if total_play_count==0 and not bool(tutorial_steps.get("play_open_guide",false)):call_deferred("_show_tutorial_guide","play_open")
		else:call_deferred("_try_start_pending_story_event")

func _load_species() -> void:
	var raw := FileAccess.get_file_as_string("res://data/species-v2.json")
	var all_species: Array = JSON.parse_string(raw)
	var parsed_hybrids:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/hybrid-species.json"))
	if parsed_hybrids is Array:
		for raw_hybrid in parsed_hybrids:
			if not raw_hybrid is Dictionary:continue
			var hybrid:Dictionary=raw_hybrid.duplicate(true)
			var fusion_tier:=int(hybrid.get("fusion_tier",0))
			var is_special_fusion:=fusion_tier>0
			hybrid["description_ja"]="特殊配合をさらに掛け合わせて誕生した、上位特殊配合多肉。" if fusion_tier>=2 else ("決められた特別な組み合わせから誕生した、二段目の特殊配合多肉。" if is_special_fusion else "ハイブリッドラボで誕生した、ふたつの系統の個性を受け継ぐ特別な多肉。")
			hybrid["description_en"]="An advanced special fusion succulent born by combining special fusions." if fusion_tier>=2 else ("A second-tier special fusion succulent born from a specific pairing." if is_special_fusion else "A special hybrid succulent born in the Hybrid Lab.")
			hybrid["rarity"]="上位特殊配合種" if fusion_tier>=2 else ("特殊配合種" if is_special_fusion else "配合種");hybrid["spawn_weight"]=0.0;hybrid["unlocked_spawn_weight"]=1.0
			hybrid["series_seed_weight"]=0.0;hybrid["series_seed_eligible"]=false
			hybrid["base_growth_rate"]=1.0;hybrid["jelly_risk_curve"]=1.0
			hybrid["visual_variant"]=str(hybrid.get("species_id",""));hybrid["habitat_image_path"]=""
			hybrid["golden_variant"]=false;hybrid["catalog_only"]=true
			hybrid["mystery_pack_eligible"]=true;hybrid["fusion_only_until_discovered"]=true
			all_species.append(hybrid)
	for entry_value in all_species:
		if not entry_value is Dictionary:continue
		var entry:Dictionary=entry_value
		if str(entry.get("fusion_series","")).is_empty():
			var fusion_series:=FusionSystemClass.default_fusion_series_for_catalog_series(str(entry.get("series_id","")))
			if not fusion_series.is_empty():entry["fusion_series"]=fusion_series
	catalog_species=all_species.duplicate(true);collection_complete_species_ids_cache.clear();collection_complete_species_membership_cache.clear();collection_complete_species_ids_cache_ready=false
	unlock_rules=JSON.parse_string(FileAccess.get_file_as_string("res://data/unlock-rules.json"))
	greenhouse_available=_initial_greenhouse_state()
	unlocked_species=greenhouse_available.duplicate(true)

func _initial_greenhouse_state()->Dictionary:
	# A new story save begins with one unidentified old seed, not a pool of
	# already-known plants. Discoveries are added to this pool permanently.
	return {}

func _load_series_data() -> void:
	series_catalog.clear()
	species_picker_series_catalog.clear()
	catalog_progression={}
	var parsed_progression=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog-progression.json"))
	if parsed_progression is Dictionary:catalog_progression=parsed_progression.duplicate(true)
	var parsed_series=JSON.parse_string(FileAccess.get_file_as_string("res://data/series.json"))
	if parsed_series is Array:
		for raw_entry in parsed_series:
			if raw_entry is Dictionary and not str(raw_entry.get("series_id","")).is_empty():series_catalog.append(raw_entry.duplicate(true))
	series_catalog.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.get("sort_order",0))<int(b.get("sort_order",0)))
	if series_catalog.is_empty():
		var fallback_ids:Array[String]=[]
		for entry in catalog_species:fallback_ids.append(str(entry.get("species_id","")))
		series_catalog.append({"series_id":INITIAL_SERIES_ID,"display_name":"原種","subtitle":"この世界に帰ってきた多肉たち","description":"新しく見つけた原種を不思議な図鑑へ記録します。","cover_image_path":"","species_ids":fallback_ids,"field_id":"base_field","unlock_type":"default","unlock_condition":{},"iap_product_id":"","sort_order":0})
	species_picker_series_catalog=_build_species_picker_series_catalog()

func _load_collection_rarity()->void:
	var by_id:Dictionary={}
	for entry_value in catalog_species:
		if entry_value is Dictionary:
			var entry:Dictionary=entry_value;entry["gold_star_count"]=0;entry["collection_rarity"]="normal";by_id[str(entry.get("species_id",""))]=entry
	var parsed=JSON.parse_string(FileAccess.get_file_as_string("res://data/collection-rarity.json"))
	if not parsed is Dictionary:return
	for series_id_value in parsed:
		var rule=parsed[series_id_value]
		if not rule is Dictionary:continue
		var two_star_id:=str(rule.get("two_star",""))
		if by_id.has(two_star_id):by_id[two_star_id]["gold_star_count"]=2;by_id[two_star_id]["collection_rarity"]="super_rare"
		for one_star_value in rule.get("one_star",[]):
			var one_star_id:=str(one_star_value)
			if by_id.has(one_star_id):by_id[one_star_id]["gold_star_count"]=1;by_id[one_star_id]["collection_rarity"]="super_rare"

func _load_pot_data()->void:
	pot_catalog.clear()
	var seen_pot_ids:Dictionary={}
	var seen_product_ids:Dictionary={}
	for data_path in ["res://data/pots.json","res://data/pot-iap-catalog.json"]:
		var parsed_pots=JSON.parse_string(FileAccess.get_file_as_string(data_path))
		if not parsed_pots is Array:continue
		for raw_pot in parsed_pots:
			if not raw_pot is Dictionary:continue
			var pot:Dictionary=raw_pot.duplicate(true)
			var pot_id:=str(pot.get("pot_id","")).strip_edges()
			if pot_id.is_empty() or seen_pot_ids.has(pot_id):
				push_error("Duplicate or empty pot_id in %s: %s"%[data_path,pot_id])
				continue
			pot["pot_id"]=pot_id
			pot["price_puku"]=maxi(0,int(pot.get("price_puku",POT_PRICE_PUKU)))
			if not pot.has("sales_group"):pot["sales_group"]="initial"
			if not pot.has("unlock_type"):pot["unlock_type"]="free"
			if not pot.has("sales_stage"):pot["sales_stage"]={"initial":0,"group_1":1,"group_2":2}.get(str(pot.get("sales_group","initial")),0)
			if not pot.has("unlock_condition"):pot["unlock_condition"]={"type":"default"}
			if not pot.has("placement_area"):pot["placement_area"]={"x":.08,"y":.10,"width":.84,"height":.56}
			var product_id:=str(pot.get("iap_product_id","")).strip_edges()
			if str(pot.get("unlock_type","free"))=="iap_unlock":
				if product_id.is_empty() or seen_product_ids.has(product_id):
					push_error("Missing or duplicate pot IAP product id in %s: %s"%[data_path,product_id])
					continue
				seen_product_ids[product_id]=true
			seen_pot_ids[pot_id]=true
			pot_catalog.append(pot)
	pot_catalog.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(a.get("sort_order",0))<int(b.get("sort_order",0)))
	if pot_catalog.is_empty():pot_catalog.append({"pot_id":DEFAULT_POT_ID,"display_name":"浅型素焼き鉢","image_path":"","price_puku":POT_PRICE_PUKU,"sales_group":"initial","unlock_type":"free","sales_stage":0,"unlock_condition":{"type":"default"},"iap_product_id":"","placement_area":{"x":.06,"y":.10,"width":.88,"height":.56},"sort_order":0})

func _setup_pot_unlock_iap()->void:
	pot_unlock_iap_service=PotUnlockIAPServiceClass.new()
	add_child(pot_unlock_iap_service)
	pot_unlock_iap_service.state_changed.connect(_on_pot_iap_state_changed)
	pot_unlock_iap_service.entitlement_changed.connect(_on_pot_iap_entitlement_changed)
	pot_unlock_iap_service.purchase_failed.connect(_on_pot_iap_purchase_failed)
	pot_unlock_iap_service.restore_finished.connect(_on_pot_iap_restore_finished)
	pot_unlock_iap_service.configure(pot_catalog,pot_design_unlocks)

func _load_save() -> void:
	_cancel_puku_gauge_animations()
	_reset_collection_complete_presentation(true)
	legacy_habitat_migration_dirty=false;puku_balance_migration_dirty=false;catalog_cover_migration_dirty=false;collection_completion_migration_dirty=false;pot_inventory_migration_dirty=false;retired_content_migration_dirty=false;legacy_habitat_notification_ids_to_cancel.clear();panda_beacon_unread_log.clear()
	puku_balance_units=0
	normal_round_free_plays=0
	catalog_cover_species={}
	collection_complete_versions={}
	collection_complete_pending_species_id=""
	collection_complete_resume_context=""
	collection_complete_resume_shop_visible=false
	collection_complete_presentation_active=false
	collection_complete_presentation_phase=""
	collection_complete_catalog_ready_before_fade_in=false
	jurejure_pending_reward_species_id=""
	jurejure_pending_reward_is_new=false
	pending_round_new_species_ids.clear()
	round_result_species_finalize_queue.clear()
	round_result_species_finalize_active=false
	round_result_species_save_pending=false
	save_file_present_on_boot=false
	language_selected=false
	pot_design_unlocks={}
	var save_path:=_active_save_path()
	if FileAccess.file_exists(save_path):
		var value = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		if value is Dictionary:
			save_file_present_on_boot=true
			var saved_progression_version:=int(value.get("progression_version",0))
			retired_content_migration_dirty=int(value.get("retired_content_version",0))<RETIRED_CONTENT_VERSION
			var retired_secret_gacha_evidence:=bool(value.get("secret_gacha_active",false)) \
					or int(value.get("secret_gacha_draws_remaining",0))>0 \
					or int(value.get("secret_gacha_last_roll_play_count",-1))>=0
			for retired_key in ["secret_gacha_active","secret_gacha_draws_remaining","secret_gacha_last_roll_play_count","mystery_route_assignments","mystery_route_completed","mystery_route_dialog_seen"]:
				if value.has(retired_key):retired_content_migration_dirty=true
			var migrating_legacy_puku_balance:bool=not value.has("puku_balance_units")
			# Legacy `yen`, `money`, and `coins` fields are intentionally ignored. They
			# remain valid JSON input, but game progression now uses puku coins only.
			var legacy_puku_points:=maxi(0,int(value.get("puku_points",0)))
			var legacy_puku_coin_gauge_cm:=maxf(0.0,float(value.get("puku_coin_gauge_cm",0.0)))
			if not migrating_legacy_puku_balance:
				puku_balance_units=maxi(0,int(value.get("puku_balance_units",0)))
			else:
				puku_balance_units=legacy_puku_points*PUKU_UNITS_PER_PUKU+roundi(legacy_puku_coin_gauge_cm/LEGACY_PUKU_GAUGE_TARGET_CM*LEGACY_PUKU_GAUGE_REWARD_UNITS)
				puku_balance_migration_dirty=true
			normal_round_free_plays=maxi(0,int(value.get("normal_round_free_plays",0)))
			bests=value.get("bests",{});puku_gauge_cm=maxf(0.0,float(value.get("puku_gauge_cm",0.0)));discovered=value.get("discovered",{});habitat_seed_date=str(value.get("habitat_seed_date",""));habitat_seeds_collected=int(value.get("habitat_seeds_collected",0))
			if saved_progression_version<21:
				# v20 used one 600 cm gauge for both rewards. Preserve its fill ratio as
				# pod light without granting migration-time seeds or coins.
				puku_gauge_cm=clampf(puku_gauge_cm/LEGACY_COMBINED_GAUGE_TARGET_CM*SEED_POD_GAUGE_TARGET_CM,0.0,SEED_POD_GAUGE_TARGET_CM-.001)
			else:
				puku_gauge_cm=fposmod(puku_gauge_cm,SEED_POD_GAUGE_TARGET_CM)
			species_get_counts=value.get("species_get_counts",{});unlocked_series=value.get("unlocked_series",{INITIAL_SERIES_ID:true});catalog_cover_species=value.get("catalog_cover_species",{})
			collection_complete_versions=_normalize_collection_complete_versions(value.get("collection_complete_versions",{}))
			owned_pots=value.get("owned_pots",{DEFAULT_POT_ID:1});pot_design_unlocks=_normalize_pot_design_unlocks(value.get("pot_design_unlocks",{}));saved_arrangements=value.get("saved_arrangements",[]);arrangement_save_capacity=maxi(1,int(value.get("arrangement_save_capacity",20)))
			if not value.has("owned_pots"):pot_inventory_migration_dirty=true
			if not species_get_counts is Dictionary:species_get_counts={}
			if not unlocked_series is Dictionary:unlocked_series={INITIAL_SERIES_ID:true}
			if not catalog_cover_species is Dictionary:catalog_cover_species={}
			if not owned_pots is Dictionary:owned_pots={DEFAULT_POT_ID:1};pot_inventory_migration_dirty=true
			if not saved_arrangements is Array:saved_arrangements=[]
			unlocked_series[INITIAL_SERIES_ID]=true
			# Legacy bool ownership is upgraded to numeric totals. Retired/unknown pots
			# are removed here; their arrangements are mapped to the current default.
			if _normalize_owned_pot_counts():pot_inventory_migration_dirty=true
			var normalized_arrangements:Array=[]
			for saved_arrangement in saved_arrangements:
				if saved_arrangement is Dictionary:
					if _arrangement_contains_retired_species(saved_arrangement):retired_content_migration_dirty=true
					var normalized_arrangement:=_normalize_arrangement(saved_arrangement)
					if not normalized_arrangement.is_empty():normalized_arrangements.append(normalized_arrangement)
			saved_arrangements=normalized_arrangements.slice(0,arrangement_save_capacity)
			if _reconcile_pot_inventory_with_arrangements():pot_inventory_migration_dirty=true
			intro_story_complete=bool(value.get("intro_story_complete",false));opening_story_complete=bool(value.get("opening_story_complete",intro_story_complete));total_play_count=int(value.get("total_play_count",0));completed_unlock_conditions=value.get("completed_unlock_conditions",{});pending_habitat_species=value.get("pending_habitat_species",[]);audio_settings=value.get("audio_settings",audio_settings)
			encyclopedia_unlocked=bool(value.get("encyclopedia_unlocked",intro_story_complete and total_play_count>=1));habitat_unlocked=bool(value.get("habitat_unlocked",intro_story_complete and total_play_count>=3));tutorial_steps=value.get("tutorial_steps",{});old_seed_bags=int(value.get("old_seed_bags",0));puku_gauge_intro_complete=bool(value.get("puku_gauge_intro_complete",value.get("buyback_unlocked",total_play_count>=4)));first_tutorial_species_id=str(value.get("first_tutorial_species_id",""))
			first_colorata_confirmed=bool(value.get("first_colorata_confirmed",false));trio_originals_confirmed=bool(value.get("trio_originals_confirmed",false));habitat_arrival_started=bool(value.get("habitat_arrival_started",false));habitat_awakened=bool(value.get("habitat_awakened",false));habitat_awakening_event_complete=bool(value.get("habitat_awakening_event_complete",habitat_awakened));seed_shop_open=bool(value.get("seed_shop_open",false));mystery_items_acquired=bool(value.get("mystery_items_acquired",false));mystery_catalog_tutorial_complete=bool(value.get("mystery_catalog_tutorial_complete",false));habitat_returned_species=value.get("habitat_returned_species",{});special_series_explanation_seen=bool(value.get("special_series_explanation_seen",false));main_story_stage=clampi(int(value.get("main_story_stage",StoryProgressionClass.ACT_1)),StoryProgressionClass.LEGACY_STAGE_MIN,StoryProgressionClass.LEGACY_STAGE_MAX);main_story_complete=bool(value.get("main_story_complete",false));main_story_completion_seen=bool(value.get("main_story_completion_seen",main_story_complete))
			var legacy_tutorials_complete:=saved_progression_version<PROGRESSION_VERSION and (mystery_items_acquired or bool(value.get("habitat_tutorial_complete",false)) or habitat_awakened)
			normal_play_tutorial_complete=bool(value.get("normal_play_tutorial_complete",legacy_tutorials_complete));seed_pod_gauge_discovery_complete=bool(value.get("seed_pod_gauge_discovery_complete",legacy_tutorials_complete));seed_pod_first_reward_seen=bool(value.get("seed_pod_first_reward_seen",legacy_tutorials_complete));initial_seed_stock_notice_complete=bool(value.get("initial_seed_stock_notice_complete",legacy_tutorials_complete));puku_buyback_tutorial_complete=bool(value.get("puku_buyback_tutorial_complete",legacy_tutorials_complete))
			original_catalog_complete_event_seen=bool(value.get("original_catalog_complete_event_seen",false));habitat_tutorial_returned_to_greenhouse=bool(value.get("habitat_tutorial_returned_to_greenhouse",false))
			jurejure_intro_complete=bool(value.get("jurejure_intro_complete",false));jurejure_enabled=bool(value.get("jurejure_enabled",jurejure_intro_complete));jurejure_growth_stage=clampi(int(value.get("jurejure_growth_stage",JureJureSystemClass.GROWTH_EARLY)),JureJureSystemClass.GROWTH_EARLY,JureJureSystemClass.GROWTH_LATE);jurejure_growth_event_mask=maxi(0,int(value.get("jurejure_growth_event_mask",0)))
			# Timed target events were retired in v23. Accept their fields, but never
			# resolve an old deadline while loading a save.
			active_jurejure_event={};jurejure_next_check_unix=0.0;jurejure_cooldown_until_unix=0.0
			jurejure_return_event_complete=bool(value.get("jurejure_return_event_complete",false));jurejure_waiting_for_seed_pod_reward=bool(value.get("jurejure_waiting_for_seed_pod_reward",false));jurejure_battle_count=maxi(0,int(value.get("jurejure_battle_count",0)));jurejure_battle_win_count=maxi(0,int(value.get("jurejure_battle_win_count",0)))
			habitat_second_awakened=bool(value.get("habitat_second_awakened",false));habitat_second_awakening_complete=bool(value.get("habitat_second_awakening_complete",habitat_second_awakened))
			act2_unlocked=bool(value.get("act2_unlocked",false));forest_gacha_unlocked=bool(value.get("forest_gacha_unlocked",false));forest_gacha_intro_seen=bool(value.get("forest_gacha_intro_seen",false))
			fantasy_first_discovery_seen=bool(value.get("fantasy_first_discovery_seen",false));fantasy_realization_seen=bool(value.get("fantasy_realization_seen",false))
			story_progression_state=value.get("story_progression_state",StoryProgressionClass.default_runtime_state())
			if not story_progression_state is Dictionary:story_progression_state=StoryProgressionClass.default_runtime_state()
			act3_unlocked=bool(value.get("act3_unlocked",false));act3_intro_pending=bool(value.get("act3_intro_pending",false));act3_intro_seen=bool(value.get("act3_intro_seen",false))
			jurejure_pool_unlocked=bool(value.get("jurejure_pool_unlocked",false))
			jurejure_species_unlocked=value.get("jurejure_species_unlocked",{})
			if not jurejure_species_unlocked is Dictionary:jurejure_species_unlocked={}
			jurejure_species_first_seen=bool(value.get("jurejure_species_first_seen",false));habitat_crisis_pending=bool(value.get("habitat_crisis_pending",false));habitat_crisis_started=bool(value.get("habitat_crisis_started",false));finale_complete=bool(value.get("finale_complete",false))
			habitat_return_dialog_seen=bool(value.get("habitat_return_dialog_seen",saved_progression_version<PROGRESSION_VERSION and mystery_items_acquired))
			if not habitat_returned_species is Dictionary:habitat_returned_species={}
			# Post-awakening rain bonus mode was retired in v22. Legacy fields are
			# accepted but deliberately normalized to an inactive state.
			rain_bag_count=0;rain_event_pending=false;rain_bonus_in_progress=false;rain_bonus_active=false;rain_time_remaining=0.0;rain_spawn_queue=0;rain_spawn_timer=0.0;rain_intro_normal_bags=0;rain_draws_unlocked=false
			normal_play_count=maxi(0,int(value.get("normal_play_count",0)));shop_visit_count=maxi(0,int(value.get("shop_visit_count",0)));hidden_species_acquired=value.get("hidden_species_acquired",{});tovar_next_play=maxi(TOVAR_FIRST_PLAY,int(value.get("tovar_next_play",TOVAR_FIRST_PLAY)));tovar_attempt_count=maxi(0,int(value.get("tovar_attempt_count",0)));tovar_event_active=false;tovar_harvested_this_play=false
			formal_play_count=maxi(0,int(value.get("formal_play_count",normal_play_count)))
			volume_seed_unlocked=bool(value.get("volume_seed_unlocked",int(value.get("volume_seed_bags",0))>0));volume_seed_intro_seen=bool(value.get("volume_seed_intro_seen",false));premium_seed_unlocked=bool(value.get("premium_seed_unlocked",int(value.get("premium_seed_bags",0))>0));mystery_seed_pack_unlocked=bool(value.get("mystery_seed_pack_unlocked",false))
			mystery_seed_count=maxi(0,int(value.get("mystery_seed_count",0)));armadillo_research_total=maxi(0,int(value.get("armadillo_research_total",0)));armadillo_research_rewards=value.get("armadillo_research_rewards",{});armadillo_research_intro_seen=bool(value.get("armadillo_research_intro_seen",armadillo_research_total>0))
			old_catalog_pages=maxi(0,int(value.get("old_catalog_pages",0)));old_catalog_intro_seen=bool(value.get("old_catalog_intro_seen",false));old_catalog_intro_pending=bool(value.get("old_catalog_intro_pending",false));research_catalog_reward_pending=bool(value.get("research_catalog_reward_pending",false))
			old_catalog_page_inventory=value.get("old_catalog_page_inventory",{})
			if not old_catalog_page_inventory is Dictionary:old_catalog_page_inventory={}
			if old_catalog_page_inventory.is_empty() and old_catalog_pages>0:
				var migration_entry:=_next_restorable_hidden_series()
				if not migration_entry.is_empty():old_catalog_page_inventory[str(migration_entry.get("series_id",""))]=old_catalog_pages
			_sync_old_catalog_page_count()
			habitat_old_catalog_page_pending=bool(value.get("habitat_old_catalog_page_pending",false));habitat_old_catalog_page_series_id=str(value.get("habitat_old_catalog_page_series_id",""));habitat_old_catalog_page_point=Vector2(float(value.get("habitat_old_catalog_page_point_x",905.0)),float(value.get("habitat_old_catalog_page_point_y",452.0)))
			old_catalog_page_roll_play_count=int(value.get("old_catalog_page_roll_play_count",-1))
			series_seed_inventory=value.get("series_seed_inventory",{})
			forest_gacha_draw_count=maxi(0,int(value.get("forest_gacha_draw_count",0)));forest_gacha_encountered=value.get("forest_gacha_encountered",{})
			if not series_seed_inventory is Dictionary:series_seed_inventory={}
			if not forest_gacha_encountered is Dictionary:forest_gacha_encountered={}
			habitat_mystery_seeds_pending=maxi(0,int(value.get("habitat_mystery_seeds_pending",0)))
			habitat_tutorial_started=bool(value.get("habitat_tutorial_started",false));habitat_tutorial_complete=bool(value.get("habitat_tutorial_complete",false));habitat_tutorial_species_id=str(value.get("habitat_tutorial_species_id",""));original_catalog_gifted=bool(value.get("original_catalog_gifted",false))
			# Preserve load compatibility, but retire all Beacon inventory/log state.
			panda_beacon_unlocked=false;panda_beacon_count=0;panda_beacon_unread_log.clear()
			var valid_habitat_ids:Array[String]=[]
			for habitat_entry in catalog_species:valid_habitat_ids.append(str(habitat_entry.get("species_id","")))
			var raw_habitat_population:Variant=value.get("habitat_wild_plants",[])
			_queue_legacy_beacon_cleanup(raw_habitat_population)
			if saved_progression_version<LEGACY_HABITAT_REGENERATION_VERSION and _migrate_legacy_runaway_habitat(raw_habitat_population):
				pass
			else:
				_queue_stale_jellied_habitat_cleanup(raw_habitat_population)
				habitat_wild_plants=HabitatWildSystemClass.normalize_saved(raw_habitat_population,valid_habitat_ids,Time.get_unix_time_from_system())
				habitat_wild_initialized=bool(value.get("habitat_wild_initialized",not habitat_wild_plants.is_empty() or habitat_tutorial_complete))
				habitat_wild_next_spawn_unix=maxf(0.0,float(value.get("habitat_wild_next_spawn_unix",0.0)))
			armadillo_intro_event_3_completed=bool(value.get("armadillo_intro_event_3_completed",false));armadillo_series_event_7_completed=bool(value.get("armadillo_series_event_7_completed",false));pending_armadillo_story_event=str(value.get("pending_armadillo_story_event",""));armadillo_gift_series_id=str(value.get("armadillo_gift_series_id",""));armadillo_gift_species_id=str(value.get("armadillo_gift_species_id",""))
			language_code=Localizer.normalize_language(str(value.get("language_code","ja")))
			language_selected=bool(value.get("language_selected",value.has("language_code")))
			first_habitat_gift_claimed=bool(value.get("first_habitat_gift_claimed",saved_progression_version<15 and habitat_tutorial_complete))
			rain_completion_count=0;best_100_achieved=bool(value.get("best_100_achieved",false))
			if value.has("normal_seed_bags"):
				normal_seed_bags=int(value.get("normal_seed_bags",0));volume_seed_bags=int(value.get("volume_seed_bags",0));premium_seed_bags=int(value.get("premium_seed_bags",0));mystery_seed_bags=int(value.get("mystery_seed_bags",0));login_bonus_date=str(value.get("login_bonus_date",""))
			else:
				normal_seed_bags=0;premium_seed_bags=0;login_bonus_date=""
			# Legacy saves used unlocked_species for several meanings and could
			# contain the full catalog. Only the dedicated greenhouse list is
			# allowed to become a spawn source. Retired species are removed below.
			var saved_greenhouse=value.get("greenhouse_available",_initial_greenhouse_state())
			greenhouse_available=_initial_greenhouse_state()
			if saved_greenhouse is Dictionary:
				for species_id in saved_greenhouse:
					if bool(saved_greenhouse[species_id]):greenhouse_available[str(species_id)]=true
			# v9: every encyclopedia discovery permanently joins the ordinary pool.
			for species_id in discovered:
				if bool(discovered.get(species_id,false)):greenhouse_available[str(species_id)]=true
			unlocked_species=greenhouse_available.duplicate(true)
			# Saves created before the encyclopedia already contain valid best sizes.
			for species_id in bests:
				if float(bests[species_id])>0.0:discovered[species_id]=true
			for species_id in discovered:
				if bool(discovered.get(species_id,false)):greenhouse_available[str(species_id)]=true
			unlocked_species=greenhouse_available.duplicate(true)
			if not value.has("species_get_counts"):
				# Earlier saves did not count repeat harvests. A discovered entry proves at
				# least one real acquisition, so migrate that safe minimum exactly once.
				for species_id in discovered:
					if bool(discovered.get(species_id,false)) and str(species_id) not in [PANDA_STORY_SPECIES_ID,ARMADILLO_STORY_SPECIES_ID]:species_get_counts[str(species_id)]=1
				get_counts_migration_dirty=true
			else:
				var sanitized_get_counts:Dictionary={}
				for species_id in species_get_counts:
					var saved_count:=maxi(0,int(species_get_counts.get(species_id,0)))
					if saved_count>0:sanitized_get_counts[str(species_id)]=saved_count
				species_get_counts=sanitized_get_counts
			var raw_pending_round_new:Variant=value.get("pending_round_new_species_ids",[])
			if raw_pending_round_new is Array:
				for raw_species_id in raw_pending_round_new:
					var pending_species_id:=str(raw_species_id)
					if not pending_species_id.is_empty() and not _catalog_entry(pending_species_id).is_empty() and _species_get_count(pending_species_id)<=0 and pending_species_id not in pending_round_new_species_ids:
						pending_round_new_species_ids.append(pending_species_id)
			for story_catalog_id in [PANDA_STORY_SPECIES_ID,ARMADILLO_STORY_SPECIES_ID]:
				if _species_get_count(story_catalog_id)<=0:
					greenhouse_available.erase(story_catalog_id);unlocked_species.erase(story_catalog_id)
			for hidden_id in [HIDDEN_PINWHEEL_ID,HIDDEN_TOVAR_ID,HIDDEN_BUSTAMANTE_ID]:
				if bool(discovered.get(hidden_id,false)):hidden_species_acquired[hidden_id]=true
			if _sanitize_retired_special_species_progress():retired_content_migration_dirty=true
			_sanitize_removed_common_progress()
			_migrate_story_progress(saved_progression_version)
			_migrate_three_act_progress(saved_progression_version,retired_secret_gacha_evidence)
			_migrate_habitat_settlement()
			active_jurejure_event={}
			if saved_progression_version<14:
				habitat_tutorial_started=habitat_unlocked
				habitat_tutorial_complete=habitat_unlocked
				original_catalog_gifted=habitat_unlocked
				if habitat_unlocked:unlocked_series[ORIGINAL_SERIES_ID]=true
				if _hidden_species_owned(HIDDEN_PINWHEEL_ID):armadillo_intro_event_3_completed=true
			pending_armadillo_story_event="";tovar_event_active=false;tovar_harvested_this_play=false
			best_spawn_unlocks_dirty=false
			_refresh_seed_pack_unlocks()
			if _normalize_catalog_cover_species() or not value.has("catalog_cover_species"):catalog_cover_migration_dirty=true
			if _reconcile_collection_completion_after_load():collection_completion_migration_dirty=true
			if _is_endless_greenhouse_enabled():
				endless_greenhouse.restore_discovery_state(value.get("endless_discovery_state",{}))
			if migrating_legacy_puku_balance and _ensure_initial_puku_capital(false):puku_balance_migration_dirty=true

func _save() -> void:
	var profile_save_name := ""
	if get_close_profile_enabled and get_close_profile_active:
		get_close_profile_save_count += 1
		profile_save_name = "save" if get_close_profile_save_count == 1 else "save_%d" % get_close_profile_save_count
		_get_close_profile_mark(profile_save_name + "_start")
	var old_colorata_save_name := ""
	if old_colorata_profile_active:
		old_colorata_profile_save_count+=1
		old_colorata_save_name="save" if old_colorata_profile_save_count==1 else "save_%d"%old_colorata_profile_save_count
		_old_colorata_profile_mark(old_colorata_save_name+"_start")
	var f := FileAccess.open(_active_save_path(),FileAccess.WRITE)
	if f==null:
		push_error("Unable to open active save path: %s"%_active_save_path())
		if not profile_save_name.is_empty():_get_close_profile_mark(profile_save_name + "_end")
		if not old_colorata_save_name.is_empty():_old_colorata_profile_mark(old_colorata_save_name+"_end")
		return
	if audio_manager:audio_settings=audio_manager.settings_dictionary()
	var payload:={
		"progression_version":PROGRESSION_VERSION,"retired_content_version":RETIRED_CONTENT_VERSION,"bests":bests,"discovered":discovered,"species_get_counts":species_get_counts,"catalog_cover_species":catalog_cover_species,"collection_complete_versions":collection_complete_versions,
		"unlocked_series":unlocked_series,"owned_pots":owned_pots,"pot_design_unlocks":pot_design_unlocks,"saved_arrangements":saved_arrangements,"arrangement_save_capacity":arrangement_save_capacity,
		"unlocked_species":unlocked_species,"greenhouse_available":greenhouse_available,"completed_unlock_conditions":completed_unlock_conditions,"pending_habitat_species":pending_habitat_species,
		"total_play_count":total_play_count,"normal_play_count":normal_play_count,"formal_play_count":formal_play_count,"shop_visit_count":shop_visit_count,
		"hidden_species_acquired":hidden_species_acquired,"tovar_next_play":tovar_next_play,"tovar_attempt_count":tovar_attempt_count,
		"opening_story_complete":opening_story_complete,"intro_story_complete":intro_story_complete,"encyclopedia_unlocked":encyclopedia_unlocked,"habitat_unlocked":habitat_unlocked,"tutorial_steps":tutorial_steps,
		"first_colorata_confirmed":first_colorata_confirmed,"trio_originals_confirmed":trio_originals_confirmed,"habitat_arrival_started":habitat_arrival_started,"habitat_awakened":habitat_awakened,"habitat_awakening_event_complete":habitat_awakening_event_complete,
		"seed_shop_open":seed_shop_open,"mystery_items_acquired":mystery_items_acquired,"mystery_catalog_tutorial_complete":mystery_catalog_tutorial_complete,"habitat_returned_species":habitat_returned_species,"special_series_explanation_seen":special_series_explanation_seen,"main_story_stage":main_story_stage,"main_story_complete":main_story_complete,"main_story_completion_seen":main_story_completion_seen,
		"normal_play_tutorial_complete":normal_play_tutorial_complete,"seed_pod_gauge_discovery_complete":seed_pod_gauge_discovery_complete,"seed_pod_first_reward_seen":seed_pod_first_reward_seen,"initial_seed_stock_notice_complete":initial_seed_stock_notice_complete,"puku_buyback_tutorial_complete":puku_buyback_tutorial_complete,
		"original_catalog_complete_event_seen":original_catalog_complete_event_seen,"habitat_tutorial_returned_to_greenhouse":habitat_tutorial_returned_to_greenhouse,
		"jurejure_intro_complete":jurejure_intro_complete,"jurejure_enabled":jurejure_enabled,"jurejure_growth_stage":jurejure_growth_stage,"jurejure_growth_event_mask":jurejure_growth_event_mask,
		"active_jurejure_event":{},"jurejure_next_check_unix":0.0,"jurejure_cooldown_until_unix":0.0,
		"jurejure_waiting_for_seed_pod_reward":jurejure_waiting_for_seed_pod_reward,"jurejure_battle_count":jurejure_battle_count,"jurejure_battle_win_count":jurejure_battle_win_count,
		"jurejure_return_event_complete":jurejure_return_event_complete,"habitat_second_awakened":habitat_second_awakened,"habitat_second_awakening_complete":habitat_second_awakening_complete,
		"act2_unlocked":act2_unlocked,"forest_gacha_unlocked":forest_gacha_unlocked,"forest_gacha_intro_seen":forest_gacha_intro_seen,
		"fantasy_first_discovery_seen":fantasy_first_discovery_seen,"fantasy_realization_seen":fantasy_realization_seen,
		"story_progression_state":story_progression_state,
		"act3_unlocked":act3_unlocked,"act3_intro_pending":act3_intro_pending,"act3_intro_seen":act3_intro_seen,"jurejure_pool_unlocked":jurejure_pool_unlocked,"jurejure_species_unlocked":jurejure_species_unlocked,
		"jurejure_species_first_seen":jurejure_species_first_seen,"habitat_crisis_pending":habitat_crisis_pending,"habitat_crisis_started":habitat_crisis_started,"finale_complete":finale_complete,"habitat_return_dialog_seen":habitat_return_dialog_seen,
		"old_seed_bags":old_seed_bags,"puku_gauge_intro_complete":puku_gauge_intro_complete,"habitat_seed_date":habitat_seed_date,"habitat_seeds_collected":habitat_seeds_collected,
		"habitat_mystery_seeds_pending":habitat_mystery_seeds_pending,"mystery_seed_count":mystery_seed_count,"armadillo_research_total":armadillo_research_total,
		"armadillo_research_rewards":armadillo_research_rewards,"armadillo_research_intro_seen":armadillo_research_intro_seen,
		"normal_seed_bags":normal_seed_bags,"volume_seed_bags":volume_seed_bags,"premium_seed_bags":premium_seed_bags,"mystery_seed_bags":mystery_seed_bags,
		"volume_seed_unlocked":volume_seed_unlocked,"volume_seed_intro_seen":volume_seed_intro_seen,"premium_seed_unlocked":premium_seed_unlocked,"mystery_seed_pack_unlocked":mystery_seed_pack_unlocked,
		"best_100_achieved":best_100_achieved,"login_bonus_date":login_bonus_date,"audio_settings":audio_settings,"pending_round_new_species_ids":pending_round_new_species_ids,
		"series_seed_inventory":series_seed_inventory,"forest_gacha_draw_count":forest_gacha_draw_count,"forest_gacha_encountered":forest_gacha_encountered,
		"puku_gauge_cm":puku_gauge_cm,"puku_balance_units":puku_balance_units,"normal_round_free_plays":normal_round_free_plays,"puku_coin_gauge_cm":_legacy_puku_coin_gauge_cm_for_save(),"puku_points":puku_points,"old_catalog_pages":old_catalog_pages,"old_catalog_page_inventory":old_catalog_page_inventory,
		"old_catalog_intro_seen":old_catalog_intro_seen,"old_catalog_intro_pending":old_catalog_intro_pending,"research_catalog_reward_pending":research_catalog_reward_pending,
		"habitat_old_catalog_page_pending":habitat_old_catalog_page_pending,"habitat_old_catalog_page_series_id":habitat_old_catalog_page_series_id,
		"habitat_old_catalog_page_point_x":habitat_old_catalog_page_point.x,"habitat_old_catalog_page_point_y":habitat_old_catalog_page_point.y,
		"old_catalog_page_roll_play_count":old_catalog_page_roll_play_count,"first_tutorial_species_id":first_tutorial_species_id,
		"habitat_wild_plants":habitat_wild_plants,"habitat_wild_initialized":habitat_wild_initialized,"habitat_wild_next_spawn_unix":habitat_wild_next_spawn_unix,
		"habitat_tutorial_started":habitat_tutorial_started,"habitat_tutorial_complete":habitat_tutorial_complete,
		"habitat_tutorial_species_id":habitat_tutorial_species_id,"original_catalog_gifted":original_catalog_gifted,
		"armadillo_intro_event_3_completed":armadillo_intro_event_3_completed,"armadillo_series_event_7_completed":armadillo_series_event_7_completed,
		"pending_armadillo_story_event":pending_armadillo_story_event,"armadillo_gift_series_id":armadillo_gift_series_id,"armadillo_gift_species_id":armadillo_gift_species_id,
		"language_code":language_code,"language_selected":language_selected,"first_habitat_gift_claimed":first_habitat_gift_claimed
	}
	# Discovery-cycle state belongs only to the endless save namespace. A legacy
	# finite save never receives these fields, even though both modes share the
	# same serializer.
	if _is_endless_greenhouse_enabled():payload["endless_discovery_state"]=endless_greenhouse.discovery_state_for_save()
	f.store_string(JSON.stringify(payload))
	f.close()
	if not profile_save_name.is_empty():_get_close_profile_mark(profile_save_name + "_end")
	if not old_colorata_save_name.is_empty():_old_colorata_profile_mark(old_colorata_save_name+"_end")

func _active_save_path()->String:
	return endless_greenhouse.active_save_path()

func _is_endless_greenhouse_enabled()->bool:
	return endless_greenhouse.enabled

func _trial_dev_controls_enabled()->bool:
	return TRIAL_DEV_CONTROLS_ENABLED

func _trial_dev_controls_enabled_for_context(_is_web_build:bool)->bool:
	# Compatibility seam for existing smoke tests and callers. Platform and URL
	# parameters intentionally do not participate in the decision anymore.
	return _trial_dev_controls_enabled()

func _is_endless_normal_play()->bool:
	return _is_endless_greenhouse_enabled() and play_active and active_seed_type=="normal"

func _endless_puku_economy_active()->bool:
	return _is_endless_normal_play() and puku_gauge_intro_complete

func _greenhouse_jelly_balance_for_spawn()->Dictionary:
	# An explicit developer override must win while the unified development gate
	# is enabled so device builds can exercise the same tuning controls as Web.
	if _trial_dev_controls_enabled() and JellyBalanceClass.override_enabled:
		return JellyBalanceClass.effective().duplicate(true)
	# Production ENDLESS plants keep their formal resistance mix. Every other
	# Succulent setup path keeps its existing balance.
	return JellyBalanceClass.endless_normal_trial_balance() if _is_endless_normal_play() else {}

func _normal_seed_play_available()->bool:
	# Unlimited supply begins only after the story actually grants the mysterious
	# pod. Formal endless progression must not expose normal seeds during the
	# old-seed prologue.
	return normal_seed_bags>0 or (_is_endless_greenhouse_enabled() and first_habitat_gift_claimed)

func _endless_normal_flow_owns_play_controls()->bool:
	return _is_endless_greenhouse_enabled() and first_habitat_gift_claimed

func _endless_auto_sow_prompt_seen()->bool:
	return bool(tutorial_steps.get(ENDLESS_AUTO_SOW_TUTORIAL_STEP,false))

func _endless_greenhouse_auto_start_unlocked()->bool:
	if not _endless_normal_flow_owns_play_controls():return false
	if not initial_seed_stock_notice_complete or not habitat_tutorial_complete:return false
	if not mystery_items_acquired or not mystery_catalog_tutorial_complete:return false
	return normal_play_tutorial_complete or _endless_auto_sow_prompt_seen()

func _endless_greenhouse_auto_start_blocked()->bool:
	if current_mode!="greenhouse" or arrangement_scene_active or arrangement_transitioning:return true
	if not opening_finished or opening_overlay and opening_overlay.visible:return true
	if catalog_preview_mode_active or dev_jelly_test_active:return true
	if not scripted_dialog_kind.is_empty() or not tutorial_dialog_kind.is_empty():return true
	if scene_transition_fade and scene_transition_fade.visible:return true
	if opening_story_overlay and opening_story_overlay.visible:return true
	if habitat_awakening_overlay and habitat_awakening_overlay.visible:return true
	if seed_pod_story_overlay and seed_pod_story_overlay.visible:return true
	if habitat_second_awakening_overlay and habitat_second_awakening_overlay.visible:return true
	if jurejure_first_encounter_overlay and jurejure_first_encounter_overlay.visible:return true
	if jurejure_first_encounter_active:return true
	if puku_buyback_tutorial_active or first_seed_pod_reward_event_active:return true
	if tutorial_guide_overlay and tutorial_guide_overlay.visible:return true
	if intro_overlay and intro_overlay.visible:return true
	if settings_overlay and settings_overlay.visible:return true
	if jelly_dev_overlay and jelly_dev_overlay.visible:return true
	if encyclopedia_overlay and encyclopedia_overlay.visible:return true
	if shop_overlay and shop_overlay.visible:return true
	if result_overlay and result_overlay.visible:return true
	if forest_gacha_ui and forest_gacha_ui.visible:return true
	if fusion_lab_ui and fusion_lab_ui.visible:return true
	if species_get_overlay and species_get_overlay.visible:return true
	if catalog_series_unlock_overlay and catalog_series_unlock_overlay.visible:return true
	if puku_puku_battle and puku_puku_battle.visible:return true
	if catalog_preview_ui and catalog_preview_ui.is_overlay_open():return true
	if habitat_plant_panel and habitat_plant_panel.visible:return true
	if habitat_dev_panel and habitat_dev_panel.visible:return true
	if story_dev_panel and story_dev_panel.visible:return true
	if habitat_restoration_ui and habitat_restoration_ui.is_modal_visible():return true
	return false

func _ensure_endless_greenhouse_running()->void:
	# Compatibility entry point retained for story callbacks from older saves.
	# Formal normal play is now a player-started 12-seed round, never an
	# automatically restarted endless loop.
	if not _endless_greenhouse_auto_start_unlocked() or play_active:return
	if play_modal_open:
		play_modal_open=false
		if play_overlay:play_overlay.visible=false
	_update_play_ui()

func _puku_whole_count(balance_units:int=-1)->int:
	var resolved_units:=puku_balance_units if balance_units<0 else balance_units
	return maxi(0,floori(float(resolved_units)/float(PUKU_UNITS_PER_PUKU)))

func _puku_fraction_units(balance_units:int=-1)->int:
	var resolved_units:=puku_balance_units if balance_units<0 else balance_units
	return posmod(maxi(0,resolved_units),PUKU_UNITS_PER_PUKU)

func _puku_cost_units(puku_cost:int)->int:
	return maxi(0,puku_cost)*PUKU_UNITS_PER_PUKU

func _can_afford_puku_units(cost_units:int)->bool:
	return puku_balance_units>=maxi(0,cost_units)

func _legacy_puku_coin_gauge_cm_for_save()->float:
	return float(_puku_fraction_units())/float(LEGACY_PUKU_GAUGE_REWARD_UNITS)*LEGACY_PUKU_GAUGE_TARGET_CM

func _ensure_initial_puku_capital(show_effect:=false)->bool:
	if not puku_gauge_intro_complete or puku_balance_units>=INITIAL_PUKU_CAPITAL_UNITS:return false
	_change_puku_balance(INITIAL_PUKU_CAPITAL_UNITS-puku_balance_units,"initial_capital",false,show_effect)
	return true

func _resolve_jurejure_progress_reward(reward_kind:String)->void:
	# The legacy save field is kept for rollback compatibility. Its release event
	# is mode-specific: finite play waits for a seed-pod payout; ENDLESS has no
	# visible gauges and waits for the next hidden 12-settlement discovery set.
	if not jurejure_waiting_for_seed_pod_reward:return
	if (_is_endless_greenhouse_enabled() and reward_kind=="discovery_set") or (not _is_endless_greenhouse_enabled() and reward_kind=="seed_pod"):
		jurejure_waiting_for_seed_pod_reward=false

func _should_simulate_endless_greenhouse()->bool:
	if not _is_endless_normal_play():return true
	if current_mode!="greenhouse" or arrangement_scene_active or arrangement_transitioning:return false
	if not species_get_queue.is_empty() or not scripted_dialog_kind.is_empty():return false
	if scene_transition_fade and scene_transition_fade.visible:return false
	if opening_overlay and opening_overlay.visible:return false
	if opening_story_overlay and opening_story_overlay.visible:return false
	if habitat_awakening_overlay and habitat_awakening_overlay.visible:return false
	if seed_pod_story_overlay and seed_pod_story_overlay.visible:return false
	if habitat_second_awakening_overlay and habitat_second_awakening_overlay.visible:return false
	if jurejure_first_encounter_overlay and jurejure_first_encounter_overlay.visible:return false
	if puku_puku_battle and puku_puku_battle.visible:return false
	if tutorial_guide_overlay and tutorial_guide_overlay.visible:return false
	if intro_overlay and intro_overlay.visible:return false
	if settings_overlay and settings_overlay.visible:return false
	if encyclopedia_overlay and encyclopedia_overlay.visible:return false
	if shop_overlay and shop_overlay.visible:return false
	if play_overlay and play_overlay.visible:return false
	if result_overlay and result_overlay.visible:return false
	if forest_gacha_ui and forest_gacha_ui.visible:return false
	if fusion_lab_ui and fusion_lab_ui.visible:return false
	if species_get_overlay and species_get_overlay.visible:return false
	if catalog_series_unlock_overlay and catalog_series_unlock_overlay.visible:return false
	if catalog_preview_ui and catalog_preview_ui.is_overlay_open():return false
	if habitat_plant_panel and habitat_plant_panel.visible:return false
	if habitat_dev_panel and habitat_dev_panel.visible:return false
	if story_dev_panel and story_dev_panel.visible:return false
	if jelly_dev_overlay and jelly_dev_overlay.visible:return false
	if habitat_restoration_ui and habitat_restoration_ui.is_modal_visible():return false
	return true

func _queue_stale_jellied_habitat_cleanup(source:Variant)->void:
	if not source is Array:return
	for value in source:
		if not value is Dictionary or not bool(value.get("jellied",false)):continue
		var individual_id:=str(value.get("individual_id",""))
		if not individual_id.is_empty():
			if individual_id not in legacy_habitat_notification_ids_to_cancel:legacy_habitat_notification_ids_to_cancel.append(individual_id)
			if habitat_notification_service:habitat_notification_service.cancel(individual_id)
		legacy_habitat_migration_dirty=true

func _queue_legacy_beacon_cleanup(source:Variant)->void:
	if not source is Array:return
	for value in source:
		if not value is Dictionary or not bool(value.get("panda_beacon_installed",false)):continue
		var individual_id:=str(value.get("individual_id",""))
		if not individual_id.is_empty() and individual_id not in legacy_habitat_notification_ids_to_cancel:legacy_habitat_notification_ids_to_cancel.append(individual_id)
	legacy_habitat_migration_dirty=legacy_habitat_migration_dirty or not legacy_habitat_notification_ids_to_cancel.is_empty()

func _migrate_habitat_settlement()->void:
	var settled:Dictionary={}
	# Preserve valid residents already recorded by old saves. JureJure reward
	# species are deliberately excluded because they have no natural spawn route.
	for species_id_value in habitat_returned_species:
		var saved_species_id:=str(species_id_value)
		var saved_entry:=_catalog_entry(saved_species_id)
		if bool(habitat_returned_species.get(species_id_value,false)) and not saved_entry.is_empty() and not _is_jurejure_species(saved_entry):settled[saved_species_id]=true
	for species_id_value in discovered:
		var species_id:=str(species_id_value)
		var entry:=_catalog_entry(species_id)
		if bool(discovered.get(species_id,false)) and not entry.is_empty() and not _is_jurejure_species(entry):settled[species_id]=true
	if habitat_awakened:
		for story_species_id in [FIRST_STORY_SPECIES_ID,PANDA_STORY_SPECIES_ID,ARMADILLO_STORY_SPECIES_ID]:settled[story_species_id]=true
	habitat_returned_species=settled
	var kept_plants:Array[Dictionary]=[]
	for plant in habitat_wild_plants:
		if bool(settled.get(str(plant.get("species_id","")),false)):kept_plants.append(plant)
	if kept_plants.size()!=habitat_wild_plants.size():legacy_habitat_migration_dirty=true
	habitat_wild_plants.assign(kept_plants)
	var kept_pending:Array=[]
	for species_id_value in pending_habitat_species:
		var species_id:=str(species_id_value)
		if bool(settled.get(species_id,false)) and species_id not in kept_pending:kept_pending.append(species_id)
	pending_habitat_species=kept_pending

func _migrate_legacy_runaway_habitat(raw_population:Variant)->bool:
	if not HabitatWildSystemClass.has_legacy_runaway_population(raw_population):return false
	legacy_habitat_notification_ids_to_cancel.clear()
	if raw_population is Array:
		for raw_value in raw_population:
			if not raw_value is Dictionary:continue
			var individual_id:=str(raw_value.get("individual_id",""))
			if not individual_id.is_empty() and individual_id not in legacy_habitat_notification_ids_to_cancel:legacy_habitat_notification_ids_to_cancel.append(individual_id)
	habitat_wild_plants.clear();habitat_wild_initialized=false;habitat_wild_next_spawn_unix=0.0;habitat_tutorial_species_id="";legacy_habitat_migration_dirty=true
	return true

func _sanitize_removed_common_progress()->void:
	# v18 retired the old common catalog. Remove only those exact IDs; every
	# unrelated record, currency, habitat clock, beacon and arrangement survives.
	for species_id in StoryProgressionClass.REMOVED_COMMON_SPECIES_IDS:
		bests.erase(species_id);discovered.erase(species_id);species_get_counts.erase(species_id)
		greenhouse_available.erase(species_id);unlocked_species.erase(species_id)
		forest_gacha_encountered.erase(species_id);hidden_species_acquired.erase(species_id)
		habitat_returned_species.erase(species_id)
	unlocked_series.erase("common")
	unlocked_series[ORIGINAL_SERIES_ID]=true
	series_seed_inventory.erase("common")
	var clean_pending:Array=[]
	for species_id in pending_habitat_species:
		if not StoryProgressionClass.is_removed_species(str(species_id)):clean_pending.append(str(species_id))
	pending_habitat_species=clean_pending

func _sanitize_retired_special_species_progress()->bool:
	# The six retired prototype rewards may occur in old development saves. Drop
	# only their references; every unrelated plant, currency and story flag stays.
	var changed:=false
	var species_dictionaries:Array[Dictionary]=[
		bests,discovered,species_get_counts,greenhouse_available,unlocked_species,
		forest_gacha_encountered,hidden_species_acquired,habitat_returned_species,
	]
	for species_id in StoryProgressionClass.RETIRED_SPECIAL_BASE_SPECIES_IDS:
		for state_dictionary in species_dictionaries:
			if state_dictionary.has(species_id):state_dictionary.erase(species_id);changed=true
	for series_id_value in catalog_cover_species.keys():
		if StoryProgressionClass.is_retired_special_base_species(str(catalog_cover_species.get(series_id_value,""))):
			catalog_cover_species.erase(series_id_value);changed=true
	var clean_pending:Array=[]
	for species_id_value in pending_habitat_species:
		var species_id:=str(species_id_value)
		if StoryProgressionClass.is_retired_special_base_species(species_id):changed=true
		elif species_id not in clean_pending:clean_pending.append(species_id)
	pending_habitat_species=clean_pending
	var clean_pending_round:Array[String]=[]
	for species_id_value in pending_round_new_species_ids:
		var species_id:=str(species_id_value)
		if StoryProgressionClass.is_retired_special_base_species(species_id):changed=true
		elif species_id not in clean_pending_round:clean_pending_round.append(species_id)
	pending_round_new_species_ids=clean_pending_round
	var clean_result_new:Array[String]=[]
	for species_id_value in result_new_species_queue:
		var species_id:=str(species_id_value)
		if StoryProgressionClass.is_retired_special_base_species(species_id):changed=true
		elif species_id not in clean_result_new:clean_result_new.append(species_id)
	result_new_species_queue=clean_result_new
	var clean_result_deferred:Array[String]=[]
	for species_id_value in result_deferred_species_queue:
		var species_id:=str(species_id_value)
		if StoryProgressionClass.is_retired_special_base_species(species_id):changed=true
		elif species_id not in clean_result_deferred:clean_result_deferred.append(species_id)
	result_deferred_species_queue=clean_result_deferred
	for property_name in ["first_tutorial_species_id","habitat_tutorial_species_id","armadillo_gift_species_id"]:
		var species_id:=str(get(property_name))
		if StoryProgressionClass.is_retired_special_base_species(species_id):set(property_name,"");changed=true
	return changed

func _migrate_story_progress(saved_progression_version:int)->void:
	unlocked_series[ORIGINAL_SERIES_ID]=true
	if saved_progression_version>=19:
		if saved_progression_version<PROGRESSION_VERSION:
			if habitat_awakened or habitat_tutorial_complete or bool(tutorial_steps.get("seed_pod_story_seen",false)):
				mystery_items_acquired=true;mystery_catalog_tutorial_complete=true
				seed_shop_open=true;original_catalog_gifted=true;puku_gauge_intro_complete=true;first_habitat_gift_claimed=true
				tutorial_steps["seed_pod_story_seen"]=true;tutorial_steps["puku_gauge_intro_complete"]=true
			else:
				encyclopedia_unlocked=false;puku_gauge_intro_complete=false
			_migrate_catalog_unlocks_without_puku()
		if mystery_items_acquired:
			encyclopedia_unlocked=true;seed_shop_open=true;original_catalog_gifted=true;puku_gauge_intro_complete=true
		if habitat_awakened:habitat_arrival_started=true;habitat_awakening_event_complete=true
		main_story_stage=clampi(main_story_stage,StoryProgressionClass.LEGACY_STAGE_MIN,StoryProgressionClass.LEGACY_STAGE_MAX)
		jurejure_growth_stage=JureJureSystemClass.growth_stage(StoryProgressionClass.original_count(discovered))
		active_jurejure_event={};jurejure_next_check_unix=0.0;jurejure_cooldown_until_unix=0.0
		return
	var previously_completed:=main_story_complete or main_story_completion_seen or main_story_stage>=9
	var established_save:=habitat_unlocked or habitat_tutorial_started or habitat_tutorial_complete or habitat_wild_initialized
	if established_save:
		opening_story_complete=true;intro_story_complete=true;first_colorata_confirmed=true;trio_originals_confirmed=true
		for species_id in [FIRST_STORY_SPECIES_ID,PANDA_STORY_SPECIES_ID,ARMADILLO_STORY_SPECIES_ID]:
			discovered[species_id]=true;greenhouse_available[species_id]=true;unlocked_species[species_id]=true
		habitat_unlocked=true;habitat_arrival_started=true;habitat_awakened=true;habitat_awakening_event_complete=true
	elif intro_story_complete and total_play_count>0:
		first_colorata_confirmed=true;discovered[FIRST_STORY_SPECIES_ID]=true;greenhouse_available[FIRST_STORY_SPECIES_ID]=true;unlocked_species[FIRST_STORY_SPECIES_ID]=true
	if habitat_tutorial_complete or puku_gauge_intro_complete or normal_seed_bags>0:
		seed_shop_open=true
	if habitat_awakened:
		for species_id in discovered:
			if bool(discovered.get(species_id,false)):habitat_returned_species[str(species_id)]=true
	habitat_tutorial_returned_to_greenhouse=habitat_tutorial_complete
	original_catalog_complete_event_seen=previously_completed and StoryProgressionClass.originals_complete(discovered)
	# v18 considered the original catalog itself the ending. In v19 it is the
	# doorway to the gang's return and the second awakening instead.
	habitat_second_awakened=false;habitat_second_awakening_complete=false;jurejure_return_event_complete=false
	main_story_complete=false;main_story_completion_seen=false
	jurejure_intro_complete=false;jurejure_enabled=false;jurejure_growth_stage=JureJureSystemClass.growth_stage(StoryProgressionClass.original_count(discovered));jurejure_growth_event_mask=0;active_jurejure_event={}
	jurejure_next_check_unix=0.0;jurejure_cooldown_until_unix=0.0;jurejure_waiting_for_seed_pod_reward=false;jurejure_battle_count=0;jurejure_battle_win_count=0
	main_story_stage=StoryProgressionClass.ACT_1
	if habitat_awakened:
		mystery_items_acquired=true;mystery_catalog_tutorial_complete=true;encyclopedia_unlocked=true
		seed_shop_open=true;original_catalog_gifted=true;puku_gauge_intro_complete=true;first_habitat_gift_claimed=true
		tutorial_steps["seed_pod_story_seen"]=true;tutorial_steps["puku_gauge_intro_complete"]=true
	_migrate_catalog_unlocks_without_puku()
	legacy_habitat_migration_dirty=true

func _migrate_three_act_progress(saved_progression_version:int,retired_secret_gacha_evidence:=false)->void:
	var sanitized_jurejure_unlocks:Dictionary={}
	var legacy_jurejure_unlock_found:=false
	for species_id_value in jurejure_species_unlocked:
		var saved_species_id:=str(species_id_value);var saved_entry:=_catalog_entry(saved_species_id)
		if bool(jurejure_species_unlocked.get(species_id_value,false)) and _is_jurejure_species(saved_entry):
			sanitized_jurejure_unlocks[saved_species_id]=true;legacy_jurejure_unlock_found=true
	jurejure_species_unlocked=sanitized_jurejure_unlocks
	# Any real legacy JureJure GET/unlock is authoritative evidence that the
	# player already crossed the new one-time pool gate. Keep ownership exact,
	# while opening all ten only as future acquisition candidates.
	for raw_entry in catalog_species:
		if raw_entry is Dictionary and _is_jurejure_species(raw_entry):
			var owned_jurejure_id:=str(raw_entry.get("species_id",""))
			if _species_get_count(owned_jurejure_id)>0:
				legacy_jurejure_unlock_found=true
	jurejure_pool_unlocked=jurejure_pool_unlocked or legacy_jurejure_unlock_found
	if jurejure_pool_unlocked:_sync_jurejure_pool_unlock_state()
	var fantasy_count:=_unique_fantasy_species_get_count()
	var act2_species_count:=_unique_act2_species_get_count()
	var jurejure_count:=_unique_jurejure_species_get_count()
	if jurejure_battle_count>=1 or habitat_second_awakened or fantasy_count>0:
		act2_unlocked=true
	story_progression_state=StoryProgressionClass.normalize_runtime_state(story_progression_state,{
		"legacy":saved_progression_version<PROGRESSION_VERSION,
		"act2_unlocked":act2_unlocked,
		"fantasy_get_count":fantasy_count,
		"arrangement_evidence":not saved_arrangements.is_empty(),
		"forest_gacha_evidence":forest_gacha_unlocked or forest_gacha_draw_count>0,
		"act3_intro_seen":act3_intro_seen,
		"jurejure_get_count":jurejure_count,
		"jurejure_intro_complete":jurejure_intro_complete,
		"habitat_crisis_started":habitat_crisis_started,
		"habitat_crisis_pending":habitat_crisis_pending,
		"secret_gacha_evidence":retired_secret_gacha_evidence,
	})
	if fantasy_first_discovery_seen:StoryProgressionClass.consume_story_event(story_progression_state,StoryProgressionClass.EVENT_FANTASY_FIRST)
	if fantasy_realization_seen:StoryProgressionClass.consume_story_event(story_progression_state,StoryProgressionClass.EVENT_FANTASY_SIX)
	# Existing access or a completed six-species milestone is durable evidence;
	# never revoke Forest Gacha from a legacy save. New v28 games wait for the
	# six-species realization dialogue before this flag is set.
	if saved_progression_version<PROGRESSION_VERSION and (forest_gacha_unlocked or forest_gacha_draw_count>0 or fantasy_count>=6):
		forest_gacha_unlocked=true
		story_progression_state["forest_gacha_unlock_pending"]=false
	if saved_progression_version<26:
		# Earlier builds had no safe post-GET discovery events. Do not replay a
		# backlog on load; acknowledge thresholds the player already passed.
		if fantasy_count>=1:fantasy_first_discovery_seen=true
		if fantasy_count>=6:fantasy_realization_seen=true
		if forest_gacha_draw_count>0:forest_gacha_intro_seen=true
	elif saved_progression_version<PROGRESSION_VERSION:
		if fantasy_count>=1 and not fantasy_first_discovery_seen:StoryProgressionClass.queue_story_event(story_progression_state,StoryProgressionClass.EVENT_FANTASY_FIRST)
		if fantasy_count>=6 and not fantasy_realization_seen:StoryProgressionClass.queue_story_event(story_progression_state,StoryProgressionClass.EVENT_FANTASY_SIX)
	if act2_species_count>=24:
		act3_unlocked=true
		if not act3_intro_seen:act3_intro_pending=true
	if act3_intro_seen:
		act3_intro_pending=false
	if jurejure_count>=1 and saved_progression_version<PROGRESSION_VERSION:jurejure_species_first_seen=true
	if jurejure_count>=8 and not habitat_crisis_started:
		habitat_crisis_pending=true
		if StoryProgressionClass.habitat_crisis_route(story_progression_state).is_empty():
			StoryProgressionClass.queue_habitat_crisis_transition(story_progression_state,false)
	if habitat_crisis_started:
		habitat_crisis_pending=false;jurejure_waiting_for_seed_pod_reward=false;StoryProgressionClass.clear_habitat_crisis_transition(story_progression_state)
	for raw_entry in catalog_species:
		if raw_entry is Dictionary and _is_jurejure_species(raw_entry):
			var jurejure_species_id:=str(raw_entry.get("species_id",""))
			habitat_returned_species.erase(jurejure_species_id)
			if _species_get_count(jurejure_species_id)>0:greenhouse_available[jurejure_species_id]=true;unlocked_species[jurejure_species_id]=true
			else:greenhouse_available.erase(jurejure_species_id);unlocked_species.erase(jurejure_species_id)

func _migrate_catalog_unlocks_without_puku()->void:
	for species_id_value in discovered:
		if not bool(discovered.get(species_id_value,false)):continue
		var series_id:=_series_id_for_species(str(species_id_value))
		if not series_id.is_empty():unlocked_series[series_id]=true
	for series_id_value in old_catalog_page_inventory:
		var series_id:=str(series_id_value)
		if not _series_entry(series_id).is_empty():unlocked_series[series_id]=true
	if not habitat_old_catalog_page_series_id.is_empty() and not _series_entry(habitat_old_catalog_page_series_id).is_empty():unlocked_series[habitat_old_catalog_page_series_id]=true
	old_catalog_page_inventory.clear();old_catalog_pages=0;old_catalog_intro_pending=false;habitat_old_catalog_page_pending=false;habitat_old_catalog_page_series_id=""

func _daily_seed_gift_due()->bool:
	return false

func _apply_saved_unlocks()->void:
	species.clear()
	for entry in catalog_species:
		var species_id:=str(entry.species_id)
		if bool(greenhouse_available.get(species_id,false)) and _species_available_in_current_era(entry):species.append(entry)
	if species.is_empty():
		# Keep random-selection callers safe before the first discovery without
		# pretending that the plant is already owned.
		var fallback:=_catalog_entry(FIRST_STORY_SPECIES_ID)
		if not fallback.is_empty():species.append(fallback)

func _evaluate_best_spawn_unlocks(apply_now:=true)->bool:
	# Retained as a compatibility entry point for old smoke helpers. Size-based
	# species unlocks were retired in progression v24.
	return false

func _build_world() -> void:
	greenhouse_layer=CanvasLayer.new();greenhouse_layer.layer=-10;add_child(greenhouse_layer)
	greenhouse_backdrop=TextureRect.new();greenhouse_backdrop.name="GreenhouseMasterBackdrop";greenhouse_backdrop.texture=load(GREENHOUSE_MASTER_PATH);greenhouse_backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;greenhouse_backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT;greenhouse_backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;greenhouse_layer.add_child(greenhouse_backdrop)
	world_root = Node3D.new(); add_child(world_root)
	habitat_env=WorldEnvironment.new(); var env:=Environment.new()
	_build_habitat_background(env)
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color=Color("#d6b98b"); env.ambient_light_energy=0.32
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	habitat_environment=env;habitat_env.environment=env; world_root.add_child(habitat_env)
	habitat_items_root=Node3D.new();habitat_items_root.visible=false;world_root.add_child(habitat_items_root)
	var sun:=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-18,72,0); sun.light_color=Color("#ffd9a0"); sun.light_energy=0.28; sun.shadow_enabled=false; world_root.add_child(sun)
	camera=Camera3D.new(); camera.fov=54.0; camera.current=true; world_root.add_child(camera)
	_build_greenhouse_pot()
	_apply_mode()

func _build_habitat_background(env:Environment)->void:
	habitat_panorama_mesh=null
	env.sky=null
	env.background_color=Color("#71816f")
	if habitat_background_mode=="current":
		var sky:=Sky.new();var panorama:=PanoramaSkyMaterial.new()
		# The visible panorama stays at its imported resolution. Only the
		# environment-lighting radiance cubemap uses the existing 512 setting.
		sky.radiance_size=Sky.RADIANCE_SIZE_512
		panorama.panorama=load("res://assets/highland-panorama.jpg")
		sky.sky_material=panorama;env.sky=sky;env.background_mode=Environment.BG_SKY
	elif habitat_background_mode=="panorama_mesh":
		env.background_mode=Environment.BG_COLOR
		habitat_panorama_mesh=MeshInstance3D.new();habitat_panorama_mesh.name="HabitatPanoramaMesh"
		var sphere:=SphereMesh.new();sphere.radius=50.0;sphere.height=100.0;sphere.radial_segments=64;sphere.rings=32;habitat_panorama_mesh.mesh=sphere
		var material:=StandardMaterial3D.new();material.albedo_texture=load("res://assets/highland-panorama.jpg");material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.cull_mode=BaseMaterial3D.CULL_FRONT;material.no_depth_test=true;material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR
		habitat_panorama_mesh.material_override=material;habitat_panorama_mesh.visible=false;world_root.add_child(habitat_panorama_mesh)
	else:
		env.background_mode=Environment.BG_COLOR
	print("HABITAT_BACKGROUND_BUILD mode=",habitat_background_mode," sky_present=",env.sky!=null," panorama_mesh_present=",habitat_panorama_mesh!=null)

func _build_greenhouse_pot()->void:
	pot_root=Node3D.new();world_root.add_child(pot_root)
	var body:=MeshInstance3D.new();var body_mesh:=CylinderMesh.new();body_mesh.top_radius=4.55;body_mesh.bottom_radius=3.75;body_mesh.height=1.65;body_mesh.radial_segments=64;body.mesh=body_mesh;body.position.y=-.86;body.material_override=_terracotta_material(false);pot_root.add_child(body)
	var rim:=MeshInstance3D.new();var rim_mesh:=TorusMesh.new();rim_mesh.inner_radius=4.18;rim_mesh.outer_radius=4.62;rim_mesh.rings=64;rim_mesh.ring_segments=16;rim.mesh=rim_mesh;rim.position.y=.02;rim.material_override=_terracotta_material(true);pot_root.add_child(rim)
	var soil:=MeshInstance3D.new();var soil_mesh:=CylinderMesh.new();soil_mesh.top_radius=4.18;soil_mesh.bottom_radius=4.18;soil_mesh.height=.18;soil_mesh.radial_segments=64;soil.mesh=soil_mesh;soil.position.y=-.03;soil.material_override=_soil_material();pot_root.add_child(soil)

func _mat(color: Color, rough: float, metallic: float) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=color; m.roughness=rough; m.metallic=metallic; return m

func _terracotta_material(is_rim: bool) -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
render_mode specular_schlick_ggx;
uniform vec3 clay_dark : source_color = vec3(0.31,0.105,0.055);
uniform vec3 clay_light : source_color = vec3(0.58,0.245,0.12);
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){float grain=hash(floor(UV*vec2(180.0,90.0)));float bands=sin(UV.y*55.0+sin(UV.x*19.0))*0.5+0.5;float wear=smoothstep(0.40,0.92,grain)*0.13;ALBEDO=mix(clay_dark,clay_light,0.46+bands*0.12+wear);ROUGHNESS=0.78;SPECULAR=0.25;}"""
	var material:=ShaderMaterial.new();material.shader=shader
	if is_rim: material.set_shader_parameter("clay_light",Color("#a94f2c"));material.set_shader_parameter("clay_dark",Color("#572315"))
	return material

func _soil_material()->ShaderMaterial:
	var shader:=Shader.new();shader.code="""shader_type spatial;
void fragment(){float a=sin(UV.x*173.0+sin(UV.y*61.0)*2.7)*sin(UV.y*157.0+sin(UV.x*47.0)*2.2);float b=sin(UV.x*43.0+UV.y*51.0)*.5+.5;float grain=clamp(a*.5+.5,0.0,1.0);vec3 lo=vec3(.105,.047,.027);vec3 hi=vec3(.31,.145,.075);vec3 c=mix(lo,hi,grain*.34+b*.12);ALBEDO=c;ROUGHNESS=.96;SPECULAR=.08;}""";var material:=ShaderMaterial.new();material.shader=shader;return material

func _build_ui() -> void:
	var ui:=CanvasLayer.new(); ui.layer=10; add_child(ui)
	labels_layer=Control.new(); labels_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); labels_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(labels_layer)
	var hud:=Control.new(); hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); hud.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(hud)
	main_status_hud=Control.new();main_status_hud.name="MainStatusHUD";main_status_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);main_status_hud.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(main_status_hud)
	effects_layer=Control.new(); effects_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); effects_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(effects_layer)
	var game_theme:=Theme.new();game_theme.default_font=load("res://assets/fonts/ZenMaruGothic-Bold.ttf") as Font;game_theme.default_font_size=16
	labels_layer.theme=game_theme;hud.theme=game_theme;main_status_hud.theme=game_theme;effects_layer.theme=game_theme
	# logo
	var logo:=Label.new(); logo.name="MainLogo";logo.text=Localizer.text(language_code,"game_title"); logo.position=Vector2(16,34); logo.size=Vector2(180,105); logo.add_theme_font_size_override("font_size",31); logo.add_theme_color_override("font_color",Color("#fff2d3")); logo.add_theme_color_override("font_outline_color",UI_BROWN); logo.add_theme_constant_override("outline_size",8); logo.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;logo.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; main_status_hud.add_child(logo)
	var ribbon:=Label.new(); ribbon.text=" PUKU PUKU TANIKU "; ribbon.position=Vector2(45,126); ribbon.add_theme_font_size_override("font_size",11); ribbon.add_theme_color_override("font_color",Color.WHITE); ribbon.add_theme_stylebox_override("normal",_box(Color("#d99a3c"),Color("#7b4a25"),12,2)); main_status_hud.add_child(ribbon)
	best_panel=PanelContainer.new(); best_panel.position=Vector2(204,122); best_panel.size=Vector2(168,65); best_panel.add_theme_stylebox_override("panel",_box(Color("#47261b"),Color("#f5c985"),16,2)); main_status_hud.add_child(best_panel)
	best_label=Label.new();best_label.name="BestLabel";best_label.text="最高記録\n0.0 cm"; best_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; best_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; best_label.add_theme_font_size_override("font_size",17); best_label.add_theme_color_override("font_color",Color.WHITE); best_panel.add_child(best_label)
	seed_pod_gauge_area=Control.new();seed_pod_gauge_area.name="SeedPodGaugeArea";seed_pod_gauge_area.position=Vector2(42,145);seed_pod_gauge_area.size=Vector2(158,47);seed_pod_gauge_area.mouse_filter=Control.MOUSE_FILTER_IGNORE;main_status_hud.add_child(seed_pod_gauge_area)
	var pod_content:=VBoxContainer.new();pod_content.position=Vector2(13,0);pod_content.size=Vector2(132,47);pod_content.alignment=BoxContainer.ALIGNMENT_CENTER;pod_content.mouse_filter=Control.MOUSE_FILTER_IGNORE;pod_content.add_theme_constant_override("separation",2);seed_pod_gauge_area.add_child(pod_content)
	seed_pod_gauge_label=Label.new();seed_pod_gauge_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;seed_pod_gauge_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;seed_pod_gauge_label.add_theme_font_size_override("font_size",14);seed_pod_gauge_label.add_theme_color_override("font_color",Color("#effff4"));seed_pod_gauge_label.add_theme_color_override("font_outline_color",Color("#183d2a"));seed_pod_gauge_label.add_theme_constant_override("outline_size",4);pod_content.add_child(seed_pod_gauge_label)
	seed_pod_gauge_meter=ProgressBar.new();seed_pod_gauge_meter.custom_minimum_size=Vector2(132,10);seed_pod_gauge_meter.max_value=SEED_POD_GAUGE_TARGET_CM;seed_pod_gauge_meter.show_percentage=false;seed_pod_gauge_meter.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var pod_meter_bg:=StyleBoxFlat.new();pod_meter_bg.bg_color=Color(0.035,.12,.09,.88);pod_meter_bg.set_corner_radius_all(5);pod_meter_bg.border_color=Color(0.18,.40,.29,.72);pod_meter_bg.set_border_width_all(1)
	seed_pod_gauge_fill_style=StyleBoxFlat.new();seed_pod_gauge_fill_style.bg_color=Color("#65d59a");seed_pod_gauge_fill_style.border_color=Color("#d7ffe7");seed_pod_gauge_fill_style.set_border_width_all(1);seed_pod_gauge_fill_style.set_corner_radius_all(5);seed_pod_gauge_meter.add_theme_stylebox_override("background",pod_meter_bg);seed_pod_gauge_meter.add_theme_stylebox_override("fill",seed_pod_gauge_fill_style);pod_content.add_child(seed_pod_gauge_meter)
	seed_pod_gauge_glow=Panel.new();seed_pod_gauge_glow.name="SeedPodGaugeGlow";seed_pod_gauge_glow.show_behind_parent=true;seed_pod_gauge_glow.mouse_filter=Control.MOUSE_FILTER_IGNORE;seed_pod_gauge_glow.position=Vector2(1,1);seed_pod_gauge_glow.size=Vector2(2,8);seed_pod_gauge_glow_style=StyleBoxFlat.new();seed_pod_gauge_glow_style.bg_color=Color(0,0,0,0);seed_pod_gauge_glow_style.border_color=Color(.55,1.0,.72,.45);seed_pod_gauge_glow_style.set_border_width_all(1);seed_pod_gauge_glow_style.set_corner_radius_all(5);seed_pod_gauge_glow_style.shadow_color=Color(.25,1.0,.55,.24);seed_pod_gauge_glow_style.shadow_size=3;seed_pod_gauge_glow.add_theme_stylebox_override("panel",seed_pod_gauge_glow_style);seed_pod_gauge_meter.add_child(seed_pod_gauge_glow)
	puku_gauge_area=Control.new();puku_gauge_area.name="PukuGaugeArea";puku_gauge_area.position=Vector2(42,190);puku_gauge_area.size=Vector2(158,60);puku_gauge_area.mouse_filter=Control.MOUSE_FILTER_IGNORE;main_status_hud.add_child(puku_gauge_area)
	var puku_content:=VBoxContainer.new();puku_content.position=Vector2(13,0);puku_content.size=Vector2(132,60);puku_content.alignment=BoxContainer.ALIGNMENT_CENTER;puku_content.mouse_filter=Control.MOUSE_FILTER_IGNORE;puku_content.add_theme_constant_override("separation",2);puku_gauge_area.add_child(puku_content)
	puku_gauge_label=Label.new();puku_gauge_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;puku_gauge_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;puku_gauge_label.add_theme_font_size_override("font_size",14);puku_gauge_label.add_theme_color_override("font_color",Color("#fff8cf"));puku_gauge_label.add_theme_color_override("font_outline_color",Color("#173622"));puku_gauge_label.add_theme_constant_override("outline_size",4);puku_content.add_child(puku_gauge_label)
	puku_gauge_meter=ProgressBar.new();puku_gauge_meter.custom_minimum_size=Vector2(132,10);puku_gauge_meter.max_value=PUKU_UNITS_PER_PUKU;puku_gauge_meter.show_percentage=false;puku_gauge_meter.mouse_filter=Control.MOUSE_FILTER_IGNORE;var meter_bg:=StyleBoxFlat.new();meter_bg.bg_color=Color(.025,.09,.045,.9);meter_bg.set_corner_radius_all(5);meter_bg.border_color=Color(.16,.34,.19,.76);meter_bg.set_border_width_all(1);puku_gauge_fill_style=StyleBoxFlat.new();puku_gauge_fill_style.bg_color=Color("#1f6840");puku_gauge_fill_style.border_color=Color("#76aa78");puku_gauge_fill_style.set_border_width_all(1);puku_gauge_fill_style.set_corner_radius_all(5);puku_gauge_meter.add_theme_stylebox_override("background",meter_bg);puku_gauge_meter.add_theme_stylebox_override("fill",puku_gauge_fill_style);puku_content.add_child(puku_gauge_meter)
	puku_gauge_glow=Panel.new();puku_gauge_glow.name="PukuGaugeGlow";puku_gauge_glow.show_behind_parent=true;puku_gauge_glow.mouse_filter=Control.MOUSE_FILTER_IGNORE;puku_gauge_glow.position=Vector2(1,1);puku_gauge_glow.size=Vector2(2,8);puku_gauge_glow_style=StyleBoxFlat.new();puku_gauge_glow_style.bg_color=Color(0,0,0,0);puku_gauge_glow_style.border_color=Color(1.0,.82,.22,.0);puku_gauge_glow_style.set_border_width_all(1);puku_gauge_glow_style.set_corner_radius_all(5);puku_gauge_glow_style.shadow_color=Color(1.0,.67,.08,0.0);puku_gauge_glow_style.shadow_size=2;puku_gauge_glow.add_theme_stylebox_override("panel",puku_gauge_glow_style);puku_gauge_meter.add_child(puku_gauge_glow);call_deferred("_start_puku_gauge_glow");call_deferred("_update_puku_ui")
	puku_point_label=Label.new();puku_point_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;puku_point_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;puku_point_label.add_theme_font_size_override("font_size",14);puku_point_label.add_theme_color_override("font_color",Color("#fff7c2"));puku_point_label.add_theme_color_override("font_outline_color",Color("#193923"));puku_point_label.add_theme_constant_override("outline_size",4);puku_content.add_child(puku_point_label)
	puku_gain_label=Label.new();puku_gain_label.position=Vector2(138,246);puku_gain_label.size=Vector2(300,60);puku_gain_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;puku_gain_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;puku_gain_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;puku_gain_label.add_theme_font_size_override("font_size",27);puku_gain_label.add_theme_color_override("font_color",Color("#fff49a"));puku_gain_label.add_theme_color_override("font_outline_color",Color("#31553c"));puku_gain_label.add_theme_constant_override("outline_size",7);puku_gain_label.visible=false;effects_layer.add_child(puku_gain_label)
	puku_combo_label=Label.new();puku_combo_label.name="PukuComboLabel";puku_combo_label.position=Vector2(168,326);puku_combo_label.size=Vector2(240,104);puku_combo_label.pivot_offset=puku_combo_label.size*.5;puku_combo_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;puku_combo_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;puku_combo_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;puku_combo_label.add_theme_font_size_override("font_size",58);puku_combo_label.add_theme_color_override("font_color",Color("#fff36b"));puku_combo_label.add_theme_color_override("font_outline_color",Color("#6f3c16"));puku_combo_label.add_theme_constant_override("outline_size",10);puku_combo_label.visible=false;effects_layer.add_child(puku_combo_label)
	mission_panel=PanelContainer.new();mission_panel.name="MissionPanel";mission_panel.position=Vector2(18,276);mission_panel.size=Vector2(354,108);mission_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;mission_panel.add_theme_stylebox_override("panel",_box(Color(0.16,.09,.16,.92),Color("#e4bd62"),18,2));main_status_hud.add_child(mission_panel)
	var mission_content:=VBoxContainer.new();mission_content.alignment=BoxContainer.ALIGNMENT_CENTER;mission_content.mouse_filter=Control.MOUSE_FILTER_IGNORE;mission_content.add_theme_constant_override("separation",1);mission_panel.add_child(mission_content)
	mission_title_label=Label.new();mission_title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;mission_title_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;mission_title_label.add_theme_font_size_override("font_size",15);mission_title_label.add_theme_color_override("font_color",Color("#f6cf69"));mission_content.add_child(mission_title_label)
	mission_text_label=Label.new();mission_text_label.custom_minimum_size=Vector2(320,60);mission_text_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;mission_text_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;mission_text_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;mission_text_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;mission_text_label.add_theme_font_size_override("font_size",16);mission_text_label.add_theme_color_override("font_color",Color("#fff7dc"));mission_content.add_child(mission_text_label)
	for entry in [{"x":398,"t":"図鑑"},{"x":478,"t":"設定"}]:
		var b:=Button.new(); b.text=entry.t; b.position=Vector2(entry.x,134); b.size=Vector2(73,55); _skin_button(b,Color("#fff0cf"),16); hud.add_child(b)
		external_navigation_controls.append(b)
		if entry.t=="図鑑":encyclopedia_icon_button=b;encyclopedia_navigation_controls.append(b);b.mouse_filter=Control.MOUSE_FILTER_STOP;b.pressed.connect(_open_encyclopedia)
		else:settings_button=b;b.pressed.connect(_open_settings)
	mode_button=Button.new();mode_button.text="原生地";mode_button.position=Vector2(398,198);mode_button.size=Vector2(153,55);_skin_button(mode_button,Color("#fff0cf"),16);mode_button.mouse_filter=Control.MOUSE_FILTER_STOP;mode_button.pressed.connect(_toggle_mode);hud.add_child(mode_button)
	external_navigation_controls.append(mode_button)
	if _trial_dev_controls_enabled():
		habitat_dev_open_button=Button.new();habitat_dev_open_button.name="HabitatDevQuickOpen";habitat_dev_open_button.text="原生地テスト";habitat_dev_open_button.position=Vector2(398,262);habitat_dev_open_button.size=Vector2(153,55);_skin_button(habitat_dev_open_button,Color("#adcbb8"),15);habitat_dev_open_button.mouse_filter=Control.MOUSE_FILTER_STOP;habitat_dev_open_button.pressed.connect(_open_habitat_dev);hud.add_child(habitat_dev_open_button)
	shop_button=Button.new();shop_button.text="おみせ";shop_button.position=Vector2(398,262);shop_button.size=Vector2(153,55);_skin_button(shop_button,Color("#fff0cf"),16);shop_button.mouse_filter=Control.MOUSE_FILTER_STOP;shop_button.pressed.connect(_open_shop);hud.add_child(shop_button)
	external_navigation_controls.append(shop_button)
	forest_gacha_button=Button.new();forest_gacha_button.name="ForestGachaButton";forest_gacha_button.text="森のガチャ";forest_gacha_button.position=Vector2(398,326);forest_gacha_button.size=Vector2(153,67);_skin_button(forest_gacha_button,Color("#d9c77d"),15);forest_gacha_button.mouse_filter=Control.MOUSE_FILTER_STOP;forest_gacha_button.pressed.connect(_open_forest_gacha);hud.add_child(forest_gacha_button)
	external_navigation_controls.append(forest_gacha_button)
	fusion_lab_button=Button.new();fusion_lab_button.name="FusionLabButton";fusion_lab_button.text="ハイブリッドラボ";fusion_lab_button.position=Vector2(398,400);fusion_lab_button.size=Vector2(153,58);_skin_button(fusion_lab_button,Color("#cda4d7"),16);fusion_lab_button.mouse_filter=Control.MOUSE_FILTER_STOP;fusion_lab_button.pressed.connect(_open_fusion_lab);hud.add_child(fusion_lab_button)
	external_navigation_controls.append(fusion_lab_button)
	habitat_status_label=Label.new();habitat_status_label.position=Vector2(163,42);habitat_status_label.size=Vector2(250,56);habitat_status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;habitat_status_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;habitat_status_label.add_theme_font_size_override("font_size",18);habitat_status_label.add_theme_color_override("font_color",UI_CREAM);habitat_status_label.add_theme_stylebox_override("normal",_box(Color("#4b2d20"),Color("#d8ad68"),18,2));habitat_status_label.visible=false;hud.add_child(habitat_status_label)
	seed_bag_panel=PanelContainer.new();seed_bag_panel.position=Vector2(210,198);seed_bag_panel.size=Vector2(156,92);seed_bag_panel.add_theme_stylebox_override("panel",_box(Color("#cda66a"),Color("#6f4325"),28,3));seed_bag_panel.visible=false;hud.add_child(seed_bag_panel)
	play_timer_label=Label.new();play_timer_label.text="たね\n残り 12粒";play_timer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;play_timer_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;play_timer_label.add_theme_font_size_override("font_size",20);play_timer_label.add_theme_color_override("font_color",Color("#4f2e1d"));play_timer_label.add_theme_color_override("font_outline_color",Color("#f4dbac"));play_timer_label.add_theme_constant_override("outline_size",2);seed_bag_panel.add_child(play_timer_label)
	play_open_button=Button.new();play_open_button.text="たねをまく";play_open_button.position=Vector2(198,499);play_open_button.size=Vector2(180,58);play_open_button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;play_open_button.clip_text=true;_skin_button(play_open_button,Color("#8b5a35"),21);play_open_button.mouse_filter=Control.MOUSE_FILTER_STOP;play_open_button.pressed.connect(_open_play_modal);hud.add_child(play_open_button)
	record_card=PanelContainer.new(); record_card.position=Vector2(394,816); record_card.size=Vector2(164,134); record_card.add_theme_stylebox_override("panel",_box(Color("#674135"),Color("#f4d36e"),18,3)); record_card.visible=false; hud.add_child(record_card)
	record_text=Label.new(); record_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; record_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; record_text.add_theme_font_size_override("font_size",19); record_text.add_theme_color_override("font_color",Color.WHITE); record_card.add_child(record_text)
	_build_encyclopedia(hud)
	_build_play_overlay(hud)
	_build_shop(hud)
	_build_arrangement_ui(hud)
	_build_arrangement_navigation_hint(hud)
	_build_result_overlay(hud)
	_build_settings(hud)
	_build_research_catalog_reward(hud)
	_build_forest_gacha_ui(hud)
	_build_species_get_overlay(hud)
	_build_catalog_series_unlock_overlay(hud)
	_build_fusion_lab_ui(hud)
	if DEVELOPMENT_CATALOG_PREVIEW_ENABLED and _trial_dev_controls_enabled():_build_catalog_preview_dev(hud)
	if _trial_dev_controls_enabled():_build_jelly_dev_overlay(hud)
	_build_intro_story(hud)
	_build_tutorial_guide(hud)
	_build_opening_screen(hud)
	_build_opening_story(hud)
	_build_habitat_awakening(hud)
	_build_seed_pod_story(hud)
	_build_habitat_second_awakening(hud)
	_build_habitat_crisis_atmosphere(hud)
	_build_habitat_restoration_ui(hud)
	_build_habitat_plant_panel(hud)
	_build_jurejure_first_encounter(hud)
	_build_puku_puku_battle(hud)
	_build_scene_transition_fade(hud)
	_build_collection_complete_overlay(hud)
	if _trial_dev_controls_enabled():
		_build_habitat_dev_panel(hud)
	if _trial_dev_controls_enabled():
		_build_story_dev_panel(hud)
	_update_best_ui()
	_update_puku_ui()
	_apply_language_to_ui()
	_update_play_ui()

func _build_opening_screen(hud:Control)->void:
	opening_overlay=Control.new();opening_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);opening_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;hud.add_child(opening_overlay)
	var background:=TextureRect.new();background.texture=load("res://assets/opening-background.jpg");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;background.mouse_filter=Control.MOUSE_FILTER_IGNORE;opening_overlay.add_child(background)
	opening_prompt=TextureRect.new();opening_prompt.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;opening_prompt.texture=load("res://assets/opening-tap.png");opening_prompt.position=Vector2(86,820);opening_prompt.size=Vector2(404,136);opening_prompt.pivot_offset=opening_prompt.size*.5;opening_prompt.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;opening_prompt.mouse_filter=Control.MOUSE_FILTER_IGNORE;opening_overlay.add_child(opening_prompt)
	opening_prompt_localized=PanelContainer.new();opening_prompt_localized.position=Vector2(86,834);opening_prompt_localized.size=Vector2(404,108);opening_prompt_localized.pivot_offset=opening_prompt_localized.size*.5;opening_prompt_localized.mouse_filter=Control.MOUSE_FILTER_IGNORE;opening_prompt_localized.add_theme_stylebox_override("panel",_box(Color("#b86e2d"),Color("#ffe18a"),38,5));opening_overlay.add_child(opening_prompt_localized)
	opening_prompt_localized_label=Label.new();opening_prompt_localized_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;opening_prompt_localized_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;opening_prompt_localized_label.add_theme_font_size_override("font_size",30);opening_prompt_localized_label.add_theme_color_override("font_color",Color("#fff8df"));opening_prompt_localized_label.add_theme_color_override("font_outline_color",Color("#63331c"));opening_prompt_localized_label.add_theme_constant_override("outline_size",7);opening_prompt_localized_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;opening_prompt_localized.add_child(opening_prompt_localized_label)
	opening_tap_area=Button.new();opening_tap_area.flat=true;opening_tap_area.focus_mode=Control.FOCUS_NONE;opening_tap_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);opening_tap_area.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;opening_tap_area.pressed.connect(_finish_opening);opening_overlay.add_child(opening_tap_area)
	opening_language_panel=PanelContainer.new();opening_language_panel.name="InitialLanguagePanel";opening_language_panel.position=Vector2(68,610);opening_language_panel.size=Vector2(440,340);opening_language_panel.add_theme_stylebox_override("panel",_box(Color(0.16,0.085,0.045,.96),Color("#f1c36f"),28,4));opening_overlay.add_child(opening_language_panel)
	var language_content:=VBoxContainer.new();language_content.alignment=BoxContainer.ALIGNMENT_CENTER;language_content.add_theme_constant_override("separation",12);opening_language_panel.add_child(language_content)
	var language_title:=Label.new();language_title.text="ことばを えらんでください\nChoose your language";language_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;language_title.add_theme_font_size_override("font_size",22);language_title.add_theme_color_override("font_color",Color("#fff4d8"));language_content.add_child(language_title)
	for language_entry in [{"code":"ja","label":"日本語"},{"code":"en","label":"英語"},{"code":"hiragana","label":"ひらがな"}]:
		var language_button:=Button.new();language_button.text=str(language_entry.label);language_button.custom_minimum_size=Vector2(330,64);_skin_button(language_button,Color("#f0d29b"),20);language_button.pressed.connect(_select_initial_language.bind(str(language_entry.code)));language_content.add_child(language_button)
	_show_opening()

func _show_opening()->void:
	opening_finished=false;opening_overlay.visible=true;_refresh_opening_prompt();opening_prompt.scale=Vector2.ONE;opening_prompt_localized.scale=Vector2.ONE
	opening_language_panel.visible=not language_selected
	opening_tap_area.disabled=not language_selected
	opening_tap_area.mouse_filter=Control.MOUSE_FILTER_IGNORE if not language_selected else Control.MOUSE_FILTER_STOP
	if opening_prompt_tween and opening_prompt_tween.is_valid():opening_prompt_tween.kill()
	if not language_selected:
		if audio_manager:audio_manager.play_bgm("opening")
		return
	_start_opening_prompt_pulse()
	if audio_manager:audio_manager.play_bgm("opening")

func _start_opening_prompt_pulse()->void:
	if opening_prompt_tween and opening_prompt_tween.is_valid():opening_prompt_tween.kill()
	var prompt_control:Control=opening_prompt if opening_prompt.visible else opening_prompt_localized
	opening_prompt_tween=create_tween().set_loops();opening_prompt_tween.tween_property(prompt_control,"scale",Vector2(1.035,1.035),1.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT);opening_prompt_tween.tween_property(prompt_control,"scale",Vector2.ONE,1.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _select_initial_language(value:String)->void:
	language_code=Localizer.normalize_language(value);language_selected=true
	_save();_apply_language_to_ui()
	opening_language_panel.visible=false;opening_tap_area.disabled=false;opening_tap_area.mouse_filter=Control.MOUSE_FILTER_STOP
	_refresh_opening_prompt();_start_opening_prompt_pulse()

func _refresh_opening_prompt()->void:
	if opening_prompt==null or opening_prompt_localized==null:return
	if not language_selected:
		opening_prompt.visible=false;opening_prompt_localized.visible=false
		return
	var use_art_prompt:=language_code=="ja"
	opening_prompt.visible=use_art_prompt;opening_prompt_localized.visible=not use_art_prompt
	if opening_prompt_localized_label:opening_prompt_localized_label.text=Localizer.text(language_code,"opening_tap")

func _finish_opening()->void:
	if opening_finished or not language_selected:return
	opening_finished=true
	if audio_manager:audio_manager.notify_user_gesture()
	if opening_prompt_tween:opening_prompt_tween.kill()
	opening_overlay.visible=false
	_continue_after_opening()

func _build_opening_story(hud:Control)->void:
	opening_story_overlay=OpeningStoryOverlayClass.new()
	hud.add_child(opening_story_overlay)
	opening_story_overlay.story_finished.connect(_on_opening_story_finished)

func _build_habitat_awakening(hud:Control)->void:
	habitat_awakening_overlay=HabitatAwakeningOverlayClass.new()
	hud.add_child(habitat_awakening_overlay)
	habitat_awakening_overlay.awakening_finished.connect(_on_habitat_awakening_finished)
	habitat_awakening_overlay.lookaround_requested.connect(_start_habitat_lookaround)

func _build_seed_pod_story(hud:Control)->void:
	seed_pod_story_overlay=SeedPodStoryOverlayClass.new()
	hud.add_child(seed_pod_story_overlay)
	seed_pod_story_overlay.story_finished.connect(_on_seed_pod_story_finished)

func _build_habitat_second_awakening(hud:Control)->void:
	habitat_second_awakening_overlay=HabitatSecondAwakeningOverlayClass.new()
	hud.add_child(habitat_second_awakening_overlay)
	habitat_second_awakening_overlay.awakening_finished.connect(_on_habitat_second_awakening_finished)

func _build_habitat_crisis_atmosphere(hud:Control)->void:
	habitat_crisis_atmosphere=HabitatCrisisAtmosphereClass.new()
	hud.add_child(habitat_crisis_atmosphere)
	if habitat_crisis_started:habitat_crisis_atmosphere.activate()
	habitat_crisis_atmosphere.set_restoration_stage(_restoration_stage())

func _build_habitat_restoration_ui(hud:Control)->void:
	habitat_restoration_ui=HabitatRestorationUIClass.new()
	hud.add_child(habitat_restoration_ui)
	habitat_restoration_ui.set_language(language_code)
	habitat_restoration_ui.return_decided.connect(_on_restoration_return_decided)
	habitat_restoration_ui.slides_finished.connect(_on_restoration_slides_finished)
	habitat_restoration_ui.ending_bgm_requested.connect(_on_restoration_ending_bgm_requested)
	habitat_restoration_ui.thank_you_closed.connect(_on_restoration_thank_you_closed)

func _build_jurejure_first_encounter(hud:Control)->void:
	jurejure_first_encounter_overlay=JureJureFirstEncounterOverlayClass.new()
	hud.add_child(jurejure_first_encounter_overlay)
	jurejure_first_encounter_overlay.story_finished.connect(_on_jurejure_first_encounter_still_finished)

func _build_puku_puku_battle(hud:Control)->void:
	puku_puku_battle=PukuPukuBattleClass.new()
	hud.add_child(puku_puku_battle)
	puku_puku_battle.battle_requested.connect(_start_puku_puku_battle)
	puku_puku_battle.battle_declined.connect(_on_jurejure_battle_declined)
	puku_puku_battle.battle_resolved.connect(_on_puku_puku_battle_resolved)
	puku_puku_battle.return_requested.connect(_on_puku_puku_battle_return_requested)

func _build_scene_transition_fade(hud:Control)->void:
	scene_transition_fade=ColorRect.new();scene_transition_fade.name="SceneTransitionFade";scene_transition_fade.color=Color.BLACK;scene_transition_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);scene_transition_fade.mouse_filter=Control.MOUSE_FILTER_STOP;scene_transition_fade.z_index=980;scene_transition_fade.visible=false;hud.add_child(scene_transition_fade)

func _build_collection_complete_overlay(hud:Control)->void:
	collection_complete_overlay=Control.new();collection_complete_overlay.name="CollectionCompleteOverlay";collection_complete_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);collection_complete_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;collection_complete_overlay.z_index=970;collection_complete_overlay.visible=false;hud.add_child(collection_complete_overlay)
	collection_complete_effect_layer=Control.new();collection_complete_effect_layer.name="CollectionCompleteEffects";collection_complete_effect_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);collection_complete_effect_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;collection_complete_overlay.add_child(collection_complete_effect_layer)
	collection_complete_card=PanelContainer.new();collection_complete_card.name="CollectionCompleteCard";collection_complete_card.position=Vector2(38,244);collection_complete_card.size=Vector2(500,452);collection_complete_card.pivot_offset=collection_complete_card.size*.5;collection_complete_card.add_theme_stylebox_override("panel",_box(Color(.13,.07,.075,.97),Color("#f1c45f"),30,4));collection_complete_card.visible=false;collection_complete_overlay.add_child(collection_complete_card)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",13);content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);content.offset_left=28;content.offset_top=24;content.offset_right=-28;content.offset_bottom=-24;collection_complete_card.add_child(content)
	collection_complete_title_label=Label.new();collection_complete_title_label.custom_minimum_size=Vector2(430,66);collection_complete_title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;collection_complete_title_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;collection_complete_title_label.add_theme_font_size_override("font_size",31);collection_complete_title_label.add_theme_color_override("font_color",Color("#fff19a"));collection_complete_title_label.add_theme_color_override("font_outline_color",Color("#6f3021"));collection_complete_title_label.add_theme_constant_override("outline_size",7);content.add_child(collection_complete_title_label)
	collection_complete_message_label=Label.new();collection_complete_message_label.custom_minimum_size=Vector2(430,112);collection_complete_message_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;collection_complete_message_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;collection_complete_message_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;collection_complete_message_label.add_theme_font_size_override("font_size",23);collection_complete_message_label.add_theme_color_override("font_color",Color("#fff5dc"));content.add_child(collection_complete_message_label)
	var divider:=HSeparator.new();divider.custom_minimum_size=Vector2(390,8);content.add_child(divider)
	collection_complete_version_label=Label.new();collection_complete_version_label.custom_minimum_size=Vector2(430,68);collection_complete_version_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;collection_complete_version_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;collection_complete_version_label.add_theme_font_size_override("font_size",17);collection_complete_version_label.add_theme_color_override("font_color",Color("#efc86e"));content.add_child(collection_complete_version_label)
	collection_complete_continue_button=Button.new();collection_complete_continue_button.name="CollectionCompleteContinue";collection_complete_continue_button.custom_minimum_size=Vector2(330,56);_skin_button(collection_complete_continue_button,Color("#f2d58a"),18);collection_complete_continue_button.pressed.connect(_on_collection_complete_card_closed);content.add_child(collection_complete_continue_button)

func _start_opening_story(as_replay:=false,start_page:=0)->void:
	if opening_story_overlay==null:return
	if opening_overlay:opening_overlay.visible=false
	if settings_overlay:settings_overlay.visible=false
	if audio_manager:audio_manager.stop_bgm()
	opening_story_overlay.start(as_replay,start_page,language_code)
	_update_play_ui()

func _on_opening_story_finished(as_replay:bool)->void:
	if as_replay:
		_play_current_area_bgm()
		_update_play_ui()
		return
	opening_story_complete=true
	_save()
	_continue_after_opening()

func _replay_opening_story_for_development()->void:
	if not _trial_dev_controls_enabled():return
	_start_opening_story(true)

func _open_opening_story_preview()->void:
	if not _trial_dev_controls_enabled():return
	if opening_overlay:opening_overlay.visible=false
	if intro_overlay:intro_overlay.visible=false
	if shop_overlay:shop_overlay.visible=false
	if play_overlay:play_overlay.visible=false
	_start_opening_story(true)

func _open_seed_pod_story_preview()->void:
	if not _trial_dev_controls_enabled():return
	if opening_overlay:opening_overlay.visible=false
	if intro_overlay:intro_overlay.visible=false
	if shop_overlay:shop_overlay.visible=false
	if play_overlay:play_overlay.visible=false
	current_mode="habitat";_apply_mode()
	seed_pod_story_overlay.start(language_code)
	_update_play_ui()

func _build_play_overlay(hud:Control)->void:
	play_overlay=Control.new();play_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);play_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(play_overlay)
	var shade:=ColorRect.new();shade.color=Color(0.12,0.07,0.04,.42);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;play_overlay.add_child(shade)
	var panel:=PanelContainer.new();panel.position=Vector2(68,205);panel.size=Vector2(440,590);panel.mouse_filter=Control.MOUSE_FILTER_STOP;panel.add_theme_stylebox_override("panel",_box(Color("#f7e8c7"),Color("#9b642f"),26,4));play_overlay.add_child(panel)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",13);panel.add_child(content)
	var title:=Label.new();title.name="PlayChooseTitle";title.text="どのたねをまく？";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",24);title.add_theme_color_override("font_color",UI_BROWN);content.add_child(title)
	play_bag_summary=Label.new();play_bag_summary.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;play_bag_summary.add_theme_font_size_override("font_size",18);play_bag_summary.add_theme_color_override("font_color",Color("#70472d"));content.add_child(play_bag_summary)
	old_seed_play_button=Button.new();old_seed_play_button.custom_minimum_size=Vector2(350,68);_skin_button(old_seed_play_button,Color("#bba67d"),19);old_seed_play_button.pressed.connect(_start_greenhouse_play.bind("old"));content.add_child(old_seed_play_button)
	normal_play_button=Button.new();normal_play_button.custom_minimum_size=Vector2(350,76);_skin_button(normal_play_button,Color("#d9b56a"),20);normal_play_button.pressed.connect(_start_greenhouse_play.bind("normal"));content.add_child(normal_play_button)
	volume_play_button=Button.new();volume_play_button.custom_minimum_size=Vector2(350,68);_skin_button(volume_play_button,Color("#c99d57"),18);volume_play_button.pressed.connect(_start_greenhouse_play.bind("volume"));content.add_child(volume_play_button)
	premium_play_button=Button.new();premium_play_button.custom_minimum_size=Vector2(350,76);_skin_button(premium_play_button,Color("#d18a55"),20);premium_play_button.pressed.connect(_start_greenhouse_play.bind("premium"));content.add_child(premium_play_button)
	mystery_play_button=Button.new();mystery_play_button.custom_minimum_size=Vector2(350,68);_skin_button(mystery_play_button,Color("#8d755f"),18);mystery_play_button.pressed.connect(_start_greenhouse_play.bind("mystery"));content.add_child(mystery_play_button)
	var close:=Button.new();close.name="PlayCloseButton";close.text="閉じる";close.custom_minimum_size=Vector2(250,44);_skin_button(close,Color("#ead8b1"),16);close.pressed.connect(_close_play_modal);content.add_child(close)

func _build_shop(hud:Control)->void:
	shop_overlay=Control.new();shop_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shop_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;shop_overlay.visible=false;hud.add_child(shop_overlay)
	var shop_texture:=load("res://assets/shop-background-final.jpg") as Texture2D
	shop_background=TextureRect.new();shop_background.texture=shop_texture;shop_background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;shop_background.stretch_mode=TextureRect.STRETCH_SCALE;shop_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shop_background.mouse_filter=Control.MOUSE_FILTER_STOP;shop_background.gui_input.connect(_on_shop_background_gui_input);shop_overlay.add_child(shop_background)
	var panda_tap:=Button.new();panda_tap.position=Vector2(190,405);panda_tap.size=Vector2(196,315);panda_tap.flat=true;panda_tap.focus_mode=Control.FOCUS_NONE;panda_tap.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;panda_tap.pressed.connect(_on_shop_panda_tapped);shop_overlay.add_child(panda_tap)
	armadillo_tap_button=Button.new();armadillo_tap_button.position=Vector2(45,595);armadillo_tap_button.size=Vector2(170,235);armadillo_tap_button.flat=true;armadillo_tap_button.focus_mode=Control.FOCUS_NONE;armadillo_tap_button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;armadillo_tap_button.pressed.connect(_on_armadillo_tapped);armadillo_tap_button.visible=false;shop_overlay.add_child(armadillo_tap_button)
	var close:=Button.new();close.name="ShopCloseButton";close.text="もどる";close.position=Vector2(446,24);close.size=Vector2(106,55);_skin_button(close,Color("#fff0cf"),17);close.pressed.connect(_close_shop);shop_overlay.add_child(close)
	var purchase_panel:=PanelContainer.new();purchase_panel.position=Vector2(28,802);purchase_panel.size=Vector2(520,198);purchase_panel.add_theme_stylebox_override("panel",_box(Color(0.22,0.12,0.07,.94),Color("#d7aa64"),20,3));shop_overlay.add_child(purchase_panel)
	shop_wallet_label=Label.new();shop_wallet_label.position=Vector2(50,806);shop_wallet_label.size=Vector2(476,25);shop_wallet_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop_wallet_label.add_theme_font_size_override("font_size",18);shop_wallet_label.add_theme_color_override("font_color",Color("#ffd778"));shop_overlay.add_child(shop_wallet_label)
	shop_bag_label=Label.new();shop_bag_label.position=Vector2(50,830);shop_bag_label.size=Vector2(476,21);shop_bag_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop_bag_label.add_theme_font_size_override("font_size",14);shop_bag_label.add_theme_color_override("font_color",UI_CREAM);shop_overlay.add_child(shop_bag_label)
	var tab_names:={"normal":"shop_tab_normal","volume":"shop_tab_volume","premium":"shop_tab_premium","mystery":"shop_tab_mystery"};var tab_colors:={"normal":Color("#d8b56b"),"volume":Color("#c99d57"),"premium":Color("#d18a55"),"mystery":Color("#8d755f")}
	var tab_index:=0
	for seed_type in ["normal","volume","premium","mystery"]:
		var tab:=Button.new();tab.text=Localizer.text(language_code,str(tab_names[seed_type]));tab.position=Vector2(43+tab_index*123,854);tab.size=Vector2(117,34);_skin_button(tab,tab_colors[seed_type],13);tab.pressed.connect(_select_shop_product.bind(seed_type));shop_overlay.add_child(tab);shop_product_tabs[seed_type]=tab;tab_index+=1
	shop_volume_buy_button=shop_product_tabs["volume"];shop_premium_buy_button=shop_product_tabs["premium"];shop_mystery_buy_button=shop_product_tabs["mystery"]
	shop_product_detail_label=Label.new();shop_product_detail_label.position=Vector2(49,892);shop_product_detail_label.size=Vector2(330,94);shop_product_detail_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;shop_product_detail_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;shop_product_detail_label.add_theme_font_size_override("font_size",15);shop_product_detail_label.add_theme_color_override("font_color",UI_CREAM);shop_overlay.add_child(shop_product_detail_label)
	shop_selected_buy_button=Button.new();shop_selected_buy_button.position=Vector2(391,914);shop_selected_buy_button.size=Vector2(137,55);_skin_button(shop_selected_buy_button,Color("#d8b56b"),16);shop_selected_buy_button.pressed.disconnect(_play_ui_tap);shop_selected_buy_button.pressed.connect(_buy_selected_shop_product);shop_overlay.add_child(shop_selected_buy_button)
	shop_buy_glow=Panel.new();shop_buy_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shop_buy_glow.offset_left=-8;shop_buy_glow.offset_top=-8;shop_buy_glow.offset_right=8;shop_buy_glow.offset_bottom=8;shop_buy_glow.mouse_filter=Control.MOUSE_FILTER_IGNORE;shop_buy_glow.show_behind_parent=true
	var glow_style:=StyleBoxFlat.new();glow_style.bg_color=Color(1.0,.80,.35,.05);glow_style.border_color=Color(1.0,.84,.48,.42);glow_style.set_border_width_all(2);glow_style.set_corner_radius_all(23);glow_style.shadow_color=Color(1.0,.72,.25,.72);glow_style.shadow_size=12;glow_style.shadow_offset=Vector2.ZERO;shop_buy_glow.add_theme_stylebox_override("panel",glow_style);shop_buy_glow.visible=false;shop_selected_buy_button.add_child(shop_buy_glow)
	shop_message=Label.new();shop_message.position=Vector2(48,775);shop_message.size=Vector2(480,25);shop_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop_message.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;shop_message.add_theme_font_size_override("font_size",14);shop_message.add_theme_color_override("font_color",UI_CREAM);shop_overlay.add_child(shop_message)
	shop_category_back_button=Button.new();shop_category_back_button.text=Localizer.text(language_code,"shop_category_short");shop_category_back_button.position=Vector2(28,735);shop_category_back_button.size=Vector2(154,48);_skin_button(shop_category_back_button,Color("#fff0cf"),15);shop_category_back_button.pressed.connect(_show_shop_categories);shop_overlay.add_child(shop_category_back_button)
	shop_purchase_controls=[purchase_panel,shop_wallet_label,shop_bag_label,shop_product_detail_label,shop_selected_buy_button,shop_message,shop_category_back_button]
	for tab in shop_product_tabs.values():shop_purchase_controls.append(tab)
	var category_panel:=PanelContainer.new();category_panel.position=Vector2(28,735);category_panel.size=Vector2(520,265);category_panel.add_theme_stylebox_override("panel",_box(Color(0.22,0.12,0.07,.94),Color("#d7aa64"),20,3));shop_overlay.add_child(category_panel)
	var category_content:=Control.new();category_content.custom_minimum_size=Vector2(500,245);category_panel.add_child(category_content)
	var category_title:=Label.new();category_title.name="ShopCategoryTitle";category_title.text="なにを見ますか？";category_title.position=Vector2(10,8);category_title.size=Vector2(480,42);category_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;category_title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;category_title.add_theme_font_size_override("font_size",22);category_title.add_theme_color_override("font_color",UI_CREAM);category_content.add_child(category_title)
	shop_pot_button=Button.new();shop_pot_button.name="ShopCategoryPot";shop_pot_button.text="鉢\n寄せ植え";shop_pot_button.position=Vector2(82,58);shop_pot_button.size=Vector2(160,160);_skin_button(shop_pot_button,Color("#c99d72"),16);shop_pot_button.pressed.connect(_open_shop_pot_category);category_content.add_child(shop_pot_button)
	shop_forest_gacha_button=Button.new();shop_forest_gacha_button.name="ShopForestGachaButton";shop_forest_gacha_button.text="森の\nガチャ";shop_forest_gacha_button.position=Vector2(258,58);shop_forest_gacha_button.size=Vector2(160,160);_skin_button(shop_forest_gacha_button,Color("#9eb06c"),16);shop_forest_gacha_button.pressed.connect(_open_forest_gacha);category_content.add_child(shop_forest_gacha_button)
	shop_category_controls=[category_panel]
	shop_catalog_controls=[]
	shop_chatter_bubble=PanelContainer.new();shop_chatter_bubble.position=Vector2(88,276);shop_chatter_bubble.size=Vector2(400,108);shop_chatter_bubble.mouse_filter=Control.MOUSE_FILTER_STOP;shop_chatter_bubble.gui_input.connect(_on_shop_chatter_gui_input);shop_chatter_bubble.add_theme_stylebox_override("panel",_box(Color(1.0,.95,.82,.97),Color("#9b6739"),24,3));shop_chatter_bubble.visible=false;shop_overlay.add_child(shop_chatter_bubble)
	var chatter_content:=VBoxContainer.new();chatter_content.alignment=BoxContainer.ALIGNMENT_CENTER;chatter_content.add_theme_constant_override("separation",9);chatter_content.mouse_filter=Control.MOUSE_FILTER_PASS;shop_chatter_bubble.add_child(chatter_content)
	var chatter_row:=HBoxContainer.new();chatter_row.alignment=BoxContainer.ALIGNMENT_CENTER;chatter_row.add_theme_constant_override("separation",10);chatter_row.mouse_filter=Control.MOUSE_FILTER_PASS;chatter_content.add_child(chatter_row)
	shop_chatter_portrait=TextureRect.new();shop_chatter_portrait.custom_minimum_size=Vector2(78,78);shop_chatter_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;shop_chatter_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;shop_chatter_portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE;chatter_row.add_child(shop_chatter_portrait)
	shop_chatter_label=Label.new();shop_chatter_label.custom_minimum_size=Vector2(170,64);shop_chatter_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;shop_chatter_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop_chatter_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;shop_chatter_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;shop_chatter_label.add_theme_font_size_override("font_size",18);shop_chatter_label.add_theme_color_override("font_color",UI_BROWN);shop_chatter_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;chatter_row.add_child(shop_chatter_label)
	var chatter_actions:=HBoxContainer.new();chatter_actions.alignment=BoxContainer.ALIGNMENT_CENTER;chatter_actions.add_theme_constant_override("separation",12);chatter_content.add_child(chatter_actions)
	shop_chatter_action_button=Button.new();shop_chatter_action_button.text=Localizer.text(language_code,"ad_seed");shop_chatter_action_button.custom_minimum_size=Vector2(250,48);_skin_button(shop_chatter_action_button,Color("#d8b56b"),17);shop_chatter_action_button.pressed.connect(_on_shop_chatter_action);shop_chatter_action_button.visible=false;chatter_actions.add_child(shop_chatter_action_button)
	shop_chatter_decline_button=Button.new();shop_chatter_decline_button.text=Localizer.text(language_code,"no");shop_chatter_decline_button.custom_minimum_size=Vector2(130,48);_skin_button(shop_chatter_decline_button,Color("#ead8b1"),17);shop_chatter_decline_button.pressed.connect(_decline_armadillo_research);shop_chatter_decline_button.visible=false;chatter_actions.add_child(shop_chatter_decline_button)
	shop_transfer_notice=Label.new();shop_transfer_notice.custom_minimum_size=Vector2(300,42);shop_transfer_notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop_transfer_notice.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;shop_transfer_notice.add_theme_font_size_override("font_size",19);shop_transfer_notice.add_theme_color_override("font_color",Color("#6a3d20"));shop_transfer_notice.add_theme_stylebox_override("normal",_box(Color(0.96,0.84,0.60,.92),Color("#c58b48"),12,1));shop_transfer_notice.mouse_filter=Control.MOUSE_FILTER_IGNORE;shop_transfer_notice.visible=false;chatter_content.add_child(shop_transfer_notice)

func _set_shop_purchase_visible(is_visible:bool)->void:
	shop_purchase_ui_enabled=is_visible
	_refresh_shop_page_visibility()

func _refresh_shop_page_visibility()->void:
	for control in shop_purchase_controls+shop_category_controls+shop_catalog_controls:
		if is_instance_valid(control):control.visible=false
	if not shop_purchase_ui_enabled:return
	var visible_controls:Array[Control]=shop_category_controls
	if shop_current_page=="seeds":visible_controls=shop_purchase_controls
	elif shop_current_page=="catalog":visible_controls=shop_catalog_controls
	for control in visible_controls:
		if is_instance_valid(control):control.visible=true

func _show_shop_categories()->void:
	shop_current_page="categories";_refresh_shop_page_visibility()

func _open_shop_seed_category()->void:
	shop_current_page="categories";_refresh_shop_page_visibility();_hide_shop_chatter(true);_sync_arrangement_ui();arrangement_ui.open_seed_shop()

func _open_shop_pot_category()->void:
	shop_current_page="categories";_refresh_shop_page_visibility();_open_pot_shop()

func _open_shop_catalog_category()->void:
	return

func _build_arrangement_ui(hud:Control)->void:
	arrangement_ui=ArrangementUIClass.new();hud.add_child(arrangement_ui)
	arrangement_ui.close_requested.connect(_on_arrangement_close_requested)
	arrangement_ui.save_requested.connect(_on_arrangement_save_requested)
	arrangement_ui.share_background_save_requested.connect(_on_arrangement_share_background_save_requested)
	arrangement_ui.share_requested.connect(_on_arrangement_share_requested)
	arrangement_ui.dismantle_requested.connect(_on_arrangement_dismantle_requested)
	arrangement_ui.pot_purchase_requested.connect(_on_pot_purchase_requested)
	arrangement_ui.pot_unlock_requested.connect(_on_pot_unlock_requested)
	arrangement_ui.pot_restore_requested.connect(_on_pot_restore_requested)
	arrangement_ui.catalog_purchase_requested.connect(_on_catalog_purchase_requested)
	arrangement_ui.seed_purchase_requested.connect(_buy_seed_bag)
	arrangement_ui.world_scroll_input.connect(_on_arrangement_world_scroll_input)
	arrangement_ui.completion_confetti_requested.connect(_on_arrangement_completion_confetti_requested)
	_sync_arrangement_ui()

func _build_arrangement_navigation_hint(hud:Control)->void:
	arrangement_navigation_hint=ArrangementNavigationHintClass.new()
	hud.add_child(arrangement_navigation_hint)
	arrangement_navigation_hint.intro_finished.connect(_on_arrangement_swipe_intro_finished)

func _sync_arrangement_ui()->void:
	if arrangement_ui==null:return
	var iap_states:Dictionary=pot_unlock_iap_service.product_states_snapshot() if pot_unlock_iap_service!=null else {}
	var restore_available:bool=pot_unlock_iap_service.restore_available() if pot_unlock_iap_service!=null else false
	var restore_in_progress:bool=pot_unlock_iap_service.restore_in_progress() if pot_unlock_iap_service!=null else false
	arrangement_ui.configure(catalog_species,[],pot_catalog,discovered,owned_pots,saved_arrangements,arrangement_save_capacity,puku_points,_species_texture,_request_species_texture,bests,language_code,_current_pot_sales_stage(),pot_design_unlocks,iap_states,restore_available,restore_in_progress,ArrangementShareBackgroundsClass.catalog(),_share_background_unlock_states(),species_picker_series_catalog)
	arrangement_ui.sync_catalog_state(unlocked_series,puku_points)
	arrangement_ui.sync_seed_shop_state(_seed_shop_products(),puku_points)

func _seed_shop_products()->Array:
	# Normal seeds come from the pod gauge, and the retired Panda Beacon is no
	# longer a shop product. Pots and gachas keep their existing shop routes.
	return []

func _open_arrangements()->void:
	if not StoryProgressionClass.arrangement_is_unlocked(story_progression_state) or not _tutorial_fully_complete() or current_mode!="greenhouse" or play_active or catalog_preview_mode_active or arrangement_scene_active or arrangement_transitioning:return
	play_modal_open=false;pointer_down=false;greenhouse_drag_accumulator=0.0;greenhouse_drag_started=false;_cancel_greenhouse_area_drag()
	saved_greenhouse_pan_x=greenhouse_pan_x;greenhouse_pan_target_x=greenhouse_pan_x
	_sync_arrangement_ui();arrangement_ui.set_world_backdrop_mode(true,_arrangement_pot_anchor_screen());arrangement_ui.visible=false
	_snap_greenhouse_area(true)

func _play_arrangement_swipe_intro()->void:
	if arrangement_navigation_hint==null or current_mode!="greenhouse":
		call_deferred("_try_start_pending_story_event")
		return
	arrangement_navigation_hint.play_intro(language_code,_arrangement_focus_transition_for_pan(saved_greenhouse_pan_x))
	_update_play_ui()

func _on_arrangement_swipe_intro_finished()->void:
	_update_play_ui()
	call_deferred("_try_start_pending_story_event")

func _open_pot_shop()->void:
	if not _tutorial_fully_complete():return
	_hide_shop_chatter(true);_sync_arrangement_ui();arrangement_ui.open_pot_shop()

func _on_arrangement_close_requested(context:String)->void:
	if context=="greenhouse" and arrangement_scene_active:
		if arrangement_transitioning:return
		_snap_greenhouse_area(false)
		return
	_update_play_ui()

func _start_arrangement_transition(target_x:float,finished:Callable)->void:
	if arrangement_transition_tween and arrangement_transition_tween.is_valid():arrangement_transition_tween.kill()
	arrangement_transition_tween=create_tween()
	var distance_ratio:=absf(target_x-arrangement_transition_x)/maxf(absf(_arrangement_focus_transition_for_pan(saved_greenhouse_pan_x)),1.0)
	var duration:=clampf(ARRANGEMENT_TRANSITION_SECONDS*distance_ratio,0.12,ARRANGEMENT_TRANSITION_SECONDS)
	arrangement_transition_tween.tween_method(_set_arrangement_transition_x,arrangement_transition_x,target_x,duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	arrangement_transition_tween.tween_callback(finished)

func _snap_greenhouse_area(to_arrangement:bool)->void:
	_cancel_greenhouse_area_drag(false)
	arrangement_transitioning=true
	if arrangement_ui:arrangement_ui.visible=false
	arrangement_transition_target_x=_arrangement_focus_transition_for_pan(saved_greenhouse_pan_x) if to_arrangement else 0.0
	_update_play_ui()
	_start_arrangement_transition(arrangement_transition_target_x,_finish_arrangement_entry if to_arrangement else _finish_arrangement_return)

func _set_arrangement_transition_x(value:float)->void:
	arrangement_transition_x=value
	_update_greenhouse_pan()

func _finish_arrangement_entry()->void:
	arrangement_transition_x=arrangement_transition_target_x;arrangement_transitioning=false;arrangement_scene_active=true
	_update_greenhouse_pan();arrangement_ui.set_world_backdrop_mode(true,_arrangement_pot_anchor_screen());arrangement_ui.open_home();_update_play_ui()

func _finish_arrangement_return()->void:
	arrangement_transition_x=0.0;arrangement_transition_target_x=0.0
	greenhouse_pan_x=clampf(saved_greenhouse_pan_x,-greenhouse_pan_limit,greenhouse_pan_limit);greenhouse_pan_target_x=greenhouse_pan_x
	arrangement_transitioning=false;arrangement_scene_active=false
	arrangement_ui.set_world_backdrop_mode(false,_arrangement_pot_anchor_screen());_update_greenhouse_pan();_update_play_ui()

func _on_arrangement_save_requested(arrangement:Dictionary)->void:
	arrangement_ui.set_save_request_result(false)
	var requested_pot_id:=str(arrangement.get("pot_id",DEFAULT_POT_ID))
	var requested_pot:=_pot_entry(requested_pot_id)
	if requested_pot.is_empty():
		arrangement_ui.set_save_request_result(false,Localizer.text(language_code,"pot_missing"))
		return
	if not _pot_unlocked(requested_pot):
		arrangement_ui.set_save_request_result(false,Localizer.text(language_code,"pot_unlock_required"))
		return
	var normalized:=_normalize_arrangement(arrangement)
	if normalized.is_empty():return
	var arrangement_id:=str(normalized.get("arrangement_id",""));var existing_index:=-1
	for index in range(saved_arrangements.size()):
		if saved_arrangements[index] is Dictionary and str(saved_arrangements[index].get("arrangement_id",""))==arrangement_id:existing_index=index;break
	if _pot_available_count_for_arrangement(requested_pot_id,arrangement_id)<=0:
		arrangement_ui.set_save_request_result(false,Localizer.text(language_code,"pot_save_unavailable"))
		return
	if existing_index>=0:saved_arrangements[existing_index]=normalized
	elif saved_arrangements.size()<arrangement_save_capacity:saved_arrangements.append(normalized)
	else:
		arrangement_ui.set_save_request_result(false,Localizer.text(language_code,"arrangement_capacity_full"))
		return
	_save();arrangement_ui.sync_state(owned_pots,saved_arrangements,arrangement_save_capacity);arrangement_ui.set_save_request_result(true)

func _on_arrangement_dismantle_requested(arrangement_id:String)->void:
	arrangement_ui.set_dismantle_request_result(false)
	if arrangement_id.is_empty():return
	for index in range(saved_arrangements.size()):
		var arrangement_value=saved_arrangements[index]
		if arrangement_value is Dictionary and str(arrangement_value.get("arrangement_id",""))==arrangement_id:
			saved_arrangements.remove_at(index)
			_save();arrangement_ui.sync_state(owned_pots,saved_arrangements,arrangement_save_capacity);arrangement_ui.set_dismantle_request_result(true)
			return

func _share_background_unlock_states()->Dictionary:
	var restoration:=_restoration_state()
	var story_cleared:=finale_complete or bool(restoration.get("ending_seen",false)) or HabitatRestorationClass.ending_phase(restoration)=="complete"
	return ArrangementShareBackgroundsClass.unlock_states(StoryProgressionClass.exploitation_is_started(story_progression_state),story_cleared)

func _on_arrangement_share_background_save_requested(arrangement_id:String,share_background_id:String)->void:
	if arrangement_id.is_empty():return
	var normalized_id:=ArrangementShareBackgroundsClass.normalize_id(share_background_id)
	if normalized_id!=share_background_id or not bool(_share_background_unlock_states().get(normalized_id,false)):return
	for index in range(saved_arrangements.size()):
		var arrangement_value=saved_arrangements[index]
		if not arrangement_value is Dictionary or str(arrangement_value.get("arrangement_id",""))!=arrangement_id:continue
		var updated:Dictionary=arrangement_value.duplicate(true)
		updated["share_background_id"]=normalized_id
		saved_arrangements[index]=updated
		# Share-background metadata must not re-run new-work, pot inventory, or
		# arrangement-capacity validation.
		_save();arrangement_ui.sync_state(owned_pots,saved_arrangements,arrangement_save_capacity)
		return

func _on_arrangement_share_requested(arrangement:Dictionary)->void:
	if arrangement_ui==null or arrangement.is_empty():return
	var image_path:String=await _create_arrangement_share_image(arrangement)
	if image_path.is_empty():arrangement_ui.set_share_state(Localizer.text(language_code,"share_failed"),false);return
	var shared:=_open_native_share_or_fallback(image_path,image_path.get_file(),"arrangement")
	arrangement_ui.set_share_state(shared,false)

func _create_arrangement_share_image(arrangement:Dictionary,output_path_override:String="")->String:
	if arrangement_ui==null or arrangement.is_empty():return ""
	var background_id:=ArrangementShareBackgroundsClass.normalize_id(arrangement.get("share_background_id",ArrangementShareBackgroundsClass.DEFAULT_ID))
	var background_entry:=ArrangementShareBackgroundsClass.entry(background_id)
	if background_entry.is_empty():return ""
	if not await _prepare_arrangement_share_textures(arrangement):return ""
	var output_path:=output_path_override
	if output_path.is_empty():output_path="user://puku-arrangement-%d-%03d.png"%[int(Time.get_unix_time_from_system()),Time.get_ticks_msec()%1000]
	return await arrangement_ui.create_share_image(arrangement,background_entry,output_path)

func _prepare_arrangement_share_textures(arrangement:Dictionary)->bool:
	var pending:Dictionary={}
	var plants_value=arrangement.get("plants",[])
	if not plants_value is Array:return false
	for plant_value in plants_value:
		if not plant_value is Dictionary:continue
		var entry:=_catalog_entry(str(plant_value.get("species_id","")))
		if entry.is_empty():return false
		var path:=_species_image_path(entry)
		if path.is_empty():return false
		if CatalogImageLoader.is_external_path(path):
			if CatalogImageLoader.is_cached(path):continue
			if not pending.has(path):
				pending[path]=0
				CatalogImageLoader.request_texture(path,_on_arrangement_share_texture_ready.bind(path,pending),true)
		elif not ResourceLoader.exists(path):return false
	if pending.is_empty():return true
	var deadline:=Time.get_ticks_msec()+ARRANGEMENT_SHARE_TEXTURE_TIMEOUT_MSEC
	while Time.get_ticks_msec()<deadline:
		var all_ready:=true
		for state_value in pending.values():
			if int(state_value)<0:return false
			if int(state_value)==0:all_ready=false
		if all_ready:return true
		await get_tree().process_frame
	return false

func _on_arrangement_share_texture_ready(texture:Texture2D,path:String,pending:Dictionary)->void:
	pending[path]=1 if texture!=null and CatalogImageLoader.is_cached(path) else -1

func _on_pot_purchase_requested(pot_id:String)->void:
	var pot:=_pot_entry(pot_id)
	if pot.is_empty():arrangement_ui.show_pot_shop_message(Localizer.text(language_code,"pot_missing"));return
	if not _pot_progression_unlocked(pot):arrangement_ui.show_pot_shop_message(Localizer.text(language_code,"pot_locked"));return
	if not _pot_design_unlocked(pot):arrangement_ui.show_pot_shop_message(Localizer.text(language_code,"pot_unlock_required"));return
	var price:=maxi(0,int(pot.get("price_puku",POT_PRICE_PUKU)))
	var price_units:=_puku_cost_units(price)
	if not _can_afford_puku_units(price_units):arrangement_ui.show_pot_shop_message(Localizer.text(language_code,"not_enough_puku"));return
	_change_puku_balance(-price_units,"pot_purchase",false,true);owned_pots[pot_id]=_owned_pot_total(pot_id)+1;_save();_update_currency_ui();arrangement_ui.sync_state(owned_pots,saved_arrangements,arrangement_save_capacity);arrangement_ui.sync_catalog_state(unlocked_series,puku_points);arrangement_ui.sync_seed_shop_state(_seed_shop_products(),puku_points);arrangement_ui.show_pot_shop_message(Localizer.text(language_code,"pot_bought_count",[Localizer.pot_name(language_code,pot),_owned_pot_total(pot_id)]))
	audio_manager.notify_user_gesture();audio_manager.play_se("purchase",1.0)

func _on_pot_unlock_requested(product_id:String)->void:
	var pot:=_pot_entry_for_product(product_id)
	if pot.is_empty() or not _pot_progression_unlocked(pot):
		arrangement_ui.show_pot_shop_message(Localizer.text(language_code,"pot_locked"))
		return
	if _pot_design_unlocked(pot):
		arrangement_ui.show_pot_shop_message(Localizer.text(language_code,"pot_already_unlocked"))
		return
	if pot_unlock_iap_service==null or not pot_unlock_iap_service.purchase(product_id):
		arrangement_ui.show_pot_shop_message(Localizer.text(language_code,"iap_purchase_unavailable"))
		return
	arrangement_ui.show_pot_shop_message(Localizer.text(language_code,"iap_purchase_processing"))

func _on_pot_restore_requested()->void:
	if pot_unlock_iap_service==null or not pot_unlock_iap_service.restore_purchases():
		arrangement_ui.show_pot_shop_message(Localizer.text(language_code,"iap_restore_unavailable"))
		return
	arrangement_ui.show_pot_shop_message(Localizer.text(language_code,"iap_restore_processing"))
	_sync_arrangement_ui()

func _on_pot_iap_state_changed()->void:
	if arrangement_ui!=null:_sync_arrangement_ui()

func _on_pot_iap_entitlement_changed(product_id:String,unlocked:bool)->void:
	if unlocked:pot_design_unlocks[product_id]=true
	else:pot_design_unlocks.erase(product_id)
	if save_file_present_on_boot or language_selected:_save()
	if arrangement_ui!=null:
		_sync_arrangement_ui()
		var pot:=_pot_entry_for_product(product_id)
		if unlocked and not pot.is_empty():arrangement_ui.show_pot_shop_message(Localizer.text(language_code,"pot_unlock_success",[Localizer.pot_name(language_code,pot)]))

func _on_pot_iap_purchase_failed(_product_id:String,reason:String)->void:
	if arrangement_ui==null:return
	arrangement_ui.show_pot_shop_message(Localizer.text(language_code,"iap_purchase_canceled" if reason=="canceled" else "iap_purchase_failed"))

func _on_pot_iap_restore_finished(success:bool)->void:
	if arrangement_ui==null:return
	arrangement_ui.show_pot_shop_message(Localizer.text(language_code,"iap_restore_complete" if success else "iap_restore_failed"))
	_sync_arrangement_ui()

func _on_catalog_purchase_requested(series_id:String)->void:
	# Catalog pages are recorded automatically on first GET; they are never sold.
	return

func _pot_entry(pot_id:String)->Dictionary:
	for value in pot_catalog:
		if value is Dictionary and str(value.get("pot_id",""))==pot_id:return value
	return {}

func _pot_entry_for_product(product_id:String)->Dictionary:
	for value in pot_catalog:
		if value is Dictionary and str(value.get("iap_product_id",""))==product_id:return value
	return {}

func _pot_unlocked(pot:Dictionary)->bool:
	return _pot_progression_unlocked(pot) and _pot_design_unlocked(pot)

func _pot_progression_unlocked(pot:Dictionary)->bool:
	if int(pot.get("sales_stage",0))>_current_pot_sales_stage():return false
	var condition=pot.get("unlock_condition",{})
	if not condition is Dictionary:return true
	match str(condition.get("type","default")):
		"formal_play_count":return formal_play_count>=int(condition.get("value",0))
		"total_get":return _all_series_get_count()>=int(condition.get("value",0))
		"default":return true
		_:return false

func _pot_design_unlocked(pot:Dictionary)->bool:
	if str(pot.get("unlock_type","free"))!="iap_unlock":return true
	var product_id:=str(pot.get("iap_product_id",""))
	return not product_id.is_empty() and bool(pot_design_unlocks.get(product_id,false))

func _current_pot_sales_stage()->int:
	if act3_unlocked:return 2
	if forest_gacha_unlocked or fantasy_realization_seen or _unique_fantasy_species_get_count()>=6:return 1
	return 0

func _normalize_pot_design_unlocks(value:Variant)->Dictionary:
	var normalized:Dictionary={}
	if not value is Dictionary:return normalized
	var known_products:Dictionary={}
	for pot_value in pot_catalog:
		if not pot_value is Dictionary or str(pot_value.get("unlock_type","free"))!="iap_unlock":continue
		var product_id:=str(pot_value.get("iap_product_id",""))
		if not product_id.is_empty():known_products[product_id]=true
	for product_id_value in value:
		var product_id:=str(product_id_value)
		if known_products.has(product_id) and bool(value[product_id_value]):normalized[product_id]=true
	return normalized

func _owned_pot_total(pot_id:String)->int:
	var value=owned_pots.get(pot_id,0)
	if value is bool:return 1 if bool(value) else 0
	if value is int or value is float:return maxi(0,int(value))
	return 0

func _pot_usage_count(pot_id:String,excluded_arrangement_id:String="")->int:
	var count:=0
	for arrangement_value in saved_arrangements:
		if not arrangement_value is Dictionary:continue
		if not excluded_arrangement_id.is_empty() and str(arrangement_value.get("arrangement_id",""))==excluded_arrangement_id:continue
		if str(arrangement_value.get("pot_id",""))==pot_id:count+=1
	return count

func _pot_available_count(pot_id:String)->int:
	return maxi(0,_owned_pot_total(pot_id)-_pot_usage_count(pot_id))

func _pot_available_count_for_arrangement(pot_id:String,arrangement_id:String)->int:
	return maxi(0,_owned_pot_total(pot_id)-_pot_usage_count(pot_id,arrangement_id))

func _normalize_owned_pot_counts()->bool:
	var changed:=false;var normalized:Dictionary={}
	for pot_id_value in owned_pots:
		var pot_id:=str(pot_id_value);var raw_value=owned_pots[pot_id_value];var count:=0
		if raw_value is bool:
			count=1 if bool(raw_value) else 0;changed=true
		elif raw_value is int or raw_value is float:
			count=maxi(0,int(raw_value))
			if float(raw_value)!=float(count):changed=true
		else:
			changed=true
		if _pot_entry(pot_id).is_empty():
			changed=true
			continue
		if count>0:normalized[pot_id]=count
		elif owned_pots.has(pot_id):changed=true
	if int(normalized.get(DEFAULT_POT_ID,0))<1:
		normalized[DEFAULT_POT_ID]=1;changed=true
	owned_pots=normalized
	return changed

func _reconcile_pot_inventory_with_arrangements()->bool:
	var changed:=false;var usage:Dictionary={}
	for arrangement_value in saved_arrangements:
		if not arrangement_value is Dictionary:continue
		var pot_id:=str(arrangement_value.get("pot_id",DEFAULT_POT_ID))
		usage[pot_id]=int(usage.get(pot_id,0))+1
	for pot_id_value in usage:
		var pot_id:=str(pot_id_value);var required:=int(usage[pot_id_value])
		if _owned_pot_total(pot_id)<required:
			owned_pots[pot_id]=required;changed=true
	return changed

func _arrangement_contains_retired_species(source:Dictionary)->bool:
	var source_plants:Variant=source.get("plants",[])
	if not source_plants is Array:return false
	for plant_value in source_plants:
		if plant_value is Dictionary and StoryProgressionClass.is_retired_special_base_species(str(plant_value.get("species_id",""))):return true
	return false

func _normalize_arrangement(source:Dictionary)->Dictionary:
	var pot_id:=str(source.get("pot_id",DEFAULT_POT_ID))
	if _pot_entry(pot_id).is_empty():pot_id=DEFAULT_POT_ID
	var source_plants=source.get("plants",[]);var plants_data:Array=[]
	if source_plants is Array:
		for plant_value in source_plants:
			if plants_data.size()>=24:break
			if not plant_value is Dictionary:continue
			var species_id:=str(plant_value.get("species_id",""))
			if _catalog_entry(species_id).is_empty() or not bool(discovered.get(species_id,false)):continue
			# Arrangement scale is creative metadata. Never reinterpret it through the
			# plant's greenhouse best record while saving or loading a finished piece.
			plants_data.append({"species_id":species_id,"x":clampf(float(plant_value.get("x",268.0)),0.0,536.0),"y":clampf(float(plant_value.get("y",276.0)),0.0,552.0),"scale":clampf(float(plant_value.get("scale",ArrangementUIClass.PLANT_SCALE_MIN)),ArrangementUIClass.PLANT_SCALE_MIN,ArrangementUIClass.PLANT_SCALE_SAFETY_MAX),"rotation":fposmod(float(plant_value.get("rotation",0.0)),360.0),"z_index":clampi(int(plant_value.get("z_index",plants_data.size())),-100,100)})
	var arrangement_id:=str(source.get("arrangement_id",""))
	if arrangement_id.is_empty():arrangement_id="arrangement_%d_%d"%[Time.get_unix_time_from_system(),Time.get_ticks_msec()%100000]
	var arrangement_name:=str(source.get("name","")).strip_edges()
	if arrangement_name.is_empty():arrangement_name=Localizer.text(language_code,"arrangement_default_name",[saved_arrangements.size()+1])
	var share_background_id:=ArrangementShareBackgroundsClass.normalize_id(source.get("share_background_id",ArrangementShareBackgroundsClass.DEFAULT_ID))
	# Legacy viewer_transform metadata is intentionally discarded. Finished-work
	# pan/zoom is transient and always starts from the standard framing.
	return {"arrangement_id":arrangement_id,"name":arrangement_name,"pot_id":pot_id,"created_at":str(source.get("created_at",Time.get_datetime_string_from_system(false,true))),"completed":true,"plants":plants_data,"share_background_id":share_background_id}

func _on_shop_panda_tapped()->void:
	if shop_chatter_bubble.visible:_dismiss_or_advance_shop_chatter();return
	if _shop_rescue_needed():
		_show_shop_chatter(Localizer.text(language_code,"shop_puku_rescue_offer" if _shop_puku_rescue_needed() else "shop_rescue_offer"),true)
		return
	_show_shop_chatter(_pick_shop_chatter(),false)

func _show_shop_chatter(message:String,is_rescue:bool,dialog_mode:="normal",speaker_id:="panda",acquired_species:Variant=null)->void:
	armadillo_dialog_mode="rescue" if is_rescue else dialog_mode
	shop_chatter_acquired_species.clear()
	if acquired_species is Array:
		for species_id in acquired_species:
			if not shop_chatter_acquired_species.has(str(species_id)):shop_chatter_acquired_species.append(str(species_id))
	if dialog_mode!="research_result":shop_transfer_notice.visible=false
	shop_chatter_bubble.modulate=Color.WHITE;shop_chatter_bubble.visible=true;shop_chatter_label.text=message;_set_shop_speaker(str(speaker_id))
	if is_rescue or dialog_mode in ["research_offer","research_result","catalog_restore_offer","catalog_restore_result"]:
		shop_chatter_bubble.position=Vector2(22,86);shop_chatter_bubble.size=Vector2(420,250)
	else:
		var bubble_width:=clampf(210.0+message.length()*4.8,280.0,440.0);var bubble_height:=118.0 if message.length()>38 else 108.0
		shop_chatter_bubble.size=Vector2(bubble_width,bubble_height);shop_chatter_bubble.position=Vector2((576.0-bubble_width)*.5,276)
	shop_chatter_action_button.visible=is_rescue or dialog_mode in ["research_offer","catalog_restore_offer"]
	shop_chatter_action_button.disabled=rescue_reward_in_progress if is_rescue else false
	shop_chatter_action_button.text=(Localizer.text(language_code,"ad_preparing") if rescue_reward_in_progress else Localizer.text(language_code,"shop_help_action") if _shop_puku_rescue_needed() else Localizer.text(language_code,"ad_seed")) if is_rescue else (Localizer.text(language_code,"restore") if dialog_mode=="catalog_restore_offer" else Localizer.text(language_code,"yes"))
	shop_chatter_decline_button.visible=dialog_mode in ["research_offer","catalog_restore_offer"]

func _start_shop_chatter_sequence(kind:String,pages:Array,speaker_id:String)->void:
	shop_chatter_pages.clear()
	for page in pages:shop_chatter_pages.append(str(page))
	shop_chatter_page_index=0;shop_chatter_sequence_kind=kind;shop_chatter_sequence_speaker=speaker_id
	_show_shop_chatter(shop_chatter_pages[0],false,"sequence",speaker_id)

func _dismiss_or_advance_shop_chatter()->void:
	if shop_chatter_action_button.visible:return
	if shop_chatter_sequence_kind.is_empty():_hide_shop_chatter();return
	if shop_chatter_page_index+1<shop_chatter_pages.size():
		shop_chatter_page_index+=1
		var is_research_choice:=shop_chatter_sequence_kind=="research_intro" and shop_chatter_page_index==shop_chatter_pages.size()-1
		_show_shop_chatter(shop_chatter_pages[shop_chatter_page_index],false,"research_offer" if is_research_choice else "sequence",shop_chatter_sequence_speaker)
		return
	var finished_kind:=shop_chatter_sequence_kind
	shop_chatter_sequence_kind="";shop_chatter_pages.clear();shop_chatter_page_index=0
	if finished_kind=="volume_intro":
		tutorial_steps["volume_intro_step"]=2;volume_seed_intro_seen=true;_save()
	elif finished_kind=="pinwheel_intro":
		var acquired:=_grant_hidden_species(HIDDEN_PINWHEEL_ID);tutorial_steps["pinwheel_intro_step"]=3
		if acquired:call_deferred("_queue_species_get_by_id",HIDDEN_PINWHEEL_ID,true,"pinwheel_gift")
		_save()
	_hide_shop_chatter()

func _on_shop_chatter_action()->void:
	match armadillo_dialog_mode:
		"rescue":_request_rescue_reward_ad()
		"research_offer":_accept_armadillo_research()
		"catalog_restore_offer":_accept_hidden_catalog_restoration()

func _on_shop_background_gui_input(event:InputEvent)->void:
	if _shop_dismiss_pressed(event):_dismiss_or_advance_shop_chatter()

func _on_shop_chatter_gui_input(event:InputEvent)->void:
	if _shop_dismiss_pressed(event):_dismiss_or_advance_shop_chatter()

func _shop_dismiss_pressed(event:InputEvent)->bool:
	if event is InputEventMouseButton:return event.button_index==MOUSE_BUTTON_LEFT and event.pressed
	if event is InputEventScreenTouch:return event.pressed
	return false

func _hide_shop_chatter(force:=false)->void:
	if not shop_chatter_bubble.visible:return
	if shop_chatter_action_button.visible and not force:return
	var dismissed_mode:=armadillo_dialog_mode;var acquired_now:=shop_chatter_acquired_species.duplicate();shop_chatter_acquired_species.clear()
	shop_chatter_bubble.visible=false;shop_chatter_bubble.modulate.a=1.0;shop_transfer_notice.visible=false;armadillo_dialog_mode="";shop_chatter_sequence_kind="";shop_chatter_pages.clear();shop_chatter_page_index=0
	if not acquired_now.is_empty():call_deferred("_play_shop_new_species_animations",acquired_now)
	if dismissed_mode=="research_result" and research_catalog_reward_pending:call_deferred("_open_research_catalog_reward")

func _set_shop_speaker(speaker_id:String)->void:
	shop_chatter_portrait.texture=_speaker_portrait_texture(speaker_id)
	shop_chatter_portrait.visible=shop_chatter_portrait.texture!=null
	shop_chatter_portrait.pivot_offset=shop_chatter_portrait.custom_minimum_size*.5
	shop_chatter_portrait.scale=Vector2.ONE
	shop_chatter_portrait.clip_contents=false

func _pick_shop_chatter()->String:
	var candidates:Array=[]
	for key in SHOP_CHATTER_KEYS:candidates.append(Localizer.text(language_code,str(key)))
	candidates.erase(last_shop_chatter)
	var chosen:=str(candidates[rng.randi_range(0,candidates.size()-1)]);last_shop_chatter=chosen;return chosen

func _is_japan_region()->bool:
	var locale:=TranslationServer.get_locale().replace("-","_").to_lower()
	return locale=="ja" or locale.begins_with("ja_") or locale.ends_with("_jp")

func _has_any_playable_seed_stock()->bool:
	if _normal_seed_play_available():return true
	if volume_seed_bags>0 and _volume_seed_unlocked():return true
	if premium_seed_bags>0 and _premium_seed_unlocked():return true
	if mystery_seed_bags>0 and _mystery_seed_pack_unlocked():return true
	for series_id in series_seed_inventory:
		if int(series_seed_inventory.get(series_id,0))>0 and bool(unlocked_series.get(str(series_id),false)):return true
	return false

func _shop_puku_rescue_needed()->bool:
	return mystery_items_acquired and habitat_tutorial_complete and puku_gauge_intro_complete and current_mode=="greenhouse" and _endless_normal_flow_owns_play_controls() and not play_active and normal_round_free_plays<=0 and puku_balance_units<NORMAL_ROUND_COST_UNITS

func _shop_seed_rescue_needed()->bool:
	return mystery_items_acquired and habitat_tutorial_complete and current_mode=="greenhouse" and not play_active and plants.is_empty() and normal_seed_bags<=0 and not _has_any_playable_seed_stock()

func _shop_rescue_needed()->bool:
	return _shop_puku_rescue_needed() or _shop_seed_rescue_needed()

func _request_rescue_reward_ad()->void:
	if rescue_reward_in_progress or not _shop_rescue_needed():return
	rescue_reward_context="shop_puku_rescue" if _shop_puku_rescue_needed() else "shop_seed_rescue"
	rescue_reward_in_progress=true;shop_chatter_action_button.disabled=true;shop_chatter_action_button.text=Localizer.text(language_code,"ad_preparing")
	if REWARDED_AD_DEVELOPMENT_STUB_ENABLED:
		await get_tree().create_timer(.65).timeout
		_on_rescue_reward_ad_completed(true)
	else:
		rescue_reward_ad_requested.emit(rescue_reward_context)

func _on_rescue_reward_ad_completed(reward_earned:bool)->void:
	if not rescue_reward_in_progress:return
	rescue_reward_in_progress=false
	if not reward_earned:
		shop_chatter_action_button.disabled=false;shop_chatter_action_button.text=Localizer.text(language_code,"shop_help_action") if rescue_reward_context=="shop_puku_rescue" else Localizer.text(language_code,"ad_seed");rescue_reward_context=""
		return
	var completed_context:=rescue_reward_context;rescue_reward_context=""
	if completed_context=="shop_puku_rescue":_change_puku_balance(PUKU_UNITS_PER_PUKU,"shop_puku_rescue",false,true)
	else:_grant_rescue_seed_bags()
	_save();_update_shop_ui();_update_play_ui();audio_manager.play_se("daily",.48)
	_show_shop_chatter(Localizer.text(language_code,"shop_puku_rescue_success" if completed_context=="shop_puku_rescue" else "shop_rescue_success"),false)

func _grant_rescue_seed_bags()->void:
	match RESCUE_REWARD_SEED_TYPE:
		"old":old_seed_bags+=RESCUE_REWARD_SEED_BAGS
		"premium":premium_seed_bags+=RESCUE_REWARD_SEED_BAGS
		_:normal_seed_bags+=RESCUE_REWARD_SEED_BAGS

func _build_intro_story(hud:Control)->void:
	intro_overlay=Control.new();intro_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);intro_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;intro_overlay.visible=false;hud.add_child(intro_overlay)
	var shade:=ColorRect.new();shade.color=Color(0.08,0.05,0.025,.18);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;intro_overlay.add_child(shade)
	intro_dialog_panel=PanelContainer.new();intro_dialog_panel.position=Vector2(40,690);intro_dialog_panel.size=Vector2(496,255);intro_dialog_panel.add_theme_stylebox_override("panel",_box(Color(0.97,0.90,0.75,.96),Color("#a86f36"),24,4));intro_overlay.add_child(intro_dialog_panel)
	var dialog_row:=HBoxContainer.new();dialog_row.alignment=BoxContainer.ALIGNMENT_CENTER;dialog_row.add_theme_constant_override("separation",12);intro_dialog_panel.add_child(dialog_row)
	intro_portrait_slot=Control.new();intro_portrait_slot.custom_minimum_size=Vector2(132,205);intro_portrait_slot.clip_contents=true;intro_portrait_slot.mouse_filter=Control.MOUSE_FILTER_IGNORE;dialog_row.add_child(intro_portrait_slot)
	intro_panda_portrait=TextureRect.new();intro_panda_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;intro_panda_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;intro_panda_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);intro_panda_portrait.offset_top=32.0;intro_panda_portrait.texture=_panda_portrait_texture();intro_panda_portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE;intro_panda_portrait.visible=false;intro_portrait_slot.add_child(intro_panda_portrait)
	intro_trio_portraits=Control.new();intro_trio_portraits.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);intro_trio_portraits.mouse_filter=Control.MOUSE_FILTER_IGNORE;intro_trio_portraits.visible=false;intro_portrait_slot.add_child(intro_trio_portraits)
	var trio_layout:=[{"speaker":"panda","position":Vector2(0,88)},{"speaker":"armadillo","position":Vector2(76,88)},{"speaker":"girl","position":Vector2(38,32)}]
	for trio_entry in trio_layout:
		var trio_position:Vector2=trio_entry.get("position",Vector2.ZERO);var trio_portrait:=TextureRect.new();trio_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;trio_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;trio_portrait.texture=_speaker_portrait_texture(str(trio_entry.speaker));trio_portrait.position=trio_position;trio_portrait.size=Vector2(86,112);trio_portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE;intro_trio_portraits.add_child(trio_portrait)
	intro_speaker_label=Label.new();intro_speaker_label.text=Localizer.text(language_code,"story_speaker_panda");intro_speaker_label.position=Vector2.ZERO;intro_speaker_label.size=Vector2(132,30);intro_speaker_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;intro_speaker_label.add_theme_font_size_override("font_size",17);intro_speaker_label.add_theme_color_override("font_color",Color("#8b5528"));intro_speaker_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;intro_speaker_label.z_index=2;intro_portrait_slot.add_child(intro_speaker_label)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",12);content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;dialog_row.add_child(content)
	intro_dialogue_label=Label.new();intro_dialogue_label.custom_minimum_size=Vector2(300,90);intro_dialogue_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;intro_dialogue_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;intro_dialogue_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;intro_dialogue_label.add_theme_font_size_override("font_size",20);intro_dialogue_label.add_theme_color_override("font_color",UI_BROWN);intro_dialogue_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_child(intro_dialogue_label)
	intro_continue_button=Button.new();intro_continue_button.text=Localizer.text(language_code,"continue");intro_continue_button.custom_minimum_size=Vector2(250,55);_skin_button(intro_continue_button,Color("#d8b56b"),19);intro_continue_button.pressed.connect(_advance_intro_story);content.add_child(intro_continue_button)
	intro_fullscreen_continue_button=Button.new();intro_fullscreen_continue_button.name="OldSeedGetContinueArea";intro_fullscreen_continue_button.flat=true;intro_fullscreen_continue_button.focus_mode=Control.FOCUS_NONE;intro_fullscreen_continue_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);intro_fullscreen_continue_button.visible=false;intro_fullscreen_continue_button.pressed.connect(_advance_intro_story);intro_overlay.add_child(intro_fullscreen_continue_button)

func _current_dialog_avoid_rect()->Rect2:
	if is_instance_valid(tutorial_harvest_plant):
		var screen:=camera.unproject_position(tutorial_harvest_plant.global_position)
		return Rect2(screen-Vector2(80,80),Vector2(160,160))
	if not tutorial_habitat_item.is_empty():
		var node=tutorial_habitat_item.get("node")
		if is_instance_valid(node):
			var screen:=camera.unproject_position(node.global_position)
			return Rect2(screen-Vector2(80,80),Vector2(160,160))
	return Rect2()

func _position_intro_dialog()->void:
	var avoid:=_current_dialog_avoid_rect();var bottom:=Vector2(40,725);var center:=Vector2(40,385)
	intro_dialog_panel.position=center if avoid.has_area() and Rect2(bottom,intro_dialog_panel.size).intersects(avoid) else bottom

func _position_tutorial_dialog(avoid:Rect2)->void:
	var bottom:=Vector2(40,790);var center:=Vector2(40,395)
	tutorial_dialog_panel.position=center if Rect2(bottom,tutorial_dialog_panel.size).intersects(avoid) else bottom

func _start_intro_story()->void:
	intro_is_daily_gift=false;tutorial_dialog_kind="";intro_story_step=0;current_mode="greenhouse";_apply_mode();_set_shop_purchase_visible(false);shop_overlay.visible=false;intro_overlay.visible=true;intro_continue_button.visible=true;intro_fullscreen_continue_button.visible=false;_set_intro_speaker("panda");_position_intro_dialog();intro_speaker_label.visible=true;play_overlay.visible=false;play_open_button.visible=false;audio_manager.play_bgm("greenhouse");_advance_intro_story();_update_play_ui()

func _start_daily_seed_gift()->void:
	intro_is_daily_gift=true;current_mode="greenhouse";_apply_mode();_set_shop_purchase_visible(false);shop_overlay.visible=true;intro_overlay.visible=true;_set_intro_speaker("panda");_position_intro_dialog();intro_speaker_label.visible=true;play_overlay.visible=false;play_open_button.visible=false;audio_manager.play_bgm("shop")
	intro_dialogue_label.text=Localizer.text(language_code,"daily_seed_gift")
	intro_dialogue_label.add_theme_font_size_override("font_size",25);intro_dialogue_label.add_theme_color_override("font_color",Color("#b66d20"));intro_continue_button.text=Localizer.text(language_code,"main_greenhouse")
	normal_seed_bags+=1;login_bonus_date=Time.get_date_string_from_system();_save();_show_intro_gift_effect();_update_play_ui()
	audio_manager.play_se("daily",.58)

func _advance_intro_story()->void:
	if not scripted_dialog_kind.is_empty():
		_advance_scripted_dialog()
		return
	if not tutorial_dialog_kind.is_empty():
		var finished_kind:=tutorial_dialog_kind;tutorial_dialog_kind="";tutorial_steps[finished_kind+"_dialog"]=true;intro_overlay.visible=false;shop_overlay.visible=false;intro_speaker_label.visible=true;intro_dialogue_label.add_theme_font_size_override("font_size",20);intro_dialogue_label.add_theme_color_override("font_color",UI_BROWN);intro_continue_button.text=Localizer.text(language_code,"continue");_save();_update_play_ui();_play_current_area_bgm()
		if finished_kind=="play3":_show_tutorial_guide("habitat")
		elif finished_kind=="habitat_scroll":habitat_scroll_tutorial_active=true
		elif finished_kind=="puku_gauge":puku_gauge_intro_complete=true;tutorial_steps["puku_gauge_intro_complete"]=true;_ensure_initial_puku_capital(true);_save();_update_currency_ui()
		return
	if intro_is_daily_gift:
		intro_is_daily_gift=false;intro_overlay.visible=false;shop_overlay.visible=false;intro_speaker_label.visible=true;intro_dialogue_label.add_theme_font_size_override("font_size",20);intro_dialogue_label.add_theme_color_override("font_color",UI_BROWN);intro_continue_button.text=Localizer.text(language_code,"continue");_update_play_ui();audio_manager.play_bgm("greenhouse");return
	intro_story_step+=1
	intro_continue_button.visible=true;intro_fullscreen_continue_button.visible=false
	match intro_story_step:
		1:
			intro_speaker_label.visible=true
			intro_dialogue_label.text=Localizer.text(language_code,"intro_old_seed")
		2:
			intro_speaker_label.visible=false;_set_intro_speaker("")
			intro_dialogue_label.text=Localizer.text(language_code,"intro_old_seed_get")
			intro_dialogue_label.add_theme_font_size_override("font_size",29);intro_dialogue_label.add_theme_color_override("font_color",Color("#b66d20"));intro_continue_button.visible=false;intro_fullscreen_continue_button.visible=true
			_show_intro_gift_effect()
		_:
			intro_story_complete=true;old_seed_bags=1;login_bonus_date=Time.get_date_string_from_system();intro_overlay.visible=false;intro_fullscreen_continue_button.visible=false;shop_overlay.visible=false;intro_speaker_label.visible=true;intro_dialogue_label.add_theme_font_size_override("font_size",20);intro_dialogue_label.add_theme_color_override("font_color",UI_BROWN);intro_continue_button.visible=true;intro_continue_button.text=Localizer.text(language_code,"continue");_save();_update_main_story_progress(false);_update_play_ui();audio_manager.play_bgm("greenhouse");_show_tutorial_guide("play_open")

func _start_scripted_dialog(kind:String,pages:Array,shop_context:=false)->void:
	scripted_dialog_kind=kind;scripted_dialog_pages.clear();scripted_dialog_index=-1;scripted_dialog_shop_context=shop_context
	for page_value in pages:
		if page_value is Dictionary:scripted_dialog_pages.append(page_value.duplicate(true))
	intro_overlay.visible=true;intro_overlay.move_to_front();shop_overlay.visible=shop_context;play_overlay.visible=false;play_open_button.visible=false;_position_intro_dialog();_update_play_ui()
	if shop_context:
		armadillo_present=scripted_dialog_pages.any(func(page:Dictionary)->bool:return str(page.get("speaker",""))=="armadillo")
		shop_background.texture=load("res://assets/shop-background-armadillo.jpg" if armadillo_present else "res://assets/shop-background-final.jpg")
		armadillo_tap_button.visible=false;audio_manager.play_bgm("shop")
	else:
		# Gang confrontations deliberately take over the habitat theme. Act III's
		# opening does so before exploitation_started is persisted.
		if kind!="collection_complete":_play_current_area_bgm(kind in ["jurejure_intro","jurejure_challenge","jurejure_exploitation_challenge","act3_intro","act3_exploitation_battle_intro"])
	_advance_scripted_dialog()

func _advance_scripted_dialog()->void:
	# A dialogue page can hand off to a catalog card, then resume at the next
	# page when that card closes. This keeps species introductions adjacent to
	# their spoken names without adding event-specific dialogue branches.
	if scripted_dialog_index>=0 and scripted_dialog_index<scripted_dialog_pages.size():
		var previous_page:Dictionary=scripted_dialog_pages[scripted_dialog_index]
		var card_species_id:=str(previous_page.get("after_species_card",""))
		if not card_species_id.is_empty() and not bool(previous_page.get("after_species_card_shown",false)):
			previous_page["after_species_card_shown"]=true
			scripted_dialog_pages[scripted_dialog_index]=previous_page
			_register_story_catalog_species(card_species_id)
			intro_continue_button.disabled=true
			_save()
			_queue_species_get_by_id(card_species_id,true,"scripted_dialog_card:%s"%card_species_id)
			return
	scripted_dialog_index+=1
	if scripted_dialog_index>=scripted_dialog_pages.size():
		_finish_scripted_dialog()
		return
	if scripted_dialog_kind=="initial_seed_stock" and scripted_dialog_index==2 and not _is_endless_greenhouse_enabled():
		_claim_first_habitat_gift_once()
	if scripted_dialog_kind=="first_seed_pod_reward" and scripted_dialog_index==3:
		_claim_first_seed_pod_reward_once()
	var page:Dictionary=scripted_dialog_pages[scripted_dialog_index]
	var speaker_id:=str(page.get("speaker","panda"))
	_set_intro_speaker(speaker_id);intro_speaker_label.visible=not speaker_id.is_empty()
	intro_dialogue_label.text=str(page.get("text",""));intro_continue_button.text=str(page.get("button",Localizer.text(language_code,"continue")));_position_intro_dialog()
	if bool(page.get("start_ending_bgm",false)):_start_restoration_ending_bgm_if_needed()
	var lookaround_context:=str(page.get("lookaround",""))
	if not lookaround_context.is_empty():call_deferred("_start_habitat_lookaround",lookaround_context)

func _finish_scripted_dialog()->void:
	var finished_kind:=scripted_dialog_kind;var keep_shop:=scripted_dialog_shop_context
	scripted_dialog_kind="";scripted_dialog_pages.clear();scripted_dialog_index=-1;scripted_dialog_shop_context=false;intro_overlay.visible=false
	var acquired:Array[String]=[];var open_puku_intro:=false;var open_catalog:=false;var guide_habitat:=false;var guide_catalog:=false;var show_pinwheel_get:=false;var show_armadillo_gift:=false;var start_second_awakening:=false;var start_trio_event:=false;var start_jurejure_reveal:=false;var show_jurejure_choice:=false;var queue_jurejure_reward:=false;var focus_act3_exploitation:=false;var show_arrangement_swipe_intro:=false
	var begin_restoration_join_habitat:=false;var restoration_return_stage:=0;var next_restoration_return_stage:=0;var start_restoration_join_after_return:=false;var start_restoration_epilogue:=false;var show_restoration_thank_you:=false;var start_habitat_crisis_travel:=false;var finish_collection_complete:=false
	if finished_kind.begins_with("restoration_return_"):
		restoration_return_stage=int(finished_kind.trim_prefix("restoration_return_"))
		var restoration:=_restoration_state()
		if restoration_return_stage>=HabitatRestorationClass.REQUIRED_RETURNED_PLANTS:HabitatRestorationClass.begin_recovery_slides(restoration)
		else:
			HabitatRestorationClass.complete_return_event(restoration,restoration_return_stage)
			start_restoration_join_after_return=restoration_return_stage==1 and not bool(restoration.get("jurejure_joined",false))
		next_restoration_return_stage=HabitatRestorationClass.pending_return_stage(restoration)
		story_progression_state["restoration"]=restoration
	match finished_kind:
		"first_colorata_discovery":
			first_colorata_confirmed=true;start_trio_event=true
		"trio_originals":
			trio_originals_confirmed=true;habitat_unlocked=true;guide_habitat=true
		"mystery_catalog_prompt":
			guide_catalog=true
		"habitat_return":
			habitat_return_dialog_seen=true;guide_catalog=true
		"mystery_catalog_tutorial":
			mystery_catalog_tutorial_complete=true;tutorial_steps["mystery_catalog_tutorial_complete"]=true
		"initial_seed_stock":
			initial_seed_stock_notice_complete=true
			if _is_endless_greenhouse_enabled():_claim_first_habitat_gift_once()
		"first_normal_sow_prompt":
			if _is_endless_greenhouse_enabled():tutorial_steps[ENDLESS_AUTO_SOW_TUTORIAL_STEP]=true
		"first_seed_pod_reward":
			first_seed_pod_reward_event_active=false
		"forest_gacha_intro":
			forest_gacha_intro_seen=true
		"fantasy_first_discovery":
			fantasy_first_discovery_seen=true;StoryProgressionClass.consume_story_event(story_progression_state,StoryProgressionClass.EVENT_FANTASY_FIRST)
		"arrangement_intro":
			StoryProgressionClass.complete_arrangement_intro(story_progression_state);show_arrangement_swipe_intro=true
		"fantasy_realization":
			fantasy_realization_seen=true;StoryProgressionClass.consume_story_event(story_progression_state,StoryProgressionClass.EVENT_FANTASY_SIX)
			if StoryProgressionClass.take_forest_gacha_unlock(story_progression_state):forest_gacha_unlocked=true;forest_gacha_intro_seen=false
		"post_jurejure_encounter_home":
			StoryProgressionClass.complete_post_encounter_greenhouse(story_progression_state)
		"act3_intro":
			act3_intro_seen=true;act3_intro_pending=false;jurejure_waiting_for_seed_pod_reward=false
			StoryProgressionClass.begin_exploitation(story_progression_state,_unique_jurejure_species_get_count());focus_act3_exploitation=current_mode=="habitat"
		"act3_exploitation_battle_intro":
			StoryProgressionClass.complete_act3_battle_intro(story_progression_state);show_jurejure_choice=true
		"jurejure_species_first":
			jurejure_species_first_seen=true
		"habitat_crisis":
			StoryProgressionClass.mark_habitat_crisis_dialog_complete(story_progression_state)
		"habitat_crisis_departure":
			start_habitat_crisis_travel=true
		"post_crisis_greenhouse":
			StoryProgressionClass.complete_post_crisis_greenhouse(story_progression_state)
		"restoration_join_home":
			StoryProgressionClass.complete_restoration_join_home(story_progression_state);begin_restoration_join_habitat=true
		"restoration_join_habitat":
			StoryProgressionClass.complete_restoration_join_habitat(story_progression_state)
		"restoration_final":
			var restoration:=_restoration_state();HabitatRestorationClass.mark_final_dialog_complete(restoration);story_progression_state["restoration"]=restoration;start_restoration_epilogue=true
		"restoration_epilogue":
			var restoration:=_restoration_state();HabitatRestorationClass.mark_epilogue_complete(restoration);story_progression_state["restoration"]=restoration;show_restoration_thank_you=true
		"exploitation_midpoint":
			StoryProgressionClass.complete_exploitation_midpoint(story_progression_state)
		"special_origin":
			special_series_explanation_seen=true;pending_special_series_explanation=false
		"jurejure_first_notice":
			start_jurejure_reveal=true
		"jurejure_intro":
			jurejure_intro_complete=true;jurejure_enabled=true;jurejure_next_check_unix=0.0;show_jurejure_choice=true;StoryProgressionClass.queue_post_encounter_greenhouse(story_progression_state)
		"jurejure_challenge":
			show_jurejure_choice=true
		"jurejure_exploitation_challenge":
			show_jurejure_choice=true
		"jurejure_post_ending":
			show_jurejure_choice=true
		"jurejure_battle_win":
			queue_jurejure_reward=not jurejure_pending_reward_species_id.is_empty()
		"jurejure_growth_mid":
			jurejure_growth_event_mask|=1
		"jurejure_growth_late":
			jurejure_growth_event_mask|=2
		"original_catalog_complete":
			original_catalog_complete_event_seen=true;start_second_awakening=current_mode=="habitat"
		"jurejure_return":
			jurejure_return_event_complete=true
			_clear_active_jurejure_event(true)
		"armadillo_3":
			if _grant_hidden_species(HIDDEN_PINWHEEL_ID):acquired.append(HIDDEN_PINWHEEL_ID)
			armadillo_intro_event_3_completed=true;pending_armadillo_story_event="";show_pinwheel_get=true
			_queue_armadillo_progress_event()
		"armadillo_7":
			if not armadillo_gift_series_id.is_empty():
				_unlock_series_and_register_encounters(armadillo_gift_series_id)
				if _register_species_discovery(armadillo_gift_species_id,true):acquired.append(armadillo_gift_species_id)
			armadillo_series_event_7_completed=true;pending_armadillo_story_event="";show_armadillo_gift=true
		"armadillo_mystery_intro":
			armadillo_research_intro_seen=true
		"puku_gauge_first_gift":
			puku_gauge_intro_complete=true;tutorial_steps["puku_gauge_intro_complete"]=true;_ensure_initial_puku_capital(true);shop_current_page="categories";_set_shop_purchase_visible(true)
		"collection_complete":
			finish_collection_complete=true
	_update_main_story_progress(false);_save();shop_overlay.visible=keep_shop
	if (habitat_crisis_pending or habitat_crisis_started) and finished_kind in ["jurejure_exploitation_challenge","act3_exploitation_battle_intro"]:
		show_jurejure_choice=false
		focus_act3_exploitation=false
	if finished_kind=="act3_intro" and current_mode=="habitat":_build_habitat_items(true)
	if keep_shop:
		armadillo_tap_button.visible=armadillo_present;_update_shop_ui()
		if show_pinwheel_get:call_deferred("_queue_species_get_by_id",HIDDEN_PINWHEEL_ID,true,"pinwheel_gift")
		elif show_armadillo_gift and not armadillo_gift_species_id.is_empty():call_deferred("_queue_species_get_by_id",armadillo_gift_species_id,true,"armadillo_gift")
	else:
		if finished_kind not in ["jurejure_intro","jurejure_challenge","jurejure_exploitation_challenge","restoration_epilogue","collection_complete"]:
			_play_current_area_bgm()
	_update_play_ui()
	if finish_collection_complete:call_deferred("_finish_collection_complete_presentation")
	elif start_habitat_crisis_travel:call_deferred("_transition_to_habitat_crisis")
	elif begin_restoration_join_habitat:call_deferred("_transition_to_restoration_habitat","join",0)
	elif restoration_return_stage>0:
		if start_restoration_join_after_return:
			call_deferred("_focus_jurejure_group","restoration_join")
		elif next_restoration_return_stage>0:
			if next_restoration_return_stage>=HabitatRestorationClass.REQUIRED_RETURNED_PLANTS:
				call_deferred("_transition_to_restoration_habitat","final_return",0)
			else:
				call_deferred("_transition_between_restoration_returns",next_restoration_return_stage)
		elif restoration_return_stage>=HabitatRestorationClass.REQUIRED_RETURNED_PLANTS:
			call_deferred("_begin_restoration_recovery_slides")
		else:call_deferred("_try_start_pending_story_event")
	elif start_restoration_epilogue:call_deferred("_start_restoration_epilogue_event")
	elif show_restoration_thank_you:
		call_deferred("_show_restoration_thank_you")
	elif focus_act3_exploitation:call_deferred("_focus_jurejure_group","act3_exploitation_start")
	elif start_trio_event:call_deferred("_start_trio_originals_event")
	elif start_jurejure_reveal:call_deferred("_focus_jurejure_first_encounter")
	elif guide_catalog:call_deferred("_show_tutorial_guide","encyclopedia")
	elif finished_kind=="initial_seed_stock":
		if _is_endless_greenhouse_enabled():call_deferred("_start_first_normal_sow_prompt")
		else:call_deferred("_show_tutorial_guide","play_open_normal")
	elif finished_kind=="first_normal_sow_prompt":
		if _is_endless_greenhouse_enabled():call_deferred("_show_tutorial_guide","play_open_normal")
		else:
			call_deferred("_open_play_modal");call_deferred("_show_tutorial_guide","normal_seed")
	elif finished_kind=="first_seed_pod_reward":
		if first_play_has_harvested and not puku_buyback_tutorial_complete:_start_puku_buyback_tutorial()
		else:call_deferred("_finish_greenhouse_play")
	elif show_jurejure_choice and puku_puku_battle:call_deferred("_show_jurejure_battle_choice")
	elif queue_jurejure_reward:
		var reward_species_id:=jurejure_pending_reward_species_id;var reward_is_new:=jurejure_pending_reward_is_new;jurejure_pending_reward_species_id="";jurejure_pending_reward_is_new=false;call_deferred("_queue_species_get_by_id",reward_species_id,reward_is_new,"jurejure_battle")
	elif show_arrangement_swipe_intro:call_deferred("_play_arrangement_swipe_intro")
	else:call_deferred("_try_start_pending_story_event")
	if finished_kind=="armadillo_mystery_intro" and mystery_seed_count>0:call_deferred("_show_shop_chatter",Localizer.text(language_code,"mystery_seed_request"),false,"research_offer","armadillo")
	if open_catalog:
		call_deferred("_open_encyclopedia")
	elif guide_habitat:
		call_deferred("_show_tutorial_guide","habitat")
	elif open_puku_intro:
		current_mode="greenhouse";_apply_mode();shop_overlay.visible=true
		call_deferred("_start_puku_gauge_intro_dialog")
	elif start_second_awakening:
		call_deferred("_start_habitat_second_awakening")

func _start_post_play_dialog(kind:String)->void:
	tutorial_dialog_kind=kind;_set_shop_purchase_visible(false);shop_overlay.visible=true;intro_overlay.visible=true;_set_intro_speaker("panda");_position_intro_dialog();intro_speaker_label.visible=true;play_overlay.visible=false;play_open_button.visible=false;_update_play_ui();audio_manager.play_bgm("shop")
	if kind=="play1":
		var tutorial_entry:=_catalog_entry(first_tutorial_species_id)
		_set_intro_speaker("");intro_speaker_label.visible=false;intro_dialogue_label.text=Localizer.text(language_code,"new")+"\n"+Localizer.species_name(language_code,tutorial_entry);intro_continue_button.text=Localizer.text(language_code,"continue")
	elif kind=="play2":intro_dialogue_label.text=Localizer.text(language_code,"tutorial_play2");intro_continue_button.text=Localizer.text(language_code,"main_greenhouse")
	else:intro_dialogue_label.text=Localizer.text(language_code,"tutorial_play3");intro_continue_button.text=Localizer.text(language_code,"main_habitat")

func _start_first_colorata_discovery_event()->void:
	if first_colorata_confirmed or not scripted_dialog_kind.is_empty():return
	var species_name:=Localizer.species_name(language_code,_catalog_entry(FIRST_STORY_SPECIES_ID))
	_start_scripted_dialog("first_colorata_discovery",[
		{"speaker":"panda","text":Localizer.text(language_code,"story_colorata_1")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"story_colorata_2",[species_name])},
		{"speaker":"panda","text":Localizer.text(language_code,"story_colorata_3")}
	],false)

func _start_trio_originals_event()->void:
	if trio_originals_confirmed or not first_colorata_confirmed or not scripted_dialog_kind.is_empty():return
	var panda_name:=Localizer.species_name(language_code,_catalog_entry(PANDA_STORY_SPECIES_ID))
	var armadillo_name:=Localizer.species_name(language_code,_catalog_entry(ARMADILLO_STORY_SPECIES_ID))
	_start_scripted_dialog("trio_originals",[
		{"speaker":"panda","text":Localizer.text(language_code,"story_trio_1",[panda_name]),"after_species_card":PANDA_STORY_SPECIES_ID},
		{"speaker":"armadillo","text":Localizer.text(language_code,"story_trio_2",[armadillo_name]),"after_species_card":ARMADILLO_STORY_SPECIES_ID},
		{"speaker":"armadillo","text":Localizer.text(language_code,"story_trio_3")},
		{"speaker":"girl","text":Localizer.text(language_code,"story_trio_4")},
		{"speaker":"panda","text":Localizer.text(language_code,"story_trio_5")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"story_habitat_found_1")},
		{"speaker":"panda","text":Localizer.text(language_code,"story_habitat_found_2"),"button":Localizer.text(language_code,"main_habitat")}
	],false)

func _start_seed_pod_story()->void:
	if mystery_items_acquired or not habitat_tutorial_complete or seed_pod_story_overlay==null or not scripted_dialog_kind.is_empty():return
	current_mode="habitat";_apply_mode()
	seed_pod_story_overlay.start(language_code)
	_update_play_ui()

func _on_seed_pod_story_finished()->void:
	tutorial_steps["seed_pod_story_seen"]=true;tutorial_steps["puku_gauge_intro_complete"]=true
	mystery_items_acquired=true;encyclopedia_unlocked=true;seed_shop_open=true;original_catalog_gifted=true;puku_gauge_intro_complete=true
	_ensure_initial_puku_capital(true)
	habitat_tutorial_returned_to_greenhouse=true;unlocked_series[ORIGINAL_SERIES_ID]=true
	if scene_transition_fade:
		scene_transition_fade.color.a=1.0;scene_transition_fade.visible=true;scene_transition_fade.move_to_front()
	seed_pod_story_overlay.visible=false
	current_mode="greenhouse";_apply_mode();_save();_update_play_ui()
	await get_tree().process_frame
	if scene_transition_fade:
		var greenhouse_fade:=create_tween();greenhouse_fade.tween_property(scene_transition_fade,"color:a",0.0,.78).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await greenhouse_fade.finished
		scene_transition_fade.visible=false
	_start_habitat_return_dialog()

func _start_habitat_return_dialog()->void:
	if habitat_return_dialog_seen or not mystery_items_acquired or not scripted_dialog_kind.is_empty():return
	_start_scripted_dialog("habitat_return",[
		{"speaker":"panda","text":Localizer.text(language_code,"habitat_return_panda")},
		{"speaker":"girl","text":Localizer.text(language_code,"habitat_return_girl_1")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"habitat_return_armadillo_1")},
		{"speaker":"girl","text":Localizer.text(language_code,"habitat_return_girl_2")},
		{"speaker":"girl","text":Localizer.text(language_code,"habitat_return_armadillo_2")}
	],false)

func _start_initial_seed_stock_notice()->void:
	if normal_play_tutorial_complete:return
	if initial_seed_stock_notice_complete:
		if _is_endless_greenhouse_enabled():
			_claim_first_habitat_gift_once()
			if _endless_auto_sow_prompt_seen():call_deferred("_ensure_endless_greenhouse_running")
			else:call_deferred("_start_first_normal_sow_prompt")
		else:call_deferred("_show_tutorial_guide","play_open_normal")
		return
	if _is_endless_greenhouse_enabled():
		_start_scripted_dialog("initial_seed_stock",[
			{"speaker":"girl","text":Localizer.text(language_code,"initial_seed_stock_endless_girl")},
			{"speaker":"armadillo","text":Localizer.text(language_code,"initial_seed_stock_endless_armadillo")}
		],false)
		return
	_start_scripted_dialog("initial_seed_stock",[
		{"speaker":"girl","text":Localizer.text(language_code,"initial_seed_stock_girl")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"initial_seed_stock_armadillo")},
		{"speaker":"","text":Localizer.text(language_code,"initial_seed_stock_received"),"button":Localizer.text(language_code,"continue")}
	],false)

func _start_first_normal_sow_prompt()->void:
	if normal_play_tutorial_complete or not scripted_dialog_kind.is_empty():return
	play_modal_open=false
	if play_overlay:play_overlay.visible=false
	var text_key:="tutorial_normal_pre_sow_endless" if _is_endless_greenhouse_enabled() else "tutorial_normal_pre_sow"
	_start_scripted_dialog("first_normal_sow_prompt",[
		{"speaker":"girl","text":Localizer.text(language_code,text_key)}
	],false)

func _start_mystery_catalog_tutorial()->void:
	if not mystery_items_acquired or mystery_catalog_tutorial_complete or not scripted_dialog_kind.is_empty():return
	current_mode="greenhouse";_apply_mode();_update_play_ui()
	if not habitat_return_dialog_seen:
		_start_habitat_return_dialog()
		return
	_start_scripted_dialog("mystery_catalog_prompt",[
		{"speaker":"armadillo","text":Localizer.text(language_code,"mystery_catalog_prompt")}
	],false)

func _start_mystery_catalog_tutorial_dialog()->void:
	if not mystery_items_acquired or mystery_catalog_tutorial_complete or not scripted_dialog_kind.is_empty():return
	_start_scripted_dialog("mystery_catalog_tutorial",[
		{"speaker":"armadillo","text":Localizer.text(language_code,"mystery_catalog_tutorial_1")},
		{"speaker":"girl","text":Localizer.text(language_code,"mystery_catalog_tutorial_2")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"mystery_catalog_tutorial_3")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"mystery_catalog_tutorial_4")}
	],false)

func _start_special_origin_event()->void:
	if special_series_explanation_seen or not pending_special_series_explanation or not scripted_dialog_kind.is_empty():return
	_start_scripted_dialog("special_origin",[
		{"speaker":"armadillo","text":Localizer.text(language_code,"special_origin_1")},
		{"speaker":"panda","text":Localizer.text(language_code,"special_origin_2")},
		{"speaker":"panda","text":Localizer.text(language_code,"special_origin_3")}
	],false)

func _start_original_catalog_complete_event()->void:
	if original_catalog_complete_event_seen or not StoryProgressionClass.originals_complete(discovered) or not scripted_dialog_kind.is_empty():return
	_start_scripted_dialog("original_catalog_complete",[
		{"speaker":"panda","text":Localizer.text(language_code,"story_complete_1")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"story_complete_2")},
		{"speaker":"panda","text":Localizer.text(language_code,"story_complete_3")},
		{"speaker":"","text":Localizer.text(language_code,"original_catalog_complete_4")}
	],false)

func _start_jurejure_intro_event()->void:
	if jurejure_intro_complete or not habitat_tutorial_returned_to_greenhouse or current_mode!="habitat" or not scripted_dialog_kind.is_empty():return
	_start_scripted_dialog("jurejure_intro",[
		{"speaker":"armadillo","text":Localizer.text(language_code,"jurejure_confront_armadillo")},
		{"speaker":"peccary","text":Localizer.text(language_code,"jurejure_confront_peccary")},
		{"speaker":"girl","text":Localizer.text(language_code,"jurejure_confront_girl_1")},
		{"speaker":"skunk","text":Localizer.text(language_code,"jurejure_confront_skunk")},
		{"speaker":"mouse","text":Localizer.text(language_code,"jurejure_confront_mouse_panda")},
		{"speaker":"panda","text":Localizer.text(language_code,"jurejure_confront_panda")},
		{"speaker":"girl","text":Localizer.text(language_code,"jurejure_confront_girl_2")},
		{"speaker":"mouse","text":Localizer.text(language_code,"jurejure_confront_mouse_battle")}
	],false)

func _start_jurejure_first_encounter()->void:
	if jurejure_intro_complete or jurejure_first_encounter_active or current_mode!="habitat" or not _should_show_jurejure_group() or not scripted_dialog_kind.is_empty():return
	jurejure_first_encounter_active=true
	_start_scripted_dialog("jurejure_first_notice",[
		{"speaker":"panda","text":Localizer.text(language_code,"jurejure_first_notice")}
	],false)

func _focus_jurejure_first_encounter()->void:
	_focus_jurejure_group("first_encounter")

func _focus_jurejure_group(context:String)->void:
	if current_mode!="habitat":
		if context=="first_encounter":jurejure_first_encounter_active=false
		return
	jurejure_focused_habitat_visit_id=habitat_visit_id
	if context=="first_encounter" and jurejure_intro_complete:
		jurejure_first_encounter_active=false
		return
	var group_node:Node3D
	for item in habitat_pickups:
		if str(item.get("kind",""))=="jurejure_group":
			group_node=item.get("group_node") as Node3D
			break
	if not is_instance_valid(group_node):
		if context=="first_encounter":
			jurejure_first_encounter_active=false;_start_jurejure_intro_event()
		elif context=="habitat_crisis":_begin_habitat_crisis_dialog()
		elif context=="act3_intro":_start_act3_intro_event()
		elif context=="act3_exploitation_start":_start_act3_exploitation_battle_intro_event()
		elif context=="exploitation_midpoint":_start_exploitation_midpoint_event()
		elif context=="restoration_join":_start_restoration_join_habitat_event()
		return
	var target:=group_node.global_position
	jurejure_intro_camera_start_yaw=view_yaw
	jurejure_intro_camera_target_yaw=JureJureSystemClass.focus_yaw(view_yaw,target)
	jurejure_camera_focus_context=context;jurejure_intro_camera_elapsed=0.0;jurejure_intro_camera_active=true
	pointer_down=false;greenhouse_drag_accumulator=0.0;greenhouse_drag_started=false
	jurejure_focused_habitat_visit_id=habitat_visit_id
	_update_play_ui()

func _restoration_returned_plant_node(stage:int)->Node3D:
	if habitat_items_root==null or stage<1:return null
	return habitat_items_root.get_node_or_null("RestorationMedalPlant%d"%stage) as Node3D

func _focus_restoration_returned_plant(stage:int,immediate:=false)->bool:
	if current_mode!="habitat":return false
	var plant_node:=_restoration_returned_plant_node(stage)
	if not is_instance_valid(plant_node):return false
	var focus_yaw:=JureJureSystemClass.focus_yaw(view_yaw,plant_node.global_position)
	pointer_down=false;greenhouse_drag_accumulator=0.0;greenhouse_drag_started=false
	if immediate:
		view_yaw=focus_yaw;view_pitch=-3.0;habitat_target_yaw=view_yaw;habitat_target_pitch=view_pitch;_apply_view_rotation()
		return true
	jurejure_intro_camera_start_yaw=view_yaw;jurejure_intro_camera_target_yaw=focus_yaw
	jurejure_camera_focus_context="restoration_return_%d"%stage;jurejure_intro_camera_elapsed=0.0;jurejure_intro_camera_active=true
	return true

func _show_jurejure_first_encounter_still()->void:
	if jurejure_intro_complete or current_mode!="habitat":
		jurejure_first_encounter_active=false
		return
	await get_tree().create_timer(.18).timeout
	if jurejure_first_encounter_overlay:jurejure_first_encounter_overlay.start(language_code)

func _on_jurejure_first_encounter_still_finished()->void:
	jurejure_first_encounter_active=false
	_start_jurejure_intro_event()

func _start_jurejure_challenge_event()->void:
	if not jurejure_intro_complete or current_mode!="habitat" or not scripted_dialog_kind.is_empty():return
	if habitat_crisis_pending or habitat_crisis_started:return
	if StoryProgressionClass.exploitation_is_started(story_progression_state):
		var pattern:=JureJureSystemClass.choose_exploitation_dialog(int(story_progression_state.get("last_exploitation_dialog_index",-1)),rng)
		story_progression_state["last_exploitation_dialog_index"]=int(pattern.get("index",-1))
		var exploitation_pages:=_localized_jurejure_pattern_pages(pattern)
		if not exploitation_pages.is_empty():
			_start_scripted_dialog("jurejure_exploitation_challenge",exploitation_pages,false)
			return
	_start_scripted_dialog("jurejure_challenge",[
		{"speaker":"mouse","text":Localizer.text(language_code,"jurejure_challenge_1")},
		{"speaker":"mouse","text":Localizer.text(language_code,"jurejure_challenge_2")}
	],false)

func _localized_jurejure_pattern_pages(pattern:Dictionary)->Array:
	var pages:Array=[]
	for raw_page in pattern.get("pages",[]):
		if raw_page is Dictionary:pages.append({"speaker":str(raw_page.get("speaker","")),"text":Localizer.text(language_code,str(raw_page.get("text_key","")))})
	return pages

func _start_jurejure_growth_event(stage:int)->void:
	# Act I keeps the gang consistently selfish. Legacy MID/LATE story masks are
	# retained only for save compatibility and never schedule dialogue.
	if stage>=JureJureSystemClass.GROWTH_MID:jurejure_growth_event_mask|=1
	if stage>=JureJureSystemClass.GROWTH_LATE:jurejure_growth_event_mask|=2

func _start_jurejure_return_event()->void:
	# Compatibility entry point for older call sites. The gang's return is no
	# longer a prerequisite; restored originals awaken the habitat directly.
	_start_habitat_second_awakening()

func _start_habitat_second_awakening()->void:
	if habitat_second_awakened or habitat_second_awakening_overlay==null:return
	if not habitat_awakened or not original_catalog_complete_event_seen or not StoryProgressionClass.originals_complete(discovered):return
	if current_mode!="habitat" or not scripted_dialog_kind.is_empty():return
	habitat_second_awakening_overlay.start(language_code)

func _on_habitat_second_awakening_finished()->void:
	if habitat_second_awakened:return
	habitat_second_awakened=true;habitat_second_awakening_complete=true
	main_story_complete=true;main_story_completion_seen=true;special_series_explanation_seen=true;pending_special_series_explanation=false
	jurejure_growth_stage=JureJureSystemClass.GROWTH_LATE
	_register_encountered_species_for_unlocked_series()
	_update_main_story_progress(false);_save();_apply_saved_unlocks();_build_habitat_items(true);_update_play_ui()

func _start_first_habitat_tutorial()->void:
	if not habitat_awakened or habitat_tutorial_complete or not scripted_dialog_kind.is_empty():return
	var habitat_result:=_ensure_habitat_wild_state()
	if bool(habitat_result.get("population_changed",false)):_build_habitat_items(true)
	tutorial_habitat_item={};habitat_tutorial_started=true;habitat_tutorial_complete=true
	for habitat_plant in habitat_wild_plants:
		habitat_plant["tutorial"]=false;habitat_plant["jelly_immune"]=false
	tutorial_steps["habitat_observation_intro"]=true
	_update_main_story_progress(false);_save();_update_play_ui();call_deferred("_start_seed_pod_story")

func _start_habitat_awakening_event()->void:
	if habitat_awakened or not trio_originals_confirmed or habitat_awakening_overlay==null:return
	habitat_arrival_started=true;_update_main_story_progress(false);_save()
	current_mode="habitat"
	_cancel_all_habitat_notifications()
	habitat_wild_plants.clear();habitat_wild_initialized=false;habitat_wild_next_spawn_unix=0.0
	_clear_habitat_items();_apply_mode();_update_play_ui();_play_current_area_bgm()
	habitat_awakening_overlay.start(language_code)

func _on_habitat_awakening_finished()->void:
	if habitat_awakened:return
	habitat_awakened=true;habitat_awakening_event_complete=true
	# Every species legitimately restored before this moment is now part of the
	# permanent settlement pool; the trio are added as the story exception.
	_migrate_habitat_settlement()
	var now_unix:=Time.get_unix_time_from_system()
	var awakening_species:Array[String]=[FIRST_STORY_SPECIES_ID,PANDA_STORY_SPECIES_ID,ARMADILLO_STORY_SPECIES_ID]
	HabitatWildSystemClass.initialize_awakened_population(habitat_wild_plants,awakening_species,awakening_species,now_unix,rng,HABITAT_SAFE_PLANT_POINTS)
	habitat_wild_initialized=true;habitat_wild_next_spawn_unix=HabitatWildSystemClass.next_spawn_unix(now_unix,rng,habitat_wild_plants.size())
	_refresh_habitat_growth_profiles();_update_main_story_progress(false);_save();_build_habitat_items(true)
	call_deferred("_start_first_habitat_tutorial")

func _start_puku_gauge_intro_dialog()->void:
	if puku_gauge_intro_complete:return
	_start_scripted_dialog("puku_gauge_first_gift",[
		{"speaker":"panda","text":Localizer.text(language_code,"puku_intro_1")},
		{"speaker":"panda","text":Localizer.text(language_code,"puku_intro_2")},
		{"speaker":"","text":Localizer.text(language_code,"puku_buyback_2_endless"),"button":Localizer.text(language_code,"continue")}
	],true)

func _claim_first_habitat_gift_once()->void:
	if first_habitat_gift_claimed:return
	first_habitat_gift_claimed=true
	if not _is_endless_greenhouse_enabled():normal_seed_bags+=1
	_save();_update_currency_ui();_update_play_ui();audio_manager.play_se("daily",.62)

func _start_puku_gauge_intro_after_greenhouse_frame()->void:
	await get_tree().process_frame
	_start_puku_gauge_intro_dialog()

func _build_tutorial_guide(hud:Control)->void:
	tutorial_guide_overlay=Control.new();tutorial_guide_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);tutorial_guide_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;tutorial_guide_overlay.visible=false;hud.add_child(tutorial_guide_overlay)
	tutorial_guide_shade=ColorRect.new();tutorial_guide_shade.color=Color(0.05,0.035,0.025,.72);tutorial_guide_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);tutorial_guide_shade.mouse_filter=Control.MOUSE_FILTER_STOP;tutorial_guide_overlay.add_child(tutorial_guide_shade)
	var spotlight_shader:=Shader.new();spotlight_shader.code="""shader_type canvas_item;
uniform int focus_count = 0;
uniform vec2 focus_uv_a = vec2(0.5, 0.5);
uniform vec2 focus_uv_b = vec2(0.5, 0.5);
uniform vec2 focus_uv_c = vec2(0.5, 0.5);
uniform float focus_radius_a = 0.11;
uniform float focus_radius_b = 0.11;
uniform float focus_radius_c = 0.11;
uniform float viewport_aspect = 0.5625;
uniform bool focus_ellipse = false;
uniform vec2 focus_half_size_uv = vec2(0.15, 0.035);
void fragment(){
	float shade=1.0;
	if(focus_count>0){
		if(focus_ellipse){
			vec2 ellipse_offset=(UV-focus_uv_a)/max(focus_half_size_uv,vec2(0.001));
			shade=min(shade,smoothstep(0.76,1.0,length(ellipse_offset)));
		}else{
			vec2 offset=UV-focus_uv_a;
			shade=min(shade,smoothstep(focus_radius_a*0.58,focus_radius_a,length(vec2(offset.x*viewport_aspect,offset.y))));
		}
	}
	if(focus_count>1){
		vec2 offset=UV-focus_uv_b;
		shade=min(shade,smoothstep(focus_radius_b*0.58,focus_radius_b,length(vec2(offset.x*viewport_aspect,offset.y))));
	}
	if(focus_count>2){
		vec2 offset=UV-focus_uv_c;
		shade=min(shade,smoothstep(focus_radius_c*0.58,focus_radius_c,length(vec2(offset.x*viewport_aspect,offset.y))));
	}
	float shade_alpha=COLOR.a*shade;
	COLOR=vec4(COLOR.rgb,shade_alpha);
}""";first_play_harvest_spotlight_material=ShaderMaterial.new();first_play_harvest_spotlight_material.shader=spotlight_shader
	tutorial_guide_button=Button.new();tutorial_guide_button.pivot_offset=Vector2(50,35);tutorial_guide_overlay.add_child(tutorial_guide_button)
	tutorial_dialog_panel=PanelContainer.new();tutorial_dialog_panel.position=Vector2(40,790);tutorial_dialog_panel.size=Vector2(496,190);tutorial_dialog_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;tutorial_dialog_panel.add_theme_stylebox_override("panel",_box(Color(0.97,0.90,0.75,.97),Color("#a86f36"),24,4));tutorial_dialog_panel.visible=false;tutorial_guide_overlay.add_child(tutorial_dialog_panel)
	var tutorial_row:=HBoxContainer.new();tutorial_row.alignment=BoxContainer.ALIGNMENT_CENTER;tutorial_row.add_theme_constant_override("separation",12);tutorial_row.mouse_filter=Control.MOUSE_FILTER_IGNORE;tutorial_dialog_panel.add_child(tutorial_row)
	tutorial_panda_portrait=TextureRect.new();tutorial_panda_portrait.texture=_panda_portrait_texture();tutorial_panda_portrait.custom_minimum_size=Vector2(126,164);tutorial_panda_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;tutorial_panda_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;tutorial_panda_portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE;tutorial_row.add_child(tutorial_panda_portrait)
	tutorial_guide_message=Label.new();tutorial_guide_message.custom_minimum_size=Vector2(330,150);tutorial_guide_message.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tutorial_guide_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;tutorial_guide_message.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;tutorial_guide_message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;tutorial_guide_message.add_theme_font_size_override("font_size",22);tutorial_guide_message.add_theme_color_override("font_color",UI_BROWN);tutorial_guide_message.mouse_filter=Control.MOUSE_FILTER_IGNORE;tutorial_row.add_child(tutorial_guide_message)
	tutorial_cost_note_panel=PanelContainer.new();tutorial_cost_note_panel.name="FirstNormalCostNote";tutorial_cost_note_panel.position=Vector2(118,418);tutorial_cost_note_panel.size=Vector2(340,64);tutorial_cost_note_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;tutorial_cost_note_panel.add_theme_stylebox_override("panel",_box(Color("#fff4cd"),Color("#d28a2d"),16,3));tutorial_cost_note_panel.visible=false;tutorial_guide_overlay.add_child(tutorial_cost_note_panel)
	tutorial_cost_note_label=Label.new();tutorial_cost_note_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;tutorial_cost_note_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;tutorial_cost_note_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;tutorial_cost_note_label.add_theme_font_size_override("font_size",18);tutorial_cost_note_label.add_theme_color_override("font_color",UI_BROWN);tutorial_cost_note_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;tutorial_cost_note_panel.add_child(tutorial_cost_note_label)

func _mirror_habitat_tutorial_button(source:Button)->void:
	# Habitat is intentionally not pulsed: it must remain the exact same runtime
	# rect as the real navigation button. Stop any tween left by the preceding
	# guide before reusing this shared overlay button.
	if tutorial_highlight_tween and tutorial_highlight_tween.is_valid():tutorial_highlight_tween.kill()
	tutorial_highlight_tween=null
	tutorial_guide_button.scale=Vector2.ONE;tutorial_guide_button.rotation=0.0;tutorial_guide_button.self_modulate=Color.WHITE
	tutorial_guide_button.anchor_left=0.0;tutorial_guide_button.anchor_top=0.0;tutorial_guide_button.anchor_right=0.0;tutorial_guide_button.anchor_bottom=0.0
	tutorial_guide_button.custom_minimum_size=Vector2.ZERO
	tutorial_guide_button.text=source.text;tutorial_guide_button.alignment=source.alignment;tutorial_guide_button.clip_text=source.clip_text;tutorial_guide_button.text_overrun_behavior=source.text_overrun_behavior
	for state in ["normal","hover","pressed","disabled","focus"]:
		var source_style:=source.get_theme_stylebox(state)
		if source_style:tutorial_guide_button.add_theme_stylebox_override(state,source_style.duplicate())
	tutorial_guide_button.add_theme_font_size_override("font_size",source.get_theme_font_size("font_size"))
	for color_name in ["font_color","font_hover_color","font_pressed_color","font_disabled_color","font_focus_color"]:
		tutorial_guide_button.add_theme_color_override(color_name,source.get_theme_color(color_name))
	var overlay_inverse:=tutorial_guide_overlay.get_global_transform_with_canvas().affine_inverse()
	var source_transform:=source.get_global_transform_with_canvas()
	var local_top_left:=overlay_inverse*(source_transform*Vector2.ZERO)
	var local_bottom_right:=overlay_inverse*(source_transform*source.size)
	tutorial_guide_button.position=local_top_left;tutorial_guide_button.size=local_bottom_right-local_top_left;tutorial_guide_button.pivot_offset=tutorial_guide_button.size*.5

func _show_tutorial_guide(target:String)->void:
	var source:Button
	if target=="encyclopedia":source=encyclopedia_icon_button
	elif target=="habitat":source=mode_button
	elif target in ["play_open","play_open_normal"]:source=play_open_button
	elif target=="old_seed":source=old_seed_play_button
	elif target=="normal_seed":source=normal_play_button
	else:return
	_prepare_standard_tutorial_guide();tutorial_guide_button.icon=null;tutorial_guide_button.expand_icon=false;tutorial_dialog_panel.visible=false
	if target=="habitat":
		_mirror_habitat_tutorial_button(source)
	else:
		tutorial_guide_button.position=source.global_position;tutorial_guide_button.custom_minimum_size=source.size;tutorial_guide_button.size=source.size;tutorial_guide_button.text=source.text;_skin_button(tutorial_guide_button,Color("#fff0cf"),17 if target=="encyclopedia" else 15)
	tutorial_guide_button.set_meta("target",target)
	for connection in tutorial_guide_button.pressed.get_connections():tutorial_guide_button.pressed.disconnect(connection.callable)
	tutorial_guide_button.pressed.connect(_complete_tutorial_guide)
	tutorial_guide_overlay.visible=true
	if target=="play_open_normal" and not bool(tutorial_steps.get("first_normal_cost_notice_seen",false)):
		tutorial_cost_note_label.text=Localizer.text(language_code,"first_normal_cost_notice")
		tutorial_cost_note_panel.visible=true
		tutorial_steps["first_normal_cost_notice_seen"]=true
		_save()
	if target!="habitat":_start_tutorial_target_pulse(tutorial_guide_button,Color(1.25,1.18,.7,1))

func _prepare_standard_tutorial_guide()->void:
	tutorial_guide_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;tutorial_guide_shade.mouse_filter=Control.MOUSE_FILTER_STOP;tutorial_guide_shade.material=null;tutorial_guide_shade.color=Color(0.05,0.035,0.025,.72)
	if tutorial_cost_note_panel:tutorial_cost_note_panel.visible=false
	first_play_harvest_spotlight_material.set_shader_parameter("focus_ellipse",false)
	tutorial_guide_button.visible=true;tutorial_guide_button.mouse_filter=Control.MOUSE_FILTER_STOP;tutorial_guide_button.flat=false;tutorial_guide_button.focus_mode=Control.FOCUS_ALL

func _start_tutorial_target_pulse(target:Control,glow_color:Color)->void:
	if tutorial_highlight_tween and tutorial_highlight_tween.is_valid():tutorial_highlight_tween.kill()
	target.pivot_offset=target.size*.5;target.scale=Vector2.ONE;target.self_modulate=Color.WHITE
	tutorial_highlight_tween=create_tween().set_loops()
	tutorial_highlight_tween.tween_property(target,"scale",Vector2(1.045,1.045),.46).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tutorial_highlight_tween.parallel().tween_property(target,"self_modulate",glow_color,.46).set_trans(Tween.TRANS_SINE)
	tutorial_highlight_tween.tween_property(target,"scale",Vector2.ONE,.46).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tutorial_highlight_tween.parallel().tween_property(target,"self_modulate",Color.WHITE,.46).set_trans(Tween.TRANS_SINE)

func _complete_tutorial_guide()->void:
	if tutorial_highlight_tween and tutorial_highlight_tween.is_valid():tutorial_highlight_tween.kill()
	tutorial_highlight_tween=null;tutorial_guide_button.self_modulate=Color.WHITE;tutorial_guide_button.scale=Vector2.ONE
	var target:=str(tutorial_guide_button.get_meta("target",""));tutorial_guide_overlay.visible=false
	if tutorial_cost_note_panel:tutorial_cost_note_panel.visible=false
	tutorial_steps[target+"_guide"]=true;_save()
	if target=="encyclopedia":
		_open_encyclopedia()
		if mystery_items_acquired and not mystery_catalog_tutorial_complete:
			encyclopedia_scroll.scroll_vertical=560
			call_deferred("_start_mystery_catalog_tutorial_dialog")
	elif target=="habitat":_toggle_mode()
	elif target=="play_open":
		_open_play_modal()
		if not play_active:call_deferred("_show_tutorial_guide","old_seed")
	elif target=="play_open_normal":
		_start_greenhouse_play("normal")
	elif target=="old_seed":_start_greenhouse_play("old")
	elif target=="normal_seed":_start_greenhouse_play("normal")

func _begin_first_play_tutorial()->void:
	first_play_tutorial_active=true;first_play_tutorial_dialog_visible=false;first_play_tutorial_message_index=0;first_play_tutorial_wait_remaining=FIRST_PLAY_TUTORIAL_INITIAL_DELAY;first_play_tutorial_sequence_complete=false;first_play_tutorial_phase="growth_dialogs";first_play_harvest_guide_active=false;old_seed_harvest_guide_active=false;first_play_has_harvested=false;tutorial_harvest_plant=null
	first_play_tutorial_reserved_plant=null;first_play_tutorial_forced_jelly_plant=null;first_play_tutorial_observe_remaining=0.0
	var original_candidates:=_first_play_tutorial_original_candidates()
	first_play_tutorial_reserved_species_id=""
	if not original_candidates.is_empty():first_play_tutorial_reserved_species_id=str(original_candidates[rng.randi_range(0,original_candidates.size()-1)].get("species_id",""))
	first_play_tutorial_reserved_seed_pending=not first_play_tutorial_reserved_species_id.is_empty()
	_hide_first_play_tutorial_overlay()

func _update_first_play_tutorial(delta:float)->bool:
	if not first_play_tutorial_active or not play_active:return false
	if first_play_harvest_guide_active:
		_update_first_play_harvest_guide_focus()
		return true
	if first_play_tutorial_dialog_visible:return true
	if first_play_tutorial_phase=="jelly_observe":
		first_play_tutorial_observe_remaining=maxf(0.0,first_play_tutorial_observe_remaining-delta)
		if first_play_tutorial_observe_remaining<=0.0:
			first_play_tutorial_phase="jelly_reaction"
			_show_first_play_tutorial_custom_dialog("tutorial_normal_jellied","panda")
		return true
	if first_play_tutorial_phase=="reserved_seed_sowing":return true
	if first_play_tutorial_phase=="reserved_seed_observe":
		first_play_tutorial_observe_remaining=maxf(0.0,first_play_tutorial_observe_remaining-delta)
		if first_play_tutorial_observe_remaining<=0.0:
			first_play_tutorial_phase="new_species_panda"
			_show_first_play_tutorial_custom_dialog("tutorial_normal_new_panda","panda")
			return true
		# This is observation time, not a pause: keep normal growth simulation and
		# visual updates running while the player watches the NEW plant.
		return false
	if first_play_tutorial_phase=="forcing_jelly":return true
	if first_play_tutorial_sequence_complete:
		_maybe_activate_first_play_harvest_guide()
		return first_play_harvest_guide_active
	first_play_tutorial_wait_remaining=maxf(0.0,first_play_tutorial_wait_remaining-delta)
	if first_play_tutorial_wait_remaining<=0.0 and _first_play_tutorial_stage_ready():
		_show_first_play_tutorial_dialog()
		return true
	return false

func _first_play_tutorial_stage_ready()->bool:
	var max_diameter:=0.0
	for plant in _first_play_growing_plants():max_diameter=maxf(max_diameter,float(plant.diameter_cm))
	if first_play_tutorial_message_index==0:return max_diameter>1.6
	if first_play_tutorial_message_index==1:return max_diameter>=FIRST_PLAY_TUTORIAL_GROWTH_DIALOG_CM
	if first_play_tutorial_message_index==2:return max_diameter>=FIRST_PLAY_TUTORIAL_JELLY_DIALOG_CM
	return false

func _show_first_play_tutorial_dialog()->void:
	if first_play_tutorial_message_index<0 or first_play_tutorial_message_index>=FIRST_PLAY_TUTORIAL_MESSAGE_KEYS.size():return
	_show_first_play_tutorial_custom_dialog(str(FIRST_PLAY_TUTORIAL_MESSAGE_KEYS[first_play_tutorial_message_index]),str(FIRST_PLAY_TUTORIAL_SPEAKERS[first_play_tutorial_message_index]))

func _show_first_play_tutorial_custom_dialog(message_key:String,speaker_id:String)->void:
	first_play_tutorial_dialog_visible=true;tutorial_harvest_plant=null
	_set_tutorial_dialog_system_style(false)
	if tutorial_highlight_tween and tutorial_highlight_tween.is_valid():tutorial_highlight_tween.kill()
	tutorial_highlight_tween=null;tutorial_guide_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;tutorial_guide_shade.mouse_filter=Control.MOUSE_FILTER_STOP;tutorial_guide_shade.material=null;tutorial_guide_shade.color=Color(0.035,0.025,0.02,.34)
	tutorial_guide_button.visible=true;tutorial_guide_button.mouse_filter=Control.MOUSE_FILTER_STOP;tutorial_guide_button.position=Vector2.ZERO;tutorial_guide_button.size=get_viewport().get_visible_rect().size;tutorial_guide_button.text="";tutorial_guide_button.icon=null;tutorial_guide_button.expand_icon=false;tutorial_guide_button.flat=true;tutorial_guide_button.focus_mode=Control.FOCUS_NONE;tutorial_guide_button.set_meta("target","first_play_dialog")
	var empty_style:=StyleBoxEmpty.new()
	for state in ["normal","hover","pressed","disabled","focus"]:tutorial_guide_button.add_theme_stylebox_override(state,empty_style)
	for connection in tutorial_guide_button.pressed.get_connections():tutorial_guide_button.pressed.disconnect(connection.callable)
	tutorial_guide_button.pressed.connect(_dismiss_first_play_tutorial_dialog);tutorial_panda_portrait.texture=_speaker_portrait_texture(speaker_id);tutorial_panda_portrait.visible=true;tutorial_guide_message.text=Localizer.text(language_code,message_key);tutorial_dialog_panel.visible=true;tutorial_dialog_panel.position=Vector2(40,790);tutorial_guide_overlay.visible=true

func _dismiss_first_play_tutorial_dialog()->void:
	if not first_play_tutorial_dialog_visible:return
	if first_play_tutorial_phase=="jelly_reaction":
		first_play_tutorial_dialog_visible=false;_hide_first_play_tutorial_overlay();_sow_first_play_tutorial_reserved_seed();return
	if first_play_tutorial_phase=="new_species_panda":
		first_play_tutorial_phase="new_species_girl";_show_first_play_tutorial_custom_dialog("tutorial_normal_new_girl","girl");return
	if first_play_tutorial_phase=="new_species_girl":
		first_play_tutorial_dialog_visible=false;_hide_first_play_tutorial_overlay();_activate_first_play_tutorial_new_harvest_guide();return
	first_play_tutorial_message_index+=1
	if first_play_tutorial_message_index>=FIRST_PLAY_TUTORIAL_MESSAGE_KEYS.size():
		first_play_tutorial_dialog_visible=false;_hide_first_play_tutorial_overlay()
		if first_play_tutorial_reserved_seed_pending:
			first_play_tutorial_phase="forcing_jelly";call_deferred("_force_first_play_tutorial_jelly")
		else:_complete_first_play_tutorial_dialog_sequence()
	else:
		first_play_tutorial_dialog_visible=false;first_play_tutorial_wait_remaining=.20;_hide_first_play_tutorial_overlay()

func _complete_first_play_tutorial_dialog_sequence()->void:
	first_play_tutorial_sequence_complete=true;first_play_tutorial_phase="harvest_guide";tutorial_steps["first_play_growth_dialogs"]=true;_save()
	_maybe_activate_first_play_harvest_guide()
	if play_active and play_seeds_remaining==0 and play_spawn_queue==0 and play_seed_animations_pending==0 and plants.is_empty():call_deferred("_finish_greenhouse_play")

func _force_first_play_tutorial_jelly()->void:
	if not first_play_tutorial_active or not play_active:return
	var growing:=_first_play_growing_plants()
	if growing.is_empty():
		_complete_first_play_tutorial_dialog_sequence();return
	first_play_tutorial_forced_jelly_plant=growing[0]
	first_play_tutorial_forced_jelly_plant.set_meta("first_tutorial_forced_jelly",true)
	first_play_tutorial_forced_jelly_plant.jelly_checks_enabled=false
	first_play_tutorial_phase="jelly_observe";first_play_tutorial_observe_remaining=FIRST_PLAY_TUTORIAL_JELLY_OBSERVE_SECONDS
	first_play_tutorial_forced_jelly_plant.jelly()

func _sow_first_play_tutorial_reserved_seed()->void:
	if not first_play_tutorial_active or not play_active:return
	var entry:=_catalog_entry(first_play_tutorial_reserved_species_id)
	if entry.is_empty() or play_seeds_remaining<=0:
		first_play_tutorial_reserved_seed_pending=false;_complete_first_play_tutorial_dialog_sequence();return
	opening_species.push_front(entry)
	first_play_tutorial_phase="reserved_seed_sowing"
	var spawn_position:=_find_spawn_position(null,true)
	if _spawn_greenhouse_seed(true,spawn_position):
		first_play_tutorial_reserved_seed_pending=false
	else:
		opening_species.pop_front();first_play_tutorial_reserved_seed_pending=false;_complete_first_play_tutorial_dialog_sequence()

func _mark_first_play_tutorial_reserved_plant(plant)->void:
	if not first_play_tutorial_active or first_play_tutorial_phase!="reserved_seed_sowing" or not is_instance_valid(plant):return
	if str(plant.data.get("species_id",""))!=first_play_tutorial_reserved_species_id:return
	first_play_tutorial_reserved_plant=plant;plant.set_meta("first_tutorial_reserved_new",true);plant.jelly_checks_enabled=false
	first_play_tutorial_phase="reserved_seed_observe";first_play_tutorial_observe_remaining=FIRST_PLAY_TUTORIAL_NEW_OBSERVE_SECONDS

func _activate_first_play_tutorial_new_harvest_guide()->void:
	if not is_instance_valid(first_play_tutorial_reserved_plant) or first_play_tutorial_reserved_plant.state!="growing":
		_complete_first_play_tutorial_dialog_sequence();return
	first_play_tutorial_sequence_complete=true;first_play_tutorial_phase="harvest_guide";tutorial_steps["first_play_growth_dialogs"]=true
	first_play_harvest_guide_active=true;tutorial_harvest_plant=first_play_tutorial_reserved_plant;tutorial_harvest_plant.jelly_checks_enabled=false
	_clamp_tutorial_harvest_plant(tutorial_harvest_plant);_show_tutorial_harvest_spotlight();_save()

func _hide_first_play_tutorial_overlay()->void:
	if tutorial_guide_overlay==null:return
	tutorial_guide_overlay.visible=false;tutorial_dialog_panel.visible=false;tutorial_guide_button.visible=false;tutorial_guide_shade.material=null
	if tutorial_cost_note_panel:tutorial_cost_note_panel.visible=false
	_set_tutorial_dialog_system_style(false)
	first_play_harvest_spotlight_material.set_shader_parameter("focus_ellipse",false)

func _set_tutorial_dialog_system_style(system_page:bool)->void:
	if tutorial_dialog_panel==null:return
	tutorial_panda_portrait.visible=not system_page
	tutorial_guide_message.custom_minimum_size=Vector2(454 if system_page else 330,150)
	tutorial_guide_message.add_theme_font_size_override("font_size",20 if system_page else 22)
	tutorial_dialog_panel.add_theme_stylebox_override("panel",_box(Color("#edf5df") if system_page else Color(0.97,0.90,0.75,.97),Color("#739158") if system_page else Color("#a86f36"),24,4))

func _start_puku_buyback_tutorial()->void:
	if puku_buyback_tutorial_complete or puku_buyback_tutorial_active or puku_gauge_area==null:return
	if not species_get_queue.is_empty() or species_get_overlay and species_get_overlay.visible or catalog_series_unlock_overlay and catalog_series_unlock_overlay.visible:return
	puku_buyback_tutorial_active=true;puku_buyback_tutorial_index=0
	_show_puku_buyback_tutorial_page()

func _show_puku_buyback_tutorial_page()->void:
	var keys:=["puku_buyback_1","puku_buyback_2","puku_buyback_2_endless"]
	if puku_buyback_tutorial_index>=keys.size():
		puku_buyback_tutorial_active=false;puku_buyback_tutorial_complete=true;_hide_first_play_tutorial_overlay();_save()
		if first_seed_pod_reward_event_active:call_deferred("_start_first_seed_pod_max_event")
		elif play_active and plants.is_empty():call_deferred("_finish_greenhouse_play")
		return
	if tutorial_highlight_tween and tutorial_highlight_tween.is_valid():tutorial_highlight_tween.kill()
	var viewport_size:=get_viewport().get_visible_rect().size
	tutorial_guide_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;tutorial_guide_shade.mouse_filter=Control.MOUSE_FILTER_STOP;tutorial_guide_shade.color=Color(.025,.02,.01,.86)
	var center:=puku_gauge_area.global_position+puku_gauge_area.size*.5
	tutorial_guide_shade.material=first_play_harvest_spotlight_material
	var focus_half_size:=(puku_gauge_area.size*.5+Vector2(9,5))/viewport_size
	first_play_harvest_spotlight_material.set_shader_parameter("focus_ellipse",true);first_play_harvest_spotlight_material.set_shader_parameter("focus_half_size_uv",focus_half_size);first_play_harvest_spotlight_material.set_shader_parameter("focus_count",1);first_play_harvest_spotlight_material.set_shader_parameter("focus_uv_a",center/viewport_size);first_play_harvest_spotlight_material.set_shader_parameter("focus_radius_a",.10);first_play_harvest_spotlight_material.set_shader_parameter("viewport_aspect",viewport_size.x/viewport_size.y)
	tutorial_guide_button.visible=true;tutorial_guide_button.mouse_filter=Control.MOUSE_FILTER_STOP;tutorial_guide_button.position=Vector2.ZERO;tutorial_guide_button.size=viewport_size;tutorial_guide_button.text="";tutorial_guide_button.icon=null;tutorial_guide_button.flat=true;tutorial_guide_button.focus_mode=Control.FOCUS_NONE;tutorial_guide_button.set_meta("target","puku_buyback")
	var empty_style:=StyleBoxEmpty.new()
	for state in ["normal","hover","pressed","disabled","focus"]:tutorial_guide_button.add_theme_stylebox_override(state,empty_style)
	for connection in tutorial_guide_button.pressed.get_connections():tutorial_guide_button.pressed.disconnect(connection.callable)
	tutorial_guide_button.pressed.connect(_advance_puku_buyback_tutorial);tutorial_panda_portrait.texture=_speaker_portrait_texture("panda");tutorial_panda_portrait.visible=true;tutorial_guide_message.text=Localizer.text(language_code,str(keys[puku_buyback_tutorial_index]));tutorial_dialog_panel.visible=true;tutorial_dialog_panel.position=Vector2(40,790);tutorial_guide_overlay.visible=true
	_set_tutorial_dialog_system_style(puku_buyback_tutorial_index==2)

func _advance_puku_buyback_tutorial()->void:
	if not puku_buyback_tutorial_active:return
	puku_buyback_tutorial_index+=1;_show_puku_buyback_tutorial_page()

func _allow_plant_jelly(plant)->bool:
	if active_seed_type=="old" and not first_colorata_confirmed:return false
	return _try_claim_jelly()

func _first_play_growing_plants()->Array:
	var growing:Array=[]
	for plant in plants:
		if is_instance_valid(plant) and plant.state=="growing":growing.append(plant)
	return growing

func _first_play_tutorial_original_candidates()->Array[Dictionary]:
	var unseen:Array[Dictionary]=[]
	var unget:Array[Dictionary]=[]
	var pools:=_normal_seed_selection_pools()
	var seed_candidates:Array=[]
	seed_candidates.append_array(pools.get("unlocked_new",[]))
	seed_candidates.append_array(pools.get("locked_new",[]))
	for raw_entry in seed_candidates:
		if not raw_entry is Dictionary:continue
		var entry:Dictionary=raw_entry;var species_id:=str(entry.get("species_id",""))
		if species_id.is_empty() or species_id in pending_round_new_species_ids or _species_get_count(species_id)>0:continue
		if not bool(entry.get("main_story_original",false)) or str(entry.get("rarity",""))!="通常":continue
		if _seed_new_species_blocked(species_id):continue
		if not _species_available_in_current_era(entry) or float(entry.get("spawn_weight",0.0))<=0.0:continue
		unget.append(entry)
		if not bool(discovered.get(species_id,false)):unseen.append(entry)
	return unseen if not unseen.is_empty() else unget

func _old_seed_story_active()->bool:
	return play_active and active_seed_type=="old" and not first_colorata_confirmed

func _maybe_start_old_seed_reaction(max_diameter:float)->bool:
	if not _old_seed_story_active() or not scripted_dialog_kind.is_empty():return false
	if old_seed_reaction_stage==0 and max_diameter>=OLD_SEED_REACTION_SPROUT_CM:
		old_seed_reaction_stage=1
		_start_scripted_dialog("old_seed_growth_reaction",[
			{"speaker":"armadillo","text":Localizer.text(language_code,"old_seed_reaction_sprout")},
			{"speaker":"trio","text":Localizer.text(language_code,"old_seed_reaction_trio")},
			{"speaker":"girl","text":Localizer.text(language_code,"old_seed_reaction_girl")}
		],false)
		return true
	elif old_seed_reaction_stage==1 and max_diameter>=OLD_SEED_REACTION_GROWTH_CM:
		old_seed_reaction_stage=2
		_start_scripted_dialog("old_seed_growth_reaction",[{"speaker":"panda","text":Localizer.text(language_code,"old_seed_reaction_growth")}],false)
		return true
	return false

func _first_play_harvestable_plants()->Array:
	var harvestable:Array=[]
	for plant in _first_play_growing_plants():
		if float(plant.diameter_cm)>=TUTORIAL_HARVEST_CM:harvestable.append(plant)
	return harvestable

func _maybe_activate_first_play_harvest_guide()->bool:
	if not first_play_tutorial_active or not first_play_tutorial_sequence_complete or first_play_harvest_guide_active or first_play_has_harvested or bool(tutorial_steps.get("first_harvest_guide",false)) or not play_active:return false
	# The normal bag can hold more seeds than the initial active-plant slots.
	# Guide the first harvest as soon as one visible plant is ready; that harvest
	# then frees a slot for the remaining seeds instead of deadlocking the lesson.
	if play_seed_animations_pending>0:return false
	var growing:=_first_play_harvestable_plants()
	if growing.is_empty():return false
	first_play_harvest_guide_active=true;tutorial_harvest_plant=growing[0]
	_clamp_tutorial_harvest_plant(tutorial_harvest_plant)
	_show_tutorial_harvest_spotlight()
	return true

func _maybe_activate_old_seed_harvest_guide()->bool:
	if not _old_seed_story_active() or old_seed_reaction_stage<2 or old_seed_harvest_guide_active:return false
	var harvestable:Array=[]
	for plant in plants:
		if is_instance_valid(plant) and plant.state=="growing" and float(plant.diameter_cm)>=TUTORIAL_HARVEST_CM:harvestable.append(plant)
	if harvestable.is_empty():return false
	old_seed_harvest_guide_active=true;tutorial_harvest_plant=harvestable[0]
	_clamp_tutorial_harvest_plant(tutorial_harvest_plant)
	_show_tutorial_harvest_spotlight()
	return true

func _clamp_tutorial_harvest_plant(plant)->void:
	if not is_instance_valid(plant) or float(plant.diameter_cm)<=TUTORIAL_HARVEST_CM:return
	plant.diameter_cm=TUTORIAL_HARVEST_CM
	plant.visual_scale=.18+(TUTORIAL_HARVEST_CM-1.6)*.058
	plant._update_visual(0.0)

func _show_tutorial_harvest_spotlight()->void:
	if tutorial_highlight_tween and tutorial_highlight_tween.is_valid():tutorial_highlight_tween.kill()
	tutorial_highlight_tween=null;tutorial_guide_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;tutorial_guide_shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;tutorial_guide_shade.material=first_play_harvest_spotlight_material;tutorial_guide_shade.color=Color(0.025,0.035,0.045,.82)
	first_play_harvest_spotlight_material.set_shader_parameter("focus_ellipse",false)
	tutorial_guide_button.visible=false;tutorial_guide_button.mouse_filter=Control.MOUSE_FILTER_IGNORE;tutorial_guide_message.text=Localizer.text(language_code,"tutorial_harvest_tap");tutorial_dialog_panel.visible=true;tutorial_guide_overlay.visible=true;_update_first_play_harvest_guide_focus()
	tutorial_panda_portrait.visible=false

func _update_first_play_harvest_guide_focus()->void:
	if not first_play_harvest_guide_active and not old_seed_harvest_guide_active:return
	if not is_instance_valid(tutorial_harvest_plant) or tutorial_harvest_plant.state!="growing":return
	var viewport_size:=get_viewport().get_visible_rect().size
	var plant=tutorial_harvest_plant;var center:=camera.unproject_position(plant.global_position+Vector3(0,plant.visual_scale*.48,0));var top:=camera.unproject_position(plant.global_position+Vector3(0,plant.visual_scale*1.25,0));var radius:=clampf(center.distance_to(top)*1.42,64.0,180.0)
	first_play_harvest_spotlight_material.set_shader_parameter("focus_ellipse",false);first_play_harvest_spotlight_material.set_shader_parameter("focus_uv_a",center/viewport_size);first_play_harvest_spotlight_material.set_shader_parameter("focus_radius_a",radius/viewport_size.y)
	var avoid:=Rect2(center-Vector2(radius,radius),Vector2(radius*2.0,radius*2.0))
	first_play_harvest_spotlight_material.set_shader_parameter("focus_count",1);first_play_harvest_spotlight_material.set_shader_parameter("viewport_aspect",viewport_size.x/viewport_size.y);_position_tutorial_dialog(avoid)

func _end_first_play_tutorial_context()->void:
	first_play_tutorial_active=false;first_play_tutorial_dialog_visible=false;first_play_tutorial_sequence_complete=false;first_play_tutorial_phase="";first_play_tutorial_reserved_seed_pending=false;first_play_tutorial_reserved_species_id="";first_play_tutorial_reserved_plant=null;first_play_tutorial_forced_jelly_plant=null;first_play_tutorial_observe_remaining=0.0;first_play_harvest_guide_active=false;old_seed_harvest_guide_active=false;tutorial_harvest_plant=null;_hide_first_play_tutorial_overlay()

func _show_intro_gift_effect()->void:
	for i in range(7):
		var mote:=UISymbolIcon.new();mote.symbol="sparkle";mote.icon_color=Color("#f4ca58") if i%2 else Color("#8dad64");mote.position=Vector2(245+rng.randf_range(-55,55),730+rng.randf_range(-15,25));mote.size=Vector2.ONE*float(18+rng.randi_range(0,7));effects_layer.add_child(mote)
		var tween:=create_tween().bind_node(mote).set_parallel();tween.tween_property(mote,"position",mote.position+Vector2(rng.randf_range(-80,80),rng.randf_range(-150,-90)),.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);tween.tween_property(mote,"modulate:a",0.0,.75).set_delay(.2);tween.chain().tween_callback(mote.queue_free)

func _build_settings(hud:Control)->void:
	settings_overlay=Control.new();settings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);settings_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;settings_overlay.visible=false;hud.add_child(settings_overlay)
	var shade:=ColorRect.new();shade.color=Color(0.12,0.07,0.04,.68);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;settings_overlay.add_child(shade)
	var panel:=PanelContainer.new();panel.position=Vector2(44,64);panel.size=Vector2(488,896);panel.add_theme_stylebox_override("panel",_box(Color("#f7e8c7"),Color("#9b642f"),26,4));settings_overlay.add_child(panel)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;scroll.scroll_deadzone=12;panel.add_child(scroll)
	var content:=VBoxContainer.new();content.custom_minimum_size=Vector2(450,0);content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",11);scroll.add_child(content)
	settings_title_label=Label.new();settings_title_label.text="設定";settings_title_label.custom_minimum_size=Vector2(420,42);settings_title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;settings_title_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;settings_title_label.add_theme_font_size_override("font_size",30);settings_title_label.add_theme_color_override("font_color",UI_BROWN);content.add_child(settings_title_label)
	settings_language_heading=Label.new();settings_language_heading.name="LanguageHeading";settings_language_heading.text=Localizer.text(language_code,"language_heading");settings_language_heading.custom_minimum_size=Vector2(420,30);settings_language_heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;settings_language_heading.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;settings_language_heading.add_theme_font_size_override("font_size",19);settings_language_heading.add_theme_color_override("font_color",UI_BROWN);content.add_child(settings_language_heading)
	var language_row:=HBoxContainer.new();language_row.alignment=BoxContainer.ALIGNMENT_CENTER;language_row.add_theme_constant_override("separation",7);content.add_child(language_row)
	for option in [{"code":"ja","label":"日本語"},{"code":"hiragana","label":"ひらがな"},{"code":"en","label":"English"}]:
		var language_button:=Button.new();language_button.text=str(option.label);language_button.custom_minimum_size=Vector2(134,50);language_button.clip_text=true;language_button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;_skin_button(language_button,Color("#d9c49d"),15);language_button.pressed.connect(_set_language.bind(str(option.code)));language_row.add_child(language_button);language_buttons[str(option.code)]=language_button
	settings_language_status=Label.new();settings_language_status.custom_minimum_size=Vector2(420,36);settings_language_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;settings_language_status.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;settings_language_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;settings_language_status.add_theme_font_size_override("font_size",13);settings_language_status.add_theme_color_override("font_color",Color("#76513b"));content.add_child(settings_language_status)
	_add_audio_setting_controls(content,Localizer.text(language_code,"audio_bgm"),true)
	_add_audio_setting_controls(content,Localizer.text(language_code,"audio_se"),false)
	var note:=Label.new();note.name="AudioSettingsNote";note.text=Localizer.text(language_code,"audio_note");note.custom_minimum_size=Vector2(420,40);note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;note.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;note.add_theme_font_size_override("font_size",14);note.add_theme_color_override("font_color",Color("#76513b"));content.add_child(note)
	if _trial_dev_controls_enabled():
		_add_harvest_sound_test_controls(content)
		var habitat_test:=Button.new();habitat_test.name="HabitatDevOpen";habitat_test.text="開発用：通常原生地テスト";habitat_test.custom_minimum_size=Vector2(370,58);_skin_button(habitat_test,Color("#adcbb8"),16);habitat_test.pressed.connect(_open_habitat_dev);content.add_child(habitat_test)
		var opening_story_replay:=Button.new();opening_story_replay.name="OpeningStoryReplay";opening_story_replay.text="開発用：オープニングストーリー再表示";opening_story_replay.custom_minimum_size=Vector2(370,58);_skin_button(opening_story_replay,Color("#d8c29e"),15);opening_story_replay.pressed.connect(_replay_opening_story_for_development);content.add_child(opening_story_replay)
	if _trial_dev_controls_enabled():
		var story_jump:=Button.new();story_jump.name="StoryDevOpen";story_jump.text="開発用：ストーリージャンプ";story_jump.custom_minimum_size=Vector2(370,58);_skin_button(story_jump,Color("#c7d6ad"),16);story_jump.pressed.connect(_open_story_dev);content.add_child(story_jump)
		var reset:=Button.new();reset.name="ProgressionDevReset";reset.text="開発用：進行を初期状態へ戻す";reset.custom_minimum_size=Vector2(370,58);_skin_button(reset,Color("#d9c49d"),16);reset.pressed.connect(_reset_progression_for_development.bind(reset));content.add_child(reset)
		_add_progression_dev_counter(content,"old_page","古びた図鑑のページ")
		_add_progression_dev_counter(content,"puku_coin","ぷくコイン")
		endless_economy_debug_label=Label.new();endless_economy_debug_label.custom_minimum_size=Vector2(410,132);endless_economy_debug_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;endless_economy_debug_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;endless_economy_debug_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;endless_economy_debug_label.add_theme_font_size_override("font_size",14);endless_economy_debug_label.add_theme_color_override("font_color",UI_BROWN);content.add_child(endless_economy_debug_label)
		var jelly_test:=Button.new();jelly_test.name="JellyDevOpen";jelly_test.text="開発用：ジュレテスト";jelly_test.custom_minimum_size=Vector2(370,58);_skin_button(jelly_test,Color("#c7b4d9"),17);jelly_test.pressed.connect(_open_jelly_dev);content.add_child(jelly_test)
		trial_dev_gacha_button=Button.new();trial_dev_gacha_button.name="TrialDevGachaOpen";trial_dev_gacha_button.text="開発用：品種ガチャ";trial_dev_gacha_button.custom_minimum_size=Vector2(370,58);_skin_button(trial_dev_gacha_button,Color("#d9c77d"),17);trial_dev_gacha_button.pressed.connect(_open_trial_dev_forest_gacha);trial_dev_gacha_button.visible=_is_endless_greenhouse_enabled() and _trial_dev_controls_enabled();content.add_child(trial_dev_gacha_button)
		if DEVELOPMENT_CATALOG_PREVIEW_ENABLED:
			catalog_preview_settings_button=Button.new();catalog_preview_settings_button.name="CatalogPreviewDevOpen";catalog_preview_settings_button.text="開発用：品種プレビュー";catalog_preview_settings_button.custom_minimum_size=Vector2(370,58);_skin_button(catalog_preview_settings_button,Color("#c7d6ad"),17);catalog_preview_settings_button.pressed.connect(_open_catalog_preview_dev);content.add_child(catalog_preview_settings_button)
	settings_close_button=Button.new();settings_close_button.text="閉じる";settings_close_button.custom_minimum_size=Vector2(280,55);_skin_button(settings_close_button,Color("#ead8b1"),18);settings_close_button.pressed.connect(_close_settings);content.add_child(settings_close_button)
	_refresh_progression_dev_counters()

func _build_habitat_plant_panel(hud:Control)->void:
	habitat_plant_panel=HabitatPlantPanelClass.new();hud.add_child(habitat_plant_panel)
	habitat_plant_panel.close_requested.connect(_update_play_ui)

func _build_habitat_dev_panel(hud:Control)->void:
	if not _trial_dev_controls_enabled():return
	habitat_dev_panel=HabitatDevPanelClass.new();hud.add_child(habitat_dev_panel)
	habitat_dev_panel.random_reset_requested.connect(_debug_reset_normal_habitat)
	habitat_dev_panel.multiplier_requested.connect(_debug_set_habitat_multiplier)
	habitat_dev_panel.time_jump_requested.connect(_debug_jump_habitat_time)
	habitat_dev_panel.close_requested.connect(_update_play_ui)

func _build_story_dev_panel(hud:Control)->void:
	if not _trial_dev_controls_enabled():return
	story_dev_panel=StoryDevPanelClass.new();hud.add_child(story_dev_panel)
	story_dev_panel.preset_requested.connect(_apply_story_dev_preset)
	story_dev_panel.spawn_101_requested.connect(_spawn_story_dev_101_colorata)
	story_dev_panel.close_requested.connect(_update_play_ui)

func _open_story_dev()->void:
	if not StoryDevPresetsClass.available(_trial_dev_controls_enabled()) or story_dev_panel==null:return
	settings_overlay.visible=false;story_dev_panel.open();_update_play_ui()

func _apply_story_dev_preset(preset_id:String)->Dictionary:
	if not StoryDevPresetsClass.available(_trial_dev_controls_enabled()):return {"ok":false,"error":"development_only"}
	var result:Dictionary=StoryDevPresetsClass.apply(self,preset_id)
	if not bool(result.get("ok",false)):return result
	if story_dev_panel and story_dev_panel.visible:story_dev_panel.close()
	if settings_overlay:settings_overlay.visible=false
	_apply_saved_unlocks();_sync_arrangement_ui();_update_main_story_progress(false);_apply_mode();_update_currency_ui();_update_best_ui();_save();_update_play_ui()
	if bool(result.get("resume_story",true)):call_deferred("_try_start_pending_story_event")
	return result

func _spawn_story_dev_101_colorata()->void:
	if not StoryDevPresetsClass.available(_trial_dev_controls_enabled()):return
	if story_dev_panel and story_dev_panel.visible:story_dev_panel.close()
	if settings_overlay:settings_overlay.visible=false
	if StoryDevPresetsClass.spawn_101cm_colorata(self):_apply_mode();_update_play_ui()

func _open_habitat_dev()->void:
	if not _trial_dev_controls_enabled() or habitat_dev_panel==null:return
	settings_overlay.visible=false
	habitat_dev_panel.open();_refresh_habitat_dev_panel();_update_play_ui()

func _add_progression_dev_counter(parent:VBoxContainer,key:String,title:String)->void:
	var row:=HBoxContainer.new();row.alignment=BoxContainer.ALIGNMENT_CENTER;row.add_theme_constant_override("separation",8);parent.add_child(row)
	var label:=Label.new();label.custom_minimum_size=Vector2(250,42);label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",15);label.add_theme_color_override("font_color",UI_BROWN);row.add_child(label);progression_dev_labels[key]=label
	var deltas:Array=[-1.0,-0.1,0.1,1.0] if key=="puku_coin" else [-1.0,1.0]
	for delta_value in deltas:
		var delta:=float(delta_value)
		var button:=Button.new();button.text=("−" if delta<0.0 else "+")+("%.1f"%absf(delta) if absf(delta)<1.0 else "%d"%roundi(absf(delta)));button.custom_minimum_size=Vector2(64,42);_skin_button(button,Color("#d9c49d"),15);button.pressed.connect(_adjust_progression_dev_value.bind(key,delta));row.add_child(button)

func _adjust_progression_dev_value(key:String,delta:float)->void:
	if not _trial_dev_controls_enabled():return
	if key=="old_page":
		var page_delta:=roundi(delta)
		if page_delta>0:_grant_old_catalog_page(page_delta,true)
		else:_remove_old_catalog_page(-page_delta)
	elif key=="puku_coin":_change_puku_balance(roundi(delta*PUKU_UNITS_PER_PUKU),"dev_adjustment",false,true)
	_save();_refresh_progression_dev_counters();_update_currency_ui();_sync_arrangement_ui()

func _refresh_progression_dev_counters()->void:
	if progression_dev_labels.has("old_page"):progression_dev_labels["old_page"].text="古びた図鑑のページ　×%d"%old_catalog_pages
	if progression_dev_labels.has("puku_coin"):progression_dev_labels["puku_coin"].text="ぷく残高　%.2fぷく"%(float(puku_balance_units)/PUKU_UNITS_PER_PUKU)
	if endless_economy_debug_label:
		var summary:=_endless_economy_debug_summary()
		endless_economy_debug_label.text="12粒ラウンド試遊ログ\n開始 %.2f / 費用 -%.2f / 収穫 +%.2f / 純収支 %+.2fぷく\n使用種 %d / 収穫 %d / ジュレ %d / 最大 %.1fcm"%[float(summary.start_puku),float(summary.seed_cost_puku),float(summary.harvest_revenue_puku),float(summary.greenhouse_net_puku),int(summary.seeds_used),int(summary.harvested),int(summary.jellied),float(summary.max_harvest_cm)]

func _build_research_catalog_reward(hud:Control)->void:
	research_catalog_reward_overlay=Control.new();research_catalog_reward_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);research_catalog_reward_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;research_catalog_reward_overlay.visible=false;hud.add_child(research_catalog_reward_overlay)
	var shade:=ColorRect.new();shade.color=Color(0.08,.04,.03,.78);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;research_catalog_reward_overlay.add_child(shade)
	var panel:=PanelContainer.new();panel.position=Vector2(34,82);panel.size=Vector2(508,860);panel.add_theme_stylebox_override("panel",_box(Color("#f7e8c7"),Color("#8f633b"),26,4));research_catalog_reward_overlay.add_child(panel)
	var content:=VBoxContainer.new();content.add_theme_constant_override("separation",12);panel.add_child(content)
	var title:=Label.new();title.name="ResearchRewardTitle";title.text=Localizer.text(language_code,"research_reward_title");title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",28);title.add_theme_color_override("font_color",UI_BROWN);content.add_child(title)
	var note:=Label.new();note.name="ResearchRewardNote";note.text=Localizer.text(language_code,"research_reward_note");note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;note.add_theme_font_size_override("font_size",17);note.add_theme_color_override("font_color",Color("#76513b"));content.add_child(note)
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(474,690);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.scroll_deadzone=12;content.add_child(scroll)
	research_catalog_reward_grid=VBoxContainer.new();research_catalog_reward_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;research_catalog_reward_grid.add_theme_constant_override("separation",10);scroll.add_child(research_catalog_reward_grid)
	var close:=Button.new();close.name="ResearchRewardClose";close.text=Localizer.text(language_code,"research_reward_later");close.custom_minimum_size=Vector2(280,52);_skin_button(close,Color("#ead8b1"),17);close.pressed.connect(_close_research_catalog_reward);content.add_child(close)

func _open_research_catalog_reward()->void:
	if not research_catalog_reward_pending or research_catalog_reward_overlay==null:return
	_hide_shop_chatter(true);_refresh_research_catalog_reward();research_catalog_reward_overlay.visible=true;_update_play_ui()

func _refresh_research_catalog_reward()->void:
	if research_catalog_reward_grid==null:return
	for child in research_catalog_reward_grid.get_children():child.free()
	var candidates:=_unowned_stocked_normal_series()
	if candidates.is_empty():
		var empty:=Label.new();empty.text=Localizer.text(language_code,"research_reward_empty");empty.custom_minimum_size=Vector2(460,150);empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;empty.add_theme_font_size_override("font_size",17);empty.add_theme_color_override("font_color",UI_BROWN);research_catalog_reward_grid.add_child(empty);return
	for entry in candidates:
		var button:=Button.new();button.text=Localizer.text(language_code,"research_reward_choose",[Localizer.series_name(language_code,entry)]);button.custom_minimum_size=Vector2(456,92);button.action_mode=BaseButton.ACTION_MODE_BUTTON_RELEASE;button.mouse_force_pass_scroll_events=true;_skin_button(button,Color("#d8b56b"),18);button.pressed.connect(_claim_research_catalog_reward.bind(str(entry.get("series_id",""))));research_catalog_reward_grid.add_child(button)

func _claim_research_catalog_reward(series_id:String)->void:
	if not research_catalog_reward_pending:return
	var valid:=false
	for entry in _unowned_stocked_normal_series():
		if str(entry.get("series_id",""))==series_id:valid=true;break
	if not valid:return
	_unlock_series_and_register_encounters(series_id);research_catalog_reward_pending=false;armadillo_research_rewards["8"]=true
	_save();_sync_arrangement_ui();research_catalog_reward_overlay.visible=false;_show_shop_chatter(Localizer.text(language_code,"research_reward_claimed",[Localizer.series_name(language_code,_series_entry(series_id))]),false,"catalog_restore_result","armadillo");_update_play_ui()

func _close_research_catalog_reward()->void:
	research_catalog_reward_overlay.visible=false;_update_play_ui()

func _build_catalog_preview_dev(hud:Control)->void:
	if not _trial_dev_controls_enabled() or not DEVELOPMENT_CATALOG_PREVIEW_ENABLED:return
	catalog_preview_ui=CatalogPreviewDevClass.new();hud.add_child(catalog_preview_ui)
	catalog_preview_ui.preview_species_requested.connect(_preview_catalog_species)
	catalog_preview_ui.preview_batch_requested.connect(_preview_catalog_batch)
	catalog_preview_ui.clear_requested.connect(_clear_catalog_preview_plants)
	catalog_preview_ui.close_requested.connect(_update_play_ui)
	catalog_preview_ui.configure(catalog_species,series_catalog)

func _open_catalog_preview_dev()->void:
	if not _trial_dev_controls_enabled() or not DEVELOPMENT_CATALOG_PREVIEW_ENABLED or catalog_preview_ui==null or play_active or arrangement_scene_active:return
	settings_overlay.visible=false;play_modal_open=false;current_mode="greenhouse";_apply_mode()
	catalog_preview_ui.configure(catalog_species,series_catalog);catalog_preview_ui.open();_update_play_ui()

func _preview_catalog_species(species_id:String)->void:
	if not _trial_dev_controls_enabled():return
	_preview_catalog_batch([species_id],str(_catalog_entry(species_id).get("name_ja",species_id)))

func _preview_catalog_batch(species_ids:Array,_series_name:String)->void:
	if not _trial_dev_controls_enabled() or not DEVELOPMENT_CATALOG_PREVIEW_ENABLED:return
	_clear_catalog_preview_plants(false)
	catalog_preview_mode_active=true
	for species_id_value in species_ids:_spawn_specific_plant(str(species_id_value),true)
	if catalog_preview_ui:catalog_preview_ui.set_session_active(not _catalog_preview_plants().is_empty())
	_update_play_ui()

func _catalog_preview_plants()->Array:
	var result:Array=[]
	for plant in plants:
		if is_instance_valid(plant) and bool(plant.get_meta("catalog_preview",false)):result.append(plant)
	return result

func _clear_catalog_preview_plants(update_ui:=true)->void:
	for plant in _catalog_preview_plants():
		plants.erase(plant)
		if plant.label and is_instance_valid(plant.label):plant.label.free()
		plant.free()
	catalog_preview_mode_active=false
	if catalog_preview_ui:catalog_preview_ui.set_session_active(false)
	if update_ui:_update_play_ui()

func _build_jelly_dev_overlay(hud:Control)->void:
	if not _trial_dev_controls_enabled():return
	jelly_dev_overlay=Control.new();jelly_dev_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);jelly_dev_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;jelly_dev_overlay.visible=false;hud.add_child(jelly_dev_overlay)
	var shade:=ColorRect.new();shade.color=Color(0.08,0.04,0.03,.78);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;jelly_dev_overlay.add_child(shade)
	var panel:=PanelContainer.new();panel.position=Vector2(18,28);panel.size=Vector2(540,968);panel.add_theme_stylebox_override("panel",_box(Color("#f7e8c7"),Color("#8f633b"),24,4));jelly_dev_overlay.add_child(panel)
	var outer:=VBoxContainer.new();outer.add_theme_constant_override("separation",8);panel.add_child(outer)
	var title:=Label.new();title.text="開発用：ジュレテスト";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",24);title.add_theme_color_override("font_color",UI_BROWN);outer.add_child(title)
	var note:=Label.new();note.text="正式ロジックは保持したまま、テスト中だけ上書きします";note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;note.add_theme_font_size_override("font_size",13);note.add_theme_color_override("font_color",Color("#76513b"));outer.add_child(note)
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(500,735);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;outer.add_child(scroll)
	var content:=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",5);scroll.add_child(content)
	_add_jelly_dev_row(content,"final_chance",.005);_add_jelly_dev_row(content,"cooldown",.1);_add_jelly_dev_row(content,"safe_min",.1);_add_jelly_dev_row(content,"safe_max",.1)
	for kind in ["short","normal","long","ultra"]:
		var heading:=Label.new();heading.text={"short":"短命タイプ","normal":"普通タイプ","long":"長命タイプ","ultra":"超長命タイプ"}[kind];heading.add_theme_font_size_override("font_size",18);heading.add_theme_color_override("font_color",Color("#754326"));content.add_child(heading)
		_add_jelly_dev_row(content,kind+"_weight",1.0);_add_jelly_dev_row(content,kind+"_min",.1);_add_jelly_dev_row(content,kind+"_max",.1)
	var slow_heading:=Label.new();slow_heading.text="生育予測 v1（短命から派生）";slow_heading.add_theme_font_size_override("font_size",18);slow_heading.add_theme_color_override("font_color",Color("#754326"));content.add_child(slow_heading)
	_add_jelly_dev_row(content,"slow_short_rate",1.0);_add_jelly_dev_row(content,"slow_resilient_rate",1.0);_add_jelly_dev_row(content,"regular_short_resilient_rate",1.0);_add_jelly_dev_row(content,"resilient_final_chance",.005)
	_add_jelly_dev_row(content,"slow_growth_min",.01);_add_jelly_dev_row(content,"slow_growth_max",.01);_add_jelly_dev_row(content,"slow_ramp_min",.1);_add_jelly_dev_row(content,"slow_ramp_max",.1)
	var prediction_actions:=HBoxContainer.new();prediction_actions.alignment=BoxContainer.ALIGNMENT_CENTER;prediction_actions.add_theme_constant_override("separation",8);content.add_child(prediction_actions)
	var apply_prediction:=Button.new();apply_prediction.text="生育予測 v1\nテスト値を適用";apply_prediction.custom_minimum_size=Vector2(238,54);_skin_button(apply_prediction,Color("#c7b4d9"),14);apply_prediction.pressed.connect(_dev_apply_prediction_v1);prediction_actions.add_child(apply_prediction)
	jelly_trait_toggle_button=Button.new();jelly_trait_toggle_button.custom_minimum_size=Vector2(220,54);_skin_button(jelly_trait_toggle_button,Color("#d9c49d"),14);jelly_trait_toggle_button.pressed.connect(_toggle_jelly_trait_display);prediction_actions.add_child(jelly_trait_toggle_button)
	_add_jelly_dev_row(content,"growth_speed",.1);_add_jelly_dev_row(content,"rhythm_amplitude",.01)
	jelly_dev_total_label=Label.new();jelly_dev_total_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;jelly_dev_total_label.add_theme_font_size_override("font_size",17);content.add_child(jelly_dev_total_label)
	var actions:=HBoxContainer.new();actions.alignment=BoxContainer.ALIGNMENT_CENTER;actions.add_theme_constant_override("separation",7);outer.add_child(actions)
	for spec in [["たね（12粒）+1セット",Callable(self,"_dev_add_seed_bag")],["50cm株 ×4 テスト",Callable(self,"_dev_spawn_50cm")],["正式値に戻す",Callable(self,"_dev_reset_jelly")]]:
		var button:=Button.new();button.text=spec[0];button.custom_minimum_size=Vector2(158,52);_skin_button(button,Color("#d8b56b"),14);button.pressed.connect(spec[1]);actions.add_child(button)
	var close:=Button.new();close.text="閉じる";close.custom_minimum_size=Vector2(280,45);_skin_button(close,Color("#ead8b1"),16);close.pressed.connect(_close_jelly_dev);outer.add_child(close)

func _add_jelly_dev_row(parent:VBoxContainer,key:String,step:float)->void:
	var row:=HBoxContainer.new();row.alignment=BoxContainer.ALIGNMENT_CENTER;row.add_theme_constant_override("separation",6);parent.add_child(row)
	var label:=Label.new();label.custom_minimum_size=Vector2(330,38);label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",15);label.add_theme_color_override("font_color",UI_BROWN);row.add_child(label);jelly_dev_labels[key]=label
	for delta in [-step,step]:
		var button:=Button.new();button.text="−" if delta<0 else "+";button.custom_minimum_size=Vector2(64,38);_skin_button(button,Color("#d9c49d"),18);button.pressed.connect(_change_jelly_dev_value.bind(key,delta));row.add_child(button)

func _open_jelly_dev()->void:
	if not _trial_dev_controls_enabled():return
	JellyBalanceClass.begin_test_defaults();JellyBalanceClass.override_enabled=true;settings_overlay.visible=false;jelly_dev_overlay.visible=true;_refresh_jelly_dev_ui();_update_play_ui()

func _close_jelly_dev()->void:
	if jelly_dev_overlay==null:return
	jelly_dev_overlay.visible=false;_update_play_ui()

func _change_jelly_dev_value(key:String,delta:float)->void:
	if not _trial_dev_controls_enabled():return
	var value:=float(JellyBalanceClass.values[key])+delta
	if key.ends_with("_weight") or key in ["slow_short_rate","slow_resilient_rate","regular_short_resilient_rate"]:value=clampf(value,0.0,100.0)
	elif key in ["final_chance","resilient_final_chance"]:value=clampf(value,.0,.50)
	elif key=="growth_speed":value=clampf(value,.1,10.0)
	elif key=="slow_growth_min" or key=="slow_growth_max":value=clampf(value,.05,2.0)
	elif key=="rhythm_amplitude":value=clampf(value,.0,.50)
	else:value=clampf(value,.0,120.0)
	if key.ends_with("_min"):
		var max_key:=key.trim_suffix("_min")+"_max";value=minf(value,float(JellyBalanceClass.values[max_key]))
	elif key.ends_with("_max"):
		var min_key:=key.trim_suffix("_max")+"_min";value=maxf(value,float(JellyBalanceClass.values[min_key]))
	JellyBalanceClass.set_value(key,value);_refresh_jelly_dev_ui()

func _jelly_dev_text(key:String)->String:
	var names={"final_chance":"最終ジュレ率","cooldown":"連続ジュレ回避","safe_min":"初期安全 MIN","safe_max":"初期安全 MAX","short_weight":"短命 割合","short_min":"短命 時間 MIN","short_max":"短命 時間 MAX","normal_weight":"普通 割合","normal_min":"普通 時間 MIN","normal_max":"普通 時間 MAX","long_weight":"長命 割合","long_min":"長命 時間 MIN","long_max":"長命 時間 MAX","ultra_weight":"超長命 割合","ultra_min":"超長命 時間 MIN","ultra_max":"超長命 時間 MAX","slow_short_rate":"短命から遅育率","slow_resilient_rate":"遅育から強健率","regular_short_resilient_rate":"通常短命から強健率","resilient_final_chance":"強健個体 最終ジュレ率","slow_growth_min":"遅育 成長 MIN","slow_growth_max":"遅育 成長 MAX","slow_ramp_min":"遅育 危険上昇 MIN","slow_ramp_max":"遅育 危険上昇 MAX","growth_speed":"成長速度倍率","rhythm_amplitude":"成長リズム幅"}
	var value:=float(JellyBalanceClass.values[key])
	if key in ["final_chance","resilient_final_chance","rhythm_amplitude"]:return "%s　%.1f%%"%[names[key],value*100.0]
	if key.ends_with("_weight") or key in ["slow_short_rate","slow_resilient_rate","regular_short_resilient_rate"]:return "%s　%.0f%%"%[names[key],value]
	if key=="slow_growth_min" or key=="slow_growth_max":return "%s　×%.2f"%[names[key],value]
	if key=="growth_speed":return "%s　×%.1f"%[names[key],value]
	return "%s　%.1f秒"%[names[key],value]

func _refresh_jelly_dev_ui()->void:
	for key in jelly_dev_labels:jelly_dev_labels[key].text=_jelly_dev_text(str(key))
	if jelly_trait_toggle_button:jelly_trait_toggle_button.text="体質表示　%s"%("ON" if jelly_trait_display_enabled else "OFF")
	var total:=JellyBalanceClass.weight_total();jelly_dev_total_label.text="タイプ割合 合計 %.0f%%　%s"%[total,"OK" if is_equal_approx(total,100.0) else "注意: 100%にしてください"]
	jelly_dev_total_label.add_theme_color_override("font_color",Color("#47713b") if is_equal_approx(total,100.0) else Color("#b33b31"))

func _dev_add_seed_bag()->void:
	if not _trial_dev_controls_enabled():return
	normal_seed_bags+=1;_update_play_ui();_save()

func _dev_reset_jelly()->void:
	if not _trial_dev_controls_enabled():return
	JellyBalanceClass.reset_formal();jelly_trait_display_enabled=false
	if dev_jelly_test_active:
		dev_jelly_test_active=false;_clear_greenhouse_plants();active_seed_type="normal"
	_refresh_jelly_dev_ui();_update_play_ui()

func _dev_apply_prediction_v1()->void:
	if not _trial_dev_controls_enabled():return
	JellyBalanceClass.apply_prediction_v1_test_values();_refresh_jelly_dev_ui()

func _toggle_jelly_trait_display()->void:
	if not _trial_dev_controls_enabled():return
	jelly_trait_display_enabled=not jelly_trait_display_enabled;_refresh_jelly_dev_ui();_update_labels()

func _dev_spawn_50cm()->void:
	if not _trial_dev_controls_enabled():return
	JellyBalanceClass.override_enabled=true;dev_jelly_test_active=true;last_jelly_claim_msec=-1000000000
	jelly_dev_overlay.visible=false;settings_overlay.visible=false;current_mode="greenhouse";_apply_mode();_clear_greenhouse_plants();play_active=false;active_seed_type="dev_jelly";play_seeds_remaining=0;play_spawn_queue=0;play_seed_animations_pending=0
	for i in range(4):
		_spawn_specific_plant("colorata");var plant=plants.back();plant.fast_forward_to_diameter(50.0)
	_update_play_ui()

func _try_claim_jelly()->bool:
	var cooldown:=float(JellyBalanceClass.effective().cooldown)
	var now:=Time.get_ticks_msec()
	if cooldown>0.0 and now-last_jelly_claim_msec<int(cooldown*1000.0):return false
	last_jelly_claim_msec=now;return true

func _add_audio_setting_controls(parent:VBoxContainer,label_text:String,is_bgm:bool)->void:
	var row:=HBoxContainer.new();row.alignment=BoxContainer.ALIGNMENT_CENTER;row.add_theme_constant_override("separation",12);parent.add_child(row)
	var toggle:=CheckButton.new();toggle.name="BgmToggle" if is_bgm else "SeToggle";toggle.text=Localizer.text(language_code,"audio_bgm_on" if is_bgm else "audio_se_on");toggle.button_pressed=bool(audio_settings.get("bgm_enabled" if is_bgm else "se_enabled",true));toggle.custom_minimum_size=Vector2(145,48);toggle.clip_text=true;toggle.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;row.add_child(toggle)
	var slider:=HSlider.new();slider.min_value=0;slider.max_value=100;slider.step=1;slider.value=float(audio_settings.get("bgm_volume" if is_bgm else "se_volume",.65)) * 100.0;slider.custom_minimum_size=Vector2(210,48);row.add_child(slider)
	toggle.toggled.connect(_change_audio_enabled.bind(is_bgm));slider.value_changed.connect(_change_audio_volume.bind(is_bgm))

func _add_harvest_sound_test_controls(parent:VBoxContainer)->void:
	var heading:=Label.new();heading.name="HarvestSoundTestHeading";heading.text="収穫音（テスト用）";heading.custom_minimum_size=Vector2(420,30);heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;heading.add_theme_font_size_override("font_size",19);heading.add_theme_color_override("font_color",UI_BROWN);parent.add_child(heading)
	var row:=HBoxContainer.new();row.name="HarvestSoundTestRow";row.alignment=BoxContainer.ALIGNMENT_CENTER;row.add_theme_constant_override("separation",7);parent.add_child(row)
	var specs:=[{"name":"HarvestSoundExisting","label":"既存"},{"name":"HarvestSoundFirefly1","label":"Firefly ①"},{"name":"HarvestSoundFirefly2","label":"Firefly ②"}]
	for index in range(specs.size()):
		var spec:Dictionary=specs[index];var button:=Button.new();button.name=str(spec.name);button.text=str(spec.label);button.custom_minimum_size=Vector2(134,48);button.clip_text=true;button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;_skin_button(button,Color("#d9c49d"),15);button.pressed.connect(_select_harvest_sound_test_variant.bind(index));row.add_child(button);harvest_sound_test_buttons.append(button)
	harvest_sound_test_status=Label.new();harvest_sound_test_status.name="HarvestSoundTestStatus";harvest_sound_test_status.custom_minimum_size=Vector2(420,32);harvest_sound_test_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;harvest_sound_test_status.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;harvest_sound_test_status.add_theme_font_size_override("font_size",14);harvest_sound_test_status.add_theme_color_override("font_color",Color("#76513b"));parent.add_child(harvest_sound_test_status)
	_refresh_harvest_sound_test_controls()

func _select_harvest_sound_test_variant(variant_index:int)->void:
	if not _trial_dev_controls_enabled():return
	harvest_sound_test_variant=clampi(variant_index,0,2)
	audio_manager.set_harvest_test_variant(harvest_sound_test_variant,true)
	_refresh_harvest_sound_test_controls()

func _refresh_harvest_sound_test_controls()->void:
	var labels:=["既存","Firefly ①","Firefly ②"]
	for index in range(harvest_sound_test_buttons.size()):
		var selected:=index==harvest_sound_test_variant;harvest_sound_test_buttons[index].disabled=selected;harvest_sound_test_buttons[index].text=("✓ " if selected else "")+labels[index]
	if harvest_sound_test_status:harvest_sound_test_status.text="選択中：%s"%labels[harvest_sound_test_variant]

func _open_settings()->void:
	if play_active:return
	_refresh_progression_dev_counters();settings_overlay.visible=true;_update_play_ui()

func _close_settings()->void:
	settings_overlay.visible=false;_save();_update_play_ui()

func _set_language(value:String)->void:
	language_code=Localizer.normalize_language(value);language_selected=true;_save();_apply_language_to_ui()
	if settings_language_status:settings_language_status.text=Localizer.text(language_code,"language_saved")

func _apply_language_to_ui()->void:
	_refresh_opening_prompt()
	if puku_gauge_label:puku_gauge_label.text=Localizer.text(language_code,"puku_gauge")
	if tutorial_cost_note_label:tutorial_cost_note_label.text=Localizer.text(language_code,"first_normal_cost_notice")
	if play_open_button:play_open_button.text=Localizer.text(language_code,"main_play")
	if shop_button:shop_button.text=Localizer.text(language_code,"main_shop")
	if arrangement_button:arrangement_button.text=Localizer.text(language_code,"main_arrangement")
	if forest_gacha_button:forest_gacha_button.text=Localizer.text(language_code,"main_forest_gacha")
	if fusion_lab_button:fusion_lab_button.text=Localizer.text(language_code,"main_fusion")
	if mode_button:mode_button.text=Localizer.text(language_code,"main_greenhouse" if current_mode=="habitat" else "main_habitat")
	if settings_button:settings_button.text=Localizer.text(language_code,"settings")
	if encyclopedia_icon_button:encyclopedia_icon_button.text=Localizer.text(language_code,"catalog")
	if settings_title_label:settings_title_label.text=Localizer.text(language_code,"settings")
	if settings_language_heading:settings_language_heading.text=Localizer.text(language_code,"language_heading")
	if settings_close_button:settings_close_button.text=Localizer.text(language_code,"close")
	var bgm_toggle:=find_child("BgmToggle",true,false) as CheckButton
	var se_toggle:=find_child("SeToggle",true,false) as CheckButton
	if bgm_toggle:bgm_toggle.text=Localizer.text(language_code,"audio_bgm_on")
	if se_toggle:se_toggle.text=Localizer.text(language_code,"audio_se_on")
	var audio_note:=find_child("AudioSettingsNote",true,false) as Label
	if audio_note:audio_note.text=Localizer.text(language_code,"audio_note")
	if intro_speaker_label:intro_speaker_label.text=Localizer.text(language_code,"story_speaker_panda")
	for code in language_buttons:
		var button:Button=language_buttons[code];button.disabled=str(code)==language_code
	var tab_keys:={"normal":"shop_tab_normal","volume":"shop_tab_volume","premium":"shop_tab_premium","mystery":"shop_tab_mystery"}
	for seed_type in shop_product_tabs:
		if tab_keys.has(seed_type):(shop_product_tabs[seed_type] as Button).text=Localizer.text(language_code,str(tab_keys[seed_type]))
	if shop_category_back_button:shop_category_back_button.text=Localizer.text(language_code,"shop_category_short")
	if shop_catalog_message:shop_catalog_message.text=Localizer.text(language_code,"shop_catalog_preparing")
	if shop_chatter_decline_button:shop_chatter_decline_button.text=Localizer.text(language_code,"no")
	if forest_gacha_ui:forest_gacha_ui.set_language(language_code)
	if fusion_lab_ui:fusion_lab_ui.set_language(language_code)
	if arrangement_ui and arrangement_ui.has_method("set_language"):arrangement_ui.set_language(language_code)
	if habitat_restoration_ui:habitat_restoration_ui.set_language(language_code)
	_set_named_localized_text("PlayChooseTitle","play_choose_seed")
	_set_named_localized_text("PlayCloseButton","close")
	_set_named_localized_text("ShopCloseButton","back")
	_set_named_localized_text("ShopCategoryTitle","shop_choose_category")
	_set_named_localized_text("ShopCategoryPot","shop_category_pot")
	_set_named_localized_text("ShopCategoryCatalog","shop_category_catalog")
	_set_named_localized_text("ShopForestGachaButton","shop_category_gacha")
	_set_named_localized_text("ShopCatalogBack","shop_category_back")
	_set_named_localized_text("ResultTitle","result_title")
	_set_named_localized_text("ResultNotableTitle","result_notable_title")
	_set_named_localized_text("ResultCloseButton","result_close")
	_set_named_localized_text("ResearchRewardTitle","research_reward_title")
	_set_named_localized_text("ResearchRewardNote","research_reward_note")
	_set_named_localized_text("ResearchRewardClose","research_reward_later")
	_set_named_localized_text("EncyclopediaTitle","encyclopedia_title")
	_set_named_localized_text("EncyclopediaCloseButton","back")
	_set_named_localized_text("MainLogo","game_title")
	_set_named_localized_text("BgmToggle","audio_bgm_on")
	_set_named_localized_text("SeToggle","audio_se_on")
	_set_named_localized_text("AudioSettingsNote","audio_note")
	_refresh_series_selection();_refresh_encyclopedia_header();_refresh_encyclopedia_cards();_refresh_collection_complete_badge();_refresh_research_catalog_reward();_update_currency_ui();_update_shop_ui();_update_play_ui()

func _set_named_localized_text(node_name:String,key:String,args:Array=[])->void:
	var control:=find_child(node_name,true,false)
	if control is Label or control is Button:(control as Control).set("text",Localizer.text(language_code,key,args))

func _build_forest_gacha_ui(hud:Control)->void:
	forest_gacha_ui=ForestGachaUIClass.new();hud.add_child(forest_gacha_ui)
	forest_gacha_ui.close_requested.connect(_close_forest_gacha)
	forest_gacha_ui.spin_requested.connect(_spin_forest_gacha)
	forest_gacha_ui.spin_animation_completed.connect(_on_forest_gacha_spin_animation_completed)
	forest_gacha_ui.unlock_requested.connect(_unlock_forest_gacha_series)
	forest_gacha_ui.later_requested.connect(_defer_forest_gacha_series)
	forest_gacha_ui.capsule_reveal_started.connect(_on_forest_gacha_capsule_reveal_started)
	forest_gacha_ui.species_reveal_requested.connect(_on_forest_gacha_species_reveal)
	forest_gacha_ui.set_language(language_code)

func _build_species_get_overlay(hud:Control)->void:
	species_get_overlay=SpeciesGetOverlayClass.new();hud.add_child(species_get_overlay)
	species_get_overlay.closed.connect(_on_species_get_overlay_closed)

func _build_catalog_series_unlock_overlay(hud:Control)->void:
	catalog_series_unlock_overlay=CatalogSeriesUnlockOverlayClass.new();hud.add_child(catalog_series_unlock_overlay)
	catalog_series_unlock_overlay.closed.connect(_on_catalog_series_unlock_overlay_closed)

func _build_fusion_lab_ui(hud:Control)->void:
	fusion_lab_ui=FusionLabUIClass.new();hud.add_child(fusion_lab_ui)
	fusion_lab_ui.close_requested.connect(_close_fusion_lab)
	fusion_lab_ui.parent_selected.connect(_on_fusion_parent_selected)
	fusion_lab_ui.fuse_requested.connect(_perform_fusion)
	fusion_lab_ui.candidate_image_requested.connect(_on_fusion_candidate_image_requested)
	fusion_lab_ui.set_language(language_code)

func _on_fusion_candidate_image_requested(entry:Dictionary,target:TextureRect,high_priority:bool)->void:
	target.texture=_species_loading_texture(entry)
	_request_species_texture(entry,target,high_priority)

func _fusion_lab_available()->bool:
	if fusion_system==null or not _tutorial_fully_complete():return false
	return not fusion_system.eligible_parents(species_get_counts).is_empty()

func _open_fusion_lab()->void:
	if fusion_lab_ui==null or play_active or arrangement_scene_active or arrangement_transitioning or current_mode!="greenhouse" or not _fusion_lab_available():return
	if (encyclopedia_overlay and encyclopedia_overlay.visible) or (settings_overlay and settings_overlay.visible) or (forest_gacha_ui and forest_gacha_ui.visible) or (species_get_overlay and species_get_overlay.visible) or (catalog_series_unlock_overlay and catalog_series_unlock_overlay.visible):return
	play_modal_open=false
	if play_overlay:play_overlay.visible=false
	fusion_return_pending=false
	fusion_parent_a_id="";fusion_parent_b_id=""
	fusion_lab_ui.set_language(language_code)
	fusion_lab_ui.open_lab(fusion_system.eligible_parents(species_get_counts),species_get_counts,"","",species_picker_series_catalog)
	_update_play_ui()

func _close_fusion_lab()->void:
	if fusion_in_progress:return
	fusion_return_pending=false
	if fusion_lab_ui:fusion_lab_ui.close_lab()
	fusion_parent_a_id="";fusion_parent_b_id=""
	_update_play_ui()

func _on_fusion_parent_selected(slot:int,species_id:String)->void:
	if fusion_in_progress or _species_get_count(species_id)<=0 or not fusion_system.is_eligible_parent_species(species_id):return
	if slot==0:fusion_parent_a_id=species_id
	else:fusion_parent_b_id=species_id
	_refresh_fusion_lab_result()

func _refresh_fusion_lab_result()->void:
	if fusion_lab_ui==null:return
	var resolution:Dictionary=fusion_system.resolve(fusion_parent_a_id,fusion_parent_b_id)
	var result_species_id:=str(resolution.get("result_species_id",""))
	var is_new:=not result_species_id.is_empty() and _species_get_count(result_species_id)<=0
	fusion_lab_ui.refresh_selection(fusion_parent_a_id,fusion_parent_b_id,resolution,is_new)
	var result_entry:Dictionary=resolution.get("result_entry",{})
	if result_entry.is_empty():return
	fusion_lab_ui.set_result_texture(_species_loading_texture(result_entry))
	_request_species_texture(result_entry,fusion_lab_ui.result_image,true)

func _perform_fusion(parent_a_id:String,parent_b_id:String)->void:
	if fusion_system==null or fusion_lab_ui==null or fusion_in_progress:return
	if not fusion_system.parents_are_owned(parent_a_id,parent_b_id,species_get_counts):
		fusion_lab_ui.show_error(Localizer.text(language_code,"fusion_parent_missing"));return
	var resolution:Dictionary=fusion_system.resolve(parent_a_id,parent_b_id)
	var result_entry:Dictionary=resolution.get("result_entry",{})
	var result_species_id:=str(resolution.get("result_species_id",""))
	if result_entry.is_empty() or result_species_id.is_empty():
		fusion_lab_ui.show_error(Localizer.text(language_code,"fusion_recipe_missing"));return
	if _species_get_count(result_species_id)>0:
		fusion_lab_ui.set_processing_state(false)
		fusion_lab_ui.show_error(Localizer.text(language_code,"fusion_result_known"))
		return
	var fusion_cost:=maxi(1,int(resolution.get("fusion_cost_puku",1)))
	var fusion_cost_units:=_puku_cost_units(fusion_cost)
	if not _can_afford_puku_units(fusion_cost_units):
		fusion_lab_ui.show_error(Localizer.text(language_code,"not_enough_puku"));return
	fusion_in_progress=true
	fusion_lab_ui.set_processing_state(true)
	var is_new:=_species_get_count(result_species_id)<=0
	# Currency and discovery are committed together and saved exactly once.
	_change_puku_balance(-fusion_cost_units,"fusion",false,true)
	_register_species_discovery(result_species_id,true)
	_apply_saved_unlocks();_sync_arrangement_ui();_refresh_series_selection()
	if encyclopedia_overlay and encyclopedia_overlay.visible:_refresh_encyclopedia_header();_refresh_encyclopedia_cards()
	_save();_update_currency_ui();_update_play_ui()
	await fusion_lab_ui.play_fusion_reveal(_species_texture(result_entry),is_new)
	fusion_in_progress=false
	if is_new:
		fusion_return_pending=true;fusion_lab_ui.visible=false;_update_play_ui()
		_queue_species_get(result_entry,true,"fusion_lab")
	else:
		fusion_lab_ui.set_processing_state(false)
		fusion_lab_ui.show_error(Localizer.text(language_code,"fusion_result_known"))

func _resume_fusion_lab_after_get()->void:
	if not fusion_return_pending or fusion_lab_ui==null or current_mode!="greenhouse":return
	if not species_get_queue.is_empty() or species_get_overlay and species_get_overlay.visible or catalog_series_unlock_overlay and catalog_series_unlock_overlay.visible:return
	fusion_return_pending=false
	fusion_lab_ui.set_language(language_code)
	fusion_lab_ui.open_lab(fusion_system.eligible_parents(species_get_counts),species_get_counts,fusion_parent_a_id,fusion_parent_b_id,species_picker_series_catalog)
	_refresh_fusion_lab_result()
	fusion_lab_ui.move_to_front()
	_update_play_ui()

func _open_forest_gacha()->void:
	if forest_gacha_ui==null or not forest_gacha_unlocked or play_active or arrangement_scene_active or not _tutorial_fully_complete():return
	if (encyclopedia_overlay and encyclopedia_overlay.visible) or (settings_overlay and settings_overlay.visible):return
	forest_gacha_preview_mode=false;forest_gacha_trial_dev_mode=false
	if shop_overlay and shop_overlay.visible:
		_hide_shop_chatter(true);shop_current_page="categories";shop_overlay.visible=false;shop_background.texture=null
		if shop_buy_pulse_tween and shop_buy_pulse_tween.is_valid():shop_buy_pulse_tween.kill()
		shop_buy_pulse_tween=null
	play_modal_open=false;play_overlay.visible=false;forest_gacha_ui.open_gacha(puku_points,forest_gacha_draw_count);audio_manager.play_bgm("shop");_update_play_ui()

func _open_forest_gacha_preview()->void:
	if not _trial_dev_controls_enabled():return
	forest_gacha_preview_mode=true;forest_gacha_trial_dev_mode=false;forest_gacha_preview_puku_points=10;forest_gacha_preview_draw_count=0;forest_gacha_preview_discovered={FIRST_STORY_SPECIES_ID:true};forest_gacha_preview_encountered={}
	if opening_overlay:opening_overlay.visible=false
	if intro_overlay:intro_overlay.visible=false
	if shop_overlay:shop_overlay.visible=false
	if play_overlay:play_overlay.visible=false
	forest_gacha_ui.open_gacha(forest_gacha_preview_puku_points,forest_gacha_preview_draw_count);audio_manager.play_bgm("shop");_update_play_ui()

func _open_trial_dev_forest_gacha()->void:
	if not _is_endless_greenhouse_enabled() or not _trial_dev_controls_enabled() or forest_gacha_ui==null:return
	if arrangement_scene_active:return
	forest_gacha_preview_mode=false;forest_gacha_trial_dev_mode=true
	if settings_overlay:settings_overlay.visible=false
	play_modal_open=false
	if play_overlay:play_overlay.visible=false
	forest_gacha_ui.open_gacha(TRIAL_DEV_GACHA_WALLET,forest_gacha_draw_count)
	if audio_manager:audio_manager.play_bgm("shop")
	_update_play_ui()

func _open_arrangement_test_preview()->void:
	if not _trial_dev_controls_enabled():return
	if opening_overlay:opening_overlay.visible=false
	if intro_overlay:intro_overlay.visible=false
	if shop_overlay:shop_overlay.visible=false
	if play_overlay:play_overlay.visible=false
	var preview_species_id:="colorata"
	if _catalog_entry(preview_species_id).is_empty() and not catalog_species.is_empty():preview_species_id=str(catalog_species[0].get("species_id",""))
	if preview_species_id.is_empty():return
	discovered[preview_species_id]=true;bests[preview_species_id]=90.0;owned_pots["shallow_terracotta"]=maxi(1,_owned_pot_total("shallow_terracotta"))
	_sync_arrangement_ui();arrangement_ui.set_world_backdrop_mode(false,_arrangement_pot_anchor_screen());arrangement_ui.open_home();arrangement_ui._select_editor_pot("shallow_terracotta");arrangement_ui._add_species_to_editor(preview_species_id);_update_play_ui()

func _prepare_jurejure_preview_state()->void:
	if not _trial_dev_controls_enabled():return
	if opening_overlay:opening_overlay.visible=false
	if opening_story_overlay:opening_story_overlay.visible=false
	if intro_overlay:intro_overlay.visible=false
	intro_story_complete=true;first_colorata_confirmed=true;trio_originals_confirmed=true;habitat_unlocked=true;habitat_arrival_started=true;habitat_awakened=true;habitat_awakening_event_complete=true;habitat_tutorial_started=true;habitat_tutorial_complete=true;habitat_tutorial_returned_to_greenhouse=true;mystery_items_acquired=true;seed_shop_open=true;original_catalog_gifted=true
	habitat_second_awakened=false;habitat_second_awakening_complete=false;jurejure_return_event_complete=false;jurejure_waiting_for_seed_pod_reward=false;jurejure_intro_complete=true;jurejure_enabled=true
	unlocked_series[ORIGINAL_SERIES_ID]=true
	for story_species_id in _original_habitat_species_ids():
		discovered[story_species_id]=true;habitat_returned_species[story_species_id]=true
	_ensure_habitat_wild_state(Time.get_unix_time_from_system(),true)
	current_mode="habitat";_apply_saved_unlocks();_apply_mode();_update_play_ui()

func _open_jurejure_habitat_preview()->void:
	if not _trial_dev_controls_enabled():return
	# Browser-only visual QA route; normal visits still choose a random safe point.
	jurejure_habitat_visit_point=Vector2(640,418)
	_prepare_jurejure_preview_state()

func _open_puku_puku_battle_preview()->void:
	if not _trial_dev_controls_enabled():return
	_prepare_jurejure_preview_state()
	_start_puku_puku_battle()

func _close_forest_gacha()->void:
	if forest_gacha_ui:forest_gacha_ui.close_gacha()
	forest_gacha_preview_mode=false;forest_gacha_trial_dev_mode=false
	_play_current_area_bgm();_update_play_ui();call_deferred("_try_start_pending_story_event")

func _spin_forest_gacha()->void:
	if forest_gacha_ui==null or not forest_gacha_ui.visible or forest_gacha_ui.is_busy():return
	if forest_gacha_preview_mode:
		if not _trial_dev_controls_enabled():forest_gacha_ui.cancel_spin_feedback();return
		if forest_gacha_preview_puku_points<FOREST_GACHA_SPIN_COST:forest_gacha_ui.cancel_spin_feedback();return
		var preview_next:=forest_gacha_preview_draw_count+1
		var preview_result:Dictionary=forest_gacha_system.draw({INITIAL_SERIES_ID:true},forest_gacha_preview_discovered,forest_gacha_preview_encountered,forest_gacha_rng)
		if preview_result.is_empty():forest_gacha_ui.cancel_spin_feedback();return
		if str(preview_result.get("source",""))=="locked":preview_result["source"]="unlocked"
		forest_gacha_pending_commit={"mode":"preview","result":preview_result.duplicate(true),"unlocked_series_id":"","next_draw":preview_next};last_forest_gacha_persist_started_msec=-1
		forest_gacha_ui.play_spin(preview_result,CatalogImageLoader.placeholder_texture);return
	if forest_gacha_trial_dev_mode:
		if not _trial_dev_controls_enabled():forest_gacha_ui.cancel_spin_feedback();return
		var trial_next:=forest_gacha_draw_count+1
		var trial_result:Dictionary=forest_gacha_system.draw(unlocked_series,discovered,forest_gacha_encountered,forest_gacha_rng,StoryProgressionClass.fantasy_is_unlocked(story_progression_state),jurejure_species_unlocked)
		if trial_result.is_empty():forest_gacha_ui.cancel_spin_feedback();return
		var trial_unlocked_series_id:=""
		if str(trial_result.get("source",""))=="locked":
			trial_unlocked_series_id=str(trial_result.get("series_id",""));trial_result["source"]="unlocked"
		forest_gacha_pending_commit={"mode":"trial","result":trial_result.duplicate(true),"unlocked_series_id":trial_unlocked_series_id,"next_draw":trial_next};last_forest_gacha_persist_started_msec=-1
		forest_gacha_ui.play_spin(trial_result,CatalogImageLoader.placeholder_texture);return
	var forest_cost_units:=_puku_cost_units(FOREST_GACHA_SPIN_COST)
	if not _can_afford_puku_units(forest_cost_units):
		forest_gacha_ui.cancel_spin_feedback();forest_gacha_ui.set_wallet(puku_points,forest_gacha_draw_count);return
	var next_draw:=forest_gacha_draw_count+1
	var result:Dictionary=forest_gacha_system.draw(unlocked_series,discovered,forest_gacha_encountered,forest_gacha_rng,StoryProgressionClass.fantasy_is_unlocked(story_progression_state),jurejure_species_unlocked)
	if result.is_empty():forest_gacha_ui.cancel_spin_feedback();return
	var unlocked_series_id:=""
	if str(result.get("source",""))=="locked":
		unlocked_series_id=str(result.get("series_id",""));result["source"]="unlocked"
	# Store the finalized draw in memory and start the real 3.4-turn animation in
	# this input call. Persistence and catalog/UI maintenance wait until every dial
	# and capsule tween has completed, so they cannot stall the visible motion.
	forest_gacha_pending_commit={"mode":"live","result":result.duplicate(true),"unlocked_series_id":unlocked_series_id,"next_draw":next_draw};last_forest_gacha_persist_started_msec=-1
	forest_gacha_ui.play_spin(result,CatalogImageLoader.placeholder_texture)

func _on_forest_gacha_spin_animation_completed()->void:
	if forest_gacha_pending_commit.is_empty():return
	var transaction:=forest_gacha_pending_commit.duplicate(true);forest_gacha_pending_commit.clear()
	last_forest_gacha_persist_started_msec=Time.get_ticks_msec();last_forest_gacha_persist_ended_msec=-1;last_forest_gacha_persist_duration_msec=-1;last_forest_gacha_registration_duration_msec=-1;last_forest_gacha_save_duration_msec=-1;last_forest_gacha_ui_update_duration_msec=-1
	if forest_gacha_ui==null:return
	var mode:=str(transaction.get("mode",""));var result:Dictionary=transaction.get("result",{})
	var unlocked_series_id:=str(transaction.get("unlocked_series_id",""));var next_draw:=int(transaction.get("next_draw",0))
	var species_id:=str(result.get("species_id",""))
	if mode=="preview":
		forest_gacha_preview_puku_points-=FOREST_GACHA_SPIN_COST;forest_gacha_preview_draw_count=next_draw
		forest_gacha_preview_discovered[species_id]=true
		var preview_ui_started_msec:=Time.get_ticks_msec()
		forest_gacha_ui.set_wallet(forest_gacha_preview_puku_points,forest_gacha_preview_draw_count)
		last_forest_gacha_registration_duration_msec=0;last_forest_gacha_save_duration_msec=0;last_forest_gacha_ui_update_duration_msec=maxi(0,Time.get_ticks_msec()-preview_ui_started_msec)
		last_forest_gacha_persist_ended_msec=Time.get_ticks_msec();last_forest_gacha_persist_duration_msec=maxi(0,last_forest_gacha_persist_ended_msec-last_forest_gacha_persist_started_msec)
		return
	forest_gacha_draw_count=next_draw
	if mode=="live":_change_puku_balance(-_puku_cost_units(FOREST_GACHA_SPIN_COST),"forest_gacha",false,true)
	if not unlocked_series_id.is_empty():unlocked_series[unlocked_series_id]=true
	var registration_started_msec:=Time.get_ticks_msec();_register_species_discovery(species_id,true);last_forest_gacha_registration_duration_msec=maxi(0,Time.get_ticks_msec()-registration_started_msec)
	if not unlocked_series_id.is_empty():_queue_catalog_series_unlock_notice(unlocked_series_id)
	var save_started_msec:=Time.get_ticks_msec();_save();last_forest_gacha_save_duration_msec=maxi(0,Time.get_ticks_msec()-save_started_msec)
	var ui_started_msec:=Time.get_ticks_msec();_update_currency_ui();_sync_arrangement_ui();forest_gacha_ui.set_wallet(TRIAL_DEV_GACHA_WALLET if mode=="trial" else puku_points,forest_gacha_draw_count);last_forest_gacha_ui_update_duration_msec=maxi(0,Time.get_ticks_msec()-ui_started_msec)
	last_forest_gacha_persist_ended_msec=Time.get_ticks_msec();last_forest_gacha_persist_duration_msec=maxi(0,last_forest_gacha_persist_ended_msec-last_forest_gacha_persist_started_msec)

func _unlock_forest_gacha_series(series_id:String,_species_id:String)->void:
	if forest_gacha_ui==null or not forest_gacha_ui.visible:return
	var entry:=_series_entry(series_id)
	if entry.is_empty():forest_gacha_ui.show_unlock_error(Localizer.text(language_code,"forest_catalog_missing"));return
	var localized_series_name:=Localizer.series_name(language_code,entry)
	if forest_gacha_preview_mode:
		forest_gacha_ui.show_unlock_complete(Localizer.text(language_code,"forest_unlock_complete_one",[localized_series_name]),forest_gacha_preview_puku_points,forest_gacha_preview_draw_count);return
	var registered:=_unlock_series_and_register_encounters(series_id)
	_save();_update_currency_ui();_sync_arrangement_ui();_refresh_series_selection()
	var message_key:="forest_unlock_complete_many" if registered.size()>1 else "forest_unlock_complete_one"
	var message_args:Array=[localized_series_name,registered.size()] if registered.size()>1 else [localized_series_name]
	forest_gacha_ui.show_unlock_complete(Localizer.text(language_code,message_key,message_args),puku_points,forest_gacha_draw_count);audio_manager.play_se("new_species",.72)

func _defer_forest_gacha_series(_series_id:String,_species_id:String)->void:
	if forest_gacha_ui==null:return
	forest_gacha_ui.show_later_message(Localizer.text(language_code,"forest_deferred"),puku_points,forest_gacha_draw_count)

func _on_forest_gacha_capsule_reveal_started()->void:
	_begin_gacha_capsule_profile()

func _on_forest_gacha_species_reveal(result:Dictionary)->void:
	if not gacha_capsule_profile_active:_begin_gacha_capsule_profile()
	_gacha_capsule_profile_mark("handler_entry")
	var entry:Dictionary=result.get("species_entry",{})
	_queue_species_get(entry,not bool(result.get("was_discovered",false)),"forest_gacha",true)

func _queue_species_get(entry:Dictionary,is_new:bool,context:String,show_immediately:=false)->void:
	if entry.is_empty():
		_on_species_get_overlay_closed(context)
		return
	species_get_queue.append({"entry":entry.duplicate(true),"is_new":is_new,"context":context})
	if species_get_overlay and not species_get_overlay.visible and (catalog_series_unlock_overlay==null or not catalog_series_unlock_overlay.visible):
		if show_immediately:_show_next_species_get()
		else:call_deferred("_show_next_species_get")

func _queue_species_get_by_id(species_id:String,is_new:bool,context:String)->void:
	_queue_species_get(_catalog_entry(species_id),is_new,context)

func _show_next_species_get()->void:
	if species_get_overlay==null or species_get_overlay.visible or catalog_series_unlock_overlay and catalog_series_unlock_overlay.visible or species_get_queue.is_empty():return
	var queued:Dictionary=species_get_queue.pop_front();var entry:Dictionary=queued.get("entry",{});species_get_active_context=str(queued.get("context",""))
	species_get_active_species_id=str(entry.get("species_id",""))
	species_get_active_series_id=_series_id_for_species(str(entry.get("species_id","")))
	if species_get_active_series_id in catalog_series_unlock_notice_queue:catalog_series_unlock_notice_ready[species_get_active_series_id]=true
	var forest_gacha_reveal:=species_get_active_context=="forest_gacha"
	var first_colorata_reveal:=species_get_active_context=="first_colorata" and species_get_active_species_id==FIRST_STORY_SPECIES_ID and old_colorata_profile_active
	var texture:=CatalogImageLoader.placeholder_texture if forest_gacha_reveal else _species_texture(entry)
	if forest_gacha_reveal:_gacha_capsule_profile_mark("get_card_show_start")
	if first_colorata_reveal:_old_colorata_profile_mark("get_card_show_start")
	species_get_overlay.show_species(entry,texture if texture!=null else CatalogImageLoader.placeholder_texture,bool(queued.get("is_new",true)),species_get_active_context,language_code)
	if forest_gacha_reveal:
		gacha_capsule_profile_started_with_placeholder=species_get_overlay.result_image.texture==CatalogImageLoader.placeholder_texture
		if forest_gacha_ui:forest_gacha_ui.complete_capsule_reveal_transition()
		call_deferred("_finish_gacha_capsule_first_display",gacha_capsule_profile_run_id,entry.duplicate(true),species_get_active_species_id)
	else:
		_request_species_texture(entry,species_get_overlay.result_image,true)
		if first_colorata_reveal:call_deferred("_finish_old_colorata_profile_after_rendered_frame",old_colorata_profile_run_id)
	if audio_manager:audio_manager.play_se("new_species",.9)

func _gacha_capsule_profile_requested()->bool:
	if gacha_capsule_profile_enabled:return true
	if not OS.has_feature("web"):return false
	return bool(JavaScriptBridge.eval("new URL(window.location.href).searchParams.has('gacha_capsule_profile')",true))

func _gacha_capsule_profile_record_at(event_name:String,event_msec:int)->void:
	if not gacha_capsule_profile_active or event_msec<0:return
	if not gacha_capsule_profile_events.has(event_name):gacha_capsule_profile_event_order.append(event_name)
	gacha_capsule_profile_events[event_name]=event_msec

func _gacha_capsule_profile_mark(event_name:String)->void:
	_gacha_capsule_profile_record_at(event_name,Time.get_ticks_msec())

func _begin_gacha_capsule_profile()->void:
	if not _gacha_capsule_profile_requested() or forest_gacha_ui==null:return
	gacha_capsule_profile_enabled=true;gacha_capsule_profile_active=true;gacha_capsule_profile_run_id+=1
	gacha_capsule_profile_events.clear();gacha_capsule_profile_event_order.clear();gacha_capsule_profile_slow_sections.clear();gacha_capsule_profile_total_msec=-1;gacha_capsule_profile_started_with_placeholder=false
	gacha_capsule_profile_decode_count_start=CatalogImageLoader.decode_count
	gacha_capsule_profile_decode_total_start=CatalogImageLoader.total_decode_duration_msec
	_gacha_capsule_profile_record_at("capsule_tap",forest_gacha_ui.last_capsule_tap_msec)
	_gacha_capsule_profile_record_at("first_visual_response",forest_gacha_ui.last_capsule_first_visual_msec)

func _finish_gacha_capsule_first_display(profile_run_id:int,entry:Dictionary,species_id:String)->void:
	if DisplayServer.get_name()=="headless":await get_tree().process_frame
	else:await RenderingServer.frame_post_draw
	if gacha_capsule_profile_active and profile_run_id==gacha_capsule_profile_run_id:
		_gacha_capsule_profile_mark("first_display_frame")
		gacha_capsule_profile_total_msec=int(gacha_capsule_profile_events.get("first_display_frame",0))-int(gacha_capsule_profile_events.get("capsule_tap",0))
		var segment_text:Array[String]=[]
		for index in range(1,gacha_capsule_profile_event_order.size()):
			var previous_name:=gacha_capsule_profile_event_order[index-1];var current_name:=gacha_capsule_profile_event_order[index]
			var elapsed:=int(gacha_capsule_profile_events[current_name])-int(gacha_capsule_profile_events[previous_name])
			var description:="%s->%s=%dms"%[previous_name,current_name,elapsed];segment_text.append(description)
			if elapsed>=50:gacha_capsule_profile_slow_sections.append(description)
		var tap_msec:=int(gacha_capsule_profile_events.get("capsule_tap",-1))
		var save_overlapped:=last_forest_gacha_persist_started_msec>=0 and last_forest_gacha_persist_ended_msec>tap_msec and last_forest_gacha_persist_started_msec<tap_msec
		var decode_count_delta:=maxi(0,CatalogImageLoader.decode_count-gacha_capsule_profile_decode_count_start)
		var decode_duration_delta:=maxi(0,CatalogImageLoader.total_decode_duration_msec-gacha_capsule_profile_decode_total_start)
		if decode_duration_delta>=50:gacha_capsule_profile_slow_sections.append("png_decode=%dms"%decode_duration_delta)
		if last_forest_gacha_registration_duration_msec>=50:gacha_capsule_profile_slow_sections.append("registration=%dms"%last_forest_gacha_registration_duration_msec)
		if last_forest_gacha_save_duration_msec>=50:gacha_capsule_profile_slow_sections.append("save=%dms"%last_forest_gacha_save_duration_msec)
		if last_forest_gacha_ui_update_duration_msec>=50:gacha_capsule_profile_slow_sections.append("ui_update=%dms"%last_forest_gacha_ui_update_duration_msec)
		print("GACHA_CAPSULE_PROFILE run=",gacha_capsule_profile_run_id," total_ms=",gacha_capsule_profile_total_msec," segments=",", ".join(segment_text)," slow_50ms=",("none" if gacha_capsule_profile_slow_sections.is_empty() else ", ".join(gacha_capsule_profile_slow_sections))," placeholder_first=",gacha_capsule_profile_started_with_placeholder," save_overlap=",save_overlapped," registration_ms=",last_forest_gacha_registration_duration_msec," save_ms=",last_forest_gacha_save_duration_msec," ui_ms=",last_forest_gacha_ui_update_duration_msec," persist_ms=",last_forest_gacha_persist_duration_msec," decode_count=",decode_count_delta," decode_ms=",decode_duration_delta)
		gacha_capsule_profile_active=false
	# Start texture work only after the placeholder card has reached a rendered
	# frame. Cached images replace it immediately; Web requests/decode remain async.
	if species_get_overlay and species_get_overlay.visible and species_get_active_context=="forest_gacha" and species_get_active_species_id==species_id:
		_request_species_texture(entry,species_get_overlay.result_image,true)

func _old_colorata_profile_requested()->bool:
	if old_colorata_profile_enabled:return true
	if not OS.has_feature("web"):return false
	return bool(JavaScriptBridge.eval("new URL(window.location.href).searchParams.has('old_colorata_profile')",true))

func _old_colorata_profile_record_at(event_name:String,event_msec:int)->void:
	if not old_colorata_profile_active or event_msec<0:return
	if not old_colorata_profile_events.has(event_name):old_colorata_profile_event_order.append(event_name)
	old_colorata_profile_events[event_name]=event_msec

func _old_colorata_profile_mark(event_name:String)->void:
	_old_colorata_profile_record_at(event_name,Time.get_ticks_msec())

func _begin_old_colorata_profile(tap_msec:int)->void:
	if not _old_colorata_profile_requested():return
	old_colorata_profile_enabled=true;old_colorata_profile_active=true;old_colorata_profile_run_id+=1
	old_colorata_profile_events.clear();old_colorata_profile_event_order.clear();old_colorata_profile_slow_sections.clear()
	old_colorata_profile_save_count=0;old_colorata_profile_tap_to_first_visual_msec=-1;old_colorata_profile_tap_to_get_start_msec=-1
	_old_colorata_profile_record_at("tap_start",tap_msec)

func _finish_old_colorata_profile_after_rendered_frame(profile_run_id:int)->void:
	if DisplayServer.get_name()=="headless":await get_tree().process_frame
	else:await RenderingServer.frame_post_draw
	if not old_colorata_profile_active or profile_run_id!=old_colorata_profile_run_id:return
	_old_colorata_profile_mark("get_card_first_frame")
	var tap_msec:=int(old_colorata_profile_events.get("tap_start",-1))
	var first_visual_msec:=int(old_colorata_profile_events.get("first_visual_response",-1))
	var get_start_msec:=int(old_colorata_profile_events.get("get_card_show_start",-1))
	old_colorata_profile_tap_to_first_visual_msec=maxi(-1,first_visual_msec-tap_msec)
	old_colorata_profile_tap_to_get_start_msec=maxi(-1,get_start_msec-tap_msec)
	var segment_text:Array[String]=[]
	for index in range(1,old_colorata_profile_event_order.size()):
		var previous_name:=old_colorata_profile_event_order[index-1];var current_name:=old_colorata_profile_event_order[index]
		var elapsed:=int(old_colorata_profile_events[current_name])-int(old_colorata_profile_events[previous_name])
		var description:="%s->%s=%dms"%[previous_name,current_name,elapsed];segment_text.append(description)
		if elapsed>=50:old_colorata_profile_slow_sections.append(description)
	print("OLD_COLORATA_PROFILE tap_to_first_visual_ms=",old_colorata_profile_tap_to_first_visual_msec," tap_to_get_start_ms=",old_colorata_profile_tap_to_get_start_msec," segments=",", ".join(segment_text)," slow_50ms=",("none" if old_colorata_profile_slow_sections.is_empty() else ", ".join(old_colorata_profile_slow_sections))," save_count=",old_colorata_profile_save_count)
	old_colorata_profile_active=false

func _get_close_profile_record_at(event_name:String,event_msec:int)->void:
	if not get_close_profile_enabled or not get_close_profile_active or event_msec<0:return
	if not get_close_profile_events.has(event_name):get_close_profile_event_order.append(event_name)
	get_close_profile_events[event_name]=event_msec

func _get_close_profile_mark(event_name:String)->void:
	_get_close_profile_record_at(event_name,Time.get_ticks_msec())

func _get_close_profile_begin_from_overlay(context:String)->void:
	if not get_close_profile_enabled or context!="round_result_new" or species_get_overlay==null:return
	get_close_profile_run_id+=1
	get_close_profile_active=true
	get_close_profile_events.clear();get_close_profile_event_order.clear();get_close_profile_slow_sections.clear()
	get_close_profile_total_msec=-1;get_close_profile_save_count=0
	_get_close_profile_record_at("close_tap",species_get_overlay.last_close_input_msec)
	_get_close_profile_record_at("overlay_visible_false",species_get_overlay.last_close_hidden_msec)
	_get_close_profile_record_at("closed_emit",species_get_overlay.last_close_emitted_msec)
	_get_close_profile_mark("handler_entry")

func _finish_get_close_profile_after_rendered_frame(profile_run_id:int)->void:
	if not get_close_profile_enabled or profile_run_id!=get_close_profile_run_id or get_close_profile_events.is_empty():return
	if DisplayServer.get_name()=="headless":await get_tree().process_frame
	else:await RenderingServer.frame_post_draw
	if profile_run_id!=get_close_profile_run_id:return
	_get_close_profile_mark("input_ready")
	get_close_profile_total_msec=int(get_close_profile_events["input_ready"])-int(get_close_profile_events["close_tap"])
	var segment_text:Array[String]=[]
	for index in range(1,get_close_profile_event_order.size()):
		var previous_name:=get_close_profile_event_order[index-1]
		var current_name:=get_close_profile_event_order[index]
		var elapsed:=int(get_close_profile_events[current_name])-int(get_close_profile_events[previous_name])
		var description:="%s->%s=%dms"%[previous_name,current_name,elapsed]
		segment_text.append(description)
		if elapsed>=50:get_close_profile_slow_sections.append(description)
	print("GET_CLOSE_PROFILE total_ms=",get_close_profile_total_msec," segments=",", ".join(segment_text)," slow_50ms=",("none" if get_close_profile_slow_sections.is_empty() else ", ".join(get_close_profile_slow_sections)))
	get_close_profile_active=false

func _on_species_get_overlay_closed(context:String)->void:
	_get_close_profile_begin_from_overlay(context)
	_mark_collection_complete_get_card_seen(species_get_active_species_id)
	_get_close_profile_mark("collection_seen_end")
	species_get_active_context=""
	species_get_active_species_id=""
	var closed_series_id:=species_get_active_series_id
	species_get_active_series_id=""
	if not closed_series_id.is_empty() and closed_series_id in catalog_series_unlock_notice_queue:
		if _show_catalog_series_unlock_notice(closed_series_id,context):return
	_continue_after_species_get_card(context)

func _on_catalog_series_unlock_overlay_closed(context:String)->void:
	catalog_series_unlock_active_id=""
	_continue_after_species_get_card(context)

func _defer_followup_for_collection_complete(context:String)->bool:
	if collection_complete_presentation_active or not _collection_completion_pending():return false
	if collection_complete_resume_context.is_empty() and not context.is_empty():collection_complete_resume_context=context
	collection_complete_resume_shop_visible=collection_complete_resume_shop_visible or (shop_overlay!=null and shop_overlay.visible)
	if not species_get_queue.is_empty():
		call_deferred("_show_next_species_get")
		return true
	if context=="round_result_new" or round_result_species_finalize_active or not round_result_species_finalize_queue.is_empty():
		call_deferred("_show_next_round_result_species")
		return true
	if not _collection_complete_get_card_seen():
		call_deferred("_queue_species_get_by_id",_collection_completion_last_species_id(),true,"collection_complete_recovery")
		return true
	if _try_start_catalog_series_unlock_notice():return true
	if not catalog_series_unlock_notice_queue.is_empty():return true
	call_deferred("_start_collection_complete_presentation")
	return true

func _continue_after_species_get_card(context:String)->void:
	if _defer_followup_for_collection_complete(context):return
	var followup_started:=false
	var continue_round_result_queue:=false
	var close_foreground_for_story:=_immediate_get_story_transition_pending()
	match context:
		"first_colorata":
			followup_started=true;call_deferred("_start_first_colorata_discovery_event")
		"forest_gacha":
			if forest_gacha_ui:
				if close_foreground_for_story:
					forest_gacha_ui.close_gacha();forest_gacha_preview_mode=false;forest_gacha_trial_dev_mode=false;_play_current_area_bgm();_update_play_ui()
				else:forest_gacha_ui.resume_after_species_reveal()
		"fusion_lab":
			if close_foreground_for_story:
				if fusion_lab_ui:fusion_lab_ui.visible=false
			else:
				followup_started=true
				call_deferred("_resume_fusion_lab_after_get")
		"habitat_tutorial":
			followup_started=true;call_deferred("_start_seed_pod_story")
		"pinwheel_gift":
			call_deferred("_continue_armadillo_mystery_intro")
		"round_result_new":
			followup_started=true;continue_round_result_queue=true
	if context.begins_with("scripted_dialog_card:"):
		followup_started=true
		intro_continue_button.disabled=false
		intro_overlay.visible=true
		intro_overlay.move_to_front()
		call_deferred("_advance_scripted_dialog")
	if not species_get_queue.is_empty():call_deferred("_show_next_species_get")
	elif continue_round_result_queue:call_deferred("_show_next_round_result_species")
	elif _is_endless_normal_play() and first_play_has_harvested and not puku_buyback_tutorial_complete:
		followup_started=true;call_deferred("_start_puku_buyback_tutorial")
	elif not followup_started:call_deferred("_try_start_pending_story_event")

func _immediate_get_story_transition_pending()->bool:
	if habitat_crisis_pending or act3_intro_pending and not act3_intro_seen:return true
	var event_id:=StoryProgressionClass.peek_story_event(story_progression_state)
	if event_id in [StoryProgressionClass.EVENT_FANTASY_FIRST,StoryProgressionClass.EVENT_FANTASY_SIX]:return true
	return _unique_jurejure_species_get_count()>=1 and not jurejure_species_first_seen

func _continue_armadillo_mystery_intro()->void:
	var pages:Array=[
		{"speaker":"armadillo","text":Localizer.text(language_code,"armadillo_mystery_1")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"armadillo_mystery_2")}
	]
	if mystery_seed_count>0:
		pages.append({"speaker":"armadillo","text":Localizer.text(language_code,"mystery_seed_owned")})
		pages.append({"speaker":"armadillo","text":Localizer.text(language_code,"mystery_seed_request")})
	_start_scripted_dialog("armadillo_mystery_intro",pages,true)

func _change_audio_enabled(enabled:bool,is_bgm:bool)->void:
	audio_settings["bgm_enabled" if is_bgm else "se_enabled"]=enabled;audio_manager.apply_settings(audio_settings);_save()

func _change_audio_volume(value:float,is_bgm:bool)->void:
	audio_settings["bgm_volume" if is_bgm else "se_volume"]=value/100.0;audio_manager.apply_settings(audio_settings);_save()

func _reset_progression_state()->void:
	_end_first_play_tutorial_context()
	_reset_collection_complete_presentation(true)
	collection_complete_versions.clear();collection_complete_pending_species_id="";collection_complete_resume_context="";collection_complete_resume_shop_visible=false
	fusion_parent_a_id="";fusion_parent_b_id="";fusion_in_progress=false;fusion_return_pending=false
	if fusion_lab_ui:fusion_lab_ui.close_lab()
	if catalog_series_unlock_overlay:catalog_series_unlock_overlay.reset_overlay()
	catalog_series_unlock_active_id="";species_get_active_series_id="";species_get_active_species_id=""
	endless_greenhouse.reset_discovery_state()
	pending_restoration_snapshot.clear()
	if habitat_restoration_ui:habitat_restoration_ui.reset_view()
	old_seed_reaction_stage=0;old_seed_harvest_guide_active=false;habitat_lookaround_active=false;habitat_lookaround_elapsed=0.0;habitat_lookaround_context="";jurejure_first_encounter_active=false;jurejure_intro_camera_active=false;jurejure_intro_camera_elapsed=0.0;jurejure_camera_focus_context=""
	_cancel_all_habitat_notifications()
	old_catalog_pages=0;old_catalog_page_inventory.clear();old_catalog_intro_seen=false;old_catalog_intro_pending=false;habitat_old_catalog_page_pending=false;habitat_old_catalog_page_series_id="";old_catalog_page_roll_play_count=-1;research_catalog_reward_pending=false
	JellyBalanceClass.reset_formal();jelly_trait_display_enabled=false;dev_jelly_test_active=false;last_jelly_claim_msec=-1000000000
	rain_completion_count=0;best_100_achieved=false;shop_selected_seed_type="normal"
	first_tutorial_species_id="";habitat_wild_plants.clear();habitat_wild_initialized=false;habitat_wild_next_spawn_unix=0.0;habitat_tutorial_started=false;habitat_tutorial_complete=false;habitat_tutorial_species_id="";original_catalog_gifted=false;panda_beacon_unlocked=false;panda_beacon_count=0;panda_beacon_unread_log.clear();first_habitat_gift_claimed=false;armadillo_intro_event_3_completed=false;armadillo_series_event_7_completed=false;pending_armadillo_story_event="";armadillo_gift_series_id="";armadillo_gift_species_id="";scripted_dialog_kind="";scripted_dialog_pages.clear();scripted_dialog_index=-1
	first_colorata_confirmed=false;trio_originals_confirmed=false;habitat_arrival_started=false;habitat_awakened=false;habitat_awakening_event_complete=false;seed_shop_open=false;mystery_items_acquired=false;mystery_catalog_tutorial_complete=false;normal_play_tutorial_complete=false;seed_pod_gauge_discovery_complete=false;seed_pod_first_reward_seen=false;initial_seed_stock_notice_complete=false;puku_buyback_tutorial_complete=false;puku_buyback_tutorial_active=false;puku_buyback_tutorial_index=0;habitat_returned_species.clear();special_series_explanation_seen=false;pending_special_series_explanation=false;main_story_stage=StoryProgressionClass.ACT_1;main_story_complete=false;main_story_completion_seen=false;catalog_series_unlock_notice_queue.clear();catalog_series_unlock_notice_ready.clear()
	act2_unlocked=false;story_progression_state=StoryProgressionClass.default_runtime_state();forest_gacha_unlocked=false;forest_gacha_intro_seen=false;fantasy_first_discovery_seen=false;fantasy_realization_seen=false;act3_unlocked=false;act3_intro_pending=false;act3_intro_seen=false;jurejure_pool_unlocked=false;jurejure_species_unlocked.clear();jurejure_species_first_seen=false;habitat_crisis_pending=false;habitat_crisis_started=false;finale_complete=false;habitat_return_dialog_seen=false
	original_catalog_complete_event_seen=false;habitat_tutorial_returned_to_greenhouse=false;jurejure_intro_complete=false;jurejure_enabled=false;jurejure_growth_stage=JureJureSystemClass.GROWTH_EARLY;jurejure_growth_event_mask=0;active_jurejure_event={};jurejure_next_check_unix=0.0;jurejure_cooldown_until_unix=0.0;jurejure_return_event_complete=false;jurejure_waiting_for_seed_pod_reward=false;jurejure_battle_count=0;jurejure_battle_win_count=0;jurejure_habitat_visit_point=Vector2(-1.0,-1.0);jurejure_pending_reward_species_id="";jurejure_pending_reward_is_new=false;jurejure_last_battle_result.clear();habitat_second_awakened=false;habitat_second_awakening_complete=false;jurejure_update_accumulator=0.0
	first_seed_pod_reward_event_active=false;habitat_visit_id=0;jurejure_focused_habitat_visit_id=-1;act3_intro_eligible_visit_id=0;habitat_crisis_eligible_visit_id=0
	if habitat_crisis_atmosphere:habitat_crisis_atmosphere.deactivate()
	_cancel_puku_gauge_animations();puku_gauge_cm=0.0;puku_balance_units=0;bests.clear();discovered.clear();species_get_counts.clear();catalog_cover_species.clear();unlocked_series={INITIAL_SERIES_ID:true};series_seed_inventory.clear();forest_gacha_draw_count=0;forest_gacha_encountered.clear();active_series_seed_id="";owned_pots={DEFAULT_POT_ID:1};saved_arrangements.clear();arrangement_save_capacity=20;greenhouse_available=_initial_greenhouse_state();unlocked_species=greenhouse_available.duplicate(true);completed_unlock_conditions.clear();pending_habitat_species.clear();total_play_count=0;formal_play_count=0;opening_story_complete=false;intro_story_complete=false;encyclopedia_unlocked=false;habitat_unlocked=false;puku_gauge_intro_complete=false;tutorial_steps.clear();normal_seed_bags=0;volume_seed_bags=0;premium_seed_bags=0;mystery_seed_bags=0;old_seed_bags=0;volume_seed_unlocked=false;volume_seed_intro_seen=false;premium_seed_unlocked=false;mystery_seed_pack_unlocked=false;login_bonus_date="";habitat_seed_date="";habitat_seeds_collected=0;habitat_mystery_seeds_pending=0;mystery_seed_count=0;armadillo_research_total=0;armadillo_research_rewards.clear();armadillo_research_intro_seen=false;armadillo_dialog_mode="";opening_species.clear();result_new_species_queue.clear();result_deferred_species_queue.clear();pending_round_new_species_ids.clear();round_result_species_finalize_queue.clear();round_result_species_finalize_active=false;round_result_species_save_pending=false;shop_chatter_acquired_species.clear();species_get_queue.clear();play_share_record.clear();play_active=false;play_time_remaining=0.0;play_harvest_cm_total=0.0;play_puku_reward_units_total=0;current_target_count=NORMAL_GERMINATION_COUNT;play_seeds_remaining=0;play_spawn_queue=0;play_seed_animations_pending=0;play_spawn_timer=0.0;play_concurrent_target=PLAY_INITIAL_MAX_PLANTS;_reset_endless_economy_stats();rain_bag_count=0;rain_event_pending=false;rain_bonus_in_progress=false;rain_bonus_active=false;rain_time_remaining=0.0;rain_spawn_queue=0;rain_spawn_timer=0.0;rain_last_saved_second=-1;rain_intro_normal_bags=0;rain_draws_unlocked=false;habitat_time_multiplier=1;habitat_simulation_unix=Time.get_unix_time_from_system();habitat_debug_log.clear();habitat_scroll_tutorial_active=false;tutorial_habitat_item.clear();_stop_rain_visual();_apply_saved_unlocks();_clear_greenhouse_plants();_clear_habitat_items();_save();_update_currency_ui();_update_play_ui()
	normal_round_free_plays=0
	normal_play_count=0;shop_visit_count=0;hidden_species_acquired.clear();tovar_next_play=TOVAR_FIRST_PLAY;tovar_attempt_count=0;tovar_event_active=false;tovar_harvested_this_play=false;armadillo_present=false;_save()

func _reset_progression_for_development(button:Button)->void:
	if not _trial_dev_controls_enabled():return
	_reset_progression_state();button.text="リセットしました（再読み込みしてください）"

func _build_result_overlay(hud:Control)->void:
	result_overlay=Control.new();result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);result_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;result_overlay.visible=false;hud.add_child(result_overlay)
	var shade:=ColorRect.new();shade.color=Color(0.08,0.05,0.035,.68);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;result_overlay.add_child(shade)
	result_card=PanelContainer.new();result_card.position=Vector2(54,150);result_card.size=Vector2(468,730);result_card.clip_contents=true;result_card.add_theme_stylebox_override("panel",_box(Color("#f7e8c7"),Color("#c8944f"),28,4));result_overlay.add_child(result_card)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",15);result_card.add_child(content)
	var title:=Label.new();title.name="ResultTitle";title.text="今回の収穫";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",30);title.add_theme_color_override("font_color",UI_BROWN);content.add_child(title)
	result_total_label=Label.new();result_total_label.custom_minimum_size=Vector2(410,108);result_total_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;result_total_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;result_total_label.add_theme_font_size_override("font_size",19);result_total_label.add_theme_color_override("font_color",Color("#b06c24"));content.add_child(result_total_label)
	result_count_label=_result_line_label();content.add_child(result_count_label)
	result_max_label=_result_line_label();content.add_child(result_max_label)
	var divider:=HSeparator.new();divider.custom_minimum_size=Vector2(380,10);content.add_child(divider)
	var notable_title:=Label.new();notable_title.name="ResultNotableTitle";notable_title.text="目立った収穫株";notable_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;notable_title.add_theme_font_size_override("font_size",19);notable_title.add_theme_color_override("font_color",Color("#725039"));content.add_child(notable_title)
	result_notable_label=Label.new();result_notable_label.custom_minimum_size=Vector2(390,112);result_notable_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;result_notable_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;result_notable_label.add_theme_font_size_override("font_size",18);result_notable_label.add_theme_color_override("font_color",UI_BROWN);content.add_child(result_notable_label)
	result_new_species_label=Label.new();result_new_species_label.custom_minimum_size=Vector2(400,52);result_new_species_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;result_new_species_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;result_new_species_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;result_new_species_label.add_theme_font_size_override("font_size",23);result_new_species_label.add_theme_color_override("font_color",Color("#b75432"));result_new_species_label.add_theme_color_override("font_outline_color",Color("#fff6c7"));result_new_species_label.add_theme_constant_override("outline_size",5);result_new_species_label.visible=false;content.add_child(result_new_species_label)
	result_share_button=Button.new();result_share_button.text=Localizer.text(language_code,"share_prompt");result_share_button.custom_minimum_size=Vector2(350,54);result_share_button.visible=false;_skin_button(result_share_button,Color("#d7aa64"),18);result_share_button.pressed.connect(_share_personal_best);content.add_child(result_share_button)
	result_share_status=Label.new();result_share_status.custom_minimum_size=Vector2(390,28);result_share_status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;result_share_status.add_theme_font_size_override("font_size",14);result_share_status.add_theme_color_override("font_color",Color("#79543a"));result_share_status.visible=false;content.add_child(result_share_status)
	var close:=Button.new();close.name="ResultCloseButton";close.text="閉じる / 戻る";close.custom_minimum_size=Vector2(350,54);_skin_button(close,Color("#ead8b1"),17);close.pressed.connect(_close_result);content.add_child(close)
	result_confetti_layer=Control.new();result_confetti_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);result_confetti_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;result_overlay.add_child(result_confetti_layer)

func _result_line_label()->Label:
	var label:=Label.new();label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",21);label.add_theme_color_override("font_color",Color("#65432e"));return label

func _clear_result_confetti()->void:
	if result_record_pulse_tween and result_record_pulse_tween.is_valid():result_record_pulse_tween.kill()
	result_record_pulse_tween=null
	if result_max_label:result_max_label.scale=Vector2.ONE
	if not result_confetti_layer:return
	for piece in result_confetti_layer.get_children():piece.free()

func _play_result_confetti()->void:
	_clear_result_confetti()
	_spawn_confetti(result_confetti_layer)

func _on_arrangement_completion_confetti_requested(layer:Control)->void:
	_spawn_confetti(layer)

func _spawn_confetti(layer:Control)->void:
	if layer==null:return
	for existing_piece in layer.get_children():existing_piece.queue_free()
	var colors:=[Color("#c98758"),Color("#d8b66a"),Color("#91a982"),Color("#c98b83"),Color("#e5d3a1")]
	for i in range(40):
		var piece:=ColorRect.new();piece.color=colors[rng.randi_range(0,colors.size()-1)];piece.color.a=.88;piece.size=Vector2(rng.randf_range(4.0,7.0),rng.randf_range(8.0,13.0));piece.position=Vector2(rng.randf_range(64.0,512.0),rng.randf_range(-65.0,115.0));piece.rotation=rng.randf_range(-1.0,1.0);piece.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(piece)
		var destination:=piece.position+Vector2(rng.randf_range(-34.0,34.0),rng.randf_range(500.0,710.0));var duration:=rng.randf_range(2.8,4.0)
		var tween:=create_tween().bind_node(piece).set_parallel();tween.tween_property(piece,"position",destination,duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN);tween.tween_property(piece,"rotation",piece.rotation+rng.randf_range(2.0,5.0),duration);tween.tween_property(piece,"modulate:a",0.0,.7).set_delay(duration-.7);tween.chain().tween_callback(piece.queue_free)

func _start_result_record_pulse()->void:
	result_max_label.pivot_offset=result_max_label.size*.5;result_max_label.scale=Vector2.ONE
	result_record_pulse_tween=create_tween().set_loops();result_record_pulse_tween.tween_property(result_max_label,"scale",Vector2(1.10,1.10),.52).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT);result_record_pulse_tween.tween_property(result_max_label,"scale",Vector2.ONE,.52).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _open_play_modal()->void:
	if play_active or current_mode!="greenhouse":return
	if _first_old_seed_play_pending():
		play_modal_open=false
		_start_greenhouse_play("old")
		return
	if _endless_normal_flow_owns_play_controls():
		play_modal_open=false
		if play_overlay:play_overlay.visible=false
		if puku_gauge_intro_complete and normal_round_free_plays<=0 and not _can_afford_puku_units(NORMAL_ROUND_COST_UNITS):
			_open_shop()
			return
		_start_greenhouse_play("normal")
		return
	play_modal_open=true;_update_play_ui()

func _first_old_seed_play_pending()->bool:
	return intro_story_complete and total_play_count==0 and old_seed_bags>0 and not _has_any_playable_seed_stock()

func _close_play_modal()->void:
	play_modal_open=false;_update_play_ui()

func _start_greenhouse_play(seed_type:String)->void:
	dev_jelly_test_active=false
	if play_active or catalog_preview_mode_active:return
	# A NEW harvested in an interrupted round is already earned, but its formal
	# catalog registration belongs to the post-result reveal sequence. Resolve
	# that foreground before charging or starting another round.
	if not pending_round_new_species_ids.is_empty():
		call_deferred("_play_result_new_species_animations")
		return
	active_series_seed_id=""
	if seed_type.begins_with("series:"):
		active_series_seed_id=seed_type.trim_prefix("series:")
		if int(series_seed_inventory.get(active_series_seed_id,0))<1 or not bool(unlocked_series.get(active_series_seed_id,false)):return
		if _series_seed_draw_candidates(active_series_seed_id).is_empty():return
		series_seed_inventory[active_series_seed_id]=maxi(0,int(series_seed_inventory.get(active_series_seed_id,0)))-1;current_target_count=1
	elif seed_type=="old":
		if old_seed_bags<1:return
		old_seed_bags-=1;current_target_count=OLD_SEED_GERMINATION_COUNT
	elif seed_type=="volume":
		if not _volume_seed_unlocked() or volume_seed_bags<1:return
		volume_seed_bags-=1;current_target_count=VOLUME_GERMINATION_COUNT
	elif seed_type=="premium":
		if not _premium_seed_unlocked():return
		if premium_seed_bags<1:return
		premium_seed_bags-=1;current_target_count=PREMIUM_GERMINATION_COUNT
	elif seed_type=="mystery":
		if not _mystery_seed_pack_unlocked() or mystery_seed_bags<1:return
		mystery_seed_bags-=1;current_target_count=MYSTERY_GERMINATION_COUNT
	else:
		if not _normal_seed_play_available():return
		if _is_endless_greenhouse_enabled() and puku_gauge_intro_complete and normal_round_free_plays<=0 and not _can_afford_puku_units(NORMAL_ROUND_COST_UNITS):return
		if not _is_endless_greenhouse_enabled():normal_seed_bags-=1
		current_target_count=NORMAL_GERMINATION_COUNT
	if seed_type=="old" and total_play_count==0:_ensure_first_tutorial_species()
	active_seed_type=seed_type;old_seed_reaction_stage=0;old_seed_harvest_guide_active=false;tutorial_harvest_plant=null;play_time_remaining=0.0;play_active=true;play_modal_open=false;play_harvest_cm_total=0.0;play_puku_reward_units_total=0;play_harvest_count=0;play_max_size=0.0;play_previous_global_best=_global_best_size();play_updated_global_best=false;play_share_record.clear();play_notable_species.clear();play_hidden_species_unlocked="";result_new_species_queue.clear();result_deferred_species_queue.clear();round_result_species_finalize_queue.clear();round_result_species_finalize_active=false;round_result_species_save_pending=false;opening_species.clear();play_seeds_remaining=current_target_count;play_spawn_queue=0;play_seed_animations_pending=0;play_spawn_timer=0.0;play_concurrent_target=_initial_greenhouse_concurrent_target(seed_type);greenhouse_finish_attempt_count=0;greenhouse_finish_completed_count=0;greenhouse_finish_last_block_reason="";greenhouse_finish_last_snapshot.clear();_clear_greenhouse_plants();_reset_endless_economy_stats()
	if seed_type=="normal" and _is_endless_greenhouse_enabled():
		endless_greenhouse.begin_play()
		if puku_gauge_intro_complete:
			if normal_round_free_plays>0:
				normal_round_free_plays-=1
			else:
				var paid_units:=_change_puku_balance(-NORMAL_ROUND_COST_UNITS,"normal_round_start",false,true)
				if paid_units!=-NORMAL_ROUND_COST_UNITS:
					play_active=false;_update_play_ui();return
	if seed_type=="normal":_prepare_story_spawn_guarantee()
	if result_overlay:result_overlay.visible=false
	for i in range(play_concurrent_target):
		if not _spawn_greenhouse_seed(true):break
	_prepare_tovar_event_for_play()
	if seed_type=="normal" and mystery_items_acquired and not normal_play_tutorial_complete:_begin_first_play_tutorial()
	audio_manager.play_se("rare_seed" if seed_type in ["premium","mystery"] or seed_type.begins_with("series:") else "seed_bag",.72)
	_save();_update_play_ui()

func _initial_greenhouse_concurrent_target(seed_type:String)->int:
	if seed_type.begins_with("series:"):return 1
	if seed_type=="old":return OLD_SEED_GERMINATION_COUNT
	if seed_type=="normal" and _is_endless_greenhouse_enabled():return rng.randi_range(ENDLESS_NORMAL_MIN_PLANTS,ENDLESS_NORMAL_MAX_PLANTS)
	return mini(current_target_count,rng.randi_range(PLAY_INITIAL_MIN_PLANTS,PLAY_INITIAL_MAX_PLANTS))

func _ensure_first_tutorial_species()->String:
	first_tutorial_species_id=FIRST_STORY_SPECIES_ID
	return first_tutorial_species_id

func _finish_greenhouse_play()->void:
	greenhouse_finish_attempt_count+=1
	greenhouse_finish_last_snapshot={"play_active":play_active,"plants_size":plants.size(),"play_seeds_remaining":play_seeds_remaining,"play_spawn_queue":play_spawn_queue,"play_seed_animations_pending":play_seed_animations_pending,"first_play_tutorial_active":first_play_tutorial_active,"first_play_tutorial_sequence_complete":first_play_tutorial_sequence_complete,"result_overlay_visible":result_overlay.visible if result_overlay else false}
	greenhouse_finish_last_block_reason=_greenhouse_finish_block_reason()
	if not greenhouse_finish_last_block_reason.is_empty():return
	if old_colorata_profile_active:_old_colorata_profile_mark("round_finish_start")
	greenhouse_finish_completed_count+=1
	var completed_endless_round:=_is_endless_normal_play()
	play_active=false;play_time_remaining=0.0;play_spawn_timer=0.0;_end_first_play_tutorial_context()
	if not completed_endless_round:
		total_play_count+=1
		var formal_play:=_tutorial_fully_complete() and active_seed_type!="old"
		if formal_play:
			formal_play_count+=1
			habitat_mystery_seeds_pending+=rng.randi_range(0,3)
			_refresh_seed_pack_unlocks()
		_resolve_tovar_event_after_play()
	if total_play_count==1:
		if first_tutorial_species_id.is_empty():_ensure_first_tutorial_species()
		_register_species_discovery(first_tutorial_species_id,false);greenhouse_available[first_tutorial_species_id]=true;unlocked_species=greenhouse_available.duplicate(true);_apply_saved_unlocks();unlocked_series[INITIAL_SERIES_ID]=true
	_evaluate_unlock_rules("play_count",float(total_play_count))
	if completed_endless_round:_log_endless_economy("round_complete")
	_clear_greenhouse_plants();_save();_update_play_ui();_show_play_result();audio_manager.play_se("result",.7)
	if old_colorata_profile_active:_old_colorata_profile_mark("round_finish_end")

func _greenhouse_finish_block_reason()->String:
	if habitat_restoration_ui and habitat_restoration_ui.is_modal_visible():return "habitat_restoration_event"
	if first_seed_pod_reward_event_active:return "first_seed_pod_reward_event"
	if puku_buyback_tutorial_active:return "puku_buyback_tutorial"
	if first_play_tutorial_active and not first_play_tutorial_sequence_complete:return "first_play_tutorial_sequence_incomplete"
	if not play_active:return "play_inactive"
	if play_seeds_remaining>0:return "play_seeds_remaining"
	if play_spawn_queue>0:return "play_spawn_queue"
	if play_seed_animations_pending>0:return "play_seed_animations_pending"
	if not plants.is_empty():return "plants_remaining"
	if _is_endless_normal_play() and (puku_gauge_animation_running or not puku_gauge_animation_queue.is_empty()):return "puku_gauge_animation"
	return ""

func _poll_greenhouse_play_completion()->void:
	if current_mode!="greenhouse" or not play_active or dev_jelly_test_active or catalog_preview_mode_active:return
	greenhouse_finish_last_block_reason=_greenhouse_finish_block_reason()
	if greenhouse_finish_last_block_reason.is_empty():_finish_greenhouse_play()

func _prepare_tovar_event_for_play()->void:
	tovar_event_active=false;tovar_harvested_this_play=false

func _resolve_tovar_event_after_play()->void:
	if not _tutorial_fully_complete() or active_seed_type not in ["normal","volume","premium"]:return
	normal_play_count+=1
	tovar_event_active=false;tovar_harvested_this_play=false

func _queue_armadillo_progress_event()->void:
	pending_armadillo_story_event=""

func _start_pending_armadillo_story()->bool:
	return false

func _prepare_armadillo_series_gift()->void:
	if not armadillo_gift_series_id.is_empty() and not armadillo_gift_species_id.is_empty():return
	var candidates:Array[Dictionary]=[]
	for rule_value in catalog_progression.get("normal_series",[]):
		if not rule_value is Dictionary:continue
		var series_id:=str(rule_value.get("series_id",""));var entry:=_series_entry(series_id)
		if series_id in [INITIAL_SERIES_ID,ORIGINAL_SERIES_ID] or entry.is_empty() or _is_series_unlocked(entry):continue
		if _series_species_entries(series_id).is_empty():continue
		candidates.append(entry)
	if candidates.is_empty():return
	var chosen_series:Dictionary=candidates[rng.randi_range(0,candidates.size()-1)];armadillo_gift_series_id=str(chosen_series.get("series_id",""))
	var gift_species:=_series_species_entries(armadillo_gift_series_id);var preferred:Array[Dictionary]=[]
	for entry in gift_species:
		if not bool(discovered.get(str(entry.get("species_id","")),false)):preferred.append(entry)
	var source:=preferred if not preferred.is_empty() else gift_species
	armadillo_gift_species_id=str(source[rng.randi_range(0,source.size()-1)].get("species_id",""))
	_save()

func _spawn_specific_plant(species_id:String,is_catalog_preview:=false)->void:
	if is_catalog_preview and (not _trial_dev_controls_enabled() or not DEVELOPMENT_CATALOG_PREVIEW_ENABLED):return
	var chosen:=_catalog_entry(species_id)
	if chosen.is_empty():return
	var spawn_rng:=catalog_preview_rng if is_catalog_preview else rng
	var pos:=_find_spawn_position(spawn_rng);var label:=_plant_label();labels_layer.add_child(label)
	var p=SucculentClass.new();p.original_pos=pos;p.position=pos;p.set_meta("catalog_preview",is_catalog_preview);world_root.add_child(p);p.setup(chosen,spawn_rng.randi(),label,null)
	if is_catalog_preview:
		p.harvested.connect(_on_catalog_preview_harvested);p.jellied.connect(_on_catalog_preview_jellied)
	else:
		p.jelly_permission=Callable(self,"_allow_plant_jelly").bind(p);p.harvested.connect(_on_harvested);p.jellied.connect(_on_jellied)
	plants.append(p)
	if audio_manager:audio_manager.play_se("sprout",.28)

func _catalog_entry(species_id:String)->Dictionary:
	for entry in catalog_species:
		if str(entry.get("species_id",""))==species_id:return entry
	return {}

func _clear_greenhouse_plants()->void:
	for plant in plants.duplicate():
		if is_instance_valid(plant):
			if plant.label and is_instance_valid(plant.label):plant.label.free()
			plant.free()
	plants.clear();recent_vacated_slots.clear();pending_seed_positions.clear()

func _current_mission_text()->String:
	var restoration:=_restoration_state()
	var ending_phase:=HabitatRestorationClass.ending_phase(restoration)
	if ending_phase=="complete" or bool(restoration.get("ending_seen",false)):
		return ""
	if not ending_phase.is_empty() or HabitatRestorationClass.returned_count(restoration)>=HabitatRestorationClass.REQUIRED_RETURNED_PLANTS:return ""
	if habitat_crisis_pending:return ""
	if habitat_crisis_started:
		if not bool(story_progression_state.get("post_crisis_greenhouse_seen",false)):return ""
		var returned:=HabitatRestorationClass.returned_count(restoration)
		return Localizer.text(language_code,"mission_return_large",[mini(5,returned)])
	if act3_unlocked and not act3_intro_seen:return ""
	if StoryProgressionClass.exploitation_is_started(story_progression_state) or act3_intro_seen:
		return Localizer.text(language_code,"mission_jurejure_species",[mini(8,_unique_jurejure_species_get_count())])
	if act2_unlocked:
		return Localizer.text(language_code,"mission_fantasy_species",[mini(24,_unique_act2_species_get_count())])
	return ""

func _mission_foreground_safe()->bool:
	return not ((opening_overlay and opening_overlay.visible) \
		or (opening_story_overlay and opening_story_overlay.visible) \
		or (habitat_awakening_overlay and habitat_awakening_overlay.visible) \
		or (seed_pod_story_overlay and seed_pod_story_overlay.visible) \
		or (habitat_second_awakening_overlay and habitat_second_awakening_overlay.visible) \
		or (jurejure_first_encounter_overlay and jurejure_first_encounter_overlay.visible) \
		or (intro_overlay and intro_overlay.visible) \
		or (tutorial_guide_overlay and tutorial_guide_overlay.visible) \
		or (result_overlay and result_overlay.visible) \
		or (play_overlay and play_overlay.visible) \
		or (species_get_overlay and species_get_overlay.visible) \
		or (catalog_series_unlock_overlay and catalog_series_unlock_overlay.visible) \
		or (forest_gacha_ui and forest_gacha_ui.visible) \
		or (fusion_lab_ui and fusion_lab_ui.visible) \
		or (encyclopedia_overlay and encyclopedia_overlay.visible) \
		or (shop_overlay and shop_overlay.visible) \
		or (settings_overlay and settings_overlay.visible) \
		or (habitat_plant_panel and habitat_plant_panel.visible) \
		or (habitat_dev_panel and habitat_dev_panel.visible) \
		or (story_dev_panel and story_dev_panel.visible) \
		or (catalog_preview_ui and catalog_preview_ui.is_overlay_open()) \
		or (arrangement_ui and arrangement_ui.visible) \
		or (puku_puku_battle and puku_puku_battle.visible) \
		or (habitat_restoration_ui and habitat_restoration_ui.is_modal_visible()))

func _update_mission_ui()->void:
	if mission_panel==null:return
	var mission_text:=_current_mission_text()
	mission_title_label.text=Localizer.text(language_code,"mission_title")
	mission_text_label.text=mission_text
	mission_panel.visible=not play_active and not mission_text.is_empty() and _mission_foreground_safe() and not arrangement_scene_active and not arrangement_transitioning

func _update_play_ui()->void:
	if not play_overlay:return
	var preview_overlay_open:bool=catalog_preview_ui!=null and catalog_preview_ui.is_overlay_open()
	var gacha_open:bool=(forest_gacha_ui!=null and forest_gacha_ui.visible) or (species_get_overlay!=null and species_get_overlay.visible) or (catalog_series_unlock_overlay!=null and catalog_series_unlock_overlay.visible) or (fusion_lab_ui!=null and fusion_lab_ui.visible)
	var battle_open:bool=puku_puku_battle!=null and puku_puku_battle.visible
	var habitat_modal_open:bool=battle_open or (habitat_plant_panel!=null and habitat_plant_panel.visible) or (habitat_dev_panel!=null and habitat_dev_panel.visible) or (story_dev_panel!=null and story_dev_panel.visible) or (habitat_awakening_overlay!=null and habitat_awakening_overlay.visible) or (seed_pod_story_overlay!=null and seed_pod_story_overlay.visible) or (habitat_second_awakening_overlay!=null and habitat_second_awakening_overlay.visible)
	var conversation_navigation_suspended:bool=(intro_overlay!=null and intro_overlay.visible) or not scripted_dialog_kind.is_empty() or not tutorial_dialog_kind.is_empty()
	var arrangement_navigation_suspended:bool=arrangement_scene_active or arrangement_transitioning or catalog_preview_mode_active or preview_overlay_open or gacha_open or habitat_modal_open or conversation_navigation_suspended or jurejure_intro_camera_active or habitat_lookaround_active
	var arrangement_hud_hidden:bool=arrangement_scene_active or arrangement_transitioning
	var endless_owns_normal_flow:=_endless_normal_flow_owns_play_controls()
	var normal_round_start_visible:=not endless_owns_normal_flow or _endless_greenhouse_auto_start_unlocked()
	var external_navigation_available:=not play_active
	if main_status_hud:main_status_hud.visible=not arrangement_hud_hidden and not battle_open
	if labels_layer:labels_layer.visible=not arrangement_hud_hidden and not battle_open
	if best_panel:best_panel.visible=mystery_catalog_tutorial_complete and not _old_seed_story_active()
	if puku_gauge_area:puku_gauge_area.visible=mystery_items_acquired
	if seed_pod_gauge_area:seed_pod_gauge_area.visible=mystery_items_acquired and not _is_endless_greenhouse_enabled()
	if trial_dev_gacha_button:trial_dev_gacha_button.visible=_is_endless_greenhouse_enabled() and _trial_dev_controls_enabled()
	play_overlay.visible=current_mode=="greenhouse" and not play_active and play_modal_open and not endless_owns_normal_flow
	play_open_button.visible=current_mode=="greenhouse" and intro_story_complete and not play_active and not play_modal_open and normal_round_start_visible and not arrangement_navigation_suspended and (not result_overlay or not result_overlay.visible) and (not shop_overlay or not shop_overlay.visible) and (not encyclopedia_overlay or not encyclopedia_overlay.visible) and (not settings_overlay or not settings_overlay.visible) and (not arrangement_ui or not arrangement_ui.visible)
	if endless_owns_normal_flow:
		var round_is_free:=normal_round_free_plays>0 or not puku_gauge_intro_complete
		var rescue_needed:=not round_is_free and not _can_afford_puku_units(NORMAL_ROUND_COST_UNITS)
		play_open_button.text=Localizer.text(language_code,"play_normal_seed_round_help" if rescue_needed else ("play_normal_seed_round_free" if round_is_free else "play_normal_seed_round"))
		play_open_button.add_theme_font_size_override("font_size",14 if rescue_needed or not round_is_free else 17)
		play_open_button.text_overrun_behavior=TextServer.OVERRUN_NO_TRIMMING if not rescue_needed and not round_is_free else TextServer.OVERRUN_TRIM_ELLIPSIS
		play_open_button.clip_text=not (not rescue_needed and not round_is_free)
		play_open_button.disabled=false
	else:
		play_open_button.text=Localizer.text(language_code,"play_first_old_seed" if _first_old_seed_play_pending() else "main_play")
		play_open_button.add_theme_font_size_override("font_size",21)
		play_open_button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		play_open_button.clip_text=true
		play_open_button.disabled=false
	seed_bag_panel.visible=current_mode=="greenhouse" and play_active and active_seed_type!="old" and not _is_endless_normal_play()
	play_timer_label.visible=seed_bag_panel.visible
	for control in external_navigation_controls:control.visible=external_navigation_available and not arrangement_navigation_suspended
	for control in encyclopedia_navigation_controls:control.visible=external_navigation_available and not arrangement_navigation_suspended and mystery_items_acquired and encyclopedia_unlocked
	if mode_button:mode_button.visible=not play_active and not arrangement_navigation_suspended and habitat_unlocked
	if habitat_dev_open_button:habitat_dev_open_button.visible=_trial_dev_controls_enabled() and current_mode=="habitat" and not play_active and not arrangement_navigation_suspended
	if shop_button:shop_button.visible=not play_active and not arrangement_navigation_suspended and current_mode=="greenhouse" and _tutorial_fully_complete()
	if forest_gacha_button:forest_gacha_button.visible=not play_active and not arrangement_navigation_suspended and current_mode=="greenhouse" and _tutorial_fully_complete() and forest_gacha_unlocked and forest_gacha_intro_seen
	if fusion_lab_button:fusion_lab_button.visible=not play_active and not arrangement_navigation_suspended and current_mode=="greenhouse" and _fusion_lab_available()
	if shop_forest_gacha_button:shop_forest_gacha_button.visible=forest_gacha_unlocked and forest_gacha_intro_seen
	if arrangement_navigation_hint:
		arrangement_navigation_hint.update_hint(language_code,arrangement_scene_active,_arrangement_navigation_hint_safe())
	if habitat_restoration_ui:
		var restoration_hud_safe:=current_mode=="greenhouse" and not arrangement_navigation_suspended and not arrangement_scene_active and (not opening_overlay or not opening_overlay.visible) and (not opening_story_overlay or not opening_story_overlay.visible) and (not intro_overlay or not intro_overlay.visible) and (not result_overlay or not result_overlay.visible) and (not shop_overlay or not shop_overlay.visible) and (not encyclopedia_overlay or not encyclopedia_overlay.visible) and (not settings_overlay or not settings_overlay.visible) and (not play_overlay or not play_overlay.visible)
		var restoration_state:=_restoration_state()
		habitat_restoration_ui.update_lamps(HabitatRestorationClass.returned_count(restoration_state),HabitatRestorationClass.should_show_progress(restoration_state) and restoration_hud_safe)
	_update_mission_ui()
	_update_habitat_button_glow()
	play_timer_label.text=Localizer.text(language_code,"series_seed_remaining" if active_seed_type.begins_with("series:") else "seed_remaining",[play_seeds_remaining]) if play_timer_label.visible else ""
	var held:Array[String]=[]
	if old_seed_bags>0:held.append(Localizer.text(language_code,"bags_held",[Localizer.text(language_code,"old_seed_name"),old_seed_bags]))
	if not _is_endless_greenhouse_enabled() and normal_seed_bags>0:held.append(Localizer.text(language_code,"normal_sets_held",[normal_seed_bags]))
	if volume_seed_bags>0 and _volume_seed_unlocked():held.append(Localizer.text(language_code,"bags_held",[Localizer.seed_name(language_code,"volume","ボリューム"),volume_seed_bags]))
	if premium_seed_bags>0 and _premium_seed_unlocked():held.append(Localizer.text(language_code,"bags_held",[Localizer.seed_name(language_code,"premium","プレミアムたね"),premium_seed_bags]))
	if mystery_seed_bags>0 and _mystery_seed_pack_unlocked():held.append(Localizer.text(language_code,"bags_held",[Localizer.seed_name(language_code,"mystery","謎種"),mystery_seed_bags]))
	play_bag_summary.text="　".join(held)
	old_seed_play_button.visible=old_seed_bags>0;old_seed_play_button.text=Localizer.text(language_code,"play_old_seed",[old_seed_bags])
	var normal_seed_available:=_normal_seed_play_available();normal_play_button.visible=normal_seed_available and not _is_endless_greenhouse_enabled();normal_play_button.text=Localizer.text(language_code,"play_normal_seed",[normal_seed_bags]);normal_play_button.disabled=not normal_seed_available
	volume_play_button.visible=volume_seed_bags>0 and _volume_seed_unlocked();volume_play_button.text=Localizer.text(language_code,"play_volume_seed",[volume_seed_bags]);volume_play_button.disabled=not _volume_seed_unlocked() or volume_seed_bags<1
	premium_play_button.visible=premium_seed_bags>0 and _premium_seed_unlocked();premium_play_button.text=Localizer.text(language_code,"play_premium_seed",[premium_seed_bags]);premium_play_button.disabled=not _premium_seed_unlocked() or premium_seed_bags<1
	mystery_play_button.visible=mystery_seed_bags>0 and _mystery_seed_pack_unlocked();mystery_play_button.text=Localizer.text(language_code,"play_mystery_seed",[mystery_seed_bags]);mystery_play_button.disabled=not _mystery_seed_pack_unlocked() or mystery_seed_bags<1

func _open_shop()->void:
	if catalog_preview_mode_active or play_active:return
	if not _tutorial_fully_complete():
		shop_overlay.visible=false;_set_shop_purchase_visible(false);_update_play_ui();return
	play_modal_open=false;shop_current_page="categories";_set_shop_purchase_visible(true);_update_shop_ui();shop_message.text=Localizer.text(language_code,"shop_seed_info");play_overlay.visible=false;shop_chatter_bubble.visible=false;shop_overlay.visible=true;audio_manager.play_bgm("shop");_prepare_shop_visit();_update_play_ui()
	if _shop_rescue_needed():_show_shop_chatter(Localizer.text(language_code,"shop_puku_rescue_offer" if _shop_puku_rescue_needed() else "shop_rescue_offer"),true)
	elif not pending_armadillo_story_event.is_empty():call_deferred("_start_pending_armadillo_story")

func _prepare_shop_visit(force_armadillo:Variant=null)->void:
	_refresh_seed_pack_unlocks()
	if not _tutorial_fully_complete():
		armadillo_present=false;shop_background.texture=load("res://assets/shop-background-final.jpg");armadillo_tap_button.visible=false;_save();return
	shop_visit_count+=1
	armadillo_present=bool(force_armadillo) if force_armadillo!=null else (old_catalog_pages>0 or research_catalog_reward_pending or mystery_seed_count>0 or rng.randi_range(1,5)==1)
	shop_background.texture=load("res://assets/shop-background-armadillo.jpg" if armadillo_present else "res://assets/shop-background-final.jpg")
	armadillo_tap_button.visible=armadillo_present
	if old_catalog_intro_pending:
		old_catalog_intro_pending=false;old_catalog_intro_seen=true
		_start_shop_chatter_sequence("old_catalog_intro",[Localizer.text(language_code,"old_page_intro_1"),Localizer.text(language_code,"old_page_intro_2")],"panda")
	_save()

func _on_armadillo_tapped()->void:
	if not armadillo_present:return
	if shop_chatter_bubble.visible:_dismiss_or_advance_shop_chatter();return
	if act2_unlocked and old_catalog_pages>0 and not _next_restorable_hidden_series().is_empty():
		_start_hidden_catalog_restoration()
	elif act2_unlocked and research_catalog_reward_pending:
		_open_research_catalog_reward()
	elif mystery_seed_count>0:
		_start_armadillo_research()
	else:
		var lines:=[Localizer.text(language_code,"armadillo_idle_1"),Localizer.text(language_code,"armadillo_idle_2"),Localizer.text(language_code,"armadillo_idle_3")]
		_show_shop_chatter(lines[rng.randi_range(0,lines.size()-1)],false,"normal","armadillo")

func _start_armadillo_research()->void:
	if mystery_seed_count<=0:return
	if not armadillo_research_intro_seen:
		_start_shop_chatter_sequence("research_intro",[Localizer.text(language_code,"research_intro_1"),Localizer.text(language_code,"research_intro_2"),Localizer.text(language_code,"research_intro_3")],"armadillo")
	else:_show_shop_chatter(Localizer.text(language_code,"research_return_offer"),false,"research_offer","armadillo")

func _grant_old_catalog_page(amount:int=1,show_intro:=true,series_id:="")->void:
	if amount<=0:return
	if series_id.is_empty():
		var entry:=_first_unowned_hidden_series()
		if entry.is_empty():return
		series_id=str(entry.get("series_id",""))
	if series_id.is_empty():return
	_unlock_series_and_register_encounters(series_id)
	old_catalog_page_inventory.erase(series_id);_sync_old_catalog_page_count();old_catalog_intro_pending=false

func _sync_old_catalog_page_count()->void:
	old_catalog_pages=0
	for series_id in old_catalog_page_inventory:old_catalog_pages+=maxi(0,int(old_catalog_page_inventory.get(series_id,0)))

func _remove_old_catalog_page(amount:int=1)->void:
	var remaining:=maxi(0,amount)
	for raw_rule in catalog_progression.get("hidden_series",[]):
		var series_id:=str(raw_rule.get("series_id",""));var held:=maxi(0,int(old_catalog_page_inventory.get(series_id,0)));var removed:=mini(held,remaining)
		if removed>0:old_catalog_page_inventory[series_id]=held-removed;remaining-=removed
		if int(old_catalog_page_inventory.get(series_id,0))<=0:old_catalog_page_inventory.erase(series_id)
		if remaining<=0:break
	_sync_old_catalog_page_count()
	if old_catalog_pages<=0 and not old_catalog_intro_seen:old_catalog_intro_pending=false

func _start_hidden_catalog_restoration()->void:
	_accept_hidden_catalog_restoration()

func _accept_hidden_catalog_restoration()->void:
	var entry:=_next_restorable_hidden_series()
	if entry.is_empty() or old_catalog_pages<=0:_hide_shop_chatter(true);return
	var series_id:=str(entry.get("series_id",""));old_catalog_page_inventory[series_id]=maxi(0,int(old_catalog_page_inventory.get(series_id,0))-1)
	if int(old_catalog_page_inventory.get(series_id,0))<=0:old_catalog_page_inventory.erase(series_id)
	_sync_old_catalog_page_count();_unlock_series_and_register_encounters(series_id)
	_save();_update_currency_ui();_sync_arrangement_ui();_refresh_progression_dev_counters()
	_show_shop_chatter(Localizer.text(language_code,"restore_success",[Localizer.series_name(language_code,entry)]),false,"catalog_restore_result","armadillo")

func _decline_armadillo_research()->void:
	if armadillo_dialog_mode=="research_offer":armadillo_research_intro_seen=true
	_save();_hide_shop_chatter(true)

func _accept_armadillo_research()->void:
	if mystery_seed_count<=0:_hide_shop_chatter(true);return
	shop_chatter_sequence_kind="";shop_chatter_pages.clear();shop_chatter_page_index=0
	var amount:=mystery_seed_count;var previous_total:=armadillo_research_total
	mystery_seed_count=0;armadillo_research_total+=amount;armadillo_research_intro_seen=true
	var research_species:Array[String]=[]
	var reward_messages:=_grant_armadillo_research_milestones(previous_total,armadillo_research_total,research_species)
	_show_mystery_seed_transfer(armadillo_research_total)
	var message:=_armadillo_research_message(armadillo_research_total,amount)
	if not reward_messages.is_empty():message+="\n\n"+"\n".join(reward_messages)
	_save();_update_shop_ui();_update_play_ui();_update_habitat_ui();_show_shop_chatter(message,false,"research_result","armadillo",research_species)

func _armadillo_research_message(total:int,amount:int)->String:
	if total==18:return Localizer.text(language_code,"research_status_sprouted")
	if total>=19 and total<=24:return Localizer.text(language_code,"research_status_growing")
	if total>=14 and total<=17:return Localizer.text(language_code,"research_status_trying")
	if total>=26:return Localizer.text(language_code,"research_status_world")
	if total>=9:return Localizer.text(language_code,"research_status_progress")
	if total>=2:return Localizer.text(language_code,"research_status_thanks")
	return Localizer.text(language_code,"research_status_first",[amount])

func _grant_armadillo_research_milestones(previous_total:int,new_total:int,new_species:Array[String]=[])->Array[String]:
	var messages:Array[String]=[]
	if previous_total<8 and new_total>=8 and not bool(armadillo_research_rewards.get("8",false)):
		research_catalog_reward_pending=true;messages.append(Localizer.text(language_code,"research_milestone_catalog"))
	if previous_total<13 and new_total>=13 and not bool(armadillo_research_rewards.get("13",false)):
		normal_seed_bags+=1;messages.append(Localizer.text(language_code,"research_milestone_seed_instead"))
		armadillo_research_rewards["13"]=true
	if previous_total<18 and new_total>=18 and not bool(armadillo_research_rewards.get("18",false)):
		armadillo_research_rewards["18"]=true;messages.append(Localizer.text(language_code,"research_milestone_sprout"))
	if act2_unlocked and new_total>=35 and not bool(armadillo_research_rewards.get("35",false)):
		if _grant_hidden_species("golden_laui"):new_species.append("golden_laui")
		armadillo_research_rewards["35"]=true;messages.append(Localizer.text(language_code,"research_milestone_gold"))
	var milestone:=40
	while milestone<=new_total:
		var key:=str(milestone)
		if previous_total<milestone and not bool(armadillo_research_rewards.get(key,false)):
			normal_seed_bags+=1;armadillo_research_rewards[key]=true;messages.append(Localizer.text(language_code,"research_milestone_seed"))
		milestone+=5
	if new_total>=13:_build_habitat_items()
	return messages

func _show_mystery_seed_transfer(amount:int)->void:
	shop_transfer_notice.text=Localizer.text(language_code,"research_transfer",[amount]);shop_transfer_notice.modulate=Color.WHITE;shop_transfer_notice.visible=true

func _hidden_species_owned(species_id:String)->bool:
	return bool(hidden_species_acquired.get(species_id,false)) or bool(discovered.get(species_id,false))

func _grant_hidden_species(species_id:String)->bool:
	if _hidden_species_owned(species_id):return false
	hidden_species_acquired[species_id]=true;_register_species_discovery(species_id,true)
	# Save migration can grant a legacy route before _ready() creates audio.
	if audio_manager:audio_manager.play_se("new_species",.62)
	_save()
	return true

func _close_shop()->void:
	_hide_shop_chatter(true);shop_current_page="categories";shop_overlay.visible=false;shop_background.texture=null
	if shop_buy_pulse_tween and shop_buy_pulse_tween.is_valid():shop_buy_pulse_tween.kill()
	shop_buy_pulse_tween=null;_play_current_area_bgm();_update_play_ui();call_deferred("_try_start_pending_story_event")

func _buy_seed_bag(seed_type:String)->void:
	if not _tutorial_fully_complete():return
	_show_seed_shop_message(Localizer.text(language_code,"shop_seed_info"))

func _show_seed_shop_message(message:String)->void:
	if shop_message:shop_message.text=message
	if arrangement_ui and arrangement_ui.seed_shop_page.visible:arrangement_ui.show_seed_shop_message(message)

func _select_shop_product(seed_type:String)->void:
	shop_selected_seed_type=seed_type;shop_message.text="";_update_shop_ui()

func _buy_selected_shop_product()->void:
	_buy_seed_bag(shop_selected_seed_type)

func _update_shop_ui()->void:
	if not shop_wallet_label:return
	shop_wallet_label.text=Localizer.text(language_code,"wallet",[puku_points]);shop_bag_label.text=Localizer.text(language_code,"shop_seed_info")
	for seed_type in shop_product_tabs:
		var tab:Button=shop_product_tabs[seed_type];tab.self_modulate=Color(1.12,1.08,.88,1.0) if str(seed_type)==shop_selected_seed_type else Color.WHITE
	var unlocked:=true;var detail:=Localizer.text(language_code,"shop_seed_info");var purchasable:=false;var price:=0
	match shop_selected_seed_type:
		"volume":
			unlocked=_volume_seed_unlocked();detail=Localizer.text(language_code,"seed_volume_detail")
			if unlocked:detail+="\n"+Localizer.text(language_code,"price_tbd")
		"premium":
			unlocked=_premium_seed_unlocked();detail=Localizer.text(language_code,"seed_premium_detail")
			if unlocked:detail+="\n"+Localizer.text(language_code,"price_tbd")
		"mystery":
			unlocked=_mystery_seed_pack_unlocked();detail=Localizer.text(language_code,"seed_mystery_detail")
			if not unlocked:detail+="\n"+Localizer.text(language_code,"unlock_mystery_species")
			else:detail+="\n"+Localizer.text(language_code,"price_tbd")
		_:pass
	var can_purchase:=unlocked and purchasable and puku_points>=price
	shop_product_detail_label.text=detail;shop_selected_buy_button.text=(Localizer.text(language_code,"buy_bundle") if purchasable else Localizer.text(language_code,"price_tbd")) if unlocked else Localizer.text(language_code,"locked");shop_selected_buy_button.disabled=not can_purchase
	if shop_buy_pulse_tween and shop_buy_pulse_tween.is_valid():shop_buy_pulse_tween.kill()
	shop_selected_buy_button.self_modulate=Color.WHITE;shop_buy_glow.visible=can_purchase;shop_buy_glow.modulate=Color(1,1,1,.34)
	if can_purchase:
		shop_buy_pulse_tween=create_tween().set_loops();shop_buy_pulse_tween.tween_property(shop_buy_glow,"modulate:a",.88,.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT);shop_buy_pulse_tween.tween_property(shop_buy_glow,"modulate:a",.34,.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _tutorial_fully_complete()->bool:
	return intro_story_complete and habitat_awakened and habitat_tutorial_complete and seed_shop_open and puku_gauge_intro_complete

func _refresh_seed_pack_unlocks()->void:
	if volume_seed_bags>0:volume_seed_unlocked=true
	if premium_seed_bags>0:premium_seed_unlocked=true
	for entry in catalog_species:
		if bool(entry.get("mystery_pack_eligible",false)) and bool(discovered.get(str(entry.get("species_id","")),false)):
			mystery_seed_pack_unlocked=true;break

func _volume_seed_unlocked()->bool:
	return volume_seed_unlocked or volume_seed_bags>0

func _premium_seed_unlocked()->bool:
	return premium_seed_unlocked or premium_seed_bags>0

func _mystery_seed_pack_unlocked()->bool:
	_refresh_seed_pack_unlocks()
	return mystery_seed_pack_unlocked

func add_seed_pod_gauge_cm(amount_cm:float,save_immediately:=true,show_effect:=true)->int:
	if _is_endless_greenhouse_enabled():return 0
	if amount_cm<=0.0 or not mystery_items_acquired:return 0
	var accumulated:=puku_gauge_cm+amount_cm
	if first_play_tutorial_active and not seed_pod_first_reward_seen:
		# The scripted first fill owns this threshold and reward. Harvested cm is
		# still shown accumulating, but cannot silently pay out behind the lesson.
		puku_gauge_cm=minf(accumulated,SEED_POD_GAUGE_TARGET_CM-.001)
		_update_puku_ui();_update_play_ui()
		if save_immediately:_save()
		return 0
	var completed_gauges:=floori(accumulated/SEED_POD_GAUGE_TARGET_CM)
	var earned_bags:=completed_gauges*SEED_POD_GAUGE_REWARD_BAGS
	puku_gauge_cm=accumulated-completed_gauges*SEED_POD_GAUGE_TARGET_CM
	if earned_bags>0:
		normal_seed_bags+=earned_bags
		# A victory buys peace until the next actual pod reward, even when the
		# gauge was already almost full at the moment of the battle.
		_resolve_jurejure_progress_reward("seed_pod")
		if show_effect:_play_seed_pod_reward(earned_bags)
	_update_puku_ui();_update_play_ui()
	if save_immediately or completed_gauges>0:_save()
	return earned_bags

func _change_puku_balance(delta_units:int,source:="",save_immediately:=true,show_effect:=true,source_position:=Vector2(-10000,-10000))->int:
	if delta_units==0:return 0
	var previous_units:=puku_balance_units
	puku_balance_units=maxi(0,puku_balance_units+delta_units)
	var applied_units:=puku_balance_units-previous_units
	if applied_units==0:return 0
	_record_endless_economy_change(str(source),applied_units)
	if show_effect and puku_gauge_meter and effects_layer:
		if not puku_gauge_animation_running and puku_gauge_animation_queue.is_empty():
			puku_gauge_display_units=float(_puku_fraction_units(previous_units))
			puku_points_display=_puku_whole_count(previous_units)
			_reset_puku_combo_display()
		puku_gauge_animation_queue.append({"delta_units":applied_units})
		if not puku_gauge_animation_running:
			puku_gauge_animation_running=true
			_run_puku_gauge_animation_queue()
	else:
		if puku_gauge_animation_running or not puku_gauge_animation_queue.is_empty():_cancel_puku_gauge_animations()
		puku_gauge_display_units=float(_puku_fraction_units())
		puku_points_display=_puku_whole_count()
	_update_puku_ui();_update_play_ui()
	if save_immediately:_save()
	return applied_units

func add_puku_points(amount:int,save_immediately:=true,show_effect:=true)->void:
	_change_puku_balance(amount*PUKU_UNITS_PER_PUKU,"legacy_api",save_immediately,show_effect)

func _harvest_puku_reward_units(diameter_cm:float,is_first_get:bool)->int:
	var harvested_cm:=maxf(0.0,diameter_cm)
	var reward_units:=0.0
	if harvested_cm>=float(HARVEST_PUKU_REWARD_ANCHORS[-1].x):
		reward_units=float(HARVEST_PUKU_REWARD_ANCHORS[-1].y)+(harvested_cm-float(HARVEST_PUKU_REWARD_ANCHORS[-1].x))/10.0*HARVEST_PUKU_POST_150_UNITS_PER_10_CM
	else:
		for index in range(HARVEST_PUKU_REWARD_ANCHORS.size()-1):
			var left:Vector2=HARVEST_PUKU_REWARD_ANCHORS[index]
			var right:Vector2=HARVEST_PUKU_REWARD_ANCHORS[index+1]
			if harvested_cm<=right.x:
				var ratio:=inverse_lerp(left.x,right.x,harvested_cm)
				reward_units=lerpf(left.y,right.y,ratio)
				break
	var rounded_units:=maxi(0,roundi(reward_units))
	return maxi(FIRST_GET_MIN_REWARD_UNITS,rounded_units) if is_first_get else rounded_units

func _format_puku_units(units:int)->String:
	return "%.2f"%(float(abs(units))/float(PUKU_UNITS_PER_PUKU))

func _puku_gauge_text()->String:
	return _format_puku_units(_puku_fraction_units())

func _update_puku_ui()->void:
	if puku_gauge_label:puku_gauge_label.text=Localizer.text(language_code,"puku_gauge")
	if seed_pod_gauge_label:seed_pod_gauge_label.text=Localizer.text(language_code,"seed_pod_gauge")
	if seed_pod_gauge_meter:seed_pod_gauge_meter.max_value=SEED_POD_GAUGE_TARGET_CM
	if puku_gauge_meter:puku_gauge_meter.max_value=PUKU_UNITS_PER_PUKU
	if not puku_gauge_animation_running and puku_gauge_animation_queue.is_empty():puku_gauge_display_units=float(_puku_fraction_units());puku_points_display=_puku_whole_count()
	_render_seed_pod_gauge(puku_gauge_cm)
	_render_puku_gauge(puku_gauge_display_units)
	if puku_point_label:puku_point_label.text=Localizer.text(language_code,"puku_count",[puku_points_display])

func _render_seed_pod_gauge(display_cm:float)->void:
	var ratio:=clampf(display_cm/SEED_POD_GAUGE_TARGET_CM,0.0,1.0)
	if seed_pod_gauge_meter:seed_pod_gauge_meter.value=clampf(display_cm,0.0,SEED_POD_GAUGE_TARGET_CM)
	if seed_pod_gauge_fill_style:
		seed_pod_gauge_fill_style.bg_color=Color("#2f9b63").lerp(Color("#a8ffc3"),ratio)
		seed_pod_gauge_fill_style.border_color=Color("#bfffd3").lerp(Color.WHITE,ratio)
	if seed_pod_gauge_glow:
		seed_pod_gauge_glow.visible=ratio>.01
		var width:=maxf(seed_pod_gauge_meter.size.x,seed_pod_gauge_meter.custom_minimum_size.x)
		var height:=maxf(seed_pod_gauge_meter.size.y,seed_pod_gauge_meter.custom_minimum_size.y)
		seed_pod_gauge_glow.position=Vector2(1,1);seed_pod_gauge_glow.size=Vector2(maxf(2.0,(width-2.0)*ratio),maxf(4.0,height-2.0));seed_pod_gauge_glow.self_modulate=Color(1,1,1,lerpf(.18,.62,ratio))
	if seed_pod_gauge_glow_style:
		seed_pod_gauge_glow_style.shadow_size=roundi(2.0+5.0*ratio);seed_pod_gauge_glow_style.shadow_color=Color(.28,1.0,.55,lerpf(.12,.42,ratio))

func _render_puku_gauge(display_units:float)->void:
	var ratio:=clampf(display_units/float(PUKU_UNITS_PER_PUKU),0.0,1.0)
	var gold_progress:=clampf((ratio-.70)/.30,0.0,1.0)
	var glow_strength:=pow(gold_progress,1.28)
	var fill_color:=Color("#174b31").lerp(Color("#348a4a"),ratio/.70) if ratio<=.70 else Color("#78c943").lerp(Color("#ffe657"),minf(1.0,gold_progress*1.35))
	if gold_progress>.72:fill_color=fill_color.lerp(Color("#f4ac22"),(gold_progress-.72)/.28)
	if puku_gauge_meter:puku_gauge_meter.value=clampf(display_units,0.0,float(PUKU_UNITS_PER_PUKU))
	if puku_gauge_glow:
		puku_gauge_glow.visible=ratio>.70
		var meter_width:=maxf(puku_gauge_meter.size.x,puku_gauge_meter.custom_minimum_size.x)
		var meter_height:=maxf(puku_gauge_meter.size.y,puku_gauge_meter.custom_minimum_size.y)
		puku_gauge_glow.position=Vector2(1,1);puku_gauge_glow.size=Vector2(maxf(2.0,(meter_width-2.0)*ratio),maxf(4.0,meter_height-2.0))
		puku_gauge_glow.self_modulate=Color(1.0,1.0,1.0,lerpf(.20,.92,glow_strength))
	if puku_gauge_glow_style:
		puku_gauge_glow_style.shadow_size=roundi(2.0+9.0*glow_strength)
		puku_gauge_glow_style.shadow_color=Color(1.0,.64,.06,lerpf(.08,.76,glow_strength))
		puku_gauge_glow_style.border_color=Color(1.0,.91,.30,lerpf(.10,.92,glow_strength))
	if puku_gauge_fill_style:
		puku_gauge_fill_style.bg_color=fill_color
		puku_gauge_fill_style.border_color=Color("#73a77b").lerp(Color("#fff2a0"),gold_progress)

func _set_puku_gauge_display_units(value:float)->void:
	puku_gauge_display_units=clampf(value,0.0,float(PUKU_UNITS_PER_PUKU))
	_render_puku_gauge(puku_gauge_display_units)

func _format_cm(amount_cm:float)->String:
	var rounded:=snappedf(amount_cm,0.1)
	return str(int(roundf(rounded))) if is_equal_approx(rounded,roundf(rounded)) else "%.1f"%rounded

func _run_puku_gauge_animation_queue()->void:
	var generation:=puku_gauge_animation_generation
	while generation==puku_gauge_animation_generation:
		while not puku_gauge_animation_queue.is_empty() and generation==puku_gauge_animation_generation:
			var item:Dictionary=puku_gauge_animation_queue.pop_front()
			await get_tree().create_timer(maxf(.001,.26*_puku_gauge_effective_speed_scale())).timeout
			if generation!=puku_gauge_animation_generation:return
			await _animate_puku_balance_delta(int(item.get("delta_units",0)),generation)
		if generation!=puku_gauge_animation_generation:return
		if puku_gauge_combo_count>=2 and puku_combo_label and puku_combo_label.visible:
			await get_tree().create_timer(maxf(.001,.14*_puku_gauge_effective_speed_scale())).timeout
			if generation!=puku_gauge_animation_generation:return
			puku_combo_tween=create_tween();puku_combo_tween.tween_property(puku_combo_label,"modulate:a",0.0,maxf(.001,.12*_puku_gauge_effective_speed_scale()))
			await puku_combo_tween.finished
			if generation!=puku_gauge_animation_generation:return
		if puku_gauge_animation_queue.is_empty():break
		if puku_combo_label:puku_combo_label.modulate.a=1.0
	_reset_puku_combo_display()
	puku_gauge_animation_running=false;puku_gauge_display_units=float(_puku_fraction_units());puku_points_display=_puku_whole_count();_update_puku_ui();call_deferred("_poll_greenhouse_play_completion")

func _animate_puku_balance_delta(delta_units:int,generation:int)->void:
	var remaining:int=absi(delta_units)
	if remaining<=0:return
	var original_amount:int=remaining
	var total_duration:=clampf(.34+minf(1.0,float(remaining)/2400.0)*.50,.34,.84)*_puku_gauge_effective_speed_scale()
	var direction:=1 if delta_units>0 else -1
	while remaining>0 and generation==puku_gauge_animation_generation:
		if direction>0:
			var positive_room:=PUKU_UNITS_PER_PUKU-roundi(puku_gauge_display_units)
			if positive_room<=0:
				await _play_puku_balance_boundary(1,generation)
				continue
			var positive_segment:=mini(remaining,positive_room)
			var positive_duration:=maxf(.001,total_duration*float(positive_segment)/float(original_amount))
			puku_gauge_active_tween=create_tween();puku_gauge_active_tween.tween_method(_set_puku_gauge_display_units,puku_gauge_display_units,puku_gauge_display_units+positive_segment,positive_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			await puku_gauge_active_tween.finished
			if generation!=puku_gauge_animation_generation:return
			remaining-=positive_segment
			if puku_gauge_display_units>=PUKU_UNITS_PER_PUKU-.001:await _play_puku_balance_boundary(1,generation)
		else:
			if puku_gauge_display_units<=.001:
				await _play_puku_balance_boundary(-1,generation)
				if puku_points_display<=0 and puku_gauge_display_units<=.001:return
			var negative_room:=maxi(0,roundi(puku_gauge_display_units))
			var negative_segment:=mini(remaining,negative_room)
			if negative_segment<=0:return
			var negative_duration:=maxf(.001,total_duration*float(negative_segment)/float(original_amount))
			puku_gauge_active_tween=create_tween();puku_gauge_active_tween.tween_method(_set_puku_gauge_display_units,puku_gauge_display_units,puku_gauge_display_units-negative_segment,negative_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			await puku_gauge_active_tween.finished
			if generation!=puku_gauge_animation_generation:return
			remaining-=negative_segment

func _play_puku_balance_boundary(direction:int,generation:int)->void:
	if generation!=puku_gauge_animation_generation:return
	puku_gauge_threshold_flash_count+=1
	if direction>0:
		puku_points_display+=1;puku_gauge_combo_count+=1;_set_puku_gauge_display_units(float(PUKU_UNITS_PER_PUKU))
	else:
		puku_points_display=maxi(0,puku_points_display-1);_set_puku_gauge_display_units(float(PUKU_UNITS_PER_PUKU))
	if puku_point_label:puku_point_label.text=Localizer.text(language_code,"puku_count",[puku_points_display])
	puku_gauge_meter.pivot_offset=puku_gauge_meter.size*.5;puku_gauge_active_tween=create_tween();puku_gauge_active_tween.tween_property(puku_gauge_meter,"scale",Vector2(1.06,1.22),maxf(.001,.025*_puku_gauge_effective_speed_scale())).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);puku_gauge_active_tween.tween_property(puku_gauge_meter,"scale",Vector2.ONE,maxf(.001,.04*_puku_gauge_effective_speed_scale())).set_trans(Tween.TRANS_QUAD)
	await puku_gauge_active_tween.finished
	if generation==puku_gauge_animation_generation and direction>0 and puku_gauge_combo_count>=2:
		await _pulse_puku_combo_display(generation)
	if generation==puku_gauge_animation_generation and direction>0:_set_puku_gauge_display_units(0.0)

func _pulse_puku_combo_display(generation:int)->void:
	if generation!=puku_gauge_animation_generation or puku_combo_label==null:return
	puku_combo_label.text="×%d"%puku_gauge_combo_count;puku_combo_label.visible=true;puku_combo_label.modulate.a=1.0;puku_combo_label.scale=Vector2.ONE
	if puku_combo_tween and puku_combo_tween.is_valid():puku_combo_tween.kill()
	puku_combo_tween=create_tween();puku_combo_tween.tween_property(puku_combo_label,"scale",Vector2(1.28,1.28),maxf(.001,.085*_puku_gauge_effective_speed_scale())).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);puku_combo_tween.tween_property(puku_combo_label,"scale",Vector2.ONE,maxf(.001,.10*_puku_gauge_effective_speed_scale())).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await puku_combo_tween.finished

func _puku_gauge_is_only_finish_blocker()->bool:
	return play_active and _is_endless_normal_play() and play_seeds_remaining<=0 and play_spawn_queue<=0 and play_seed_animations_pending<=0 and plants.is_empty()

func _puku_gauge_effective_speed_scale()->float:
	var finish_scale:=PUKU_GAUGE_FINISH_SPEED_SCALE if _puku_gauge_is_only_finish_blocker() else 1.0
	return puku_gauge_animation_speed_scale*finish_scale

func _reset_puku_combo_display()->void:
	puku_gauge_combo_count=0
	if puku_combo_tween and puku_combo_tween.is_valid():puku_combo_tween.kill()
	puku_combo_tween=null
	if puku_combo_label:
		puku_combo_label.visible=false
		puku_combo_label.modulate=Color.WHITE
		puku_combo_label.scale=Vector2.ONE
		puku_combo_label.text=""

func _cancel_puku_gauge_animations()->void:
	puku_gauge_animation_generation+=1;puku_gauge_animation_queue.clear();puku_gauge_animation_running=false
	if puku_gauge_active_tween and puku_gauge_active_tween.is_valid():puku_gauge_active_tween.kill()
	puku_gauge_active_tween=null;puku_gauge_display_units=float(_puku_fraction_units());puku_points_display=_puku_whole_count()
	_reset_puku_combo_display()
	if puku_gauge_meter:puku_gauge_meter.scale=Vector2.ONE

func _start_puku_gauge_glow()->void:
	if not puku_gauge_glow:return
	if puku_gauge_glow_tween and puku_gauge_glow_tween.is_valid():puku_gauge_glow_tween.kill()
	puku_gauge_glow.modulate=Color(1.0,1.0,1.0,.82)
	puku_gauge_glow_tween=create_tween().bind_node(puku_gauge_glow).set_loops();puku_gauge_glow_tween.tween_property(puku_gauge_glow,"modulate:a",1.0,1.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT);puku_gauge_glow_tween.tween_property(puku_gauge_glow,"modulate:a",.82,1.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _play_seed_pod_reward(bag_count:int)->void:
	if seed_pod_gauge_meter==null:return
	if seed_pod_reward_tween and seed_pod_reward_tween.is_valid():seed_pod_reward_tween.kill()
	_render_seed_pod_gauge(SEED_POD_GAUGE_TARGET_CM);seed_pod_gauge_meter.pivot_offset=seed_pod_gauge_meter.size*.5;seed_pod_gauge_meter.scale=Vector2.ONE
	seed_pod_reward_tween=create_tween().bind_node(seed_pod_gauge_meter);seed_pod_reward_tween.tween_property(seed_pod_gauge_meter,"scale",Vector2(1.10,1.40),.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);seed_pod_reward_tween.tween_property(seed_pod_gauge_meter,"scale",Vector2.ONE,.18);seed_pod_reward_tween.tween_interval(.25);seed_pod_reward_tween.tween_callback(func():_render_seed_pod_gauge(puku_gauge_cm))
	if puku_gain_tween and puku_gain_tween.is_valid():puku_gain_tween.kill()
	puku_gain_label.text=Localizer.text(language_code,"seed_pod_gauge_reward",[bag_count]);puku_gain_label.position=Vector2(24,250);puku_gain_label.size=Vector2(260,60);puku_gain_label.scale=Vector2(.82,.82);puku_gain_label.modulate=Color.WHITE;puku_gain_label.visible=true
	puku_gain_tween=create_tween().bind_node(puku_gain_label);puku_gain_tween.tween_property(puku_gain_label,"scale",Vector2.ONE,.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);puku_gain_tween.tween_interval(.7);puku_gain_tween.tween_property(puku_gain_label,"modulate:a",0.0,.25);puku_gain_tween.tween_callback(func():puku_gain_label.visible=false;puku_gain_label.modulate=Color.WHITE)

func _queue_first_seed_pod_max_event()->bool:
	if _is_endless_greenhouse_enabled():return false
	if not first_play_tutorial_active or seed_pod_first_reward_seen or first_seed_pod_reward_event_active:return false
	first_seed_pod_reward_event_active=true
	call_deferred("_start_first_seed_pod_max_event")
	return true

func _start_first_seed_pod_max_event()->void:
	if not first_seed_pod_reward_event_active:return
	if puku_buyback_tutorial_active:return
	var viewport_size:=get_viewport().get_visible_rect().size
	var center:=seed_pod_gauge_area.global_position+seed_pod_gauge_area.size*.5
	tutorial_guide_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;tutorial_guide_shade.mouse_filter=Control.MOUSE_FILTER_STOP;tutorial_guide_shade.material=first_play_harvest_spotlight_material;tutorial_guide_shade.color=Color(.018,.025,.022,.90)
	var focus_half_size:=(seed_pod_gauge_area.size*.5+Vector2(12,8))/viewport_size
	first_play_harvest_spotlight_material.set_shader_parameter("focus_ellipse",true);first_play_harvest_spotlight_material.set_shader_parameter("focus_half_size_uv",focus_half_size);first_play_harvest_spotlight_material.set_shader_parameter("focus_count",1);first_play_harvest_spotlight_material.set_shader_parameter("focus_uv_a",center/viewport_size);first_play_harvest_spotlight_material.set_shader_parameter("viewport_aspect",viewport_size.x/viewport_size.y)
	tutorial_guide_button.visible=false;tutorial_dialog_panel.visible=false;tutorial_guide_overlay.visible=true
	var start_cm:=clampf(puku_gauge_cm,0.0,SEED_POD_GAUGE_TARGET_CM)
	seed_pod_reward_tween=create_tween();seed_pod_reward_tween.tween_method(_render_seed_pod_gauge,start_cm,SEED_POD_GAUGE_TARGET_CM,1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT);seed_pod_reward_tween.tween_interval(.32)
	await seed_pod_reward_tween.finished
	_hide_first_play_tutorial_overlay()
	_start_scripted_dialog("first_seed_pod_reward",[
		{"speaker":"girl","text":Localizer.text(language_code,"seed_pod_tutorial_girl")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"seed_pod_tutorial_armadillo")},
		{"speaker":"panda","text":Localizer.text(language_code,"seed_pod_tutorial_panda")},
		{"speaker":"","text":Localizer.text(language_code,"seed_pod_tutorial_received")}
	],false)

func _claim_first_seed_pod_reward_once()->void:
	if seed_pod_first_reward_seen:return
	seed_pod_first_reward_seen=true;seed_pod_gauge_discovery_complete=true;puku_gauge_cm=0.0;normal_seed_bags+=SEED_POD_GAUGE_REWARD_BAGS
	_resolve_jurejure_progress_reward("seed_pod")
	_play_seed_pod_reward(SEED_POD_GAUGE_REWARD_BAGS);_save();_update_currency_ui();_update_play_ui();audio_manager.play_se("daily",.62)

func _update_currency_ui()->void:
	_update_puku_ui()

func _show_play_result()->void:
	if active_seed_type=="old" and total_play_count==1:
		result_overlay.visible=false
		_clear_result_confetti()
		if not result_new_species_queue.is_empty() or not result_deferred_species_queue.is_empty():call_deferred("_play_result_new_species_animations")
		else:call_deferred("_start_first_colorata_discovery_event")
		return
	result_total_label.visible=true
	var endless_round_result:=active_seed_type=="normal" and _is_endless_greenhouse_enabled()
	if endless_round_result:
		var round_net_units:=endless_economy_harvest_reward_units-endless_economy_seed_cost_units
		_set_named_localized_text("ResultTitle","round_result_title")
		result_total_label.text=Localizer.text(language_code,"round_result_economy",[_format_puku_units(endless_economy_seed_cost_units),_format_puku_units(endless_economy_harvest_reward_units),("+" if round_net_units>=0 else "-")+_format_puku_units(round_net_units)])
		result_count_label.text=Localizer.text(language_code,"round_result_count",[endless_economy_harvest_count,endless_economy_jelly_count])
	else:
		_set_named_localized_text("ResultTitle","result_title")
		result_total_label.text=Localizer.text(language_code,"result_total_before_items",[_format_cm(play_harvest_cm_total)])
		result_count_label.text=Localizer.text(language_code,"result_count",[play_harvest_count])
	result_max_label.remove_theme_color_override("font_outline_color");result_max_label.remove_theme_constant_override("outline_size")
	if play_updated_global_best:
		result_max_label.text=Localizer.text(language_code,"result_best_update",[play_max_size]);result_max_label.add_theme_font_size_override("font_size",30);result_max_label.add_theme_color_override("font_color",Color("#b83b32"));result_max_label.add_theme_color_override("font_outline_color",Color("#f8e8c8"));result_max_label.add_theme_constant_override("outline_size",3);_play_result_confetti();call_deferred("_start_result_record_pulse");audio_manager.play_se("result_new_best",.48)
	else:
		result_max_label.text=Localizer.text(language_code,"result_max",[play_max_size]);result_max_label.add_theme_font_size_override("font_size",21);result_max_label.add_theme_color_override("font_color",Color("#65432e"));_clear_result_confetti()
	var notable:Array=[]
	for notable_species_id_value in play_notable_species:
		var notable_species_id:=str(notable_species_id_value)
		# Do not reveal a pending NEW on the result card. Its identity first appears
		# on the Species GET card after the player closes this result.
		if notable_species_id in pending_round_new_species_ids:continue
		notable.append(play_notable_species[notable_species_id])
	notable.sort_custom(func(a,b):return float(a.get("size",0.0))>float(b.get("size",0.0)));var lines:Array[String]=[]
	for i in range(mini(3,notable.size())):lines.append("%s　%.1fcm"%[str(notable[i].get("name","")),float(notable[i].get("size",0.0))])
	result_notable_label.text="\n".join(lines) if not lines.is_empty() else Localizer.text(language_code,"result_none")
	if play_hidden_species_unlocked==HIDDEN_TOVAR_ID:result_notable_label.text+="\n\n"+Localizer.text(language_code,"result_hidden_registered",[Localizer.species_name(language_code,_catalog_entry(HIDDEN_TOVAR_ID))])
	result_new_species_label.visible=false;result_new_species_label.text=""
	var share_species_id:=str(play_share_record.get("species_id",""))
	result_share_button.visible=not play_share_record.is_empty() and share_species_id not in pending_round_new_species_ids;result_share_button.disabled=false;result_share_button.text=Localizer.text(language_code,"share_prompt");result_share_status.visible=false;result_share_status.text=""
	result_overlay.visible=true;result_overlay.modulate.a=0.0;result_card.position.y=170.0;play_open_button.visible=false
	var tween:=create_tween().set_parallel();tween.tween_property(result_overlay,"modulate:a",1.0,.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);tween.tween_property(result_card,"position:y",150.0,.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _play_result_new_species_animations()->void:
	if round_result_species_finalize_active:return
	round_result_species_finalize_active=true;round_result_species_save_pending=false
	var immediate_first_colorata:=active_seed_type=="old" and total_play_count==1 and not first_colorata_confirmed and FIRST_STORY_SPECIES_ID in result_new_species_queue
	if not immediate_first_colorata:await get_tree().create_timer(.48).timeout
	# Finite/old-seed flows already registered their discoveries before the
	# result. Keep their established card contexts and follow-ups unchanged.
	if pending_round_new_species_ids.is_empty():
		var registered_queue:=result_new_species_queue.duplicate();result_new_species_queue.clear()
		registered_queue.append_array(result_deferred_species_queue);result_deferred_species_queue.clear()
		round_result_species_finalize_active=false
		for species_id_value in registered_queue:
			var registered_species_id:=str(species_id_value)
			var registered_context:="first_colorata" if total_play_count==1 and registered_species_id==FIRST_STORY_SPECIES_ID else "main_result"
			_queue_species_get_by_id(registered_species_id,true,registered_context)
		if registered_queue.is_empty():call_deferred("_try_start_pending_story_event")
		return
	round_result_species_finalize_queue.clear()
	for species_id_value in pending_round_new_species_ids:
		round_result_species_finalize_queue.append({"species_id":str(species_id_value),"formalize":true,"is_new":true})
	for species_id_value in result_new_species_queue:
		round_result_species_finalize_queue.append({"species_id":str(species_id_value),"formalize":false,"is_new":true})
	for species_id_value in result_deferred_species_queue:
		round_result_species_finalize_queue.append({"species_id":str(species_id_value),"formalize":false,"is_new":true})
	result_new_species_queue.clear();result_deferred_species_queue.clear()
	_show_next_round_result_species()

func _show_next_round_result_species()->void:
	_get_close_profile_mark("show_next_entry")
	if not species_get_queue.is_empty() or species_get_overlay and species_get_overlay.visible or catalog_series_unlock_overlay and catalog_series_unlock_overlay.visible:return
	if round_result_species_finalize_queue.is_empty():
		round_result_species_finalize_active=false
		# Formal registrations from every card in this result are persisted as one
		# transaction. The pending IDs were already saved at harvest time, so an
		# interruption before this point remains recoverable without rewriting the
		# complete save between consecutive cards.
		if round_result_species_save_pending:
			round_result_species_save_pending=false;_save()
		if total_play_count==1 and not first_colorata_confirmed:call_deferred("_start_first_colorata_discovery_event")
		else:call_deferred("_try_start_pending_story_event")
		_get_close_profile_mark("show_next_exit")
		if get_close_profile_active:call_deferred("_finish_get_close_profile_after_rendered_frame",get_close_profile_run_id)
		return
	var queued:Dictionary=round_result_species_finalize_queue.pop_front()
	var species_id:=str(queued.get("species_id",""))
	if species_id.is_empty():
		call_deferred("_show_next_round_result_species")
		return
	var formalize:=bool(queued.get("formalize",false))
	var is_new:=bool(queued.get("is_new",_species_get_count(species_id)<=0))
	if formalize:
		is_new=_species_get_count(species_id)<=0
		if is_new:_register_species_discovery(species_id,true)
		if species_id in pending_round_new_species_ids:
			pending_round_new_species_ids.erase(species_id);round_result_species_save_pending=true
		if not is_new:
			call_deferred("_show_next_round_result_species")
			return
	_queue_species_get_by_id(species_id,is_new,"round_result_new")

func _start_result_new_species_pulse()->void:
	if result_new_species_pulse_tween and result_new_species_pulse_tween.is_valid():result_new_species_pulse_tween.kill()
	if not result_new_species_label.visible:return
	result_new_species_label.pivot_offset=result_new_species_label.size*.5;result_new_species_label.scale=Vector2.ONE
	result_new_species_pulse_tween=create_tween().set_loops(3);result_new_species_pulse_tween.tween_property(result_new_species_label,"scale",Vector2(1.07,1.07),.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT);result_new_species_pulse_tween.tween_property(result_new_species_label,"scale",Vector2.ONE,.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _share_personal_best()->void:
	if play_share_record.is_empty() or result_share_button.disabled:return
	result_share_button.disabled=true;result_share_status.visible=true;result_share_status.text=Localizer.text(language_code,"share_creating")
	var image_path:String=await _create_personal_best_share_image(play_share_record)
	if image_path.is_empty():
		result_share_status.text=Localizer.text(language_code,"share_failed");result_share_button.disabled=false;return
	var shared:=_open_native_share_or_fallback(image_path)
	result_share_status.text=shared;result_share_button.disabled=false

func _create_personal_best_share_image(record:Dictionary)->String:
	var entry:=_catalog_entry(str(record.get("species_id","")))
	if entry.is_empty():return ""
	var viewport:=SubViewport.new();viewport.size=Vector2i(1080,1350);viewport.transparent_bg=false;viewport.render_target_update_mode=SubViewport.UPDATE_ONCE;viewport.disable_3d=true;add_child(viewport)
	var root:=Control.new();root.size=Vector2(1080,1350);viewport.add_child(root)
	var background:=ColorRect.new();background.color=Color("#f7e7ca");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(background)
	var top_band:=ColorRect.new();top_band.color=Color("#5d3923");top_band.position=Vector2(0,0);top_band.size=Vector2(1080,184);root.add_child(top_band)
	var title:=Label.new();title.text=Localizer.text(language_code,"game_title");title.position=Vector2(80,40);title.size=Vector2(920,110);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",64);title.add_theme_color_override("font_color",Color("#fff2c8"));root.add_child(title)
	var image_panel:=PanelContainer.new();image_panel.position=Vector2(90,225);image_panel.size=Vector2(900,760);image_panel.add_theme_stylebox_override("panel",_box(Color("#fffaf0"),Color("#d3a75f"),42,7));root.add_child(image_panel)
	var image:=TextureRect.new();image.texture=_species_texture(entry)
	if image.texture==null:image.texture=CatalogImageLoader.placeholder_texture
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image_panel.add_child(image)
	var species_name:=Localizer.species_name(language_code,entry);var size_cm:=float(record.get("size",0.0))
	var record_label:=Label.new();record_label.text=Localizer.text(language_code,"share_harvest",[size_cm,species_name]);record_label.position=Vector2(70,1015);record_label.size=Vector2(940,100);record_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;record_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;record_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;record_label.add_theme_font_size_override("font_size",48);record_label.add_theme_color_override("font_color",UI_BROWN);root.add_child(record_label)
	var best_label:=Label.new();best_label.text=Localizer.text(language_code,"share_record");best_label.position=Vector2(90,1125);best_label.size=Vector2(900,120);best_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;best_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;best_label.add_theme_font_size_override("font_size",58);best_label.add_theme_color_override("font_color",Color("#c17724"));root.add_child(best_label)
	var footer:=Label.new();footer.text="puku puku taniku";footer.position=Vector2(90,1250);footer.size=Vector2(900,55);footer.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;footer.add_theme_font_size_override("font_size",28);footer.add_theme_color_override("font_color",Color("#8e6949"));root.add_child(footer)
	await get_tree().process_frame;await get_tree().process_frame
	var rendered:=viewport.get_texture().get_image();var output_path:="user://puku-personal-best-%d.png"%int(Time.get_unix_time_from_system());var error:=rendered.save_png(output_path)
	viewport.queue_free()
	return output_path if error==OK else ""

func _open_native_share_or_fallback(image_path:String,download_filename:String="",share_context:String="personal_best")->String:
	var absolute_path:=ProjectSettings.globalize_path(image_path)
	var safe_filename:=download_filename.strip_edges()
	if safe_filename.is_empty():safe_filename=image_path.get_file()
	if safe_filename.is_empty():safe_filename="puku-share.png"
	var share_subject:=Localizer.text(language_code,"viewer_title") if share_context=="arrangement" else Localizer.text(language_code,"share_record")
	if Engine.has_singleton("SharePlugin"):
		var share_plugin=Engine.get_singleton("SharePlugin")
		_connect_native_share_bridge(share_plugin)
		native_share_context=share_context
		if share_plugin and share_plugin.has_method("share_image"):
			share_plugin.call(
				"share_image",
				absolute_path,
				Localizer.text(language_code,"game_title"),
				share_subject,
				Localizer.text(language_code,"share_prompt")
			)
			return Localizer.text(language_code,"share_opening")
		if share_plugin and share_plugin.has_method("share_file"):
			share_plugin.call(
				"share_file",
				absolute_path,
				"image/png",
				Localizer.text(language_code,"game_title"),
				share_subject,
				Localizer.text(language_code,"share_prompt")
			)
			return Localizer.text(language_code,"share_opening")
	for singleton_name in ["PukuNativeShare","Share"]:
		if not Engine.has_singleton(singleton_name):continue
		var native_share=Engine.get_singleton(singleton_name)
		if native_share and native_share.has_method("share_file"):
			native_share.call("share_file",absolute_path,"image/png",Localizer.text(language_code,"game_title"))
			return Localizer.text(language_code,"share_opening")
	if OS.has_feature("web"):
		var bytes:=FileAccess.get_file_as_bytes(image_path);var encoded:=Marshalls.raw_to_base64(bytes)
		JavaScriptBridge.eval(_web_share_file_script(encoded,safe_filename,Localizer.text(language_code,"game_title")),true)
		return Localizer.text(language_code,"share_web_opened")
	OS.shell_open(absolute_path)
	return "%s: %s"%[Localizer.text(language_code,"share_fallback"),absolute_path]

func _web_share_file_script(encoded:String,filename:String,title:String)->String:
	return """(()=>{const b=atob(%s),a=new Uint8Array(b.length);for(let i=0;i<b.length;i++)a[i]=b.charCodeAt(i);const f=new File([a],%s,{type:'image/png'});const save=()=>{const u=URL.createObjectURL(f),x=document.createElement('a');x.href=u;x.download=f.name;x.click();setTimeout(()=>URL.revokeObjectURL(u),1000)};if(navigator.share&&navigator.canShare&&navigator.canShare({files:[f]})){navigator.share({title:%s,files:[f]}).catch(save)}else save();return true})()"""%[JSON.stringify(encoded),JSON.stringify(filename),JSON.stringify(title)]

func _connect_native_share_bridge(share_plugin:Object)->void:
	if share_plugin==null:return
	var handlers:={
		"share_completed":Callable(self,"_on_native_share_completed"),
		"share_canceled":Callable(self,"_on_native_share_canceled"),
		"share_failed":Callable(self,"_on_native_share_failed")
	}
	for signal_name in handlers:
		if share_plugin.has_signal(signal_name) and not share_plugin.is_connected(signal_name,handlers[signal_name]):share_plugin.connect(signal_name,handlers[signal_name])

func _on_native_share_completed(_activity_type:="")->void:
	_update_native_share_feedback("share_complete")

func _on_native_share_canceled()->void:
	_update_native_share_feedback("share_canceled")

func _on_native_share_failed(_message:="")->void:
	_update_native_share_feedback("share_native_failed")

func _update_native_share_feedback(key:String)->void:
	var message:=Localizer.text(language_code,key)
	if native_share_context=="arrangement" and arrangement_ui:arrangement_ui.set_share_state(message,false)
	elif result_share_status:result_share_status.visible=true;result_share_status.text=message
	native_share_context=""

func _play_shop_new_species_animations(species_ids:Array)->void:
	for species_id_value in species_ids:
		_queue_species_get_by_id(str(species_id_value),true,"armadillo_gift")

func _close_result()->void:
	if result_new_species_pulse_tween and result_new_species_pulse_tween.is_valid():result_new_species_pulse_tween.kill()
	result_new_species_pulse_tween=null;result_new_species_label.scale=Vector2.ONE;result_overlay.visible=false;result_overlay.modulate.a=1.0;_clear_result_confetti();_update_play_ui()
	if not pending_round_new_species_ids.is_empty() or not result_new_species_queue.is_empty() or not result_deferred_species_queue.is_empty():call_deferred("_play_result_new_species_animations")
	elif total_play_count==1 and not first_colorata_confirmed:_start_first_colorata_discovery_event()
	else:call_deferred("_try_start_pending_story_event")

func _build_encyclopedia(hud:Control)->void:
	encyclopedia_overlay=Control.new();encyclopedia_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);encyclopedia_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;encyclopedia_overlay.visible=false;hud.add_child(encyclopedia_overlay)
	var background:=ColorRect.new();background.color=Color("#3d2419");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.mouse_filter=Control.MOUSE_FILTER_STOP;encyclopedia_overlay.add_child(background)
	_build_series_selection_page()
	encyclopedia_detail_page=Control.new();encyclopedia_detail_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);encyclopedia_detail_page.visible=false;encyclopedia_overlay.add_child(encyclopedia_detail_page)

func _build_series_selection_page()->void:
	encyclopedia_series_page=Control.new();encyclopedia_series_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);encyclopedia_overlay.add_child(encyclopedia_series_page)
	encyclopedia_list_page=encyclopedia_series_page
	var title:=Label.new();title.name="EncyclopediaTitle";title.text="ぷくぷく図鑑";title.position=Vector2(28,25);title.size=Vector2(390,55);title.add_theme_font_size_override("font_size",31);title.add_theme_color_override("font_color",UI_CREAM);encyclopedia_series_page.add_child(title)
	var close:=Button.new();close.name="EncyclopediaCloseButton";close.text="もどる";close.position=Vector2(447,27);close.size=Vector2(105,55);_skin_button(close,Color("#fff0cf"),17);close.pressed.connect(_close_encyclopedia);encyclopedia_series_page.add_child(close)
	all_series_get_label=Label.new();all_series_get_label.visible=false;encyclopedia_series_page.add_child(all_series_get_label)
	encyclopedia_scroll=ScrollContainer.new();encyclopedia_scroll.position=Vector2(0,88);encyclopedia_scroll.size=Vector2(576,907);encyclopedia_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;encyclopedia_scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO;encyclopedia_scroll.scroll_deadzone=12;encyclopedia_scroll.mouse_filter=Control.MOUSE_FILTER_STOP;encyclopedia_series_page.add_child(encyclopedia_scroll)
	encyclopedia_scroll.get_v_scroll_bar().value_changed.connect(func(_value:float):call_deferred("_update_encyclopedia_visible_textures"))
	var scroll_content:=VBoxContainer.new();scroll_content.custom_minimum_size=Vector2(576,0);scroll_content.mouse_filter=Control.MOUSE_FILTER_PASS;scroll_content.add_theme_constant_override("separation",12);encyclopedia_scroll.add_child(scroll_content)
	var cover_section:=Control.new();cover_section.name="SeriesCoverSection";cover_section.custom_minimum_size=Vector2(576,608);cover_section.mouse_filter=Control.MOUSE_FILTER_PASS;scroll_content.add_child(cover_section)
	series_carousel_track=Control.new();series_carousel_track.name="SeriesCarouselTrack";series_carousel_track.position=SERIES_CAROUSEL_TRACK_ORIGIN;series_carousel_track.size=SERIES_CAROUSEL_CARD_SIZE;series_carousel_track.mouse_filter=Control.MOUSE_FILTER_IGNORE;cover_section.add_child(series_carousel_track)
	series_carousel_cards.clear()
	for relative_index in [-1,0,1]:series_carousel_cards.append(_build_series_card(series_carousel_track,relative_index))
	var center_card:Dictionary=series_carousel_cards[1]
	series_title_label=center_card.title;series_subtitle_label=center_card.subtitle;series_description_label=center_card.description;series_cover_image=center_card.cover_image;series_cover_placeholder=center_card.cover_placeholder;series_lock_label=center_card.lock_label;series_progress_label=center_card.progress;series_get_label=center_card.get_label
	var swipe_area:=Control.new();swipe_area.name="SeriesSwipeArea";swipe_area.position=Vector2.ZERO;swipe_area.size=Vector2(576,590);swipe_area.mouse_filter=Control.MOUSE_FILTER_PASS;swipe_area.mouse_force_pass_scroll_events=true;swipe_area.gui_input.connect(_on_series_swipe_input);cover_section.add_child(swipe_area)
	series_previous_button=Button.new();series_previous_button.text="＜";series_previous_button.position=Vector2(16,275);series_previous_button.size=Vector2(58,64);series_previous_button.mouse_force_pass_scroll_events=true;_skin_button(series_previous_button,Color("#f3dfb9"),25);series_previous_button.pressed.connect(_change_series_selection.bind(-1));cover_section.add_child(series_previous_button)
	series_next_button=Button.new();series_next_button.text="＞";series_next_button.position=Vector2(502,275);series_next_button.size=Vector2(58,64);series_next_button.mouse_force_pass_scroll_events=true;_skin_button(series_next_button,Color("#f3dfb9"),25);series_next_button.pressed.connect(_change_series_selection.bind(1));cover_section.add_child(series_next_button)
	series_position_label=Label.new();series_position_label.visible=false;cover_section.add_child(series_position_label)
	var species_header:=Control.new();species_header.name="SpeciesListHeader";species_header.custom_minimum_size=Vector2(576,58);species_header.mouse_filter=Control.MOUSE_FILTER_PASS;scroll_content.add_child(species_header)
	encyclopedia_list_title=Label.new();encyclopedia_list_title.position=Vector2(28,0);encyclopedia_list_title.size=Vector2(520,42);encyclopedia_list_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;encyclopedia_list_title.add_theme_font_size_override("font_size",27);encyclopedia_list_title.add_theme_color_override("font_color",UI_CREAM);species_header.add_child(encyclopedia_list_title)
	encyclopedia_complete_badge_label=Label.new();encyclopedia_complete_badge_label.name="CollectionCompleteBadge";encyclopedia_complete_badge_label.position=Vector2(28,43);encyclopedia_complete_badge_label.size=Vector2(520,35);encyclopedia_complete_badge_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;encyclopedia_complete_badge_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;encyclopedia_complete_badge_label.add_theme_font_size_override("font_size",14);encyclopedia_complete_badge_label.add_theme_color_override("font_color",Color("#f6cf69"));encyclopedia_complete_badge_label.add_theme_color_override("font_outline_color",Color("#4d271b"));encyclopedia_complete_badge_label.add_theme_constant_override("outline_size",4);encyclopedia_complete_badge_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;encyclopedia_complete_badge_label.visible=false;species_header.add_child(encyclopedia_complete_badge_label)
	encyclopedia_list_progress=Label.new();encyclopedia_list_progress.visible=false;species_header.add_child(encyclopedia_list_progress)
	encyclopedia_list_get=Label.new();encyclopedia_list_get.visible=false;species_header.add_child(encyclopedia_list_get)
	encyclopedia_unlock_panel=PanelContainer.new();encyclopedia_unlock_panel.visible=false;species_header.add_child(encyclopedia_unlock_panel)
	encyclopedia_unlock_status=Label.new();encyclopedia_unlock_panel.add_child(encyclopedia_unlock_status)
	encyclopedia_unlock_puku_button=Button.new();encyclopedia_unlock_puku_button.visible=false;species_header.add_child(encyclopedia_unlock_puku_button)
	encyclopedia_grid=GridContainer.new();encyclopedia_grid.columns=2;encyclopedia_grid.custom_minimum_size=Vector2(536,0);encyclopedia_grid.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;encyclopedia_grid.mouse_filter=Control.MOUSE_FILTER_PASS;encyclopedia_grid.add_theme_constant_override("h_separation",12);encyclopedia_grid.add_theme_constant_override("v_separation",14);scroll_content.add_child(encyclopedia_grid)
	var bottom_space:=Control.new();bottom_space.custom_minimum_size=Vector2(536,54);bottom_space.mouse_filter=Control.MOUSE_FILTER_PASS;scroll_content.add_child(bottom_space)

func _build_series_card(parent:Control,relative_index:int)->Dictionary:
	var card:=Control.new();card.name="SeriesCard%d"%relative_index;card.position=Vector2(relative_index*SERIES_CAROUSEL_SPACING,0);card.size=SERIES_CAROUSEL_CARD_SIZE;card.mouse_filter=Control.MOUSE_FILTER_IGNORE;parent.add_child(card)
	var title:=Label.new();title.position=Vector2(40,0);title.size=Vector2(400,50);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",29);title.add_theme_color_override("font_color",UI_CREAM);title.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(title)
	var subtitle:=Label.new();subtitle.position=Vector2(-8,48);subtitle.size=Vector2(496,31);subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;subtitle.add_theme_font_size_override("font_size",16);subtitle.add_theme_color_override("font_color",Color("#e9cda3"));subtitle.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(subtitle)
	var cover_panel:=PanelContainer.new();cover_panel.name="SeriesCoverFrame";cover_panel.position=Vector2(50,88);cover_panel.size=Vector2(380,420);cover_panel.add_theme_stylebox_override("panel",_box(Color("#ead9b5"),Color("#c38c4b"),28,4));cover_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(cover_panel)
	var cover_content:=Control.new();cover_content.custom_minimum_size=Vector2(352,392);cover_content.mouse_filter=Control.MOUSE_FILTER_IGNORE;cover_panel.add_child(cover_content)
	var cover_image:=TextureRect.new();cover_image.name="SeriesCoverImage";cover_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);cover_image.offset_left=12;cover_image.offset_top=12;cover_image.offset_right=-12;cover_image.offset_bottom=-12;cover_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;cover_image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;cover_image.mouse_filter=Control.MOUSE_FILTER_IGNORE;cover_content.add_child(cover_image)
	var cover_placeholder:=Label.new();cover_placeholder.text="表紙画像\n準備中";cover_placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);cover_placeholder.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;cover_placeholder.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;cover_placeholder.add_theme_font_size_override("font_size",25);cover_placeholder.add_theme_color_override("font_color",Color("#815d43"));cover_placeholder.mouse_filter=Control.MOUSE_FILTER_IGNORE;cover_content.add_child(cover_placeholder)
	var lock_label:=Label.new();lock_label.position=Vector2(62,165);lock_label.size=Vector2(260,90);lock_label.text="未開放";lock_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;lock_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;lock_label.add_theme_font_size_override("font_size",24);lock_label.add_theme_color_override("font_color",UI_CREAM);lock_label.add_theme_color_override("font_outline_color",UI_BROWN);lock_label.add_theme_constant_override("outline_size",7);lock_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;cover_content.add_child(lock_label)
	var lock_icon:=UISymbolIcon.new();lock_icon.symbol="lock";lock_icon.icon_color=Color("#fff0b0");lock_icon.position=Vector2(155,105);lock_icon.size=Vector2(54,54);cover_content.add_child(lock_icon)
	var description:=Label.new();description.position=Vector2(-6,523);description.size=Vector2(492,61);description.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;description.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;description.add_theme_font_size_override("font_size",17);description.add_theme_color_override("font_color",UI_CREAM);description.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(description)
	var progress:=Label.new();progress.visible=false;card.add_child(progress)
	var get_label:=Label.new();get_label.visible=false;card.add_child(get_label)
	return {"relative_index":relative_index,"container":card,"title":title,"subtitle":subtitle,"cover_image":cover_image,"cover_placeholder":cover_placeholder,"lock_label":lock_label,"lock_icon":lock_icon,"description":description,"progress":progress,"get_label":get_label,"detail_nodes":[title,subtitle,description,progress,get_label]}

func _open_encyclopedia()->void:
	if catalog_preview_mode_active or play_active:return
	if not encyclopedia_unlocked or not mystery_items_acquired:return
	play_modal_open=false;encyclopedia_detail_page.visible=false;encyclopedia_series_page.visible=true;play_overlay.visible=false;encyclopedia_overlay.visible=true;encyclopedia_scroll.scroll_vertical=0;_refresh_series_selection();_update_play_ui()

func _close_encyclopedia()->void:
	if collection_complete_presentation_active:return
	_cancel_series_carousel_motion()
	encyclopedia_overlay.visible=false
	_release_encyclopedia_textures()
	for card in series_carousel_cards:
		var cover_image=card.get("cover_image")
		if cover_image is TextureRect:cover_image.texture=null
	for child in encyclopedia_detail_page.get_children():child.free()
	_update_play_ui()
	if mystery_items_acquired and mystery_catalog_tutorial_complete and habitat_tutorial_complete and not normal_play_tutorial_complete:call_deferred("_start_initial_seed_stock_notice")
	elif first_colorata_confirmed and not trio_originals_confirmed:call_deferred("_start_trio_originals_event")
	else:call_deferred("_try_start_pending_story_event")

func _current_series_entry()->Dictionary:
	var owned:=_owned_series_entries()
	if owned.is_empty():return {}
	selected_series_index=clampi(selected_series_index,0,owned.size()-1)
	return owned[selected_series_index]

func _owned_series_entries()->Array[Dictionary]:
	var owned:Array[Dictionary]=[]
	for entry in series_catalog:
		if entry is Dictionary and _is_series_unlocked(entry) and not _catalog_series_hidden_from_navigation(entry):owned.append(entry)
	return owned

func _series_entry(series_id:String)->Dictionary:
	for entry in series_catalog:
		if str(entry.get("series_id",""))==series_id:return entry
	return {}

func _series_species_entries(series_id:String)->Array[Dictionary]:
	var entries:Array[Dictionary]=[];var selected:=_series_entry(series_id)
	var ids:Array=selected.get("species_ids",[])
	for species_id_value in ids:
		var entry:=_catalog_entry(str(species_id_value))
		if not entry.is_empty():entries.append(entry)
	return entries

func _catalog_entry_is_fusion(entry:Dictionary)->bool:
	return str(entry.get("series_id",""))=="hybrid" or int(entry.get("fusion_tier",0))>0

func _catalog_display_series_id_for_entry(entry:Dictionary)->String:
	var display_series_id:=str(entry.get("series_id",""))
	var fusion_display_series:=str(entry.get("fusion_display_series",""))
	if not fusion_display_series.is_empty():display_series_id=fusion_display_series
	elif display_series_id=="hybrid":display_series_id=str(entry.get("fusion_series",""))
	return JUREJURE_SERIES_ID if display_series_id=="jure" else display_series_id

func _catalog_series_hidden_from_navigation(series_entry:Dictionary)->bool:
	var source_entries:=_series_species_entries(str(series_entry.get("series_id","")))
	if source_entries.is_empty():return false
	for entry in source_entries:
		if not _catalog_entry_is_fusion(entry):return false
	return true

func _catalog_display_entries_for_series(series_id:String)->Array[Dictionary]:
	var destination_series:=_series_entry(series_id)
	if destination_series.is_empty() or _catalog_series_hidden_from_navigation(destination_series):return []
	var entries:Array[Dictionary]=_series_species_entries(series_id)
	var included:Dictionary={}
	for entry in entries:included[str(entry.get("species_id",""))]=true
	# Basic hybrids come first and retain hybrid-species.json order.
	for entry in _series_species_entries("hybrid"):
		var species_id:=str(entry.get("species_id",""))
		if _catalog_display_series_id_for_entry(entry)==series_id and not included.has(species_id):
			entries.append(entry);included[species_id]=true
	# Higher fusion source pages follow series.json order. This also lets a future
	# tier participate automatically when its species define fusion_display_series.
	for source_series in series_catalog:
		var source_series_id:=str(source_series.get("series_id",""))
		if source_series_id=="hybrid" or not _catalog_series_hidden_from_navigation(source_series):continue
		for entry in _series_species_entries(source_series_id):
			var species_id:=str(entry.get("species_id",""))
			if _catalog_display_series_id_for_entry(entry)==series_id and not included.has(species_id):
				entries.append(entry);included[species_id]=true
	return entries

func _build_species_picker_series_catalog()->Array:
	var picker_series:Array=[]
	for raw_series in series_catalog:
		if not raw_series is Dictionary:continue
		var series:Dictionary=raw_series
		if _catalog_series_hidden_from_navigation(series):continue
		var picker_entry:Dictionary=series.duplicate(true)
		var display_species_ids:Array[String]=[]
		for entry in _catalog_display_entries_for_series(str(series.get("series_id",""))):
			display_species_ids.append(str(entry.get("species_id","")))
		picker_entry["species_ids"]=display_species_ids
		picker_series.append(picker_entry)
	return picker_series

func _catalog_cover_entry_for_series(series_id:String)->Dictionary:
	var species_id:=str(catalog_cover_species.get(series_id,""))
	if species_id.is_empty() or _species_get_count(species_id)<=0:return {}
	var entry:=_catalog_entry(species_id)
	if entry.is_empty() or not _catalog_entry_is_listed_for_series(entry,series_id):return {}
	return entry

func _catalog_entry_is_listed_for_series(entry:Dictionary,series_id:String)->bool:
	if entry.is_empty() or series_id.is_empty() or _catalog_display_series_id_for_entry(entry)!=series_id:return false
	var species_id:=str(entry.get("species_id",""))
	for listed_entry in _catalog_display_entries_for_series(series_id):
		if str(listed_entry.get("species_id",""))==species_id:return true
	return false

func _game_version_key()->String:
	var version:=str(ProjectSettings.get_setting("application/config/version","1.0.0")).strip_edges()
	return "1.0.0" if version.is_empty() else version.trim_prefix("v").trim_prefix("V")

func _collection_complete_entry_is_eligible(entry:Dictionary)->bool:
	if entry.is_empty():return false
	var species_id:=str(entry.get("species_id","")).strip_edges()
	if species_id.is_empty():return false
	for excluded_flag in ["development_only","dev_only","preview_only","test_only","retired","removed","placeholder","future_placeholder"]:
		if bool(entry.get(excluded_flag,false)):return false
	if entry.has("collectible") and not bool(entry.get("collectible",true)):return false
	if entry.has("collection_complete_required") and not bool(entry.get("collection_complete_required",true)):return false
	var lifecycle:=str(entry.get("status","")).to_lower()
	if lifecycle in ["development","preview","test","retired","removed","placeholder","future"]:return false
	return true

func _ensure_collection_complete_species_cache()->void:
	if collection_complete_species_ids_cache_ready:return
	var eligible_species:Dictionary={}
	for entry_value in catalog_species:
		if entry_value is Dictionary and _collection_complete_entry_is_eligible(entry_value):eligible_species[str(entry_value.get("species_id",""))]=true
	var visible_series:Dictionary={}
	for series_value in series_catalog:
		if not series_value is Dictionary:continue
		var series_entry:Dictionary=series_value;var series_id:=str(series_entry.get("series_id",""))
		if not series_id.is_empty() and not _catalog_series_hidden_from_navigation(series_entry):visible_series[series_id]=true
	# Build each visible page once. The previous per-species lookup rebuilt the
	# same page hundreds of times during every NEW registration.
	var listed_species:Dictionary={}
	for series_id_value in visible_series:
		for listed_entry in _catalog_display_entries_for_series(str(series_id_value)):
			listed_species[str(listed_entry.get("species_id",""))]=true
	var ids:Array[String]=[];var membership:Dictionary={}
	for entry_value in catalog_species:
		if not entry_value is Dictionary:continue
		var entry:Dictionary=entry_value;var species_id:=str(entry.get("species_id",""))
		if membership.has(species_id) or not eligible_species.has(species_id):continue
		var display_series_id:=_catalog_display_series_id_for_entry(entry)
		if not visible_series.has(display_series_id) or not listed_species.has(species_id):continue
		membership[species_id]=true;ids.append(species_id)
	collection_complete_species_ids_cache=ids;collection_complete_species_membership_cache=membership;collection_complete_species_ids_cache_ready=true

func _is_collection_complete_species(entry:Dictionary)->bool:
	if not _collection_complete_entry_is_eligible(entry):return false
	_ensure_collection_complete_species_cache()
	return bool(collection_complete_species_membership_cache.get(str(entry.get("species_id","")),false))

func _collection_complete_species_ids()->Array[String]:
	_ensure_collection_complete_species_cache()
	return collection_complete_species_ids_cache.duplicate()

func _collection_complete_target_count()->int:
	return _collection_complete_species_ids().size()

func _collection_complete_get_count()->int:
	var count:=0
	for species_id in _collection_complete_species_ids():
		if _species_get_count(species_id)>0:count+=1
	return count

func _normalize_collection_complete_versions(raw_value:Variant)->Dictionary:
	var normalized:Dictionary={}
	if not raw_value is Dictionary:return normalized
	for raw_version in raw_value:
		var version:=str(raw_version).strip_edges()
		var raw_record:Variant=raw_value.get(raw_version,{})
		if version.is_empty() or not raw_record is Dictionary:continue
		var record:Dictionary=raw_record.duplicate(true)
		record["completed"]=bool(record.get("completed",false))
		record["presentation_seen"]=bool(record.get("presentation_seen",false))
		record["last_get_card_seen"]=bool(record.get("last_get_card_seen",true))
		record["completed_at"]=str(record.get("completed_at",""))
		record["species_count"]=maxi(0,int(record.get("species_count",0)))
		record["last_species_id"]=str(record.get("last_species_id",""))
		normalized[version]=record
	return normalized

func _collection_complete_current_record()->Dictionary:
	var record:Variant=collection_complete_versions.get(_game_version_key(),{})
	return record if record is Dictionary else {}

func _collection_is_currently_complete()->bool:
	var target_count:=_collection_complete_target_count()
	return target_count>0 and _collection_complete_get_count()==target_count

func _collection_completion_pending()->bool:
	var record:=_collection_complete_current_record()
	return bool(record.get("completed",false)) and not bool(record.get("presentation_seen",false)) and _collection_is_currently_complete()

func _collection_completion_last_species_id()->String:
	var record:=_collection_complete_current_record()
	var species_id:=str(record.get("last_species_id",collection_complete_pending_species_id))
	if _is_collection_complete_species(_catalog_entry(species_id)):return species_id
	var target_ids:=_collection_complete_species_ids()
	return "" if target_ids.is_empty() else target_ids[-1]

func _new_collection_complete_record(last_species_id:String)->Dictionary:
	return {
		"completed":true,
		"presentation_seen":false,
		"last_get_card_seen":false,
		"completed_at":Time.get_datetime_string_from_system(false,true),
		"species_count":_collection_complete_target_count(),
		"last_species_id":last_species_id,
	}

func _mark_collection_complete_if_earned(last_species_id:String)->bool:
	if not _is_collection_complete_species(_catalog_entry(last_species_id)) or not _collection_is_currently_complete():return false
	var version:=_game_version_key();var record:=_collection_complete_current_record()
	if bool(record.get("completed",false)):return false
	collection_complete_versions[version]=_new_collection_complete_record(last_species_id)
	collection_complete_pending_species_id=last_species_id
	# The species itself has already been formally registered. Persist both that
	# GET and the achievement before any optional presentation begins.
	_save()
	_refresh_collection_complete_badge()
	return true

func _reconcile_collection_completion_after_load()->bool:
	var changed:=false;var version:=_game_version_key();var record:=_collection_complete_current_record()
	if _collection_is_currently_complete() and not bool(record.get("completed",false)):
		var target_ids:=_collection_complete_species_ids()
		var last_species_id:="" if target_ids.is_empty() else target_ids[-1]
		record=_new_collection_complete_record(last_species_id)
		record["last_get_card_seen"]=true
		collection_complete_versions[version]=record;changed=true
	if bool(record.get("completed",false)) and not bool(record.get("presentation_seen",false)) and _collection_is_currently_complete():
		collection_complete_pending_species_id=_collection_completion_last_species_id()
	return changed

func _collection_complete_get_card_seen()->bool:
	return bool(_collection_complete_current_record().get("last_get_card_seen",false))

func _mark_collection_complete_get_card_seen(species_id:String)->void:
	if species_id.is_empty():return
	var record:=_collection_complete_current_record()
	if not bool(record.get("completed",false)) or bool(record.get("last_get_card_seen",false)):return
	var last_species_id:=str(record.get("last_species_id",""))
	if last_species_id.is_empty():last_species_id=_collection_completion_last_species_id()
	if species_id!=last_species_id:return
	record["last_get_card_seen"]=true
	collection_complete_versions[_game_version_key()]=record
	_save()

func _collection_complete_date_text(record:Dictionary)->String:
	var completed_at:=str(record.get("completed_at",""))
	if completed_at.length()<10:return ""
	return completed_at.substr(0,10).replace("-",".")

func _refresh_collection_complete_badge()->void:
	if encyclopedia_complete_badge_label==null:return
	var record:=_collection_complete_current_record();var completed:=bool(record.get("completed",false))
	encyclopedia_complete_badge_label.visible=completed
	var species_header:=encyclopedia_complete_badge_label.get_parent() as Control
	if species_header:
		species_header.custom_minimum_size.y=86.0 if completed else 58.0
	if not completed:return
	var date_text:=_collection_complete_date_text(record)
	encyclopedia_complete_badge_label.text="Ver.%s COMPLETE ✓"%_game_version_key()
	if not date_text.is_empty():encyclopedia_complete_badge_label.text+="　"+date_text

func _collection_complete_seconds(base_seconds:float)->float:
	return maxf(.001,base_seconds*maxf(.001,collection_complete_animation_speed_scale))

func _clear_collection_complete_effects()->void:
	if collection_complete_effect_layer==null:return
	for child in collection_complete_effect_layer.get_children():child.queue_free()

func _reset_collection_complete_card_visual()->void:
	if is_instance_valid(collection_complete_target_image):
		collection_complete_target_image.material=null
		collection_complete_target_image.modulate=Color.WHITE
	if is_instance_valid(collection_complete_silhouette_image):collection_complete_silhouette_image.queue_free()
	collection_complete_target_image=null;collection_complete_silhouette_image=null

func _reset_collection_complete_presentation(reset_fade:=false)->void:
	_reset_collection_complete_card_visual();_clear_collection_complete_effects()
	collection_complete_presentation_active=false;collection_complete_presentation_phase="";collection_complete_catalog_ready_before_fade_in=false
	collection_complete_prepared_series_id="";collection_complete_prepared_species_id="";collection_complete_prepared_scroll=0
	if collection_complete_card:collection_complete_card.visible=false;collection_complete_card.modulate=Color.WHITE;collection_complete_card.scale=Vector2.ONE
	if collection_complete_overlay:collection_complete_overlay.visible=false
	if reset_fade and scene_transition_fade:scene_transition_fade.visible=false;scene_transition_fade.color=Color.BLACK

func _collection_complete_card_index(species_id:String)->int:
	for index in range(encyclopedia_card_entries.size()):
		if str(encyclopedia_card_entries[index].get("species_id",""))==species_id:return index
	return -1

func _prepare_collection_complete_catalog(species_id:String):
	var entry:=_catalog_entry(species_id)
	if entry.is_empty():return null
	var series_id:=_catalog_display_series_id_for_entry(entry)
	if not _catalog_entry_is_listed_for_series(entry,series_id):return null
	unlocked_series[series_id]=true
	var owned:=_owned_series_entries();var series_index:=-1
	for index in range(owned.size()):
		if str(owned[index].get("series_id",""))==series_id:series_index=index;break
	if series_index<0:return null
	selected_series_index=series_index;current_encyclopedia_series_id=series_id
	encyclopedia_detail_page.visible=false;encyclopedia_series_page.visible=true;play_overlay.visible=false
	encyclopedia_overlay.visible=true;encyclopedia_overlay.move_to_front();encyclopedia_scroll.scroll_vertical=0
	_refresh_series_selection();_update_play_ui()
	await get_tree().process_frame;await get_tree().process_frame
	var card_index:=_collection_complete_card_index(species_id)
	if card_index<0 or card_index>=encyclopedia_grid.get_child_count():return null
	var card:=encyclopedia_grid.get_child(card_index) as Control
	var current_scroll:=float(encyclopedia_scroll.scroll_vertical)
	var card_content_y:=card.global_position.y-encyclopedia_scroll.global_position.y+current_scroll
	var desired_scroll:=card_content_y+card.size.y*.5-encyclopedia_scroll.size.y*.58
	var scroll_bar:=encyclopedia_scroll.get_v_scroll_bar()
	var maximum_scroll:=maxf(0.0,scroll_bar.max_value-scroll_bar.page)
	encyclopedia_scroll.scroll_vertical=roundi(clampf(desired_scroll,0.0,maximum_scroll))
	await get_tree().process_frame;await get_tree().process_frame
	_update_encyclopedia_visible_textures()
	var image:=encyclopedia_card_images[card_index]
	_request_species_texture(entry,image,true)
	var expected_path:=_species_image_path(entry)
	for _frame in range(180):
		if not is_instance_valid(image):return null
		var request_path:=str(image.get_meta("catalog_request_path",""))
		var loaded_path:=str(image.get_meta("catalog_loaded_path",""))
		if request_path.is_empty() and (not CatalogImageLoader.is_external_path(expected_path) or loaded_path==expected_path):break
		await get_tree().process_frame
	collection_complete_target_image=image
	image.material=null;image.modulate=Color(1,1,1,0)
	var silhouette:=TextureRect.new();silhouette.name="CollectionCompleteSilhouette";silhouette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);silhouette.expand_mode=image.expand_mode;silhouette.stretch_mode=image.stretch_mode;silhouette.texture=image.texture;silhouette.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if encyclopedia_silhouette_material==null:encyclopedia_silhouette_material=FusionLabUIClass.create_silhouette_material()
	silhouette.material=encyclopedia_silhouette_material;silhouette.modulate=Color.WHITE;image.get_parent().add_child(silhouette);silhouette.move_to_front()
	collection_complete_silhouette_image=silhouette
	collection_complete_prepared_series_id=series_id;collection_complete_prepared_species_id=species_id;collection_complete_prepared_scroll=encyclopedia_scroll.scroll_vertical
	collection_complete_catalog_ready_before_fade_in=true
	return image

func _play_collection_complete_light()->void:
	_clear_collection_complete_effects()
	var sweep:=Panel.new();sweep.name="CollectionCompleteLightSweep";sweep.position=Vector2(-190,-70);sweep.size=Vector2(150,1160);sweep.rotation=.10;sweep.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var sweep_style:=StyleBoxFlat.new();sweep_style.bg_color=Color(1.0,.78,.28,.18);sweep_style.shadow_color=Color(1.0,.65,.16,.26);sweep_style.shadow_size=42;sweep_style.set_corner_radius_all(75);sweep.add_theme_stylebox_override("panel",sweep_style);collection_complete_effect_layer.add_child(sweep)
	var light_duration:=_collection_complete_seconds(COLLECTION_COMPLETE_LIGHT_SECONDS)
	var sweep_tween:=create_tween();sweep_tween.tween_property(sweep,"position:x",760.0,light_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT);sweep_tween.parallel().tween_property(sweep,"modulate:a",0.0,light_duration*.35).set_delay(light_duration*.65)
	var sparkle_positions:=[Vector2(62,168),Vector2(168,312),Vector2(286,202),Vector2(438,354),Vector2(510,510),Vector2(92,612),Vector2(238,738),Vector2(390,664),Vector2(486,806),Vector2(146,876),Vector2(322,906),Vector2(522,248)]
	for index in range(sparkle_positions.size()):
		var sparkle:=UISymbolIconClass.new();sparkle.symbol="sparkle";sparkle.icon_color=Color("#ffe98b");sparkle.position=sparkle_positions[index];sparkle.size=Vector2(22,22) if index%3 else Vector2(30,30);sparkle.pivot_offset=sparkle.size*.5;sparkle.scale=Vector2(.35,.35);sparkle.modulate.a=0.0;sparkle.mouse_filter=Control.MOUSE_FILTER_IGNORE;collection_complete_effect_layer.add_child(sparkle)
		var delay:=light_duration*(.08+.055*float(index%8));var sparkle_tween:=create_tween().bind_node(sparkle);sparkle_tween.tween_interval(delay);sparkle_tween.tween_property(sparkle,"modulate:a",1.0,light_duration*.18);sparkle_tween.parallel().tween_property(sparkle,"scale",Vector2(1.18,1.18),light_duration*.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);sparkle_tween.tween_property(sparkle,"modulate:a",0.0,light_duration*.28);sparkle_tween.parallel().tween_property(sparkle,"scale",Vector2(.72,.72),light_duration*.28);sparkle_tween.tween_callback(sparkle.queue_free)
	await sweep_tween.finished
	if is_instance_valid(sweep):sweep.queue_free()

func _show_collection_complete_card()->void:
	collection_complete_title_label.text=Localizer.text(language_code,"collection_complete_title")
	collection_complete_message_label.text=Localizer.text(language_code,"collection_complete_message")
	collection_complete_version_label.text="COLLECTION COMPLETE\nVer.%s"%_game_version_key()
	collection_complete_continue_button.text=Localizer.text(language_code,"continue")
	collection_complete_card.visible=true;collection_complete_card.modulate=Color(1,1,1,0);collection_complete_card.scale=Vector2(.88,.88)
	var reveal:=create_tween().set_parallel();reveal.tween_property(collection_complete_card,"modulate:a",1.0,_collection_complete_seconds(.34));reveal.tween_property(collection_complete_card,"scale",Vector2.ONE,_collection_complete_seconds(.42)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if audio_manager:audio_manager.play_se("new_species",.68)
	collection_complete_presentation_phase="complete"

func _start_collection_complete_presentation()->void:
	if collection_complete_presentation_active or not _collection_completion_pending():return
	if collection_complete_overlay==null or scene_transition_fade==null:return
	collection_complete_presentation_active=true;collection_complete_presentation_phase="fade_out";collection_complete_catalog_ready_before_fade_in=false
	var species_id:=_collection_completion_last_species_id();collection_complete_pending_species_id=species_id
	collection_complete_resume_shop_visible=collection_complete_resume_shop_visible or (shop_overlay!=null and shop_overlay.visible)
	collection_complete_overlay.visible=true;collection_complete_overlay.move_to_front();collection_complete_card.visible=false;_clear_collection_complete_effects()
	scene_transition_fade.color=Color.BLACK;scene_transition_fade.color.a=0.0;scene_transition_fade.visible=true;scene_transition_fade.move_to_front()
	var fade_out:=create_tween();fade_out.tween_property(scene_transition_fade,"color:a",1.0,_collection_complete_seconds(COLLECTION_COMPLETE_FADE_OUT_SECONDS)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fade_out.finished
	if not collection_complete_presentation_active:return
	var target_image=await _prepare_collection_complete_catalog(species_id)
	if not collection_complete_presentation_active:return
	collection_complete_overlay.move_to_front();scene_transition_fade.move_to_front()
	collection_complete_presentation_phase="fade_in"
	var fade_in:=create_tween();fade_in.tween_property(scene_transition_fade,"color:a",0.0,_collection_complete_seconds(COLLECTION_COMPLETE_FADE_IN_SECONDS)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_in.finished
	scene_transition_fade.visible=false;scene_transition_fade.color=Color.BLACK
	collection_complete_presentation_phase="silhouette"
	await get_tree().create_timer(_collection_complete_seconds(COLLECTION_COMPLETE_SILHOUETTE_SECONDS)).timeout
	if not collection_complete_presentation_active:return
	collection_complete_presentation_phase="reveal"
	if is_instance_valid(target_image):
		var reveal:=create_tween().set_parallel();reveal.tween_property(target_image,"modulate:a",1.0,_collection_complete_seconds(COLLECTION_COMPLETE_REVEAL_SECONDS)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if is_instance_valid(collection_complete_silhouette_image):reveal.tween_property(collection_complete_silhouette_image,"modulate:a",0.0,_collection_complete_seconds(COLLECTION_COMPLETE_REVEAL_SECONDS)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await reveal.finished
	if audio_manager:audio_manager.play_se("level_up",.58)
	if is_instance_valid(collection_complete_silhouette_image):collection_complete_silhouette_image.queue_free()
	collection_complete_silhouette_image=null
	await _play_collection_complete_light()
	if collection_complete_presentation_active:_show_collection_complete_card()

func _on_collection_complete_card_closed()->void:
	if not collection_complete_presentation_active or collection_complete_presentation_phase!="complete":return
	collection_complete_continue_button.disabled=true
	var hide:=create_tween().set_parallel();hide.tween_property(collection_complete_card,"modulate:a",0.0,_collection_complete_seconds(.18));hide.tween_property(collection_complete_card,"scale",Vector2(.92,.92),_collection_complete_seconds(.18))
	await hide.finished
	collection_complete_continue_button.disabled=false;collection_complete_card.visible=false;collection_complete_overlay.visible=false;_clear_collection_complete_effects()
	collection_complete_presentation_phase="dialogue"
	_start_scripted_dialog("collection_complete",[
		{"speaker":"girl","text":Localizer.text(language_code,"collection_complete_dialog_1")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"collection_complete_dialog_2")},
		{"speaker":"panda","text":Localizer.text(language_code,"collection_complete_dialog_3")},
		{"speaker":"girl","text":Localizer.text(language_code,"collection_complete_dialog_4")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"collection_complete_dialog_5")},
		{"speaker":"panda","text":Localizer.text(language_code,"collection_complete_dialog_6")},
	],collection_complete_resume_shop_visible)

func _close_collection_complete_catalog()->void:
	_cancel_series_carousel_motion();encyclopedia_overlay.visible=false;_release_encyclopedia_textures()
	for card in series_carousel_cards:
		var cover_image=card.get("cover_image")
		if cover_image is TextureRect:cover_image.texture=null
	for child in encyclopedia_detail_page.get_children():child.free()

func _finish_collection_complete_presentation()->void:
	var version:=_game_version_key();var record:=_collection_complete_current_record()
	if bool(record.get("completed",false)):
		record["presentation_seen"]=true;collection_complete_versions[version]=record
	var resume_context:=collection_complete_resume_context
	_close_collection_complete_catalog();_reset_collection_complete_card_visual();_clear_collection_complete_effects()
	collection_complete_pending_species_id="";collection_complete_resume_context="";collection_complete_resume_shop_visible=false;collection_complete_presentation_active=false;collection_complete_presentation_phase="";collection_complete_overlay.visible=false
	_save();_refresh_collection_complete_badge();_update_play_ui()
	if not resume_context.is_empty():call_deferred("_continue_after_species_get_card",resume_context)
	else:call_deferred("_try_start_pending_story_event")

func _remember_catalog_cover_species(species_id:String)->bool:
	if species_id.is_empty() or _species_get_count(species_id)<=0:return false
	var entry:=_catalog_entry(species_id)
	if entry.is_empty():return false
	var series_id:=_catalog_display_series_id_for_entry(entry)
	if series_id.is_empty() or catalog_cover_species.has(series_id):return false
	var series_entry:=_series_entry(series_id)
	if series_entry.is_empty() or _catalog_series_hidden_from_navigation(series_entry) or not _catalog_entry_is_listed_for_series(entry,series_id):return false
	catalog_cover_species[series_id]=species_id
	return true

func _normalize_catalog_cover_species()->bool:
	var previous:Dictionary=catalog_cover_species.duplicate(true)
	var normalized:Dictionary={}
	for raw_series_id in catalog_cover_species:
		var series_id:=str(raw_series_id)
		if series_id=="jure":series_id=JUREJURE_SERIES_ID
		var species_id:=str(catalog_cover_species.get(raw_series_id,""))
		var entry:=_catalog_entry(species_id)
		var series_entry:=_series_entry(series_id)
		if species_id.is_empty() or entry.is_empty() or series_entry.is_empty():continue
		if _species_get_count(species_id)<=0 or _catalog_series_hidden_from_navigation(series_entry):continue
		if not _catalog_entry_is_listed_for_series(entry,series_id) or normalized.has(series_id):continue
		normalized[series_id]=species_id
	# Old saves do not know acquisition order. Choose the first owned card in the
	# exact catalog display order once, then persist it like every new cover.
	for raw_series in series_catalog:
		if not raw_series is Dictionary or _catalog_series_hidden_from_navigation(raw_series):continue
		var series_id:=str(raw_series.get("series_id",""))
		if series_id.is_empty() or normalized.has(series_id):continue
		for entry in _catalog_display_entries_for_series(series_id):
			var species_id:=str(entry.get("species_id",""))
			if _species_get_count(species_id)>0:
				normalized[series_id]=species_id
				break
	catalog_cover_species=normalized
	return catalog_cover_species!=previous

func _series_id_for_species(species_id:String)->String:
	for raw_series in series_catalog:
		if not raw_series is Dictionary:continue
		if species_id in raw_series.get("species_ids",[]):return str(raw_series.get("series_id",""))
	return ""

func _register_forest_gacha_encounters_for_series(series_id:String)->Array[String]:
	var registered:Array[String]=[]
	for species_id_value in forest_gacha_encountered:
		var species_id:=str(species_id_value)
		if not bool(forest_gacha_encountered.get(species_id,false)) or bool(discovered.get(species_id,false)):continue
		if _series_id_for_species(species_id)!=series_id:continue
		if not _species_available_in_current_era(_catalog_entry(species_id)):continue
		if _register_species_discovery(species_id,true):registered.append(species_id)
	return registered

func _register_encountered_species_for_unlocked_series()->bool:
	var changed:=false
	for raw_series in series_catalog:
		if not raw_series is Dictionary or not _is_series_unlocked(raw_series):continue
		if not _register_forest_gacha_encounters_for_series(str(raw_series.get("series_id",""))).is_empty():changed=true
	return changed

func _unlock_series_and_register_encounters(series_id:String)->Array[String]:
	var was_unlocked:=_is_series_unlocked(_series_entry(series_id))
	unlocked_series[series_id]=true
	var registered:=_register_forest_gacha_encounters_for_series(series_id)
	if not was_unlocked and not registered.is_empty():_queue_catalog_series_unlock_notice(series_id,true)
	return registered

func _species_is_in_unlocked_series(species_id:String)->bool:
	var series_id:=_series_id_for_species(species_id)
	if series_id.is_empty():return false
	var series_entry:=_series_entry(series_id)
	return not series_entry.is_empty() and _is_series_unlocked(series_entry)

func _series_seed_draw_candidates(series_id:String)->Array[Dictionary]:
	var candidates:Array[Dictionary]=[]
	for entry in _series_species_entries(series_id):
		if not _species_available_in_current_era(entry):continue
		var species_id:=str(entry.get("species_id",""))
		if species_id.is_empty() or _seed_new_species_blocked(species_id):continue
		if str(entry.get("rarity","")) in ["隠し原種","謎品種"]:continue
		candidates.append(entry)
	return candidates

func _choose_series_seed_species(series_id:String)->Dictionary:
	var candidates:=_series_seed_draw_candidates(series_id)
	return {} if candidates.is_empty() else candidates[rng.randi_range(0,candidates.size()-1)]

func _is_series_unlocked(entry:Dictionary)->bool:
	var series_id:=str(entry.get("series_id",""))
	return str(entry.get("unlock_type","future"))=="default" or bool(unlocked_series.get(series_id,false))

func _can_browse_series(entry:Dictionary)->bool:
	return _is_series_unlocked(entry) and not _catalog_series_hidden_from_navigation(entry)

func _catalog_purchase_enabled(entry:Dictionary)->bool:
	return false

func _catalog_price_puku(entry:Dictionary)->int:
	return 0

func _normal_series_rule(series_id:String)->Dictionary:
	for value in catalog_progression.get("normal_series",[]):
		if value is Dictionary and str(value.get("series_id",""))==series_id:return value
	return {}

func _hidden_series_rule(series_id:String)->Dictionary:
	for value in catalog_progression.get("hidden_series",[]):
		if value is Dictionary and str(value.get("series_id",""))==series_id:return value
	return {}

func _is_normal_series(series_id:String)->bool:
	return not _normal_series_rule(series_id).is_empty()

func _is_hidden_series(series_id:String)->bool:
	return not _hidden_series_rule(series_id).is_empty()

func _condition_met(condition:Dictionary)->bool:
	match str(condition.get("type","default")):
		"formal_play_count":return formal_play_count>=int(condition.get("value",0))
		"total_play_count":return total_play_count>=int(condition.get("value",0))
		"default":return true
		_:return false

func _is_series_stocked(series_id:String)->bool:
	var rule:=_normal_series_rule(series_id)
	return not rule.is_empty()

func _shop_series_catalog()->Array:
	var visible:Array=[]
	for entry in series_catalog:
		if entry is Dictionary and _is_normal_series(str(entry.get("series_id",""))) and _is_series_stocked(str(entry.get("series_id",""))):visible.append(entry)
	return visible

func _unowned_stocked_normal_series()->Array[Dictionary]:
	var candidates:Array[Dictionary]=[]
	for entry in _shop_series_catalog():
		if entry is Dictionary and not _is_series_unlocked(entry):candidates.append(entry)
	return candidates

func _next_restorable_hidden_series()->Dictionary:
	for raw_rule in catalog_progression.get("hidden_series",[]):
		if not raw_rule is Dictionary:continue
		var series_id:=str(raw_rule.get("series_id",""));var entry:=_series_entry(series_id)
		if not entry.is_empty() and not _is_series_unlocked(entry) and (old_catalog_page_inventory.is_empty() or int(old_catalog_page_inventory.get(series_id,0))>0):return entry
	return {}

func _first_unowned_hidden_series()->Dictionary:
	for raw_rule in catalog_progression.get("hidden_series",[]):
		if not raw_rule is Dictionary:continue
		var entry:=_series_entry(str(raw_rule.get("series_id","")))
		if not entry.is_empty() and not _is_series_unlocked(entry):return entry
	return {}

func _hidden_restoration_cost(series_id:String)->int:
	return 0

func _series_unlock_text(entry:Dictionary)->String:
	if _is_series_unlocked(entry):return ""
	var condition=entry.get("unlock_condition",{})
	if condition is Dictionary:
		var display_text:=str(condition.get("display_text",""))
		if not display_text.is_empty():
			if language_code=="ja":return display_text
			match display_text:
				"5ぷくコインで交換","5ぷくコインで解放":return Localizer.text(language_code,"unlock_five_puku")
				"古びた図鑑のページを復元":return Localizer.text(language_code,"unlock_restore_page")
				"ゲームを進めると入荷":return Localizer.text(language_code,"unlock_progress")
				_:return Localizer.text(language_code,"unlock_future")
	return Localizer.text(language_code,"unlock_future")

func _species_get_count(species_id:String)->int:
	return maxi(0,int(species_get_counts.get(species_id,0)))

func _is_jurejure_species(entry:Dictionary)->bool:
	return not entry.is_empty() and str(entry.get("story_group","")).to_lower()==JUREJURE_STORY_GROUP

func _is_jurejure_species_unlocked(species_id:String)->bool:
	return jurejure_pool_unlocked and _is_jurejure_species(_catalog_entry(species_id))

func _sync_jurejure_pool_unlock_state()->void:
	if not jurejure_pool_unlocked:return
	unlocked_series[JUREJURE_SERIES_ID]=true
	for entry in catalog_species:
		if entry is Dictionary and _is_jurejure_species(entry):
			jurejure_species_unlocked[str(entry.get("species_id",""))]=true

func _unlock_jurejure_pool()->bool:
	var newly_unlocked:=not jurejure_pool_unlocked
	jurejure_pool_unlocked=true
	_sync_jurejure_pool_unlock_state()
	return newly_unlocked

func _unlock_jurejure_species(species_id:String)->bool:
	var entry:=_catalog_entry(species_id)
	if not _is_jurejure_species(entry):return false
	return _unlock_jurejure_pool()

func _is_fantasy_species(entry:Dictionary)->bool:
	if entry.is_empty():return false
	# Story counts follow the page the player actually sees in the integrated
	# catalog. This includes every fusion tier while keeping JureJure's separate
	# eight-species progression out of the fantasy-only 1/6 milestones.
	if _is_jurejure_species(entry):return false
	return _catalog_display_series_id_for_entry(entry) in FANTASY_SERIES_IDS

func _fantasy_six_missing_series()->Array[String]:
	var found:Dictionary={}
	for entry_value in catalog_species:
		if not entry_value is Dictionary:continue
		var entry:Dictionary=entry_value
		if _species_get_count(str(entry.get("species_id","")))<=0:continue
		var display_series:=_catalog_display_series_id_for_entry(entry)
		if display_series in FANTASY_SIX_REQUIRED_SERIES:found[display_series]=true
	var missing:Array[String]=[]
	for series_id in FANTASY_SIX_REQUIRED_SERIES:
		if not bool(found.get(series_id,false)):missing.append(series_id)
	return missing

func _fantasy_six_required_series_complete()->bool:
	return _fantasy_six_missing_series().is_empty()

func _fantasy_six_new_candidate_allowed(entry:Dictionary)->bool:
	if _is_jurejure_species(entry):return false
	if fantasy_realization_seen or not StoryProgressionClass.fantasy_is_unlocked(story_progression_state) or not _is_fantasy_species(entry):return true
	var display_series:=_catalog_display_series_id_for_entry(entry)
	if display_series not in FANTASY_SIX_REQUIRED_SERIES:return false
	var missing:=_fantasy_six_missing_series()
	return missing.is_empty() or display_series in missing

func _unique_fantasy_species_get_count()->int:
	var count:=0
	for entry_value in catalog_species:
		if entry_value is Dictionary and _is_fantasy_species(entry_value) and _species_get_count(str(entry_value.get("species_id","")))>0:count+=1
	return count

func _unique_act2_species_get_count()->int:
	var counted:Dictionary={}
	for entry_value in catalog_species:
		if not entry_value is Dictionary:continue
		var entry:Dictionary=entry_value
		if _is_jurejure_species(entry):continue
		if not bool(entry.get("main_story_original",false)) and not _is_fantasy_species(entry):continue
		var species_id:=str(entry.get("species_id",""))
		if species_id.is_empty() or counted.has(species_id) or _species_get_count(species_id)<=0:continue
		counted[species_id]=true
	return counted.size()

func _unique_jurejure_species_get_count()->int:
	var count:=0
	for entry_value in catalog_species:
		if entry_value is Dictionary and _is_jurejure_species(entry_value) and _species_get_count(str(entry_value.get("species_id","")))>0:count+=1
	return count

func _refresh_narrative_species_progress()->void:
	var act2_species_count:=_unique_act2_species_get_count()
	if act2_species_count>=24 and not act3_unlocked:
		act3_unlocked=true;act3_intro_pending=not act3_intro_seen;act3_intro_eligible_visit_id=habitat_visit_id
	var jurejure_count:=_unique_jurejure_species_get_count()
	StoryProgressionClass.update_jurejure_progress(story_progression_state,jurejure_count)
	if jurejure_count>=8 and not habitat_crisis_started and not habitat_crisis_pending:
		habitat_crisis_pending=true
		StoryProgressionClass.queue_habitat_crisis_transition(story_progression_state,current_mode=="habitat")
	_update_main_story_progress(false)

func _series_get_count(series_id:String)->int:
	var total:=0
	for entry in _series_species_entries(series_id):total+=_species_get_count(str(entry.get("species_id","")))
	return total

func _all_series_get_count()->int:
	var total:=0;var counted:Dictionary={}
	for series_entry in series_catalog:
		for species_id_value in series_entry.get("species_ids",[]):
			var species_id:=str(species_id_value)
			if species_id.is_empty() or counted.has(species_id):continue
			counted[species_id]=true;total+=_species_get_count(species_id)
	return total

func _record_species_get(species_id:String,amount:int=1)->void:
	if amount<=0 or _catalog_entry(species_id).is_empty():return
	var previous_count:=_species_get_count(species_id)
	species_get_counts[species_id]=previous_count+amount
	if previous_count==0:
		_remember_catalog_cover_species(species_id)
		var entry:=_catalog_entry(species_id)
		var transition:=StoryProgressionClass.record_new_get(story_progression_state,{
			"act2_unlocked":act2_unlocked,
			"is_original":bool(entry.get("main_story_original",false)),
			"is_fantasy":_is_fantasy_species(entry),
			"fantasy_get_count":_unique_fantasy_species_get_count(),
			"fantasy_first_seen":fantasy_first_discovery_seen,
			"fantasy_six_seen":fantasy_realization_seen,
			"forest_gacha_unlocked":forest_gacha_unlocked,
		})
		if bool(transition.get("fantasy_unlocked_now",false)):_apply_saved_unlocks()
		StoryProgressionClass.record_restoration_new_get(story_progression_state,species_id,habitat_crisis_started)
		call_deferred("_try_start_pending_story_event")
	_refresh_narrative_species_progress()

func _species_available_in_current_era(entry:Dictionary)->bool:
	if entry.is_empty():return false
	if _is_jurejure_species(entry):return _is_jurejure_species_unlocked(str(entry.get("species_id","")))
	if bool(entry.get("main_story_original",false)):return true
	if StoryProgressionClass.fantasy_is_unlocked(story_progression_state):return true
	# The creation-era gate controls new discoveries.  A v18 save may already
	# own creative species, so keep those plants usable without opening any new
	# pre-awakening acquisition route.
	return bool(discovered.get(str(entry.get("species_id","")),false))

func _register_species_discovery(species_id:String,count_get:=true,check_collection_complete:=true)->bool:
	var profile_first_colorata:=old_colorata_profile_active and species_id==FIRST_STORY_SPECIES_ID and count_get
	if profile_first_colorata:_old_colorata_profile_mark("registration_lookup_start")
	var entry:=_catalog_entry(species_id)
	if entry.is_empty():return false
	if _is_jurejure_species(entry) and not _is_jurejure_species_unlocked(species_id):return false
	var series_id:=_series_id_for_species(species_id)
	var series_entry:=_series_entry(series_id)
	var series_page_was_unlocked:=not series_entry.is_empty() and _is_series_unlocked(series_entry)
	var first_discovery:=not bool(discovered.get(species_id,false));var first_get:=count_get and _species_get_count(species_id)==0
	discovered[species_id]=true
	greenhouse_available[species_id]=true;unlocked_species[species_id]=true
	if profile_first_colorata:_old_colorata_profile_mark("registration_record_get_start")
	if count_get:_record_species_get(species_id)
	if profile_first_colorata:_old_colorata_profile_mark("registration_record_get_end")
	var already_present:=false
	for active_entry in species:
		if str(active_entry.get("species_id",""))==species_id:already_present=true;break
	if not already_present:species.append(entry)
	if habitat_awakened and not _is_jurejure_species(entry):habitat_returned_species[species_id]=true
	if profile_first_colorata:_old_colorata_profile_mark("registration_inventory_end")
	if first_discovery:
		if not series_id.is_empty():unlocked_series[series_id]=true
		if count_get and not series_page_was_unlocked and not series_id.is_empty():
			_queue_catalog_series_unlock_notice(series_id)
		encyclopedia_unlocked=mystery_items_acquired;_refresh_seed_pack_unlocks()
		_update_main_story_progress(false)
	if profile_first_colorata:_old_colorata_profile_mark("registration_unlocks_end")
	if first_get and check_collection_complete:_mark_collection_complete_if_earned(species_id)
	if profile_first_colorata:_old_colorata_profile_mark("registration_collection_end")
	return first_discovery or first_get

func _register_story_catalog_species(species_id:String)->void:
	var entry:=_catalog_entry(species_id)
	if entry.is_empty():return
	discovered[species_id]=true
	var series_id:=_series_id_for_species(species_id)
	if not series_id.is_empty():unlocked_series[series_id]=true
	# Panda's and Armadillo's plants are catalog observations, not the player's
	# inventory. They become normal seed candidates until actually obtained.
	if _species_get_count(species_id)<=0:
		greenhouse_available.erase(species_id);unlocked_species.erase(species_id)
		for index in range(species.size()-1,-1,-1):
			if str(species[index].get("species_id",""))==species_id:species.remove_at(index)
	if habitat_awakened:habitat_returned_species[species_id]=true

func _update_main_story_progress(schedule_completion:=true)->void:
	main_story_stage=StoryProgressionClass.act_stage(act2_unlocked,act3_unlocked,finale_complete)
	main_story_complete=finale_complete
	if main_story_complete:main_story_completion_seen=true
	if schedule_completion:call_deferred("_try_start_pending_story_event")

func _queue_catalog_series_unlock_notice(series_id:String,species_get_already_shown:=false)->void:
	if series_id.is_empty():return
	var series_entry:=_series_entry(series_id)
	if series_entry.is_empty() or _catalog_series_hidden_from_navigation(series_entry):return
	if series_id not in catalog_series_unlock_notice_queue:catalog_series_unlock_notice_queue.append(series_id)
	if species_get_already_shown:catalog_series_unlock_notice_ready[series_id]=true

func _catalog_series_notice_name(series_entry:Dictionary)->String:
	var display_name:=Localizer.series_name(language_code,series_entry)
	if language_code!="en" and not display_name.ends_with("多肉") and not display_name.ends_with("たにく"):
		if language_code=="ja":display_name+="多肉"
		else:display_name+="たにく"
	return display_name

func _catalog_series_notice_cover(series_entry:Dictionary)->Texture2D:
	return _series_cover_texture(series_entry)

func _show_catalog_series_unlock_notice(series_id:String,context:String="")->bool:
	if catalog_series_unlock_overlay==null or catalog_series_unlock_overlay.visible:return false
	if species_get_overlay and species_get_overlay.visible:return false
	var queue_index:=catalog_series_unlock_notice_queue.find(series_id)
	if queue_index<0 or not bool(catalog_series_unlock_notice_ready.get(series_id,false)):return false
	var series_entry:=_series_entry(series_id)
	if series_entry.is_empty() or _catalog_series_hidden_from_navigation(series_entry):
		catalog_series_unlock_notice_queue.remove_at(queue_index)
		catalog_series_unlock_notice_ready.erase(series_id)
		return false
	catalog_series_unlock_notice_queue.remove_at(queue_index)
	catalog_series_unlock_notice_ready.erase(series_id)
	catalog_series_unlock_active_id=series_id
	catalog_series_unlock_overlay.show_series(series_entry,_catalog_series_notice_cover(series_entry),_catalog_series_notice_name(series_entry),context,language_code)
	var cover_entry:=_catalog_cover_entry_for_series(series_id)
	if not cover_entry.is_empty():_request_species_texture(cover_entry,catalog_series_unlock_overlay.cover_image,true)
	return true

func _try_start_catalog_series_unlock_notice()->bool:
	while not catalog_series_unlock_notice_queue.is_empty():
		var series_id:String=catalog_series_unlock_notice_queue[0]
		var series_entry:=_series_entry(series_id)
		if series_entry.is_empty() or _catalog_series_hidden_from_navigation(series_entry):catalog_series_unlock_notice_queue.pop_front();catalog_series_unlock_notice_ready.erase(series_id);continue
		if not bool(catalog_series_unlock_notice_ready.get(series_id,false)):return false
		return _show_catalog_series_unlock_notice(series_id)
	return false

func _try_start_pending_story_event()->void:
	if play_active:return
	if collection_complete_presentation_active:return
	if not opening_finished or opening_overlay and opening_overlay.visible:return
	# A newly harvested species owns the foreground first. Its story transition
	# is reconsidered by _on_species_get_overlay_closed after the full card queue.
	if not species_get_queue.is_empty():return
	if not scripted_dialog_kind.is_empty() or jurejure_intro_camera_active or opening_story_overlay and opening_story_overlay.visible or seed_pod_story_overlay and seed_pod_story_overlay.visible or jurejure_first_encounter_overlay and jurejure_first_encounter_overlay.visible or jurejure_first_encounter_active:return
	if intro_overlay and intro_overlay.visible:return
	if habitat_awakening_overlay and habitat_awakening_overlay.visible:return
	if habitat_second_awakening_overlay and habitat_second_awakening_overlay.visible:return
	if first_seed_pod_reward_event_active or tutorial_guide_overlay and tutorial_guide_overlay.visible:return
	if puku_puku_battle and puku_puku_battle.visible:return
	if species_get_overlay and species_get_overlay.visible:return
	if catalog_series_unlock_overlay and catalog_series_unlock_overlay.visible:return
	if result_overlay and result_overlay.visible:return
	if play_overlay and play_overlay.visible:return
	if encyclopedia_overlay and encyclopedia_overlay.visible:return
	if shop_overlay and shop_overlay.visible:return
	if forest_gacha_ui and forest_gacha_ui.visible:return
	if fusion_lab_ui and fusion_lab_ui.visible:return
	if arrangement_ui and arrangement_ui.visible:return
	if catalog_preview_ui and catalog_preview_ui.is_overlay_open():return
	if habitat_plant_panel and habitat_plant_panel.visible:return
	if habitat_dev_panel and habitat_dev_panel.visible:return
	if story_dev_panel and story_dev_panel.visible:return
	if settings_overlay and settings_overlay.visible:return
	if habitat_restoration_ui and habitat_restoration_ui.is_modal_visible():return
	if round_result_species_finalize_active or not round_result_species_finalize_queue.is_empty():return
	if not pending_round_new_species_ids.is_empty():
		call_deferred("_play_result_new_species_animations")
		return
	if _collection_completion_pending() and not _collection_complete_get_card_seen():
		call_deferred("_queue_species_get_by_id",_collection_completion_last_species_id(),true,"collection_complete_recovery")
		return
	if _try_start_post_ending_greenhouse_dialog():return
	if _try_start_catalog_series_unlock_notice():return
	if not catalog_series_unlock_notice_queue.is_empty():return
	if _collection_completion_pending():
		call_deferred("_start_collection_complete_presentation")
		return
	if fusion_return_pending and current_mode=="greenhouse" and not _immediate_get_story_transition_pending():
		call_deferred("_resume_fusion_lab_after_get")
		return
	if _try_start_pending_habitat_crisis_transition():return
	var queued_story_event:=StoryProgressionClass.peek_story_event(story_progression_state)
	if act3_intro_pending and not act3_intro_seen:
		if current_mode=="habitat":_focus_jurejure_group("act3_intro")
		else:call_deferred("_transition_to_story_habitat","act3_intro")
	elif current_mode=="greenhouse" and queued_story_event==StoryProgressionClass.EVENT_POST_ENCOUNTER_HOME:
		_start_post_jurejure_encounter_home_event()
	elif current_mode=="greenhouse" and queued_story_event==StoryProgressionClass.EVENT_POST_CRISIS_GREENHOUSE:
		_start_post_crisis_greenhouse_event()
	elif current_mode=="greenhouse" and queued_story_event==StoryProgressionClass.EVENT_RESTORATION_JOIN_HOME:
		_start_restoration_join_home_event()
	elif bool(_restoration_state().get("join_habitat_pending",false)):
		call_deferred("_transition_to_restoration_habitat","join",0)
	elif HabitatRestorationClass.pending_return_count(_restoration_state())>0:
		if current_mode=="habitat" and HabitatRestorationClass.returned_count(_restoration_state())==HabitatRestorationClass.REQUIRED_RETURNED_PLANTS-1:
			# Even when stages four and five were earned in one round, preserve the
			# fifth plant's white completion transition before it is committed.
			call_deferred("_transition_to_story_habitat","restoration_return")
		elif current_mode=="habitat":call_deferred("_commit_and_start_next_restoration_return")
		else:call_deferred("_transition_to_story_habitat","restoration_return")
	elif HabitatRestorationClass.pending_return_stage(_restoration_state())>0:
		var restoration:=_restoration_state()
		var pending_return_stage:=HabitatRestorationClass.pending_return_stage(restoration)
		if current_mode=="habitat":call_deferred("_start_restoration_return_event",pending_return_stage)
		else:call_deferred("_transition_to_story_habitat","restoration_return_event")
	elif _resume_restoration_ending():
		pass
	elif current_mode=="greenhouse" and queued_story_event==StoryProgressionClass.EVENT_ARRANGEMENT_INTRO:
		_start_arrangement_intro_event()
	elif current_mode=="habitat" and queued_story_event==StoryProgressionClass.EVENT_ACT3_BATTLE_INTRO:
		_focus_jurejure_group("act3_exploitation_start")
	elif current_mode=="habitat" and queued_story_event==StoryProgressionClass.EVENT_EXPLOITATION_MIDPOINT:
		_focus_jurejure_group("exploitation_midpoint")
	elif queued_story_event==StoryProgressionClass.EVENT_FANTASY_FIRST:
		_start_fantasy_first_discovery_event()
	elif queued_story_event==StoryProgressionClass.EVENT_FANTASY_SIX:
		_start_fantasy_realization_event()
	elif current_mode=="greenhouse" and forest_gacha_unlocked and not forest_gacha_intro_seen:
		_start_forest_gacha_intro_event()
	elif _unique_jurejure_species_get_count()>=1 and not jurejure_species_first_seen:
		_start_jurejure_species_first_event()
	elif current_mode=="habitat" and StoryProgressionClass.exploitation_is_started(story_progression_state) and not habitat_crisis_started:
		_maybe_start_habitat_exploitation_concern()
	elif current_mode=="habitat":
		_maybe_focus_jurejure_group_for_visit()

func _try_start_pending_habitat_crisis_transition()->bool:
	if not habitat_crisis_pending or habitat_crisis_started:return false
	var route:=StoryProgressionClass.habitat_crisis_route(story_progression_state)
	if route.is_empty():
		StoryProgressionClass.queue_habitat_crisis_transition(story_progression_state,current_mode=="habitat")
		route=StoryProgressionClass.habitat_crisis_route(story_progression_state)
	if current_mode=="habitat":
		_start_habitat_crisis_event()
		return true
	if current_mode=="greenhouse" and route==StoryProgressionClass.CRISIS_ROUTE_FORCE_TRAVEL:
		_start_habitat_crisis_departure_event()
		return true
	return false

func _start_habitat_crisis_departure_event()->void:
	if current_mode!="greenhouse" or not habitat_crisis_pending or habitat_crisis_started:return
	_start_scripted_dialog("habitat_crisis_departure",[
		{"speaker":"panda","text":Localizer.text(language_code,"habitat_crisis_departure_panda")}
	],false)

func _transition_to_habitat_crisis()->void:
	if scene_transition_fade==null or scene_transition_fade.visible or not habitat_crisis_pending or habitat_crisis_started:return
	scene_transition_fade.visible=true;scene_transition_fade.color.a=0.0;scene_transition_fade.move_to_front()
	var fade_out:=create_tween();fade_out.tween_property(scene_transition_fade,"color:a",1.0,.42).set_trans(Tween.TRANS_SINE)
	await fade_out.finished
	current_mode="habitat";habitat_visit_id+=1;_apply_mode();_build_habitat_items(true)
	var fade_in:=create_tween();fade_in.tween_property(scene_transition_fade,"color:a",0.0,.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_in.finished
	scene_transition_fade.visible=false
	_start_habitat_crisis_event()

func _start_post_jurejure_encounter_home_event()->void:
	if current_mode!="greenhouse" or not bool(story_progression_state.get("post_encounter_greenhouse_pending",false)):return
	_start_scripted_dialog("post_jurejure_encounter_home",[
		{"speaker":"panda","text":Localizer.text(language_code,"jurejure_after_encounter_panda")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"jurejure_after_encounter_armadillo")}
	],false)

func _start_post_crisis_greenhouse_event()->void:
	if current_mode!="greenhouse" or not bool(story_progression_state.get("post_crisis_greenhouse_pending",false)):return
	_start_scripted_dialog("post_crisis_greenhouse",HabitatRestorationClass.dialog_pages(language_code,"post_crisis_greenhouse"),false)

func _restoration_state()->Dictionary:
	return StoryProgressionClass.restoration_state(story_progression_state)

func _restoration_stage()->int:
	return HabitatRestorationClass.restoration_stage(_restoration_state())

func _start_restoration_join_home_event()->void:
	if current_mode!="greenhouse":return
	_start_scripted_dialog("restoration_join_home",HabitatRestorationClass.dialog_pages(language_code,"join_home"),false)

func _start_restoration_join_habitat_event()->void:
	if current_mode!="habitat":return
	_start_scripted_dialog("restoration_join_habitat",HabitatRestorationClass.dialog_pages(language_code,"join_habitat"),false)

func _restoration_return_pages(stage:int)->Array[Dictionary]:
	var pages:=HabitatRestorationClass.dialog_pages(language_code,"return",stage)
	if not pages.is_empty():pages[0]["restoration_stage"]=stage
	return pages

func _start_restoration_return_event(stage:int)->void:
	if current_mode!="habitat" or stage<1 or stage>5:return
	_build_habitat_items(true)
	_focus_restoration_returned_plant(stage)
	_start_scripted_dialog("restoration_return_%d"%stage,_restoration_return_pages(stage),false)

func _transition_between_restoration_returns(stage:int)->void:
	if current_mode!="habitat" or stage<1 or stage>=HabitatRestorationClass.REQUIRED_RETURNED_PLANTS:
		_start_restoration_return_event(stage)
		return
	if scene_transition_fade==null or scene_transition_fade.visible:
		_start_restoration_return_event(stage)
		return
	scene_transition_fade.color=Color.BLACK;scene_transition_fade.color.a=0.0;scene_transition_fade.visible=true;scene_transition_fade.move_to_front()
	var fade_out:=create_tween();fade_out.tween_property(scene_transition_fade,"color:a",1.0,.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fade_out.finished
	_build_habitat_items(true);_focus_restoration_returned_plant(stage,true)
	var fade_in:=create_tween();fade_in.tween_property(scene_transition_fade,"color:a",0.0,.80).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_in.finished
	scene_transition_fade.visible=false;scene_transition_fade.color=Color.BLACK
	_start_scripted_dialog("restoration_return_%d"%stage,_restoration_return_pages(stage),false)

func _commit_and_start_next_restoration_return()->void:
	if current_mode!="habitat":return
	var restoration:=_restoration_state()
	var stage:=HabitatRestorationClass.commit_next_pending_return(restoration)
	story_progression_state["restoration"]=restoration
	if stage<=0:
		call_deferred("_try_start_pending_story_event")
		return
	_save();_update_play_ui();_start_restoration_return_event(stage)

func _start_restoration_final_event()->void:
	_start_scripted_dialog("restoration_final",HabitatRestorationClass.dialog_pages(language_code,"final"),false)

func _start_restoration_epilogue_event()->void:
	var pages:=HabitatRestorationClass.dialog_pages(language_code,"epilogue")
	if pages.size()>2:pages[2]["start_ending_bgm"]=true
	_start_scripted_dialog("restoration_epilogue",pages,false)

func _try_start_post_ending_greenhouse_dialog()->bool:
	if current_mode!="greenhouse":return false
	var restoration:=_restoration_state()
	if HabitatRestorationClass.ending_phase(restoration)!="complete" or not bool(restoration.get("ending_seen",false)):return false
	if HabitatRestorationClass.post_ending_greenhouse_dialog_seen(restoration):return false
	HabitatRestorationClass.mark_post_ending_greenhouse_dialog_seen(restoration);story_progression_state["restoration"]=restoration;_save()
	_start_scripted_dialog("post_ending_greenhouse",[
		{"speaker":"girl","text":Localizer.text(language_code,"post_ending_greenhouse_girl_1")},
		{"speaker":"panda","text":Localizer.text(language_code,"post_ending_greenhouse_panda_1")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"post_ending_greenhouse_armadillo")},
		{"speaker":"girl","text":Localizer.text(language_code,"post_ending_greenhouse_girl_2")},
		{"speaker":"girl","text":Localizer.text(language_code,"post_ending_greenhouse_girl_3")},
		{"speaker":"girl","text":Localizer.text(language_code,"post_ending_greenhouse_girl_4")},
		{"speaker":"panda","text":Localizer.text(language_code,"post_ending_greenhouse_panda_2")},
	],false)
	return true

func _transition_to_restoration_habitat(event_kind:String,stage:int=0)->void:
	if scene_transition_fade==null or scene_transition_fade.visible:return
	var final_return:=event_kind=="final_return"
	scene_transition_fade.color=Color.WHITE if final_return else Color.BLACK
	scene_transition_fade.color.a=0.0;scene_transition_fade.visible=true;scene_transition_fade.move_to_front()
	if final_return:await get_tree().create_timer(.38).timeout
	var fade_out:=create_tween();fade_out.tween_property(scene_transition_fade,"color:a",1.0,.78 if final_return else .42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fade_out.finished
	current_mode="habitat";habitat_visit_id+=1;jurejure_focused_habitat_visit_id=habitat_visit_id;_apply_mode();_build_habitat_items(true)
	if final_return:_focus_restoration_returned_plant(HabitatRestorationClass.REQUIRED_RETURNED_PLANTS,true)
	var fade_in:=create_tween();fade_in.tween_property(scene_transition_fade,"color:a",0.0,.92 if final_return else .62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_in.finished
	scene_transition_fade.visible=false;scene_transition_fade.color=Color.BLACK
	if event_kind=="join":_start_restoration_join_habitat_event()
	elif event_kind=="return":_start_restoration_return_event(stage)
	elif event_kind=="final_return":
		await get_tree().create_timer(.32).timeout
		_start_restoration_return_event(HabitatRestorationClass.pending_return_stage(_restoration_state()))
	elif event_kind=="slides":_begin_restoration_recovery_slides()
	elif event_kind=="final":_start_restoration_final_event()
	elif event_kind=="epilogue":_start_restoration_epilogue_event()

func _transition_to_story_habitat(event_kind:String)->void:
	if scene_transition_fade==null or scene_transition_fade.visible:return
	var restoration_before:=_restoration_state()
	var final_return:=event_kind=="restoration_return" and HabitatRestorationClass.returned_count(restoration_before)==HabitatRestorationClass.REQUIRED_RETURNED_PLANTS-1 and HabitatRestorationClass.pending_return_count(restoration_before)>0
	if event_kind=="restoration_return_event":final_return=HabitatRestorationClass.pending_return_stage(restoration_before)==HabitatRestorationClass.REQUIRED_RETURNED_PLANTS
	scene_transition_fade.color=Color.WHITE if final_return else Color.BLACK;scene_transition_fade.color.a=0.0;scene_transition_fade.visible=true;scene_transition_fade.move_to_front()
	if final_return:await get_tree().create_timer(.38).timeout
	var fade_out:=create_tween();fade_out.tween_property(scene_transition_fade,"color:a",1.0,.78 if final_return else .42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fade_out.finished
	current_mode="habitat";habitat_visit_id+=1;jurejure_focused_habitat_visit_id=habitat_visit_id
	var committed_stage:=0
	if event_kind=="restoration_return":
		var restoration:=_restoration_state();committed_stage=HabitatRestorationClass.commit_next_pending_return(restoration);story_progression_state["restoration"]=restoration;_save()
	_apply_mode();_build_habitat_items(true)
	if final_return:_focus_restoration_returned_plant(HabitatRestorationClass.REQUIRED_RETURNED_PLANTS,true)
	var fade_in:=create_tween();fade_in.tween_property(scene_transition_fade,"color:a",0.0,.92 if final_return else .62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_in.finished
	scene_transition_fade.visible=false;scene_transition_fade.color=Color.BLACK
	match event_kind:
		"act3_intro":_focus_jurejure_group("act3_intro")
		"restoration_return":
			if committed_stage>0:_start_restoration_return_event(committed_stage)
			else:call_deferred("_try_start_pending_story_event")
		"restoration_return_event":_start_restoration_return_event(HabitatRestorationClass.pending_return_stage(_restoration_state()))
		_:call_deferred("_try_start_pending_story_event")

func _transition_back_to_greenhouse_after_restoration()->void:
	if scene_transition_fade==null or scene_transition_fade.visible:return
	scene_transition_fade.visible=true;scene_transition_fade.color.a=0.0;scene_transition_fade.move_to_front()
	var fade_out:=create_tween();fade_out.tween_property(scene_transition_fade,"color:a",1.0,.38).set_trans(Tween.TRANS_SINE)
	await fade_out.finished
	current_mode="greenhouse";_apply_mode()
	var fade_in:=create_tween();fade_in.tween_property(scene_transition_fade,"color:a",0.0,.58).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await fade_in.finished
	scene_transition_fade.visible=false
	_update_play_ui();call_deferred("_poll_greenhouse_play_completion");call_deferred("_try_start_pending_story_event")

func _begin_restoration_recovery_slides()->void:
	if habitat_restoration_ui==null or habitat_restoration_ui.is_modal_visible():return
	if scene_transition_fade:
		scene_transition_fade.visible=true;scene_transition_fade.color.a=0.0;scene_transition_fade.move_to_front()
		var fade_out:=create_tween();fade_out.tween_property(scene_transition_fade,"color:a",1.0,.42).set_trans(Tween.TRANS_SINE)
		await fade_out.finished
	habitat_restoration_ui.set_language(language_code);habitat_restoration_ui.start_recovery_slides()
	if scene_transition_fade:
		var fade_in:=create_tween();fade_in.tween_property(scene_transition_fade,"color:a",0.0,.58).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await fade_in.finished
		scene_transition_fade.visible=false

func _show_restoration_thank_you()->void:
	habitat_restoration_ui.set_language(language_code)
	habitat_restoration_ui.show_thank_you(_restoration_ending_record_slides(),_restoration_ending_plant_slides())
	_update_play_ui()

func _restoration_ending_record_slides()->Array[Dictionary]:
	var catalog_count:=0
	for get_count_value in species_get_counts.values():
		if int(get_count_value)>0:catalog_count+=1
	return [
		{"kind":"harvest_count","text":Localizer.text(language_code,"restoration_record_harvested",[StoryProgressionClass.lifetime_harvest_count(story_progression_state)])},
		{"kind":"harvest_cm_total","text":Localizer.text(language_code,"restoration_record_size",[_format_cm(StoryProgressionClass.lifetime_harvest_cm_total(story_progression_state))])},
		{"kind":"catalog_count","text":Localizer.text(language_code,"restoration_record_catalog",[catalog_count])},
		{"kind":"battle_count","text":Localizer.text(language_code,"restoration_record_battles",[jurejure_battle_count])},
		{"kind":"battle_win_count","text":Localizer.text(language_code,"restoration_record_wins",[jurejure_battle_win_count])},
	]

func _restoration_ending_plant_slides()->Array[Dictionary]:
	var slides:Array[Dictionary]=[]
	for snapshot_value in HabitatRestorationClass.returned_plants(_restoration_state()):
		if not snapshot_value is Dictionary or slides.size()>=HabitatRestorationClass.REQUIRED_RETURNED_PLANTS:continue
		var snapshot:Dictionary=(snapshot_value as Dictionary).duplicate(true)
		var species_id:=str(snapshot.get("species_id",""));var entry:=_catalog_entry(species_id)
		snapshot["display_name"]=Localizer.species_name(language_code,entry) if not entry.is_empty() else str(snapshot.get("display_name",species_id))
		snapshot["diameter_text"]=_format_cm(float(snapshot.get("diameter_cm",0.0)))
		snapshot["heading"]=Localizer.text(language_code,"restoration_returned_plant_heading")
		snapshot["image_path"]=_species_image_path(entry) if not entry.is_empty() else ""
		slides.append(snapshot)
	return slides

func _on_restoration_ending_bgm_requested()->void:
	# The ending UI still emits this as a resume fallback, but the normal story
	# has already started the same track on Peccary's SDGs line.
	_start_restoration_ending_bgm_if_needed()

func _start_restoration_ending_bgm_if_needed()->void:
	if audio_manager==null or audio_manager.current_bgm_key=="ending":return
	audio_manager.play_bgm("ending",true,ENDING_BGM_FADE_IN_SECONDS)

func _resume_restoration_ending()->bool:
	var phase:=HabitatRestorationClass.ending_phase(_restoration_state())
	match phase:
		"slides":
			if current_mode=="habitat":call_deferred("_begin_restoration_recovery_slides")
			else:call_deferred("_transition_to_restoration_habitat","slides",0)
		"final":
			if current_mode=="habitat":call_deferred("_start_restoration_final_event")
			else:call_deferred("_transition_to_restoration_habitat","final",0)
		"epilogue":
			if current_mode=="habitat":call_deferred("_start_restoration_epilogue_event")
			else:call_deferred("_transition_to_restoration_habitat","epilogue",0)
		"thank_you":call_deferred("_show_restoration_thank_you")
		_:return false
	return true

func _on_restoration_return_decided(accepted:bool)->void:
	var snapshot:=pending_restoration_snapshot.duplicate(true);pending_restoration_snapshot.clear()
	if not accepted:
		_update_play_ui();call_deferred("_poll_greenhouse_play_completion")
		return
	var restoration:=_restoration_state()
	var stage:=HabitatRestorationClass.add_returned_plant(restoration,snapshot)
	story_progression_state["restoration"]=restoration
	if stage<=0:
		_update_play_ui();call_deferred("_poll_greenhouse_play_completion")
		return
	_save();_update_play_ui()
	call_deferred("_poll_greenhouse_play_completion");call_deferred("_try_start_pending_story_event")

func _on_restoration_slides_finished()->void:
	if scene_transition_fade:
		scene_transition_fade.visible=true;scene_transition_fade.color.a=1.0;scene_transition_fade.move_to_front()
	var restoration:=_restoration_state();HabitatRestorationClass.reveal_full_recovery(restoration);story_progression_state["restoration"]=restoration
	if habitat_crisis_atmosphere:habitat_crisis_atmosphere.set_restoration_stage(5)
	_build_habitat_items(true);_play_current_area_bgm();_save();_update_play_ui()
	if scene_transition_fade:
		var fade_in:=create_tween();fade_in.tween_property(scene_transition_fade,"color:a",0.0,.78).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await fade_in.finished
		scene_transition_fade.visible=false
	call_deferred("_start_restoration_final_event")

func _on_restoration_thank_you_closed()->void:
	var restoration:=_restoration_state();HabitatRestorationClass.complete_ending(restoration);story_progression_state["restoration"]=restoration
	audio_manager.play_bgm("greenhouse",false,ENDING_BGM_FADE_OUT_SECONDS)
	finale_complete=true;current_mode="greenhouse";_apply_mode();_update_main_story_progress(false);_save()
	await habitat_restoration_ui.fade_out_ending_sequence(ENDING_BGM_FADE_OUT_SECONDS)
	_update_play_ui()
	call_deferred("_poll_greenhouse_play_completion");call_deferred("_try_start_pending_story_event")

func _start_forest_gacha_intro_event()->void:
	if not forest_gacha_unlocked or forest_gacha_intro_seen or current_mode!="greenhouse":return
	_start_scripted_dialog("forest_gacha_intro",[
		{"speaker":"panda","text":Localizer.text(language_code,"forest_gacha_intro_panda")},
		{"speaker":"","text":Localizer.text(language_code,"forest_gacha_intro_system")}
	],false)

func _start_fantasy_first_discovery_event()->void:
	if fantasy_first_discovery_seen or not act2_unlocked or _unique_fantasy_species_get_count()<1:return
	_start_scripted_dialog("fantasy_first_discovery",[
		{"speaker":"girl","text":Localizer.text(language_code,"fantasy_first_girl")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"fantasy_first_armadillo")},
		{"speaker":"panda","text":Localizer.text(language_code,"fantasy_first_panda")}
	],false)

func _start_arrangement_intro_event()->void:
	if current_mode!="greenhouse" or not bool(story_progression_state.get("arrangement_intro_pending",false)):return
	_start_scripted_dialog("arrangement_intro",[
		{"speaker":"panda","text":Localizer.text(language_code,"arrangement_unlock_panda")}
	],false)

func _start_fantasy_realization_event()->void:
	if fantasy_realization_seen or not act2_unlocked or _unique_fantasy_species_get_count()<6 or not _fantasy_six_required_series_complete():return
	_start_scripted_dialog("fantasy_realization",[
		{"speaker":"girl","text":Localizer.text(language_code,"fantasy_six_girl_1")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"fantasy_six_armadillo")},
		{"speaker":"girl","text":Localizer.text(language_code,"fantasy_six_girl_2")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"fantasy_six_armadillo_2")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"fantasy_six_armadillo_3")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"fantasy_six_armadillo_4")}
	],false)

func _start_exploitation_midpoint_event()->void:
	if current_mode!="habitat" or not bool(story_progression_state.get("exploitation_midpoint_pending",false)):return
	if habitat_crisis_pending or habitat_crisis_started:return
	_start_scripted_dialog("exploitation_midpoint",[
		{"speaker":"panda","text":Localizer.text(language_code,"habitat_exploit_midpoint_panda_1")},
		{"speaker":"girl","text":Localizer.text(language_code,"habitat_exploit_midpoint_girl")},
		{"speaker":"mouse","text":Localizer.text(language_code,"habitat_exploit_midpoint_mouse_1")},
		{"speaker":"peccary","text":Localizer.text(language_code,"habitat_exploit_midpoint_peccary")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"habitat_exploit_midpoint_armadillo")},
		{"speaker":"mouse","text":Localizer.text(language_code,"habitat_exploit_midpoint_mouse_2")}
	],false)

func _maybe_start_habitat_exploitation_concern()->void:
	if habitat_crisis_pending or habitat_crisis_started:return
	var concern:=JureJureSystemClass.concern_for_visit(story_progression_state,habitat_visit_id,StoryProgressionClass.exploitation_midpoint_is_seen(story_progression_state),rng)
	if concern.is_empty():return
	_start_scripted_dialog("habitat_exploitation_concern",[
		{"speaker":str(concern.get("speaker","")),"text":Localizer.text(language_code,str(concern.get("text_key","")))}
	],false)

func _start_act3_intro_event()->void:
	if not act3_intro_pending or act3_intro_seen or current_mode!="habitat":return
	_start_scripted_dialog("act3_intro",[
		{"speaker":"mouse","text":Localizer.text(language_code,"act3_mouse_realizes")},
		{"speaker":"mouse","text":Localizer.text(language_code,"act3_mouse_demands")},
		{"speaker":"peccary","text":Localizer.text(language_code,"act3_peccary_wants")},
		{"speaker":"skunk","text":Localizer.text(language_code,"act3_skunk_wants")}
	],false)

func _start_act3_exploitation_battle_intro_event()->void:
	if current_mode!="habitat" or not bool(story_progression_state.get("act3_battle_intro_pending",false)):return
	if habitat_crisis_pending or habitat_crisis_started:return
	_start_scripted_dialog("act3_exploitation_battle_intro",[
		{"speaker":"mouse","text":Localizer.text(language_code,"act3_exploitation_battle_intro")},
		{"speaker":"panda","text":Localizer.text(language_code,"act3_exploitation_battle_intro_panda")},
		{"speaker":"mouse","text":Localizer.text(language_code,"act3_exploitation_battle_intro_mouse_2")}
	],false)

func _start_jurejure_species_first_event()->void:
	if jurejure_species_first_seen or _unique_jurejure_species_get_count()<1:return
	_start_scripted_dialog("jurejure_species_first",[
		{"speaker":"girl","text":Localizer.text(language_code,"jurejure_species_first_girl")},
		{"speaker":"girl","text":Localizer.text(language_code,"jurejure_species_first_girl_2")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"jurejure_species_first_armadillo")}
	],false)

func _start_habitat_crisis_event()->void:
	if not habitat_crisis_pending or habitat_crisis_started or current_mode!="habitat":return
	habitat_crisis_pending=false;habitat_crisis_started=true;StoryProgressionClass.begin_habitat_crisis(story_progression_state)
	story_progression_state["last_crisis_concern_visit"]=habitat_visit_id
	# Rebuild only the presentation nodes so the living collection is visibly
	# subdued. The saved population, growth clocks, ownership and GET history are
	# untouched.
	_build_habitat_items(true)
	if habitat_crisis_atmosphere:
		habitat_crisis_atmosphere.activate()
		habitat_crisis_atmosphere.set_habitat_visible(true)
	jurejure_waiting_for_seed_pod_reward=false;_save()
	_play_current_area_bgm()
	_focus_jurejure_group("habitat_crisis")

func _begin_habitat_crisis_dialog()->void:
	if current_mode!="habitat" or not habitat_crisis_started or not scripted_dialog_kind.is_empty():return
	_start_scripted_dialog("habitat_crisis",[
		{"speaker":"armadillo","text":Localizer.text(language_code,"habitat_crisis_armadillo_1")},
		{"speaker":"armadillo","text":Localizer.text(language_code,"habitat_crisis_armadillo_2")},
		{"speaker":"girl","text":Localizer.text(language_code,"habitat_crisis_girl")},
		{"speaker":"mouse","text":Localizer.text(language_code,"habitat_crisis_mouse")},
		{"speaker":"peccary","text":Localizer.text(language_code,"habitat_crisis_peccary")},
		{"speaker":"skunk","text":Localizer.text(language_code,"habitat_crisis_skunk")}
	],false)

func _series_found_count(series_id:String)->int:
	var found:=0
	for entry in _series_species_entries(series_id):
		if bool(discovered.get(str(entry.get("species_id","")),false)):found+=1
	return found

func _refresh_series_selection()->void:
	var entry:=_current_series_entry()
	if entry.is_empty():return
	var owned:=_owned_series_entries()
	_refresh_series_carousel_cards()
	series_previous_button.disabled=owned.size()<2;series_next_button.disabled=owned.size()<2
	_refresh_unified_series_contents(false)

func _refresh_unified_series_contents(reset_scroll:bool)->void:
	var entry:=_current_series_entry()
	if entry.is_empty():return
	current_encyclopedia_series_id=str(entry.get("series_id",INITIAL_SERIES_ID))
	_refresh_encyclopedia_header();_refresh_encyclopedia_cards()
	if reset_scroll:encyclopedia_scroll.scroll_vertical=0

func _refresh_series_carousel_cards()->void:
	var owned:=_owned_series_entries()
	if owned.is_empty():return
	for card in series_carousel_cards:
		var relative_index:=int(card.get("relative_index",0));var series_index:=wrapi(selected_series_index+relative_index,0,owned.size())
		_populate_series_card(card,series_index,owned)
	_set_series_carousel_offset(series_carousel_offset)

func _populate_series_card(card:Dictionary,series_index:int,owned:Array[Dictionary])->void:
	var entry:Dictionary=owned[series_index];var series_id:=str(entry.get("series_id",""));var cover_entry:=_catalog_cover_entry_for_series(series_id);var unlocked:=_is_series_unlocked(entry)
	var container:Control=card.container;var cover_image:TextureRect=card.cover_image
	card.title.text=Localizer.series_name(language_code,entry);card.subtitle.text=Localizer.series_subtitle(language_code,entry);card.description.text=Localizer.series_description(language_code,entry)
	cover_image.set_meta("catalog_loaded_path","");cover_image.set_meta("catalog_request_path","")
	cover_image.texture=_series_cover_texture(entry)
	if not cover_entry.is_empty():_request_species_texture(cover_entry,cover_image,true)
	card.cover_placeholder.visible=cover_image.texture==null and unlocked;card.cover_placeholder.text=Localizer.text(language_code,"catalog_cover_preparing");card.lock_label.visible=not unlocked;card.lock_label.text=Localizer.text(language_code,"catalog_locked_preparing" if cover_image.texture==null else "catalog_locked")
	var lock_icon:Control=card.get("lock_icon")
	if is_instance_valid(lock_icon):lock_icon.visible=not unlocked
	container.visible=owned.size()>1 or int(card.relative_index)==0;container.set_meta("series_index",series_index);container.set_meta("series_id",series_id)

func _series_cover_texture(entry:Dictionary)->Texture2D:
	var cover_entry:=_catalog_cover_entry_for_series(str(entry.get("series_id","")))
	return _species_texture(cover_entry) if not cover_entry.is_empty() else null

func _change_series_selection(direction:int)->void:
	if collection_complete_presentation_active:return
	if _owned_series_entries().size()<2 or direction==0 or series_carousel_animating:return
	_animate_series_selection(signi(direction))

func _on_series_swipe_input(event:InputEvent)->void:
	if event is InputEventScreenTouch:
		if event.pressed and not series_carousel_animating:series_swipe_start=event.position;series_swipe_tracking=true;series_swipe_axis=0
		elif series_swipe_tracking:_finish_series_swipe(event.position)
	elif event is InputEventScreenDrag and series_swipe_tracking:
		_update_series_swipe(event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed and not series_carousel_animating:series_swipe_start=event.position;series_swipe_tracking=true;series_swipe_axis=0
		elif series_swipe_tracking:_finish_series_swipe(event.position)
	elif event is InputEventMouseMotion and series_swipe_tracking and event.button_mask&MOUSE_BUTTON_MASK_LEFT:
		_update_series_swipe(event.position)

func _update_series_swipe(position:Vector2)->void:
	var delta:=position-series_swipe_start
	if series_swipe_axis==0 and maxf(absf(delta.x),absf(delta.y))>=12.0:series_swipe_axis=1 if absf(delta.x)>absf(delta.y)*1.15 else 2
	if series_swipe_axis!=1:return
	_set_series_carousel_offset(clampf(delta.x,-SERIES_CAROUSEL_SPACING,SERIES_CAROUSEL_SPACING))

func _finish_series_swipe(end_position:Vector2)->void:
	_update_series_swipe(end_position);series_swipe_tracking=false
	if series_swipe_axis==2:series_swipe_axis=0;_set_series_carousel_offset(0.0);return
	var delta:=end_position-series_swipe_start;series_swipe_axis=0
	if absf(delta.x)>=SERIES_CAROUSEL_SWIPE_THRESHOLD and absf(delta.x)>absf(delta.y):_animate_series_selection(1 if delta.x<0.0 else -1)
	else:_animate_series_snap_back()

func _set_series_carousel_offset(value:float)->void:
	series_carousel_offset=value
	if not series_carousel_track:return
	series_carousel_track.position=SERIES_CAROUSEL_TRACK_ORIGIN+Vector2(value,0)
	var travel:=clampf(absf(value)/SERIES_CAROUSEL_SPACING,0.0,1.0);var incoming_relative:=1 if value<0.0 else -1
	for card in series_carousel_cards:
		var relative_index:=int(card.get("relative_index",0));var container:Control=card.container;var brightness:=1.0 if relative_index==0 else 0.72
		if relative_index==incoming_relative:brightness=lerpf(0.72,1.0,travel)
		elif relative_index==0:brightness=lerpf(1.0,0.72,travel)
		container.modulate=Color(brightness,brightness,brightness,1.0)
		var detail_alpha:=1.0 if relative_index==0 else 0.0
		if relative_index==incoming_relative:detail_alpha=travel
		elif relative_index==0:detail_alpha=1.0-travel
		for detail_node in card.detail_nodes:detail_node.self_modulate.a=detail_alpha

func _animate_series_selection(direction:int)->void:
	if _owned_series_entries().size()<2 or series_carousel_animating:return
	series_swipe_tracking=false;series_carousel_animating=true
	if series_carousel_tween and series_carousel_tween.is_valid():series_carousel_tween.kill()
	series_carousel_tween=create_tween();series_carousel_tween.tween_method(_set_series_carousel_offset,series_carousel_offset,-direction*SERIES_CAROUSEL_SPACING,SERIES_CAROUSEL_SLIDE_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT);series_carousel_tween.tween_callback(_finish_series_transition.bind(direction))

func _finish_series_transition(direction:int)->void:
	var owned:=_owned_series_entries();selected_series_index=wrapi(selected_series_index+direction,0,owned.size());_refresh_series_carousel_cards();_set_series_carousel_offset(0.0);series_carousel_animating=false;_refresh_unified_series_contents(true)

func _animate_series_snap_back()->void:
	if is_zero_approx(series_carousel_offset):_set_series_carousel_offset(0.0);return
	series_carousel_animating=true
	if series_carousel_tween and series_carousel_tween.is_valid():series_carousel_tween.kill()
	series_carousel_tween=create_tween();series_carousel_tween.tween_method(_set_series_carousel_offset,series_carousel_offset,0.0,SERIES_CAROUSEL_SLIDE_SECONDS*.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT);series_carousel_tween.tween_callback(func():series_carousel_animating=false)

func _cancel_series_carousel_motion()->void:
	if series_carousel_tween and series_carousel_tween.is_valid():series_carousel_tween.kill()
	series_carousel_animating=false;series_swipe_tracking=false;series_swipe_axis=0;_set_series_carousel_offset(0.0)

func _open_selected_series_encyclopedia()->void:
	var entry:=_current_series_entry()
	if series_carousel_animating or series_swipe_tracking or entry.is_empty() or not _can_browse_series(entry):return
	encyclopedia_detail_page.visible=false;encyclopedia_series_page.visible=true;_refresh_unified_series_contents(false)

func _return_to_series_selection()->void:
	_release_encyclopedia_textures()
	for child in encyclopedia_detail_page.get_children():child.free()
	encyclopedia_detail_page.visible=false;encyclopedia_series_page.visible=true;_refresh_series_selection()

func _refresh_encyclopedia_header()->void:
	if encyclopedia_list_title==null:return
	var entry:=_series_entry(current_encyclopedia_series_id)
	encyclopedia_list_title.text=Localizer.series_name(language_code,entry)
	_refresh_collection_complete_badge()
	encyclopedia_unlock_panel.visible=false;encyclopedia_unlock_puku_button.visible=false

func _acquire_current_catalog(method:String)->void:
	return

func _refresh_encyclopedia_cards()->void:
	encyclopedia_card_images.clear();encyclopedia_card_entries.clear()
	for child in encyclopedia_grid.get_children():child.free()
	for entry in _catalog_display_entries_for_series(current_encyclopedia_series_id):
		var species_id:=str(entry.get("species_id",""));var found:=bool(discovered.get(species_id,false));var identity_visible:=found or _catalog_identity_visible_before_get(entry)
		var card:=Button.new();card.custom_minimum_size=Vector2(252,274);card.mouse_filter=Control.MOUSE_FILTER_PASS;card.mouse_force_pass_scroll_events=true;card.action_mode=BaseButton.ACTION_MODE_BUTTON_RELEASE;_skin_button(card,Color("#f6e7c5"),16);card.disabled=not found;encyclopedia_grid.add_child(card)
		var content:=VBoxContainer.new();content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);content.offset_left=10;content.offset_top=8;content.offset_right=-10;content.offset_bottom=-8;content.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.alignment=BoxContainer.ALIGNMENT_CENTER;card.add_child(content)
		var image_frame:=MarginContainer.new();image_frame.name="SpeciesCardImageFrame";image_frame.custom_minimum_size=Vector2(210,137);image_frame.add_theme_constant_override("margin_left",10);image_frame.add_theme_constant_override("margin_top",8);image_frame.add_theme_constant_override("margin_right",10);image_frame.add_theme_constant_override("margin_bottom",8);image_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(image_frame)
		var image:=TextureRect.new();image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.mouse_filter=Control.MOUSE_FILTER_IGNORE;image.texture=_species_loading_texture(entry)
		_apply_encyclopedia_image_style(image,entry,found)
		image_frame.add_child(image);encyclopedia_card_images.append(image);encyclopedia_card_entries.append(entry)
		var name_label:=Label.new();name_label.text=Localizer.species_name(language_code,entry) if identity_visible else "？？？";name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name_label.add_theme_font_size_override("font_size",18);name_label.add_theme_color_override("font_color",UI_BROWN);content.add_child(name_label)
		var best_label_card:=Label.new();var card_best:=float(bests.get(species_id,0.0));best_label_card.text=(Localizer.text(language_code,"self_best",[card_best]) if card_best>0.0 else Localizer.text(language_code,"self_best_none")) if found else Localizer.text(language_code,"undiscovered");best_label_card.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;best_label_card.add_theme_font_size_override("font_size",14);best_label_card.add_theme_color_override("font_color",Color("#79543a"));content.add_child(best_label_card)
		var get_label_card:=Label.new();get_label_card.text="GET %d"%_species_get_count(species_id) if found else "GET 0";get_label_card.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;get_label_card.add_theme_font_size_override("font_size",13);get_label_card.add_theme_color_override("font_color",Color("#98602e"));content.add_child(get_label_card)
		if found:card.pressed.connect(_open_species_detail.bind(entry))
	call_deferred("_update_encyclopedia_visible_textures")

func _encyclopedia_unfound_status(_series_id:String)->String:
	return Localizer.text(language_code,"undiscovered")

func _catalog_identity_visible_before_get(_entry:Dictionary)->bool:
	return false

func _catalog_uses_species_silhouette_before_get(entry:Dictionary)->bool:
	return _catalog_entry_is_fusion(entry)

func _apply_encyclopedia_image_style(image:TextureRect,entry:Dictionary,found:bool)->void:
	if found:
		image.material=null;image.modulate=Color.WHITE;return
	if _catalog_uses_species_silhouette_before_get(entry):
		if encyclopedia_silhouette_material==null:encyclopedia_silhouette_material=FusionLabUIClass.create_silhouette_material()
		image.material=encyclopedia_silhouette_material;image.modulate=Color.WHITE;return
	image.material=null;image.modulate=Color(0.12,0.09,0.08,0.82)

func _update_encyclopedia_visible_textures()->void:
	if not encyclopedia_overlay.visible or not encyclopedia_list_page.visible:return
	var visible_top:=float(encyclopedia_scroll.scroll_vertical)
	var visible_bottom:=visible_top+encyclopedia_scroll.size.y
	var prefetch_top:=visible_top-280.0
	var prefetch_bottom:=visible_bottom+360.0
	for i in range(encyclopedia_card_images.size()):
		var image:=encyclopedia_card_images[i]
		if not is_instance_valid(image):continue
		var card:=image.get_parent().get_parent().get_parent() as Control
		# The cards now follow the cover in one tall scroll document. Convert the
		# displayed global position back to content coordinates before deciding
		# which external catalog images should be requested or prefetched.
		var card_top:=card.global_position.y-encyclopedia_scroll.global_position.y+visible_top
		var visible_now:=card_top+card.size.y>=visible_top and card_top<=visible_bottom
		var should_prefetch:=card_top+card.size.y>=prefetch_top and card_top<=prefetch_bottom
		var entry:=encyclopedia_card_entries[i];var path:=_species_image_path(entry)
		if should_prefetch:
			if str(image.get_meta("catalog_loaded_path",""))!=path and str(image.get_meta("catalog_request_path",""))!=path:_request_species_texture(entry,image,visible_now)
		else:
			image.set_meta("catalog_loaded_path","");image.set_meta("catalog_request_path","");image.texture=_species_loading_texture(entry)

func _release_encyclopedia_textures()->void:
	for image in encyclopedia_card_images:
		if is_instance_valid(image):image.texture=null;image.set_meta("catalog_loaded_path","");image.set_meta("catalog_request_path","")

func _species_image_path(entry:Dictionary)->String:
	if entry.has("image_path"):
		return str(entry.get("image_path",""))
	var variant:=str(entry.get("visual_variant","laui"))
	return str(SucculentClass.SPRITES.get(variant,SucculentClass.SPRITES.laui))

func _species_loading_texture(entry:Dictionary)->Texture2D:
	var path:=_species_image_path(entry)
	return CatalogImageLoader.placeholder_texture if CatalogImageLoader.is_external_path(path) else null

func _request_species_texture(entry:Dictionary,target:TextureRect,high_priority:bool=true)->void:
	if not is_instance_valid(target):return
	var path:=_species_image_path(entry)
	if path.is_empty():return
	target.set_meta("catalog_request_path",path)
	var immediate:=CatalogImageLoader.get_texture(path)
	if immediate!=null:target.texture=immediate
	if not CatalogImageLoader.is_external_path(path):
		target.set_meta("catalog_loaded_path",path);target.set_meta("catalog_request_path","");target.set_meta("catalog_request_callback",Callable());return
	if CatalogImageLoader.is_cached(path):
		target.set_meta("catalog_loaded_path",path);target.set_meta("catalog_request_path","");target.set_meta("catalog_request_callback",Callable());return
	var callback:=_apply_requested_species_texture.bind(target,path)
	target.set_meta("catalog_request_callback",callback)
	CatalogImageLoader.request_texture(path,callback,high_priority)

func _apply_requested_species_texture(texture:Texture2D,target:TextureRect,path:String)->void:
	if not is_instance_valid(target) or str(target.get_meta("catalog_request_path",""))!=path:return
	target.texture=texture if texture!=null else CatalogImageLoader.placeholder_texture
	target.set_meta("catalog_loaded_path",path if CatalogImageLoader.is_cached(path) else "")
	target.set_meta("catalog_request_path","");target.set_meta("catalog_request_callback",Callable())

func _species_texture(entry:Dictionary)->Texture2D:
	return CatalogImageLoader.get_texture(_species_image_path(entry))

func _habitat_species_texture(entry:Dictionary)->Texture2D:
	if habitat_texture_mode!="thumb":
		if habitat_texture_build_active:habitat_full_texture_loads_during_build+=1
		var full_texture:=_species_texture(entry)
		_record_habitat_build_texture(full_texture.resource_path if full_texture else "",full_texture)
		return full_texture
	var habitat_path:=str(entry.get("habitat_image_path",""))
	if habitat_path.is_empty() or not ResourceLoader.exists(habitat_path):
		# Series images can enter the habitat before a dedicated thumbnail is authored.
		return _species_texture(entry)
	var habitat_texture:=load(habitat_path) as Texture2D
	_record_habitat_build_texture(habitat_path,habitat_texture)
	return habitat_texture

func _record_habitat_build_texture(path:String,texture:Texture2D)->void:
	if not habitat_texture_build_active or texture==null or path.is_empty() or habitat_build_texture_paths.has(path):return
	habitat_build_texture_paths[path]=true
	habitat_texture_count+=1
	var texture_size:=Vector2i(texture.get_width(),texture.get_height())
	habitat_texture_max_size=Vector2i(maxi(habitat_texture_max_size.x,texture_size.x),maxi(habitat_texture_max_size.y,texture_size.y))
	habitat_texture_estimated_bytes+=texture_size.x*texture_size.y*4

func _begin_habitat_texture_build()->void:
	habitat_texture_build_active=true
	habitat_full_texture_loads_during_build=0
	habitat_texture_count=0
	habitat_texture_max_size=Vector2i.ZERO
	habitat_texture_estimated_bytes=0
	habitat_build_texture_paths.clear()

func _finish_habitat_texture_build()->void:
	habitat_texture_build_active=false
	print("HABITAT_TEXTURE_BUILD mode=",habitat_texture_mode," habitat_texture_count=",habitat_texture_count," max_texture_size=",habitat_texture_max_size.x,"x",habitat_texture_max_size.y," estimated_expanded_bytes=",habitat_texture_estimated_bytes," full_texture_loads_during_habitat_build=",habitat_full_texture_loads_during_build)

func _print_habitat_memory_snapshot(point:String)->void:
	print("HABITAT_TEXTURE_MEMORY point=",point," mode=",habitat_texture_mode," memory_static=",int(Performance.get_monitor(Performance.MEMORY_STATIC))," memory_static_max=",int(Performance.get_monitor(Performance.MEMORY_STATIC_MAX))," object_count=",int(Performance.get_monitor(Performance.OBJECT_COUNT))," resource_count=",int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))," node_count=",int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))

func _clear_habitat_items()->void:
	for child in habitat_items_root.get_children():child.free()
	habitat_pickups.clear()

func _build_habitat_items(force:=false)->void:
	_clear_habitat_items()
	if current_mode!="habitat" and not force:return
	if not habitat_awakened:
		_update_habitat_ui();return
	_ensure_habitat_wild_state()
	_ensure_habitat_old_catalog_page_roll()
	_begin_habitat_texture_build()
	for plant in habitat_wild_plants:_add_habitat_wild_plant(plant)
	_add_restoration_habitat_plants()
	_add_restoration_recovery_sprouts()
	if _should_show_jurejure_group():_add_jurejure_habitat_group()
	var seed_points:Array=HABITAT_SAFE_SEED_POINTS.duplicate();var daily_rng:=RandomNumberGenerator.new();daily_rng.seed=("%d:%d"%[formal_play_count,habitat_mystery_seeds_pending]).hash()
	for i in range(seed_points.size()-1,0,-1):
		var swap_index:=daily_rng.randi_range(0,i);var held=seed_points[i];seed_points[i]=seed_points[swap_index];seed_points[swap_index]=held
	for i in range(mini(habitat_mystery_seeds_pending,seed_points.size())):_add_habitat_seed(seed_points[i])
	if habitat_old_catalog_page_pending:_add_habitat_old_catalog_page(habitat_old_catalog_page_point)
	_finish_habitat_texture_build()
	_save()
	_update_habitat_ui()

func _original_habitat_species_ids()->Array[String]:
	var ids:Array[String]=[]
	for species_id in [FIRST_STORY_SPECIES_ID,PANDA_STORY_SPECIES_ID,ARMADILLO_STORY_SPECIES_ID]:
		if not _catalog_entry(species_id).is_empty():ids.append(species_id)
	return ids

func _habitat_population_candidate_ids()->Array[String]:
	var ids:Array[String]=[]
	for returned_id_value in habitat_returned_species:
		var returned_id:=str(returned_id_value)
		var returned_entry:=_catalog_entry(returned_id)
		if not bool(habitat_returned_species.get(returned_id,false)):continue
		if returned_entry.is_empty() or not _species_available_in_current_era(returned_entry):continue
		if returned_id not in ids:ids.append(returned_id)
	ids.sort()
	return ids

func _ensure_habitat_wild_state(target_unix:float=-1.0,allow_native_notifications:=true)->Dictionary:
	var now_unix:=Time.get_unix_time_from_system() if target_unix<0.0 else target_unix
	var candidates:=_habitat_population_candidate_ids()
	var result:={"changed":false,"population_changed":false,"timing_changed":false,"jellied":[],"jellied_details":[],"removed":[]}
	if not habitat_awakened:return result
	if not habitat_wild_initialized:
		var initial_size:=habitat_wild_plants.size()
		HabitatWildSystemClass.initialize_population(habitat_wild_plants,candidates,candidates,true,now_unix,rng,HABITAT_SAFE_PLANT_POINTS)
		habitat_wild_initialized=true
		result["population_changed"]=habitat_wild_plants.size()!=initial_size
	if habitat_wild_next_spawn_unix<=0.0:habitat_wild_next_spawn_unix=HabitatWildSystemClass.next_spawn_unix(now_unix,rng,habitat_wild_plants.size())
	result["timing_changed"]=_refresh_habitat_growth_profiles() or bool(result["timing_changed"])
	var spawn_guard:=0
	while now_unix>=habitat_wild_next_spawn_unix and spawn_guard<20000:
		_merge_habitat_time_result(result,HabitatWildSystemClass.advance_time_with_events(habitat_wild_plants,habitat_wild_next_spawn_unix))
		if HabitatWildSystemClass.spawn_one(habitat_wild_plants,candidates,habitat_wild_next_spawn_unix,rng,HABITAT_SAFE_PLANT_POINTS):
			result["population_changed"]=true
			_refresh_habitat_growth_profile(habitat_wild_plants.back())
		habitat_wild_next_spawn_unix=HabitatWildSystemClass.next_spawn_unix(habitat_wild_next_spawn_unix,rng,habitat_wild_plants.size())
		spawn_guard+=1
		if habitat_wild_plants.size()>=HabitatWildSystemClass.MAX_POPULATION and now_unix-habitat_wild_next_spawn_unix>HabitatWildSystemClass.MAX_SPAWN_INTERVAL_SECONDS*2:
			habitat_wild_next_spawn_unix=HabitatWildSystemClass.next_spawn_unix(now_unix,rng,habitat_wild_plants.size())
			break
	if habitat_wild_plants.is_empty() and habitat_wild_next_spawn_unix>now_unix+HabitatWildSystemClass.MAX_EMPTY_INTERVAL_SECONDS:
		habitat_wild_next_spawn_unix=now_unix+HabitatWildSystemClass.MAX_EMPTY_INTERVAL_SECONDS
	if HabitatWildSystemClass.repair_unsafe_positions(habitat_wild_plants,HABITAT_SAFE_PLANT_POINTS,rng):result["changed"]=true
	_merge_habitat_time_result(result,HabitatWildSystemClass.advance_time_with_events(habitat_wild_plants,now_unix))
	result["changed"]=bool(result["changed"]) or bool(result["population_changed"]) or bool(result["timing_changed"])
	_handle_habitat_time_events(result,allow_native_notifications)
	var tutorial_plant:Dictionary=HabitatWildSystemClass.tutorial_plant(habitat_wild_plants)
	if not tutorial_plant.is_empty():habitat_tutorial_species_id=str(tutorial_plant.get("species_id",""))
	return result

func _refresh_habitat_growth_profiles()->bool:
	var changed:=false
	for plant in habitat_wild_plants:changed=_refresh_habitat_growth_profile(plant) or changed
	return changed

func _refresh_habitat_growth_profile(plant:Dictionary)->bool:
	var entry:=_catalog_entry(str(plant.get("species_id","")))
	if entry.is_empty():return false
	return HabitatWildSystemClass.refresh_growth_profile(plant,maxf(.05,float(entry.get("base_growth_rate",1.0))),maxf(.05,float(entry.get("jelly_risk_curve",1.0))),float(plant.get("last_updated_unix",Time.get_unix_time_from_system())))

func _merge_habitat_time_result(target:Dictionary,source:Dictionary)->void:
	if bool(source.get("changed",false)):target["changed"]=true
	for key in ["jellied","removed"]:
		for individual_id_value in source.get(key,[]):
			var individual_id:=str(individual_id_value)
			if individual_id not in target[key]:target[key].append(individual_id)
	for key in ["jellied_details"]:
		for detail_value in source.get(key,[]):
			if not detail_value is Dictionary:continue
			var individual_id:=str(detail_value.get("individual_id",""));var already_added:=false
			for existing_value in target[key]:
				if existing_value is Dictionary and str(existing_value.get("individual_id",""))==individual_id:already_added=true;break
			if not already_added:target[key].append(detail_value.duplicate(true))
	if not source.get("removed",[]).is_empty():target["population_changed"]=true

func _handle_habitat_time_events(events:Dictionary,allow_native_notifications:bool)->void:
	for individual_id_value in events.get("removed",[]):
		var removed_id:=str(individual_id_value)
		if habitat_plant_panel and habitat_plant_panel.visible and str(habitat_plant_panel.individual_id)==removed_id:habitat_plant_panel.close()
	var active_removed:=str(active_jurejure_event.get("individual_id",""))
	if not active_removed.is_empty() and active_removed in events.get("removed",[]):_clear_active_jurejure_event(false,false)

func _habitat_event_detail(details:Variant,individual_id:String)->Dictionary:
	if details is Array:
		for value in details:
			if value is Dictionary and str(value.get("individual_id",""))==individual_id:return value
	return {}

func _habitat_species_name(species_id:String)->String:
	var entry:=_catalog_entry(species_id)
	return species_id if entry.is_empty() else Localizer.species_name(language_code,entry)

func _format_habitat_event_time(unix_time:float)->String:
	return Time.get_datetime_string_from_unix_time(int(unix_time),true) if unix_time>0.0 else "—"

func _record_habitat_debug_event(message:String)->void:
	habitat_debug_log.append(message)
	while habitat_debug_log.size()>40:habitat_debug_log.pop_front()
	_refresh_habitat_dev_panel()

func _add_habitat_wild_plant(plant:Dictionary)->void:
	if bool(plant.get("jellied",false)):return
	var entry:=_catalog_entry(str(plant.get("species_id","")))
	if entry.is_empty():return
	var texture:=_habitat_species_texture(entry)
	if texture==null:texture=CatalogImageLoader.placeholder_texture
	var sprite:=Sprite3D.new();sprite.texture=texture;sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED;sprite.no_depth_test=true;sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS;sprite.pixel_size=1.15/maxf(1.0,float(sprite.texture.get_width()));sprite.offset.y=-float(sprite.texture.get_height())*.18;sprite.position=_panorama_point_to_world(Vector2(float(plant.get("panorama_x",640.0)),float(plant.get("panorama_y",410.0))),HABITAT_ITEM_RADIUS);habitat_items_root.add_child(sprite)
	var scale_value:=_habitat_wild_visual_scale(float(plant.get("diameter_cm",1.6)));sprite.scale=Vector3.ONE*scale_value
	if bool(plant.get("tutorial",false)):sprite.modulate=Color(1.15,1.10,.78,1.0)
	var item={"node":sprite,"kind":"wild_plant","species_id":str(plant.get("species_id","")),"individual_id":str(plant.get("individual_id",""))};habitat_pickups.append(item);_refresh_habitat_wild_item(item,plant)

func _add_restoration_habitat_plants()->void:
	var returned:Array=HabitatRestorationClass.returned_plants(_restoration_state())
	var points:=[Vector2(132,405),Vector2(335,423),Vector2(625,410),Vector2(910,423),Vector2(1135,405)]
	for index in range(mini(returned.size(),points.size())):
		var snapshot:Dictionary=returned[index];var entry:=_catalog_entry(str(snapshot.get("species_id","")))
		if entry.is_empty():continue
		var texture:=_habitat_species_texture(entry)
		if texture==null:continue
		var sprite:=Sprite3D.new();sprite.name="RestorationMedalPlant%d"%(index+1);sprite.texture=texture;sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED;sprite.no_depth_test=true;sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.pixel_size=1.22/maxf(1.0,float(texture.get_width()));sprite.offset.y=-float(texture.get_height())*.18;sprite.position=_panorama_point_to_world(points[index],HABITAT_ITEM_RADIUS-.18)
		var diameter:=float(snapshot.get("diameter_cm",100.0));var saved_visual_scale:=float(snapshot.get("visual_scale",0.0));var expected_visual_scale:=.18+(diameter-1.6)*.058
		if saved_visual_scale<2.0:saved_visual_scale=expected_visual_scale
		var visual_diameter:=1.6+maxf(0.0,saved_visual_scale-.18)/.058;var represented_diameter:=(diameter+visual_diameter)*.5
		var compressed_scale:=clampf(2.15+(represented_diameter-100.0)*.012,2.15,3.65);sprite.scale=Vector3.ONE*compressed_scale
		sprite.set_meta("restoration_stage",index+1);sprite.set_meta("restoration_snapshot",snapshot.duplicate(true))
		sprite.modulate=Color(1.08,1.08,1.02,1.0);habitat_items_root.add_child(sprite)
		habitat_pickups.append({"node":sprite,"kind":"restoration_plant","stage":index+1,"snapshot":snapshot.duplicate(true)})

func _add_restoration_recovery_sprouts()->void:
	var stage:=_restoration_stage()
	if stage<3:return
	var points:=[Vector2(245,420),Vector2(745,425),Vector2(1030,415)]
	var species_ids:=[FIRST_STORY_SPECIES_ID,PANDA_STORY_SPECIES_ID,ARMADILLO_STORY_SPECIES_ID]
	var count:=3 if stage>=5 else (2 if stage>=4 else 1)
	for index in count:
		var entry:=_catalog_entry(species_ids[index]);var texture:=_habitat_species_texture(entry)
		if texture==null:continue
		var sprite:=Sprite3D.new();sprite.name="RestorationWildSprout%d"%(index+1);sprite.texture=texture;sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED;sprite.no_depth_test=true;sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.pixel_size=.72/maxf(1.0,float(texture.get_width()));sprite.offset.y=-float(texture.get_height())*.18;sprite.position=_panorama_point_to_world(points[index],HABITAT_ITEM_RADIUS);sprite.scale=Vector3.ONE*(.58+.12*stage);habitat_items_root.add_child(sprite)

func _should_show_jurejure_group()->bool:
	var restoration:=_restoration_state()
	return JureJureSystemClass.should_be_present(habitat_awakened,habitat_tutorial_returned_to_greenhouse,StoryProgressionClass.exploitation_is_started(story_progression_state),jurejure_waiting_for_seed_pod_reward,HabitatRestorationClass.is_started(restoration),HabitatRestorationClass.is_complete(restoration))

func _add_jurejure_habitat_group()->void:
	if jurejure_habitat_visit_point.x<0.0:
		jurejure_habitat_visit_point=JureJureSystemClass.choose_visit_point(habitat_wild_plants,rng)
	var group:=Node3D.new();group.name="JureJureGangGroup"
	var base_position:=_panorama_point_to_world(jurejure_habitat_visit_point,HABITAT_ITEM_RADIUS-.35);group.position=base_position;habitat_items_root.add_child(group)
	var tangent:=Vector3(base_position.z,0.0,-base_position.x).normalized()
	var members:=[
		{"name":"Skunk","path":"res://assets/jurejure/skunk.png","offset":-1.48,"height":2.35},
		{"name":"Mouse","path":"res://assets/jurejure/mouse.png","offset":0.0,"height":2.15},
		{"name":"Peccary","path":"res://assets/jurejure/peccary.png","offset":1.52,"height":2.75}
	]
	for member in members:
		var texture:=load(str(member.path)) as Texture2D
		if texture==null:continue
		var sprite:=Sprite3D.new();sprite.name=str(member.name);sprite.texture=texture;sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED;sprite.no_depth_test=true;sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var target_height:=float(member.height);sprite.pixel_size=target_height/maxf(1.0,float(texture.get_height()));sprite.position=tangent*float(member.offset)+Vector3.UP*(target_height*.5);group.add_child(sprite)
	var tap_anchor:=Node3D.new();tap_anchor.name="TapAnchor";tap_anchor.position=Vector3.UP*1.35;group.add_child(tap_anchor)
	habitat_pickups.append({"node":tap_anchor,"group_node":group,"kind":"jurejure_group"})

func _habitat_wild_visual_scale(diameter_cm:float)->float:
	# Habitat plants keep growing in their data, but the observation view caps
	# their billboard size so one old individual cannot hide the whole habitat.
	return clampf(.18+(maxf(1.6,diameter_cm)-1.6)*.058,.32,2.8)

func _refresh_habitat_wild_item(item:Dictionary,plant:Dictionary,animate_beacon:=false)->void:
	var node:Sprite3D=item.get("node")
	if not is_instance_valid(node):return
	var diameter:=float(plant.get("diameter_cm",1.6));var visual_scale:=_habitat_wild_visual_scale(diameter);node.scale=Vector3.ONE*visual_scale
	if habitat_crisis_started:
		var recovery:=float(_restoration_stage())/5.0;node.modulate=Color(.56+.44*recovery,.63+.37*recovery,.59+.41*recovery,1.0)
	elif bool(plant.get("tutorial",false)):node.modulate=Color(1.15,1.10,.78,1.0)
	else:node.modulate=Color.WHITE

func _habitat_wild_item_by_id(individual_id:String)->Dictionary:
	for item in habitat_pickups:
		if str(item.get("kind",""))=="wild_plant" and str(item.get("individual_id",""))==individual_id:return item
	return {}

func _add_habitat_seed(panorama_point:Vector2)->void:
	var seed:=MeshInstance3D.new();var mesh:=SphereMesh.new();mesh.radius=.105;mesh.height=.24;mesh.radial_segments=12;mesh.rings=6;seed.mesh=mesh
	var material:=StandardMaterial3D.new();material.albedo_color=Color("#b87932");material.roughness=.72;material.emission_enabled=true;material.emission=Color("#5c3514");material.emission_energy_multiplier=.35;seed.material_override=material;seed.position=_panorama_point_to_world(panorama_point,HABITAT_ITEM_RADIUS);habitat_items_root.add_child(seed);habitat_pickups.append({"node":seed,"kind":"seed"})

func _ensure_habitat_old_catalog_page_roll()->void:
	if not act2_unlocked:return
	if habitat_old_catalog_page_pending or old_catalog_page_roll_play_count==formal_play_count:return
	old_catalog_page_roll_play_count=formal_play_count
	for raw_rule in catalog_progression.get("hidden_series",[]):
		if not raw_rule is Dictionary:continue
		var series_id:=str(raw_rule.get("series_id",""));var spawn=raw_rule.get("old_page_spawn",{})
		if not spawn is Dictionary or not bool(spawn.get("enabled",false)) or bool(unlocked_series.get(series_id,false)):continue
		if not _condition_met(spawn.get("condition",{})):continue
		if rng.randf()<clampf(float(spawn.get("chance",0.0)),0.0,1.0):
			habitat_old_catalog_page_pending=true;habitat_old_catalog_page_series_id=series_id
			var points:=[Vector2(905,452),Vector2(1120,438),Vector2(510,448)];habitat_old_catalog_page_point=points[rng.randi_range(0,points.size()-1)];break
	_save()

func _add_habitat_old_catalog_page(panorama_point:Vector2)->void:
	var page:=MeshInstance3D.new();var mesh:=QuadMesh.new();mesh.size=Vector2(.5,.66);page.mesh=mesh
	var material:=StandardMaterial3D.new();material.albedo_color=Color("#aa8657");material.roughness=.9;material.emission_enabled=true;material.emission=Color("#6f4d2f");material.emission_energy_multiplier=.22;material.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED;page.material_override=material;page.position=_panorama_point_to_world(panorama_point,HABITAT_ITEM_RADIUS);habitat_items_root.add_child(page)
	var badge:=Label3D.new();badge.text="？";badge.position.y=.46;badge.font_size=36;badge.outline_size=7;badge.modulate=Color("#f5dfad");page.add_child(badge);habitat_pickups.append({"node":page,"kind":"old_catalog_page","series_id":habitat_old_catalog_page_series_id})

func _panorama_point_to_world(point:Vector2,radius:float)->Vector3:
	var longitude:float=(point.x/1280.0-.5)*TAU;var latitude:float=(.5-point.y/640.0)*PI;var horizontal:=cos(latitude)
	return Vector3(sin(longitude)*horizontal,sin(latitude),-cos(longitude)*horizontal)*radius

func _reset_daily_seeds_if_needed()->void:
	var today:=Time.get_date_string_from_system()
	if habitat_seed_date!=today:habitat_seed_date=today;habitat_seeds_collected=0;_save()

func _update_habitat_ui()->void:
	if habitat_status_label:
		habitat_status_label.visible=false
		habitat_status_label.text=""
	if mode_button and current_mode=="greenhouse":mode_button.text=Localizer.text(language_code,"main_habitat")
	_update_habitat_button_glow()

func _roll_rain_event()->void:
	# Post-awakening rain bonus gameplay was retired. Story rain is rendered by
	# HabitatAwakeningOverlay and does not pass through this legacy hook.
	return

func _show_rain_notice(message:String)->void:
	if effects_layer==null:return
	var notice:=Label.new();notice.text=message;notice.position=Vector2(68,215);notice.size=Vector2(440,72);notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;notice.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;notice.add_theme_font_size_override("font_size",22);notice.add_theme_color_override("font_color",Color("#eef8ff"));notice.add_theme_color_override("font_outline_color",Color("#28465d"));notice.add_theme_constant_override("outline_size",7);notice.add_theme_stylebox_override("normal",_box(Color(0.16,0.28,0.34,.9),Color("#b9deec"),18,2));effects_layer.add_child(notice)
	var tween:=create_tween().bind_node(notice);tween.tween_property(notice,"position:y",notice.position.y-12,.25).set_trans(Tween.TRANS_QUAD);tween.tween_interval(2.2);tween.tween_property(notice,"modulate:a",0.0,.45);tween.tween_callback(notice.queue_free)

func _evaluate_unlock_rules(trigger:String,current_value:float)->void:
	# Legacy callers remain harmless for save compatibility. The generic
	# threshold/reward table is no longer a progression source.
	return

func _queue_random_species(rarity:String)->bool:
	var candidates:Array=[]
	for entry in catalog_species:
		if not _species_available_in_current_era(entry):continue
		var species_id:=str(entry.species_id)
		if bool(entry.get("catalog_only",false)):continue
		if str(entry.get("rarity","通常"))!=rarity:continue
		if bool(discovered.get(species_id,false)) or bool(greenhouse_available.get(species_id,false)):continue
		candidates.append(entry)
	if candidates.is_empty():return false
	var chosen:Dictionary=candidates[rng.randi_range(0,candidates.size()-1)]
	var species_id:=str(chosen.get("species_id",""));greenhouse_available[species_id]=true;unlocked_species[species_id]=true
	_apply_saved_unlocks()
	return true

func _habitat_new_species_candidates()->Array[Dictionary]:
	return []

func _roll_habitat_new_species()->String:
	return ""

func _update_habitat_button_glow()->void:
	if not mode_button:return
	# Mystery seeds are ordinary habitat scenery and no longer summon the player.
	# A catalog page or the gang's actual presence still deserves attention.
	var has_pending:=current_mode=="greenhouse" and (habitat_old_catalog_page_pending or _should_show_jurejure_group())
	if bool(mode_button.get_meta("habitat_glow_active",false))==has_pending:return
	mode_button.set_meta("habitat_glow_active",has_pending)
	if habitat_glow_tween and habitat_glow_tween.is_valid():habitat_glow_tween.kill()
	habitat_glow_tween=null
	mode_button.self_modulate=Color.WHITE
	if habitat_sparkle and is_instance_valid(habitat_sparkle):habitat_sparkle.queue_free()
	if not has_pending:return
	habitat_sparkle=UISymbolIcon.new();habitat_sparkle.symbol="sparkle";habitat_sparkle.icon_color=Color("#fff2a1");habitat_sparkle.position=Vector2(5,-9);habitat_sparkle.size=Vector2(26,26);habitat_sparkle.mouse_filter=Control.MOUSE_FILTER_IGNORE;mode_button.add_child(habitat_sparkle)
	var glow_color:=Color(1.2,1.12,.72,1)
	habitat_glow_tween=create_tween().set_loops();habitat_glow_tween.tween_property(mode_button,"self_modulate",glow_color,.75).set_trans(Tween.TRANS_SINE);habitat_glow_tween.parallel().tween_property(habitat_sparkle,"position:x",72.0,.75).set_trans(Tween.TRANS_SINE);habitat_glow_tween.parallel().tween_property(habitat_sparkle,"modulate:a",.25,.75);habitat_glow_tween.tween_property(mode_button,"self_modulate",Color.WHITE,.75);habitat_glow_tween.parallel().tween_property(habitat_sparkle,"position:x",5.0,.01);habitat_glow_tween.parallel().tween_property(habitat_sparkle,"modulate:a",1.0,.01);habitat_glow_tween.tween_interval(1.25)

func _open_species_detail(entry:Dictionary)->void:
	if collection_complete_presentation_active:return
	for child in encyclopedia_detail_page.get_children():child.free()
	encyclopedia_list_page.visible=false;encyclopedia_detail_page.visible=true
	var back:=Button.new();back.text=Localizer.text(language_code,"list_back");back.position=Vector2(24,28);back.size=Vector2(105,55);_skin_button(back,Color("#fff0cf"),17);back.pressed.connect(func():encyclopedia_detail_page.visible=false;encyclopedia_list_page.visible=true);encyclopedia_detail_page.add_child(back)
	var panel:=PanelContainer.new();panel.position=Vector2(28,105);panel.size=Vector2(520,825);panel.add_theme_stylebox_override("panel",_box(Color("#f6e7c5"),Color("#d3a75f"),24,4));encyclopedia_detail_page.add_child(panel)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",18);panel.add_child(content)
	var image_frame:=MarginContainer.new();image_frame.name="SpeciesImageFrame";image_frame.custom_minimum_size=Vector2(450,430);image_frame.add_theme_constant_override("margin_left",22);image_frame.add_theme_constant_override("margin_top",22);image_frame.add_theme_constant_override("margin_right",22);image_frame.add_theme_constant_override("margin_bottom",22);content.add_child(image_frame)
	var species_id:=str(entry.get("species_id",""));var found:=bool(discovered.get(species_id,false))
	var image:=TextureRect.new();image.name="SpeciesImage";image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.texture=_species_texture(entry);image.mouse_filter=Control.MOUSE_FILTER_IGNORE;_apply_encyclopedia_image_style(image,entry,found);image_frame.add_child(image);_request_species_texture(entry,image,true)
	var name_label:=Label.new();name_label.name="SpeciesName";name_label.text=Localizer.species_name(language_code,entry) if found or _catalog_identity_visible_before_get(entry) else "？？？";name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name_label.add_theme_font_size_override("font_size",31);name_label.add_theme_color_override("font_color",UI_BROWN);content.add_child(name_label)
	var description_text:=Localizer.species_description(language_code,entry) if found else _encyclopedia_unfound_status(current_encyclopedia_series_id)
	if not description_text.is_empty():
		var description:=Label.new();description.name="SpeciesDescription";description.text=description_text;description.custom_minimum_size=Vector2(450,48);description.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;description.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;description.add_theme_font_size_override("font_size",17);description.add_theme_color_override("font_color",Color("#79543a"));content.add_child(description)
	var best_detail:=Label.new();best_detail.name="SpeciesBest";var best_cm:=float(bests.get(species_id,0.0));best_detail.text=Localizer.text(language_code,"self_best",[best_cm]) if found and best_cm>0.0 else Localizer.text(language_code,"self_best_none");best_detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;best_detail.add_theme_font_size_override("font_size",23);best_detail.add_theme_color_override("font_color",Color("#98602e"));content.add_child(best_detail)
	var get_detail:=Label.new();get_detail.name="SpeciesGetCount";get_detail.text="GET %d"%_species_get_count(species_id) if found else "GET 0";get_detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;get_detail.add_theme_font_size_override("font_size",20);get_detail.add_theme_color_override("font_color",Color("#7f5a3d"));content.add_child(get_detail)

func _box(bg: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new(); s.bg_color=bg; s.border_color=border
	s.set_border_width_all(width); s.set_corner_radius_all(radius); s.shadow_color=Color(0.18,0.08,0.02,0.34); s.shadow_size=6; s.shadow_offset=Vector2(0,3); s.content_margin_left=10; s.content_margin_right=10; s.content_margin_top=6; s.content_margin_bottom=6; return s

func _panda_portrait_texture()->Texture2D:
	return DialoguePortraitsClass.texture("panda")

func _armadillo_portrait_texture()->Texture2D:
	return DialoguePortraitsClass.texture("armadillo")

func _jurejure_portrait_texture(speaker_id:String)->Texture2D:
	var source:Texture2D
	var normalized_region:=Rect2()
	match speaker_id:
		"skunk":source=load("res://assets/jurejure/skunk.png") as Texture2D;normalized_region=Rect2(0.0,0.057,0.82,0.656)
		"mouse":source=load("res://assets/jurejure/mouse.png") as Texture2D;normalized_region=Rect2(0.089,0.0,0.822,0.642)
		"peccary":source=load("res://assets/jurejure/peccary.png") as Texture2D;normalized_region=Rect2(0.16,0.014,0.802,0.642)
		_:return null
	if source==null:return null
	var texture_size:=source.get_size()
	var region:=Rect2(normalized_region.position*texture_size,normalized_region.size*texture_size)
	var portrait:=AtlasTexture.new();portrait.atlas=source;portrait.region=region
	return portrait

func _speaker_portrait_texture(speaker_id:String)->Texture2D:
	match speaker_id:
		"panda","armadillo","girl":return DialoguePortraitsClass.texture(speaker_id)
		"mouse","skunk","peccary":return _jurejure_portrait_texture(speaker_id)
		_:return null

func _set_intro_speaker(speaker_id:String)->void:
	if intro_portrait_slot:
		intro_portrait_slot.visible=not speaker_id.is_empty()
		intro_portrait_slot.custom_minimum_size=Vector2(162,205) if speaker_id=="trio" else Vector2(132,205)
	if intro_speaker_label:intro_speaker_label.size.x=162.0 if speaker_id=="trio" else 132.0
	intro_panda_portrait.texture=_speaker_portrait_texture(speaker_id)
	intro_panda_portrait.visible=intro_panda_portrait.texture!=null and speaker_id!="trio"
	if intro_trio_portraits:intro_trio_portraits.visible=speaker_id=="trio"
	if intro_speaker_label:
		var speaker_key:="story_speaker_panda"
		match speaker_id:
			"girl":speaker_key="story_speaker_girl"
			"armadillo":speaker_key="armadillo_name"
			"trio":speaker_key="story_speaker_trio"
			"mouse":speaker_key="jurejure_mouse_name"
			"skunk":speaker_key="jurejure_skunk_name"
			"peccary":speaker_key="jurejure_peccary_name"
		intro_speaker_label.text=Localizer.text(language_code,speaker_key)

func _skin_button(b:Button,bg:Color,font_size:int)->void:
	b.add_theme_font_size_override("font_size",font_size); b.add_theme_color_override("font_color",UI_BROWN if bg.get_luminance()>.55 else Color.WHITE); b.add_theme_color_override("font_hover_color",UI_BROWN); b.add_theme_stylebox_override("normal",_box(bg,bg.lightened(.22),20,3)); b.add_theme_stylebox_override("hover",_box(bg.lightened(.08),Color.WHITE,20,3)); b.add_theme_stylebox_override("pressed",_box(bg.darkened(.08),bg.lightened(.2),20,3))
	if audio_manager and not b.pressed.is_connected(_play_ui_tap):b.pressed.connect(_play_ui_tap)

func _wire_ui_sounds(node:Node)->void:
	if node is Button and node!=shop_selected_buy_button and not node.pressed.is_connected(_play_ui_tap):node.pressed.connect(_play_ui_tap)
	for child in node.get_children():_wire_ui_sounds(child)

func _play_ui_tap()->void:
	if audio_manager:audio_manager.notify_user_gesture();audio_manager.play_se("ui_tap",.22)

func _layout() -> void:
	if arrangement_scene_active:
		arrangement_transition_target_x=_arrangement_focus_transition_for_pan(saved_greenhouse_pan_x)
		if not arrangement_transitioning:arrangement_transition_x=arrangement_transition_target_x
	if arrangement_ui:arrangement_ui.set_world_backdrop_mode(arrangement_scene_active,_arrangement_pot_anchor_screen())
	_update_greenhouse_pan()

func _update_greenhouse_pan()->void:
	if greenhouse_backdrop==null or greenhouse_backdrop.texture==null:return
	var viewport_size:=get_viewport().get_visible_rect().size
	var texture_size:=greenhouse_backdrop.texture.get_size()
	var master_scale:=viewport_size.y/texture_size.y
	var display_size:=texture_size*master_scale
	var min_position_x:=minf(0.0,viewport_size.x-display_size.x)
	var max_position_x:=maxf(0.0,viewport_size.x-display_size.x)
	greenhouse_main_position_x=clampf(viewport_size.x*.5-SOIL_SOURCE_CENTER.x*master_scale,min_position_x,max_position_x)
	greenhouse_arrangement_position_x=clampf(viewport_size.x*ARRANGEMENT_TABLE_SCREEN_TARGET_RATIO.x-ARRANGEMENT_TABLE_SOURCE_CENTER.x*master_scale,min_position_x,max_position_x)
	greenhouse_pan_limit=maxf(0.0,minf(greenhouse_main_position_x-min_position_x,max_position_x-greenhouse_main_position_x))
	greenhouse_pan_x=clampf(greenhouse_pan_x,-greenhouse_pan_limit,greenhouse_pan_limit)
	greenhouse_pan_target_x=clampf(greenhouse_pan_target_x,-greenhouse_pan_limit,greenhouse_pan_limit)
	greenhouse_backdrop.size=display_size
	greenhouse_background_position_x=clampf(greenhouse_main_position_x+greenhouse_pan_x+arrangement_transition_x,min_position_x,max_position_x)
	greenhouse_backdrop.position=Vector2(greenhouse_background_position_x,0.0)
	greenhouse_world_pan_x=0.0
	if camera:
		var soil_center:=camera.unproject_position(Vector3(0,.12,0))
		var soil_right:=camera.unproject_position(Vector3(1,.12,0))
		var pixels_per_world:=soil_right.x-soil_center.x
		if absf(pixels_per_world)>.001:
			greenhouse_world_pan_x=(greenhouse_background_position_x-greenhouse_main_position_x)/pixels_per_world

func _arrangement_focus_transition_for_pan(pan_x:float)->float:
	if greenhouse_backdrop==null or greenhouse_backdrop.texture==null:return 0.0
	var viewport_size:=get_viewport().get_visible_rect().size
	var master_scale:=viewport_size.y/greenhouse_backdrop.texture.get_height()
	var display_width:=greenhouse_backdrop.texture.get_width()*master_scale
	var min_position_x:=minf(0.0,viewport_size.x-display_width)
	var max_position_x:=maxf(0.0,viewport_size.x-display_width)
	var main_position_x:=clampf(viewport_size.x*.5-SOIL_SOURCE_CENTER.x*master_scale,min_position_x,max_position_x)
	var arrangement_position_x:=clampf(viewport_size.x*ARRANGEMENT_TABLE_SCREEN_TARGET_RATIO.x-ARRANGEMENT_TABLE_SOURCE_CENTER.x*master_scale,min_position_x,max_position_x)
	return arrangement_position_x-(main_position_x+pan_x)

func _arrangement_pot_anchor_screen()->Vector2:
	return get_viewport().get_visible_rect().size*ARRANGEMENT_POT_ANCHOR

func spawn_plant(force_golden := false,spawn_position:Variant=null) -> void:
	var chosen:Dictionary
	var endless_forced_new:=false
	var endless_carryover_advanced:=false
	if active_seed_type=="old":
		chosen=_catalog_entry(FIRST_STORY_SPECIES_ID)
	elif active_seed_type.begins_with("series:"):
		# The concrete species is intentionally decided only when this seed sprouts.
		chosen=_choose_series_seed_species(active_series_seed_id)
		if chosen.is_empty():chosen=_catalog_entry(FIRST_STORY_SPECIES_ID)
	elif force_golden:
		for entry in species:
			if str(entry.visual_variant) == "gold_laui": chosen = entry
		if chosen.is_empty(): chosen = species[0]
		forced_golden_done=true
	elif not opening_species.is_empty():chosen=opening_species.pop_front()
	elif _is_endless_normal_play() and not jurejure_intro_complete:
		# A stale forced reservation from an older save must not leak a random NEW
		# into the story before the gang's first encounter is complete.
		if endless_greenhouse.forced_new_pending:endless_greenhouse.cancel_forced_new_pending()
		endless_greenhouse.clear_discovery_carryover()
		chosen=_select_normal_seed_species(-1.0,false)
	elif _is_endless_normal_play():
		if not endless_greenhouse.forced_new_pending:
			var carryover_result:=_roll_endless_carryover_for_seed()
			endless_carryover_advanced=bool(carryover_result.get("consumed",false))
		if endless_greenhouse.forced_new_pending:
			chosen=_select_endless_forced_new_candidate()
			if chosen.is_empty():
				# Eligibility can legitimately disappear between a roll and sprout.
				# Never invent a NEW species.
				endless_greenhouse.cancel_forced_new_pending()
				chosen=_select_normal_seed_species(-1.0,false)
			else:
				endless_forced_new=endless_greenhouse.consume_forced_new(str(chosen.get("species_id","")))
		else:chosen=_select_species_for_seed(active_seed_type)
	else:chosen=_select_species_for_seed(active_seed_type)
	var pos:Vector3=_find_spawn_position() if spawn_position==null else spawn_position
	var label:=_plant_label(); labels_layer.add_child(label)
	var p = SucculentClass.new()
	var chosen_species_id:=str(chosen.get("species_id",""))
	var new_species_candidate:=_species_get_count(chosen_species_id)<=0 and chosen_species_id not in pending_round_new_species_ids
	if _is_endless_normal_play() and new_species_candidate:
		# Any NEW that actually appears ends the current carryover chain,
		# regardless of whether it came from the carryover roll or a story slot.
		endless_greenhouse.clear_discovery_carryover()
		if not endless_forced_new and endless_greenhouse.forced_new_pending:endless_greenhouse.cancel_forced_new_pending()
	p.original_pos=pos; p.position=pos;p.set_meta("new_species_candidate",new_species_candidate);p.set_meta("endless_forced_new",endless_forced_new); world_root.add_child(p); p.setup(chosen,rng.randi(),label,null,false,_greenhouse_jelly_balance_for_spawn());p.jelly_permission=Callable(self,"_allow_plant_jelly").bind(p)
	if active_seed_type=="old" and chosen_species_id==FIRST_STORY_SPECIES_ID and not first_colorata_confirmed:
		p.growth_rate*=FIRST_STORY_COLORATA_GROWTH_MULTIPLIER
		p.set_meta("first_story_growth_multiplier",FIRST_STORY_COLORATA_GROWTH_MULTIPLIER)
	if first_play_tutorial_active:p.jelly_checks_enabled=false
	p.harvested.connect(_on_harvested); p.jellied.connect(_on_jellied)
	plants.append(p)
	_mark_first_play_tutorial_reserved_plant(p)
	if endless_forced_new or endless_carryover_advanced or (_is_endless_normal_play() and new_species_candidate):_save()
	if audio_manager:audio_manager.play_se("sprout",.28)

func _spawn_greenhouse_seed(suppress_puku_effect:=false,requested_spawn_position:Variant=null)->bool:
	if not play_active or play_seeds_remaining<=0:return false
	var spawn_position:Vector3=_find_spawn_position() if requested_spawn_position==null else requested_spawn_position;pending_seed_positions.append(spawn_position)
	play_seeds_remaining-=1
	play_seed_animations_pending+=1;_update_play_ui();_animate_and_spawn_greenhouse_seed(spawn_position)
	return true

func _animate_and_spawn_greenhouse_seed(spawn_position:Vector3)->void:
	var seed:=UISymbolIcon.new();seed.symbol="seed";seed.icon_color=Color("#6b3f20");seed.size=Vector2(22,22);seed.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var origin:=seed_bag_panel.global_position+Vector2(seed_bag_panel.size.x*.5,seed_bag_panel.size.y*.84)-Vector2(11,11);var displayed_spawn_position:=spawn_position+Vector3(_greenhouse_world_offset_for_position(spawn_position),0,0);var destination:=camera.unproject_position(displayed_spawn_position)-Vector2(11,11);seed.position=origin;effects_layer.add_child(seed)
	var midpoint:=Vector2(lerpf(origin.x,destination.x,.55),minf(origin.y,destination.y)-34.0)
	var tween:=create_tween();tween.tween_property(seed,"position",midpoint,.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);tween.tween_property(seed,"position",destination,.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	if is_instance_valid(seed):seed.queue_free()
	while _is_endless_normal_play() and not _should_simulate_endless_greenhouse():
		await get_tree().process_frame
	pending_seed_positions.erase(spawn_position)
	play_seed_animations_pending=maxi(0,play_seed_animations_pending-1)
	if play_active:
		spawn_plant(false,spawn_position)
		_record_normal_greenhouse_seed_sown()
		_register_endless_greenhouse_spawn()
	if play_active and play_seeds_remaining==0 and play_spawn_queue==0 and play_seed_animations_pending==0 and plants.is_empty():call_deferred("_finish_greenhouse_play")

func _queue_greenhouse_replacements()->void:
	if not play_active or active_seed_type=="old":return
	# One of the formal round's twelve seeds is held back for the scripted NEW
	# sprout.  Never let ordinary slot refill consume or overtake that seed.
	if first_play_tutorial_active and (first_play_tutorial_reserved_seed_pending or first_play_tutorial_phase in ["forcing_jelly","jelly_observe","jelly_reaction","reserved_seed_sowing"]):return
	var open_slots:=maxi(0,play_concurrent_target-(plants.size()+play_spawn_queue+play_seed_animations_pending))
	var add_count:=mini(open_slots,maxi(0,play_seeds_remaining-play_spawn_queue))
	if add_count<=0:return
	var was_empty:=play_spawn_queue==0;play_spawn_queue+=add_count
	if was_empty:play_spawn_timer=_next_greenhouse_spawn_interval()

func _register_endless_greenhouse_spawn()->void:
	if not _is_endless_normal_play():return
	endless_economy_seed_count+=1
	if endless_greenhouse.register_spawn():_complete_endless_virtual_batch()

func _record_normal_greenhouse_seed_sown()->bool:
	if not play_active or active_seed_type!="normal" or dev_jelly_test_active or catalog_preview_mode_active:return false
	var restoration:=_restoration_state()
	var previous_count:=HabitatRestorationClass.seeds_sown_since_crisis(restoration)
	StoryProgressionClass.record_normal_seed_sown_after_crisis(story_progression_state,habitat_crisis_started,1)
	var current_count:=HabitatRestorationClass.seeds_sown_since_crisis(_restoration_state())
	if current_count==previous_count:return false
	_save()
	return true

func _complete_endless_virtual_batch()->void:
	# One invisible batch preserves the old 12-seed progression hooks without
	# clearing plants, opening results, or interrupting the greenhouse.
	total_play_count+=1
	var formal_play:=_tutorial_fully_complete()
	if formal_play:
		formal_play_count+=1
		habitat_mystery_seeds_pending+=rng.randi_range(0,3)
		_refresh_seed_pack_unlocks()
	_resolve_tovar_event_after_play()
	_evaluate_unlock_rules("play_count",float(total_play_count))
	_prepare_story_spawn_guarantee()
	_save();_update_play_ui();_log_endless_economy("virtual_batch")

func _reset_endless_economy_stats()->void:
	endless_economy_start_units=puku_balance_units;endless_economy_seed_count=0;endless_economy_seed_cost_units=0;endless_economy_harvest_reward_units=0;endless_economy_jelly_count=0;endless_economy_harvest_count=0;endless_economy_max_harvest_cm=0.0

func _record_endless_economy_change(source:String,applied_units:int)->void:
	if not _is_endless_normal_play():return
	match source:
		"normal_round_start":
			if applied_units<0:endless_economy_seed_cost_units+=-applied_units
		"endless_harvest":
			if applied_units>0:endless_economy_harvest_reward_units+=applied_units

func _endless_economy_debug_summary()->Dictionary:
	return {
		"start_puku":float(endless_economy_start_units)/PUKU_UNITS_PER_PUKU,
		"seeds_used":endless_economy_seed_count,
		"seed_cost_puku":float(endless_economy_seed_cost_units)/PUKU_UNITS_PER_PUKU,
		"harvest_revenue_puku":float(endless_economy_harvest_reward_units)/PUKU_UNITS_PER_PUKU,
		"jellied":endless_economy_jelly_count,
		"harvested":endless_economy_harvest_count,
		"max_harvest_cm":snappedf(endless_economy_max_harvest_cm,0.1),
		"current_puku":float(puku_balance_units)/PUKU_UNITS_PER_PUKU,
		"greenhouse_net_puku":float(endless_economy_harvest_reward_units-endless_economy_seed_cost_units)/PUKU_UNITS_PER_PUKU,
		"wallet_net_puku":float(puku_balance_units-endless_economy_start_units)/PUKU_UNITS_PER_PUKU,
	}

func _log_endless_economy(reason:String)->void:
	if not (OS.is_debug_build() or _trial_dev_controls_enabled()) or not _is_endless_greenhouse_enabled() or active_seed_type!="normal":return
	print("ENDLESS_PUKU_ECONOMY reason=",reason," ",JSON.stringify(_endless_economy_debug_summary()))

func _roll_endless_carryover_for_seed(forced_roll:float=-1.0)->Dictionary:
	var result:={"consumed":false,"chance":0.0,"queued":false}
	if not _is_endless_normal_play() or not jurejure_intro_complete:return result
	var chance:=endless_greenhouse.take_carryover_chance_for_seed()
	if chance<=0.0:return result
	result["consumed"]=true;result["chance"]=chance
	var candidates:=_eligible_endless_forced_new_candidates()
	if candidates.is_empty():return result
	var roll:=rng.randf() if forced_roll<0.0 else clampf(forced_roll,0.0,.999999)
	if roll<chance:result["queued"]=endless_greenhouse.queue_forced_new()
	return result

func _record_endless_discovery_settlement(harvested:bool,diameter_cm:float=0.0,_forced_roll:float=-1.0)->Dictionary:
	if not _is_endless_normal_play():return {"set_completed":false}
	var result:=endless_greenhouse.register_discovery_settlement(harvested,diameter_cm)
	if bool(result.get("set_completed",false)):
		# Keep the legacy 12-settlement story hook independent from NEW rolls.
		_resolve_jurejure_progress_reward("discovery_set")
	if not jurejure_intro_complete:
		if endless_greenhouse.forced_new_pending:endless_greenhouse.cancel_forced_new_pending()
		endless_greenhouse.clear_discovery_carryover()
		return result
	return result

func _next_greenhouse_spawn_interval()->float:
	if plants.size()<=3:return rng.randf_range(.04,.18)
	if rng.randf()<.20:return rng.randf_range(.04,.16)
	return rng.randf_range(.28,.92)

func _weighted_species()->Dictionary:
	var total:=0.0
	for s in species:total+=float(s.spawn_weight)
	var roll:=rng.randf()*total
	for s in species:
		roll-=float(s.spawn_weight)
		if roll<=0:return s
	return species[0]

func _prepare_story_spawn_guarantee()->void:
	if not jurejure_intro_complete:return
	var guaranteed:=StoryProgressionClass.take_normal_play_guarantee(
		story_progression_state,
		_story_spawn_guarantee_candidates(false),
		_story_spawn_guarantee_candidates(true),
		rng
	)
	if not guaranteed.is_empty():opening_species.append(guaranteed)

func _story_spawn_guarantee_candidates(want_fantasy:bool)->Array[Dictionary]:
	var candidates:Array[Dictionary]=[]
	for raw_entry in catalog_species:
		if not raw_entry is Dictionary:continue
		var entry:Dictionary=raw_entry;var species_id:=str(entry.get("species_id",""))
		if species_id.is_empty() or species_id in pending_round_new_species_ids or _species_get_count(species_id)>0:continue
		if _seed_new_species_blocked(species_id) or str(entry.get("rarity","")) in ["隠し原種","謎品種"]:continue
		if want_fantasy:
			if not StoryProgressionClass.fantasy_is_unlocked(story_progression_state) or not _is_fantasy_species(entry) or _is_jurejure_species(entry):continue
			if not _fantasy_six_new_candidate_allowed(entry):continue
		else:
			if not bool(entry.get("main_story_original",false)):continue
		if not _species_is_in_unlocked_series(species_id) and not _normal_seed_locked_series_eligible(species_id):continue
		var candidate:=entry.duplicate(true)
		if not _species_is_in_unlocked_series(species_id):candidate["_deferred_series_get"]=true
		candidates.append(candidate)
	return candidates

func _select_species_for_seed(seed_type:String,forced_category_roll:float=-1.0)->Dictionary:
	if seed_type=="mystery":
		var mystery_pool:Array=[]
		for entry in catalog_species:
			if _species_available_in_current_era(entry) and bool(entry.get("mystery_pack_eligible",false)) and bool(discovered.get(str(entry.get("species_id","")),false)):mystery_pool.append(entry)
		if not mystery_pool.is_empty():return mystery_pool[rng.randi_range(0,mystery_pool.size()-1)]
		return _catalog_entry(FIRST_STORY_SPECIES_ID)
	if seed_type=="normal":return _select_normal_seed_species(forced_category_roll,not _is_endless_normal_play())
	var config:Dictionary=SEED_PACK_CONFIG.get(seed_type,SEED_PACK_CONFIG.normal)
	var unlocked_new_candidates:Array=[]
	var locked_new_candidates:Array=[]
	var normal_pool:Array=[];var rare_pool:Array=[];var super_pool:Array=[];var any_pool:Array=[]
	for entry in catalog_species:
		if not _species_available_in_current_era(entry):continue
		var species_id:=str(entry.get("species_id",""))
		var is_found:=_species_get_count(species_id)>0
		# Route-only species stay exclusive to their dedicated acquisition route,
		# even after they have been discovered and added to the greenhouse.
		if not is_found:
			if _seed_new_species_blocked(species_id) or str(entry.get("rarity","")) in ["隠し原種","謎品種"]:continue
			if _species_is_in_unlocked_series(species_id):unlocked_new_candidates.append(entry)
			elif seed_type=="normal" and _normal_seed_locked_series_eligible(species_id) and not bool(forest_gacha_encountered.get(species_id,false)):locked_new_candidates.append(entry)
			continue
		if not bool(greenhouse_available.get(species_id,false)):continue
		any_pool.append(entry)
		match str(entry.get("rarity","通常")):
			"レア":rare_pool.append(entry)
			"スーパーレア":super_pool.append(entry)
			_:normal_pool.append(entry)
	var category_roll:=rng.randf() if forced_category_roll<0.0 else forced_category_roll;var new_rate:=float(config.get("new",0.0));var super_rate:=float(config.get("super",0.0));var rare_rate:=float(config.get("rare",0.0))
	var target_pool:Array
	if seed_type=="normal" and category_roll<NORMAL_SEED_UNLOCKED_NEW_RATE:
		if not unlocked_new_candidates.is_empty():return unlocked_new_candidates[rng.randi_range(0,unlocked_new_candidates.size()-1)]
		target_pool=normal_pool
	elif seed_type=="normal" and category_roll<NORMAL_SEED_UNLOCKED_NEW_RATE+NORMAL_SEED_LOCKED_NEW_RATE:
		if not locked_new_candidates.is_empty():
			var locked_choice:Dictionary=locked_new_candidates[rng.randi_range(0,locked_new_candidates.size()-1)].duplicate(true)
			locked_choice["_deferred_series_get"]=true
			return locked_choice
		target_pool=normal_pool
	elif seed_type!="normal" and category_roll<new_rate:
		if not unlocked_new_candidates.is_empty():return unlocked_new_candidates[rng.randi_range(0,unlocked_new_candidates.size()-1)]
		target_pool=normal_pool
	elif category_roll<new_rate+super_rate:target_pool=super_pool
	elif category_roll<new_rate+super_rate+rare_rate:target_pool=rare_pool
	else:target_pool=normal_pool
	if target_pool.is_empty():target_pool=normal_pool if not normal_pool.is_empty() else any_pool
	if target_pool.is_empty():return _catalog_entry(FIRST_STORY_SPECIES_ID)
	return _weighted_from_pool(target_pool)

func _normal_seed_selection_pools()->Dictionary:
	var unlocked_new_candidates:Array=[]
	var locked_new_candidates:Array=[]
	var known_by_stars:Array=[[],[],[]]
	var all_known:Array=[]
	for entry in catalog_species:
		if not _species_available_in_current_era(entry):continue
		var species_id:=str(entry.get("species_id",""))
		if species_id.is_empty() or species_id in pending_round_new_species_ids:continue
		# Legacy rarity is consulted only for the established exclusion rule. The
		# normal-seed rarity category itself comes exclusively from gold_star_count.
		if str(entry.get("rarity","")) in ["隠し原種","謎品種"]:continue
		if _species_get_count(species_id)<=0:
			if _seed_new_species_blocked(species_id):continue
			if _species_is_in_unlocked_series(species_id):unlocked_new_candidates.append(entry)
			elif _normal_seed_locked_series_eligible(species_id) and not bool(forest_gacha_encountered.get(species_id,false)):locked_new_candidates.append(entry)
			continue
		if not bool(greenhouse_available.get(species_id,false)):continue
		var stars:=clampi(int(entry.get("gold_star_count",0)),0,2)
		known_by_stars[stars].append(entry)
		all_known.append(entry)
	return {
		"unlocked_new":unlocked_new_candidates,
		"locked_new":locked_new_candidates,
		"known_by_stars":known_by_stars,
		"all_known":all_known,
	}

func _select_normal_seed_species(forced_category_roll:float=-1.0,allow_random_new:=true)->Dictionary:
	var pools:=_normal_seed_selection_pools()
	var unlocked_new_candidates:Array=pools.get("unlocked_new",[])
	var locked_new_candidates:Array=pools.get("locked_new",[])
	var known_by_stars:Array=pools.get("known_by_stars",[[],[],[]])
	var all_known:Array=pools.get("all_known",[])
	var category_roll:=rng.randf() if forced_category_roll<0.0 else clampf(forced_category_roll,0.0,.999999)
	if allow_random_new and category_roll<NORMAL_SEED_UNLOCKED_NEW_RATE:
		if not unlocked_new_candidates.is_empty():return unlocked_new_candidates[rng.randi_range(0,unlocked_new_candidates.size()-1)]
		return _uniform_normal_seed_fallback(all_known)
	if allow_random_new and category_roll<NORMAL_SEED_UNLOCKED_NEW_RATE+NORMAL_SEED_LOCKED_NEW_RATE:
		if not locked_new_candidates.is_empty():
			var locked_choice:Dictionary=locked_new_candidates[rng.randi_range(0,locked_new_candidates.size()-1)].duplicate(true)
			locked_choice["_deferred_series_get"]=true
			return locked_choice
		return _uniform_normal_seed_fallback(all_known)
	var target_stars:=0
	# Explicit cumulative boundaries avoid floating-point addition moving the
	# exact 85% and 95% category edges.
	if category_roll>=NORMAL_SEED_TWO_STAR_START:target_stars=2
	elif category_roll>=NORMAL_SEED_ONE_STAR_START:target_stars=1
	var target_pool:Array=known_by_stars[target_stars]
	if target_pool.is_empty():return _uniform_normal_seed_fallback(all_known)
	return target_pool[rng.randi_range(0,target_pool.size()-1)]

func _eligible_endless_forced_new_candidates()->Array[Dictionary]:
	var pools:=_normal_seed_selection_pools()
	var candidates:Array[Dictionary]=[]
	for raw_candidate in (pools.get("unlocked_new",[]) as Array):
		if raw_candidate is Dictionary and _fantasy_six_new_candidate_allowed(raw_candidate):candidates.append(raw_candidate)
	for raw_candidate in (pools.get("locked_new",[]) as Array):
		if not raw_candidate is Dictionary:continue
		if not _fantasy_six_new_candidate_allowed(raw_candidate):continue
		var candidate:Dictionary=raw_candidate.duplicate(true)
		candidate["_deferred_series_get"]=true
		candidates.append(candidate)
	return candidates

func _select_endless_forced_new_candidate()->Dictionary:
	var candidates:=_eligible_endless_forced_new_candidates()
	var reserved_id:=endless_greenhouse.forced_new_candidate_hint()
	if not reserved_id.is_empty():
		for candidate in candidates:
			if str(candidate.get("species_id",""))==reserved_id:return candidate
	if candidates.is_empty():return {}
	return candidates[rng.randi_range(0,candidates.size()-1)]

func _uniform_normal_seed_fallback(all_known:Array)->Dictionary:
	if all_known.is_empty():return _catalog_entry(FIRST_STORY_SPECIES_ID)
	return all_known[rng.randi_range(0,all_known.size()-1)]

func _normal_seed_locked_series_eligible(species_id:String)->bool:
	var series_id:=_series_id_for_species(species_id)
	if series_id.is_empty() or not _is_normal_series(series_id):return false
	var series_entry:=_series_entry(series_id)
	return not series_entry.is_empty() and not _is_series_unlocked(series_entry)

func _register_deferred_seed_get(species_id:String)->bool:
	if species_id.is_empty() or bool(discovered.get(species_id,false)):return false
	var first_get:=not bool(forest_gacha_encountered.get(species_id,false))
	forest_gacha_encountered[species_id]=true
	return first_get

func _weighted_from_pool(pool:Array)->Dictionary:
	var total:=0.0
	for entry in pool:total+=_normal_spawn_weight(entry)
	var roll:=rng.randf()*total
	for entry in pool:
		roll-=_normal_spawn_weight(entry)
		if roll<=0.0:return entry
	return pool[0]

func _normal_spawn_weight(entry:Dictionary)->float:
	return maxf(.001,float(entry.get("spawn_weight",1.0)))

func _seed_new_species_blocked(species_id:String)->bool:
	var entry:=_catalog_entry(species_id)
	if bool(entry.get("fusion_only_until_discovered",false)) and _species_get_count(species_id)<=0:return true
	return species_id in [MYSTERY_RESEARCH_TRANSPARENT_ID,"golden_laui","golden_kannte"]

func _find_spawn_position(position_rng:RandomNumberGenerator=null,front_only:=false)->Vector3:
	# Sample world positions, but accept them only after projecting into the
	# scrolling background image's source-pixel coordinates.
	var spawn_rng:=position_rng if position_rng!=null else rng
	var best := Vector3.ZERO
	var best_clearance := -1.0
	for attempt in range(192):
		var angle := spawn_rng.randf_range(0.0, TAU)
		var radius := sqrt(spawn_rng.randf())
		var candidate := Vector3(cos(angle)*3.55*radius,.12,sin(angle)*3.15*radius)
		if front_only and candidate.z<FIRST_PLAY_TUTORIAL_FRONT_SPAWN_MIN_Z:continue
		if not _spawn_center_inside_soil(candidate):continue
		var clearance := 99.0
		for plant in plants:
			if is_instance_valid(plant): clearance = minf(clearance, candidate.distance_to(plant.original_pos))
		for pending_position in pending_seed_positions:
			clearance=minf(clearance,candidate.distance_to(pending_position))
		for old_pos in recent_vacated_slots:
			clearance = minf(clearance, candidate.distance_to(old_pos) * .82)
		if clearance > best_clearance:
			best = candidate
			best_clearance = clearance
		# Normal seeds retain their existing first-safe-position behavior. The
		# scripted NEW seed evaluates every front-side candidate so the clearest
		# visible spot wins while its sampled position remains random.
		if not front_only and clearance >= .82:return candidate
	return best

func _spawn_center_inside_soil(candidate:Vector3)->bool:
	if camera==null or greenhouse_backdrop==null or greenhouse_backdrop.texture==null:return false
	var displayed_world:=candidate+Vector3(_greenhouse_world_offset_for_position(candidate),0,0)
	if camera.is_position_behind(displayed_world):return false
	var screen_point:=camera.unproject_position(displayed_world)
	var texture_scale:=greenhouse_backdrop.size.x/greenhouse_backdrop.texture.get_width()
	if texture_scale<=0.0:return false
	var source_point:=(screen_point-greenhouse_backdrop.position)/texture_scale
	var safe_radii:=SOIL_SOURCE_RADII-Vector2.ONE*SPAWN_SPRITE_MARGIN_SOURCE_PX
	var normalized:=source_point-SOIL_SOURCE_CENTER
	return pow(normalized.x/safe_radii.x,2.0)+pow(normalized.y/safe_radii.y,2.0)<=1.0

func _plant_label()->Label:
	var l:=Label.new(); l.text="1.6 cm"; l.size=Vector2(92,34); l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; l.add_theme_font_size_override("font_size",17); l.add_theme_color_override("font_color",Color.WHITE); l.add_theme_stylebox_override("normal",_box(Color(0.14,0.08,0.05,.92),Color("#f4e1be"),11,2)); l.mouse_filter=Control.MOUSE_FILTER_IGNORE; return l

func _stop_rain_visual()->void:
	if rain_visual and is_instance_valid(rain_visual):rain_visual.free()
	rain_visual=null;rain_drops.clear()

func _process(delta:float)->void:
	_update_greenhouse_pan_follow(delta)
	_update_habitat_view_follow(delta)
	_update_habitat_wild_growth(delta)
	_update_habitat_scroll_tutorial()
	var endless_simulation_paused:=_is_endless_normal_play() and not _should_simulate_endless_greenhouse()
	if not endless_simulation_paused and _update_first_play_tutorial(delta):
		_update_labels()
		return
	if scripted_dialog_kind=="old_seed_growth_reaction":
		_update_labels()
		return
	if old_seed_harvest_guide_active:
		_update_first_play_harvest_guide_focus();_update_labels()
		return
	if puku_buyback_tutorial_active or first_seed_pod_reward_event_active:
		_update_labels()
		return
	if current_mode=="greenhouse" and (play_active or dev_jelly_test_active or catalog_preview_mode_active) and not endless_simulation_paused:
		var old_seed_max_diameter:=0.0
		for p in plants:
			if is_instance_valid(p):
				p.simulate(delta)
				if play_active and active_seed_type=="old" and p.state=="growing":
					old_seed_max_diameter=maxf(old_seed_max_diameter,float(p.diameter_cm))
			if first_play_harvest_guide_active:break
		if _maybe_start_old_seed_reaction(old_seed_max_diameter):
			_update_labels()
			return
		if _maybe_activate_old_seed_harvest_guide():
			_update_labels()
			return
		if first_play_harvest_guide_active:
			_update_first_play_harvest_guide_focus();_update_labels()
			return
		if _maybe_activate_first_play_harvest_guide():
			_update_labels()
			return
		if play_spawn_queue>0:
			play_spawn_timer-=delta
			if play_spawn_timer<=0.0:
				play_spawn_queue-=1;_spawn_greenhouse_seed()
				if play_spawn_queue>0:play_spawn_timer=_next_greenhouse_spawn_interval()
	_poll_greenhouse_play_completion()
	_resolve_crowding(delta)
	_update_labels()

func _update_habitat_wild_growth(delta:float)->void:
	if not habitat_awakened or (not habitat_unlocked and not habitat_wild_initialized):return
	habitat_wild_update_accumulator+=delta;habitat_wild_save_accumulator+=delta
	if habitat_wild_update_accumulator<1.0:return
	var elapsed_real:=habitat_wild_update_accumulator;habitat_wild_update_accumulator=0.0
	var wall_now:=Time.get_unix_time_from_system();var target_unix:=wall_now
	if _trial_dev_controls_enabled() and habitat_time_multiplier>1:target_unix+=elapsed_real*float(habitat_time_multiplier-1)
	var result:=_ensure_habitat_wild_state(target_unix,habitat_time_multiplier==1)
	if target_unix>wall_now:_rebase_habitat_clock(target_unix-wall_now)
	var event_changed:bool=not result.get("jellied",[]).is_empty()
	if bool(result.get("population_changed",false)):
		if current_mode=="habitat":_build_habitat_items(true)
		else:_save()
	elif current_mode=="habitat":_refresh_habitat_wild_badges()
	if bool(result.get("timing_changed",false)) or event_changed:_save()
	if habitat_wild_save_accumulator>=10.0:habitat_wild_save_accumulator=0.0;_save()
	_refresh_habitat_dev_panel()

func _on_jurejure_group_pressed()->void:
	if current_mode!="habitat" or not _should_show_jurejure_group() or not scripted_dialog_kind.is_empty() or jurejure_first_encounter_active or jurejure_intro_camera_active:return
	if puku_puku_battle and puku_puku_battle.visible:return
	if habitat_crisis_pending:return
	if not jurejure_intro_complete:_start_jurejure_first_encounter()
	else:
		if habitat_crisis_started:
			var restoration:=_restoration_state()
			match HabitatRestorationClass.jurejure_interaction_phase(restoration):
				HabitatRestorationClass.JUREJURE_PHASE_POST_ENDING:
					var pattern:=JureJureSystemClass.choose_post_ending_dialog(HabitatRestorationClass.last_post_ending_dialog_index(restoration),rng)
					HabitatRestorationClass.set_last_post_ending_dialog_index(restoration,int(pattern.get("index",-1)));story_progression_state["restoration"]=restoration;_save()
					_start_scripted_dialog("jurejure_post_ending",_localized_jurejure_pattern_pages(pattern),false)
				HabitatRestorationClass.JUREJURE_PHASE_RESTORATION:
					_start_scripted_dialog("jurejure_restoration_hurry",[
						{"speaker":"mouse","text":Localizer.text(language_code,"restoration_jurejure_hurry")}
					],false)
				_:
					_start_scripted_dialog("jurejure_crisis_unavailable",[
						{"speaker":"mouse","text":Localizer.text(language_code,"habitat_crisis_no_battle")}
					],false)
			return
		_play_current_area_bgm(true)
		_start_jurejure_challenge_event()

func _show_jurejure_battle_choice()->void:
	if puku_puku_battle==null:return
	puku_puku_battle.show_choice(language_code);_update_play_ui()

func _on_jurejure_battle_declined()->void:
	_play_current_area_bgm()
	_update_play_ui()

func _jurejure_battle_species_entries()->Array[Dictionary]:
	var entries:Array[Dictionary]=[]
	for species_id_value in habitat_returned_species:
		var species_id:=str(species_id_value);var entry:=_catalog_entry(species_id)
		if not bool(habitat_returned_species.get(species_id,false)) or entry.is_empty() or not _species_available_in_current_era(entry):continue
		entries.append(entry)
	if entries.is_empty():
		for story_species_id in _original_habitat_species_ids():
			var story_entry:=_catalog_entry(story_species_id)
			if not story_entry.is_empty():entries.append(story_entry)
	return entries

func _jurejure_battle_textures(entries:Array[Dictionary])->Dictionary:
	var textures:Dictionary={}
	for entry in entries:
		var species_id:=str(entry.get("species_id",""));var texture:Texture2D=null;var habitat_path:=str(entry.get("habitat_image_path",""))
		if not habitat_path.is_empty() and ResourceLoader.exists(habitat_path):texture=load(habitat_path) as Texture2D
		if texture==null:texture=_species_texture(entry)
		if texture!=null:textures[species_id]=texture
	return textures

func _start_puku_puku_battle()->void:
	if puku_puku_battle==null:return
	var entries:=_jurejure_battle_species_entries();var textures:=_jurejure_battle_textures(entries)
	if entries.is_empty() or textures.is_empty():
		puku_puku_battle.visible=false
		_play_current_area_bgm()
		_update_play_ui();return
	jurejure_last_battle_result.clear();jurejure_pending_reward_species_id="";jurejure_pending_reward_is_new=false
	if audio_manager:audio_manager.play_bgm("puku_battle")
	puku_puku_battle.start_battle(entries,textures,language_code);_update_play_ui()

func _jurejure_reward_candidates()->Array[Dictionary]:
	if _is_post_ending_jurejure_battle():return _post_ending_normal_reward_candidates()
	var candidates:Array[Dictionary]=[]
	var all_jurejure:Array[Dictionary]=[]
	for entry in catalog_species:
		var species_id:=str(entry.get("species_id",""))
		if species_id.is_empty():continue
		if act3_intro_seen:
			if not _is_jurejure_species(entry):continue
			all_jurejure.append(entry)
			if _species_get_count(species_id)<=0:candidates.append(entry)
			continue
		if _species_get_count(species_id)>0:continue
		if _is_jurejure_species(entry) or not _species_available_in_current_era(entry):continue
		if _seed_new_species_blocked(species_id) or str(entry.get("rarity","")) in ["隠し原種","謎品種"]:continue
		if not _species_is_in_unlocked_series(species_id):continue
		candidates.append(entry)
	# After all ten have actually been obtained, repeat wins may award any one.
	if act3_intro_seen and candidates.is_empty():candidates=all_jurejure
	return candidates

func _is_post_ending_jurejure_battle()->bool:
	return HabitatRestorationClass.jurejure_interaction_phase(_restoration_state())==HabitatRestorationClass.JUREJURE_PHASE_POST_ENDING

func _post_ending_normal_reward_candidates()->Array[Dictionary]:
	var pools:=_normal_seed_selection_pools()
	var candidates:Array[Dictionary]=[];var included:Dictionary={}
	var source_groups:Array=[pools.get("all_known",[]),pools.get("unlocked_new",[]),pools.get("locked_new",[])]
	for source_group_value in source_groups:
		if not source_group_value is Array:continue
		for entry_value in source_group_value:
			if not entry_value is Dictionary:continue
			var entry:Dictionary=entry_value;var species_id:=str(entry.get("species_id",""))
			if species_id.is_empty() or included.has(species_id):continue
			# A friendly victory may mirror ordinary-greenhouse availability, but
			# it must never bypass a dedicated fusion/special/hidden acquisition route.
			if bool(entry.get("fusion_only_until_discovered",false)):continue
			if str(entry.get("rarity","")) in ["隠し原種","謎品種"]:continue
			included[species_id]=true;candidates.append(entry)
	return candidates

func _grant_jurejure_battle_reward()->String:
	var candidates:=_jurejure_reward_candidates()
	jurejure_pending_reward_is_new=false
	if candidates.is_empty():return ""
	var chosen:Dictionary=candidates[rng.randi_range(0,candidates.size()-1)];var species_id:=str(chosen.get("species_id",""))
	jurejure_pending_reward_is_new=_species_get_count(species_id)<=0
	if act3_intro_seen:_unlock_jurejure_pool()
	_register_species_discovery(species_id,true);_apply_saved_unlocks();_sync_arrangement_ui()
	return species_id

func _apply_jurejure_battle_loss()->Dictionary:
	if _is_post_ending_jurejure_battle():return {"taken_count":0,"take_ratio":0.0,"puku_lost":0,"friendly":true}
	var ratio:=rng.randf_range(JureJureSystemClass.LOSS_TAKE_MIN_RATIO,JureJureSystemClass.LOSS_TAKE_MAX_RATIO)
	var taken_ids:=JureJureSystemClass.choose_loss_ids(habitat_wild_plants,rng,ratio)
	for individual_id in taken_ids:
		if habitat_plant_panel and habitat_plant_panel.visible and str(habitat_plant_panel.individual_id)==individual_id:habitat_plant_panel.close()
		HabitatWildSystemClass.remove_individual(habitat_wild_plants,individual_id)
	var puku_lost:=1 if _can_afford_puku_units(PUKU_UNITS_PER_PUKU) else 0
	if puku_lost>0:_change_puku_balance(-PUKU_UNITS_PER_PUKU,"jurejure_battle_loss",false,true)
	return {"taken_count":taken_ids.size(),"take_ratio":ratio,"puku_lost":puku_lost}

func _on_puku_puku_battle_resolved(result:Dictionary)->void:
	var first_resolved_battle:=jurejure_battle_count==0
	var post_ending_battle:=_is_post_ending_jurejure_battle()
	jurejure_battle_count+=1;jurejure_last_battle_result=result.duplicate(true)
	if bool(result.get("won",false)):
		jurejure_battle_win_count+=1;jurejure_waiting_for_seed_pod_reward=not StoryProgressionClass.exploitation_is_started(story_progression_state)
		jurejure_pending_reward_species_id=_grant_jurejure_battle_reward()
	else:
		var penalty:=_apply_jurejure_battle_loss()
		for key in penalty:jurejure_last_battle_result[key]=penalty[key]
	if first_resolved_battle and not post_ending_battle:
		act2_unlocked=true;StoryProgressionClass.begin_act_two(story_progression_state)
		_update_main_story_progress(false)
	_save();_update_currency_ui();_build_habitat_items(true);_refresh_habitat_dev_panel();_update_play_ui()

func _on_puku_puku_battle_return_requested()->void:
	current_mode="habitat";_apply_mode();_update_play_ui()
	if bool(jurejure_last_battle_result.get("won",false)):
		var win_key:="jurejure_battle_win_mouse" if not jurejure_pending_reward_species_id.is_empty() else "jurejure_battle_win_no_reward"
		_start_scripted_dialog("jurejure_battle_win",[
			{"speaker":"mouse","text":Localizer.text(language_code,win_key)}
		],false)
	else:
		if bool(jurejure_last_battle_result.get("friendly",false)):
			_start_scripted_dialog("jurejure_battle_loss",[
				{"speaker":"mouse","text":Localizer.text(language_code,"jurejure_battle_loss_friendly_mouse")},
				{"speaker":"","text":Localizer.text(language_code,"jurejure_battle_loss_friendly")}
			],false)
		else:
			var puku_lost:=int(jurejure_last_battle_result.get("puku_lost",0))
			var penalty_key:="jurejure_battle_loss_penalty" if puku_lost>0 else "jurejure_battle_loss_penalty_zero"
			var penalty_args:Array=[int(jurejure_last_battle_result.get("taken_count",0)),puku_lost] if puku_lost>0 else [int(jurejure_last_battle_result.get("taken_count",0))]
			_start_scripted_dialog("jurejure_battle_loss",[
				{"speaker":"mouse","text":Localizer.text(language_code,"jurejure_battle_loss_mouse")},
				{"speaker":"","text":Localizer.text(language_code,penalty_key,penalty_args)}
			],false)

func _clear_active_jurejure_event(_play_escape:=true,_clear_targeted_log:=true)->void:
	# Kept as a compatibility hook for old saves and stale call sites.
	active_jurejure_event={}

func _habitat_wild_plant_by_id(individual_id:String)->Dictionary:
	for plant in habitat_wild_plants:
		if str(plant.get("individual_id",""))==individual_id:return plant
	return {}

func _habitat_individual_ids()->Array[String]:
	var ids:Array[String]=[]
	for plant in habitat_wild_plants:ids.append(str(plant.get("individual_id","")))
	return ids

func _cancel_all_habitat_notifications()->void:
	if habitat_notification_service==null:return
	var ids:=_habitat_individual_ids();habitat_notification_service.cancel_all(ids)

func _open_habitat_plant_panel(plant:Dictionary)->void:
	if habitat_plant_panel==null or plant.is_empty() or bool(plant.get("jellied",false)):return
	var size_text:=Localizer.text(language_code,"habitat_observe_size",[float(plant.get("diameter_cm",0.0))])
	var observation_text:=Localizer.text(language_code,"habitat_observe_note")
	habitat_plant_panel.open_for(plant,_habitat_species_name(str(plant.get("species_id",""))),size_text,observation_text,Localizer.text(language_code,"close"))
	_update_play_ui()

func _open_restoration_plant_panel(item:Dictionary)->void:
	if habitat_plant_panel==null:return
	var snapshot_value:Variant=item.get("snapshot",{})
	if not snapshot_value is Dictionary:return
	var snapshot:Dictionary=(snapshot_value as Dictionary).duplicate(true)
	if snapshot.is_empty():return
	var species_id:=str(snapshot.get("species_id",""));var entry:=_catalog_entry(species_id);var species_name:=""
	if not entry.is_empty():species_name=Localizer.species_name(language_code,entry)
	if species_name.is_empty():species_name=str(snapshot.get("display_name",species_id))
	var size_text:=Localizer.text(language_code,"habitat_observe_size",[float(snapshot.get("diameter_cm",0.0))])
	var observation_text:=Localizer.text(language_code,"habitat_observe_note")
	habitat_plant_panel.open_for(snapshot,species_name,size_text,observation_text,Localizer.text(language_code,"close"))
	_update_play_ui()

func _refresh_habitat_wild_badges()->void:
	for item in habitat_pickups:
		if str(item.get("kind",""))!="wild_plant":continue
		var plant:=_habitat_wild_plant_by_id(str(item.get("individual_id","")))
		if not plant.is_empty():_refresh_habitat_wild_item(item,plant)

func _refresh_habitat_dev_panel()->void:
	if habitat_dev_panel==null or not habitat_dev_panel.visible:return
	habitat_dev_panel.refresh({"multiplier":habitat_time_multiplier,"population":habitat_wild_plants.size(),"max_population":HabitatWildSystemClass.MAX_POPULATION,"settled_count":_habitat_population_candidate_ids().size()},habitat_wild_plants,Callable(self,"_habitat_species_name"),Time.get_unix_time_from_system(),habitat_debug_log)

func _debug_reset_normal_habitat()->void:
	if not _trial_dev_controls_enabled():return
	_clear_active_jurejure_event(false)
	_cancel_all_habitat_notifications()
	habitat_wild_plants.clear();habitat_wild_initialized=false;habitat_wild_next_spawn_unix=0.0
	_ensure_habitat_wild_state(Time.get_unix_time_from_system(),false);_save()
	if current_mode=="habitat":_build_habitat_items(true)
	_record_habitat_debug_event("原生地の個体だけをランダムリセットしました")

func _debug_set_habitat_multiplier(multiplier:int)->void:
	if not _trial_dev_controls_enabled() or multiplier not in HABITAT_TIME_MULTIPLIERS:return
	habitat_time_multiplier=multiplier;_record_habitat_debug_event("時間倍率を ×%d に変更"%multiplier)

func _debug_jump_habitat_time(seconds:int)->void:
	if not _trial_dev_controls_enabled() or seconds<=0:return
	var wall_now:=Time.get_unix_time_from_system()
	_ensure_habitat_wild_state(wall_now,false)
	var target:=wall_now+float(seconds)
	_ensure_habitat_wild_state(target,false)
	_rebase_habitat_clock(target-wall_now);_save()
	if current_mode=="habitat":_build_habitat_items(true)
	_record_habitat_debug_event("通常原生地を %s 進めました"%_format_habitat_debug_duration(seconds))

func _rebase_habitat_clock(offset_seconds:float)->void:
	if offset_seconds<=0.0:return
	for plant in habitat_wild_plants:
		for key in ["spawned_unix","last_updated_unix","jelly_eligible_since_unix","jelly_due_unix","jellied_unix"]:
			var value:=float(plant.get(key,0.0))
			if value>0.0:plant[key]=value-offset_seconds
	if habitat_wild_next_spawn_unix>0.0:habitat_wild_next_spawn_unix-=offset_seconds

func _format_habitat_debug_duration(seconds:int)->String:
	if seconds%86400==0:return "%d日"%(seconds/86400)
	return "%d時間"%(seconds/3600)

func _open_habitat_test_preview()->void:
	if not _trial_dev_controls_enabled() or habitat_dev_panel==null:return
	intro_story_complete=true;first_colorata_confirmed=true;trio_originals_confirmed=true;total_play_count=maxi(3,total_play_count);formal_play_count=maxi(1,formal_play_count);habitat_unlocked=true;habitat_arrival_started=true;habitat_awakened=true;habitat_awakening_event_complete=true;habitat_tutorial_started=true;habitat_tutorial_complete=true;habitat_tutorial_returned_to_greenhouse=true;seed_shop_open=true;mystery_items_acquired=true;mystery_catalog_tutorial_complete=true;normal_play_tutorial_complete=true;seed_pod_gauge_discovery_complete=true;seed_pod_first_reward_seen=true;initial_seed_stock_notice_complete=true;puku_buyback_tutorial_complete=true;original_catalog_gifted=true;puku_gauge_intro_complete=true;unlocked_series[ORIGINAL_SERIES_ID]=true
	if puku_balance_units<10000:_change_puku_balance(10000-puku_balance_units,"habitat_test_preview",false,false)
	for story_species_id in [FIRST_STORY_SPECIES_ID,PANDA_STORY_SPECIES_ID,ARMADILLO_STORY_SPECIES_ID]:habitat_returned_species[story_species_id]=true
	if opening_overlay:opening_overlay.visible=false
	current_mode="habitat";_apply_saved_unlocks();_apply_mode();habitat_dev_panel.open();_refresh_habitat_dev_panel();_save();_update_play_ui()

func _update_greenhouse_pan_follow(delta:float)->void:
	if current_mode!="greenhouse" or is_equal_approx(greenhouse_pan_x,greenhouse_pan_target_x):return
	var follow:=1.0-exp(-delta/GREENHOUSE_PAN_FOLLOW_SECONDS)
	greenhouse_pan_x=lerpf(greenhouse_pan_x,greenhouse_pan_target_x,follow)
	if absf(greenhouse_pan_target_x-greenhouse_pan_x)<0.05:greenhouse_pan_x=greenhouse_pan_target_x
	_update_greenhouse_pan()

func _update_habitat_view_follow(delta:float)->void:
	if current_mode!="habitat":return
	if jurejure_intro_camera_active:
		jurejure_intro_camera_elapsed=minf(.82,jurejure_intro_camera_elapsed+delta)
		var focus_progress:=clampf(jurejure_intro_camera_elapsed/.82,0.0,1.0)
		var focus_eased:=0.5-0.5*cos(PI*focus_progress)
		view_yaw=lerpf(jurejure_intro_camera_start_yaw,jurejure_intro_camera_target_yaw,focus_eased);habitat_target_yaw=view_yaw;view_pitch=lerpf(view_pitch,-3.0,focus_eased);habitat_target_pitch=view_pitch;_apply_view_rotation()
		if focus_progress>=1.0:
			var focus_context:=jurejure_camera_focus_context
			jurejure_intro_camera_active=false;jurejure_intro_camera_elapsed=0.0;jurejure_camera_focus_context=""
			_update_play_ui()
			if focus_context=="habitat_crisis":
				_play_current_area_bgm();call_deferred("_begin_habitat_crisis_dialog")
			elif focus_context=="act3_intro":
				_play_current_area_bgm(true);call_deferred("_start_act3_intro_event")
			elif focus_context=="act3_exploitation_start":
				_play_current_area_bgm();call_deferred("_start_act3_exploitation_battle_intro_event")
			elif focus_context=="exploitation_midpoint":
				_play_current_area_bgm();call_deferred("_start_exploitation_midpoint_event")
			elif focus_context=="restoration_join":
				_play_current_area_bgm();call_deferred("_start_restoration_join_habitat_event")
			elif focus_context=="habitat_visit":
				_play_current_area_bgm()
			elif focus_context.begins_with("restoration_return_"):
				pass
			elif focus_context=="first_encounter":
				_play_current_area_bgm(true);call_deferred("_show_jurejure_first_encounter_still")
		return
	if habitat_lookaround_active:
		var lookaround_duration:=HABITAT_ARRIVAL_LOOKAROUND_DURATION_SECONDS if habitat_lookaround_context=="arrival" else HABITAT_LOOKAROUND_DURATION_SECONDS
		habitat_lookaround_elapsed=minf(lookaround_duration,habitat_lookaround_elapsed+delta)
		var progress:=clampf(habitat_lookaround_elapsed/lookaround_duration,0.0,1.0)
		var eased:=0.5-0.5*cos(PI*progress)
		view_yaw=lerpf(habitat_lookaround_start_yaw,habitat_lookaround_end_yaw,eased)
		view_pitch=habitat_lookaround_start_pitch;habitat_target_yaw=view_yaw;habitat_target_pitch=view_pitch;_apply_view_rotation()
		if progress>=1.0:
			var finished_context:=habitat_lookaround_context
			view_yaw=habitat_lookaround_end_yaw if finished_context=="arrival" else habitat_lookaround_start_yaw;view_pitch=habitat_lookaround_start_pitch;habitat_target_yaw=view_yaw;habitat_target_pitch=view_pitch
			habitat_lookaround_active=false;habitat_lookaround_elapsed=0.0;habitat_lookaround_context="";_apply_view_rotation()
			call_deferred("_finish_habitat_lookaround",finished_context)
		return
	var follow:=1.0-exp(-delta/GREENHOUSE_PAN_FOLLOW_SECONDS)
	view_yaw=rad_to_deg(lerp_angle(deg_to_rad(view_yaw),deg_to_rad(habitat_target_yaw),follow));view_pitch=lerpf(view_pitch,habitat_target_pitch,follow)
	if absf(wrapf(habitat_target_yaw-view_yaw,-180.0,180.0))<.02:view_yaw=habitat_target_yaw
	if absf(habitat_target_pitch-view_pitch)<.02:view_pitch=habitat_target_pitch
	_apply_view_rotation()

func _maybe_focus_jurejure_group_for_visit()->bool:
	if current_mode!="habitat" or habitat_visit_id<=0 or jurejure_focused_habitat_visit_id==habitat_visit_id:return false
	if not jurejure_intro_complete or not _should_show_jurejure_group() or not scripted_dialog_kind.is_empty() or jurejure_intro_camera_active:return false
	if habitat_crisis_pending and not habitat_crisis_started:return false
	jurejure_focused_habitat_visit_id=habitat_visit_id
	_focus_jurejure_group("habitat_visit")
	return true

func _start_habitat_lookaround(context:String)->void:
	if current_mode!="habitat" or habitat_lookaround_active:return
	pointer_down=false;greenhouse_drag_accumulator=0.0;greenhouse_drag_started=false
	habitat_lookaround_active=true;habitat_lookaround_elapsed=0.0;habitat_lookaround_context=context
	habitat_lookaround_end_yaw=view_yaw
	habitat_lookaround_start_yaw=view_yaw-HABITAT_ARRIVAL_LOOKAROUND_DEGREES if context=="arrival" else view_yaw
	if context!="arrival":habitat_lookaround_end_yaw=view_yaw+360.0
	habitat_lookaround_start_pitch=view_pitch;view_yaw=habitat_lookaround_start_yaw
	habitat_target_yaw=view_yaw;habitat_target_pitch=view_pitch;_apply_view_rotation()

func _finish_habitat_lookaround(context:String)->void:
	if context=="arrival" and habitat_awakening_overlay and habitat_awakening_overlay.visible:
		habitat_awakening_overlay.complete_lookaround(context)

func _toggle_mode()->void:
	if catalog_preview_mode_active or play_active or jurejure_intro_camera_active or habitat_lookaround_active:return
	if current_mode=="greenhouse" and not habitat_unlocked:return
	var leaving_habitat:=current_mode=="habitat"
	current_mode="habitat" if current_mode=="greenhouse" else "greenhouse"
	if current_mode=="habitat":habitat_visit_id+=1
	if leaving_habitat and habitat_tutorial_complete:
		habitat_tutorial_returned_to_greenhouse=true
		StoryProgressionClass.queue_post_crisis_greenhouse_on_return(story_progression_state)
	_apply_mode()
	if current_mode=="habitat" and not habitat_awakened:
		call_deferred("_start_habitat_awakening_event")
	elif current_mode=="habitat" and not habitat_tutorial_complete and not habitat_tutorial_started:
		call_deferred("_start_first_habitat_tutorial")
	elif current_mode=="habitat" and not jurejure_intro_complete and _should_show_jurejure_group():
		call_deferred("_start_jurejure_first_encounter")
	elif leaving_habitat and habitat_tutorial_complete and not puku_gauge_intro_complete:
		call_deferred("_start_puku_gauge_intro_after_greenhouse_frame")
	else:
		call_deferred("_try_start_pending_story_event")
	_save()

func _play_current_area_bgm(force_jurejure:=false)->void:
	if audio_manager==null:return
	if current_mode=="habitat":
		var key:="jurejure" if force_jurejure else JureJureSystemClass.habitat_bgm_key(StoryProgressionClass.exploitation_is_started(story_progression_state),habitat_crisis_started,StoryProgressionClass.restoration_is_complete(story_progression_state))
		audio_manager.play_bgm(key)
	else:
		audio_manager.play_bgm("greenhouse")

func _update_habitat_scroll_tutorial()->void:
	# The original "pan until a pickup appears" tutorial is retired. Panning
	# remains available, while the first wild plant is explained by dialogue.
	return

func _apply_mode()->void:
	if camera==null:return
	var greenhouse_mode:=current_mode=="greenhouse"
	if not greenhouse_mode:
		_print_habitat_memory_snapshot("enter_before")
		_build_habitat_items()
		_print_habitat_memory_snapshot("enter_after")
	else:
		jurejure_habitat_visit_point=Vector2(-1.0,-1.0)
		_print_habitat_memory_snapshot("exit_before")
		_clear_habitat_items()
		_print_habitat_memory_snapshot("exit_after")
	greenhouse_layer.visible=greenhouse_mode
	habitat_items_root.visible=not greenhouse_mode
	if habitat_crisis_atmosphere:
		if habitat_crisis_started:habitat_crisis_atmosphere.activate()
		habitat_crisis_atmosphere.set_restoration_stage(_restoration_stage())
		habitat_crisis_atmosphere.set_habitat_visible(not greenhouse_mode and habitat_crisis_started)
	if habitat_status_label:habitat_status_label.visible=false
	# The official greenhouse artwork already contains the finished pot and soil.
	# Keep the old geometry disabled so no duplicate rim covers the sprites.
	pot_root.visible=false
	if greenhouse_mode:habitat_environment.background_mode=Environment.BG_CANVAS
	else:habitat_environment.background_mode=Environment.BG_SKY if habitat_background_mode=="current" else Environment.BG_COLOR
	if habitat_panorama_mesh:habitat_panorama_mesh.visible=not greenhouse_mode
	print("HABITAT_BACKGROUND_STATE mode=",habitat_background_mode," screen=",("greenhouse" if greenhouse_mode else "habitat")," background_mode=",habitat_environment.background_mode," sky_present=",habitat_environment.sky!=null," panorama_mesh_visible=",habitat_panorama_mesh!=null and habitat_panorama_mesh.visible)
	for p in plants:
		if is_instance_valid(p):p.visible=greenhouse_mode;p.label.visible=false
	if greenhouse_mode:
		camera.position=Vector3(0,7.3,8.6);camera.look_at_from_position(camera.position,Vector3(0,1.05,0),Vector3.UP)
		_update_greenhouse_pan()
	else:
		camera.position=Vector3.ZERO;habitat_target_yaw=view_yaw;habitat_target_pitch=view_pitch;_apply_view_rotation()
	if mode_button:
		mode_button.text=Localizer.text(language_code,"main_habitat" if greenhouse_mode else "main_greenhouse")
	_play_current_area_bgm()
	_update_play_ui()

func _resolve_crowding(_delta:float)->void:
	# Sprite plants remain rooted at their spawn point. Natural overlap is less
	# distracting than sliding a planted rosette around as it grows.
	for p in plants:
		if is_instance_valid(p):
			p.target_offset = Vector3.ZERO
			var combined_pan:=_greenhouse_world_offset_for_position(p.original_pos) if current_mode=="greenhouse" else 0.0
			p.position.x = p.original_pos.x+combined_pan
			p.position.z = p.original_pos.z

func _greenhouse_world_offset_for_position(world_position:Vector3)->float:
	if camera==null:return greenhouse_world_pan_x
	var screen_x:=camera.unproject_position(world_position).x
	var screen_right_x:=camera.unproject_position(world_position+Vector3.RIGHT).x
	var pixels_per_world:=screen_right_x-screen_x
	var background_delta:=greenhouse_background_position_x-greenhouse_main_position_x
	return background_delta/pixels_per_world if absf(pixels_per_world)>.001 else greenhouse_world_pan_x

func _update_labels()->void:
	if _old_seed_story_active():
		for p in plants:
			if is_instance_valid(p):p.label.visible=false
		return
	if current_mode!="greenhouse":
		for p in plants:
			if is_instance_valid(p):p.label.visible=false
		return
	var occupied:Array[Rect2]=[]
	var sorted:=plants.duplicate(); sorted.sort_custom(func(a,b):return a.position.z<b.position.z)
	for p in sorted:
		if not is_instance_valid(p):continue
		if camera.is_position_behind(p.global_position):
			p.label.visible=false
			continue
		var screen:=camera.unproject_position(p.global_position+Vector3(0,p.visual_scale*.7,0))
		var show_traits:=jelly_trait_display_enabled and JellyBalanceClass.override_enabled
		var label_size:=Vector2(154,100) if show_traits else Vector2(92,34)
		var r:=Rect2(screen-Vector2(label_size.x*.5,label_size.y+28),label_size)
		for other in occupied:
			if r.intersects(other):r.position.y=other.position.y-label_size.y-3
		occupied.append(r)
		var new_prefix:="NEW！\n" if bool(p.get_meta("new_species_candidate",false)) and _species_get_count(str(p.data.get("species_id","")))<=0 else ""
		p.label.position=r.position;p.label.size=label_size+Vector2(0,26 if not new_prefix.is_empty() else 0);p.label.add_theme_font_size_override("font_size",12 if show_traits else 17);p.label.text=new_prefix+(("%.1f cm\n%s"%[p.diameter_cm,p.development_trait_text()]) if show_traits else "%.1f cm"%p.diameter_cm);p.label.add_theme_color_override("font_color",Color("#ffe56f") if not new_prefix.is_empty() else Color.WHITE);p.label.visible=p.state=="growing" and Rect2(Vector2.ZERO,get_viewport().get_visible_rect().size).grow(80).has_point(screen)

func _greenhouse_area_navigation_available()->bool:
	if not StoryProgressionClass.arrangement_is_unlocked(story_progression_state) or not _tutorial_fully_complete() or current_mode!="greenhouse" or play_active or catalog_preview_mode_active or arrangement_transitioning:return false
	if arrangement_scene_active and arrangement_ui and (arrangement_ui.is_editor_active() or arrangement_ui.is_viewer_active()):return false
	return not ((opening_story_overlay and opening_story_overlay.visible) or (habitat_awakening_overlay and habitat_awakening_overlay.visible) or (seed_pod_story_overlay and seed_pod_story_overlay.visible) or (habitat_second_awakening_overlay and habitat_second_awakening_overlay.visible) or (jurejure_first_encounter_overlay and jurejure_first_encounter_overlay.visible) or jurejure_first_encounter_active or (puku_puku_battle and puku_puku_battle.visible) or (tutorial_guide_overlay and tutorial_guide_overlay.visible) or (intro_overlay and intro_overlay.visible) or (settings_overlay and settings_overlay.visible) or (jelly_dev_overlay and jelly_dev_overlay.visible) or (habitat_plant_panel and habitat_plant_panel.visible) or (habitat_dev_panel and habitat_dev_panel.visible) or (story_dev_panel and story_dev_panel.visible) or (forest_gacha_ui and forest_gacha_ui.visible) or (species_get_overlay and species_get_overlay.visible) or (catalog_series_unlock_overlay and catalog_series_unlock_overlay.visible) or (catalog_preview_ui and catalog_preview_ui.is_overlay_open()) or (encyclopedia_overlay and encyclopedia_overlay.visible) or (shop_overlay and shop_overlay.visible) or (result_overlay and result_overlay.visible) or (play_overlay and play_overlay.visible))

func _arrangement_navigation_hint_safe()->bool:
	# Navigation availability covers gameplay overlays. The opening screen is a
	# separate boot layer, so explicitly require it to be completed and hidden.
	if opening_overlay==null or not opening_finished or opening_overlay.visible:return false
	if not _greenhouse_area_navigation_available():return false
	if arrangement_scene_active:return arrangement_ui!=null and arrangement_ui.is_navigation_hint_safe()
	return true

func _unhandled_input(event:InputEvent)->void:
	if arrangement_ui and arrangement_ui.is_viewer_active():
		if greenhouse_area_drag_tracking:_cancel_greenhouse_area_drag()
		return
	if greenhouse_area_drag_tracking or (not arrangement_scene_active and _greenhouse_area_navigation_available()):
		_handle_greenhouse_area_scroll_input(event,false)

func _on_arrangement_world_scroll_input(event:InputEvent)->void:
	if arrangement_ui and (arrangement_ui.is_editor_active() or arrangement_ui.is_viewer_active()):
		if greenhouse_area_drag_tracking:_cancel_greenhouse_area_drag()
		return
	if greenhouse_area_drag_tracking or (arrangement_scene_active and _greenhouse_area_navigation_available()):
		_handle_greenhouse_area_scroll_input(event,true)

func _handle_greenhouse_area_scroll_input(event:InputEvent,from_arrangement:bool)->void:
	if event is InputEventScreenTouch:
		if event.pressed:_begin_greenhouse_area_drag(event.position,from_arrangement)
		else:_finish_greenhouse_area_drag(event.position)
	elif event is InputEventScreenDrag:
		_update_greenhouse_area_drag(event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:_begin_greenhouse_area_drag(event.position,from_arrangement)
		else:_finish_greenhouse_area_drag(event.position)
	elif event is InputEventMouseMotion and greenhouse_area_drag_tracking and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_greenhouse_area_drag(event.position)

func _begin_greenhouse_area_drag(screen_position:Vector2,from_arrangement:bool)->void:
	if greenhouse_area_drag_tracking or not _greenhouse_area_navigation_available():return
	if arrangement_transition_tween and arrangement_transition_tween.is_valid():arrangement_transition_tween.kill()
	greenhouse_area_drag_tracking=true;greenhouse_area_drag_started=false;greenhouse_area_drag_from_arrangement=from_arrangement
	greenhouse_area_drag_start_position=screen_position;greenhouse_area_drag_last_position=screen_position
	greenhouse_area_drag_start_transition_x=arrangement_transition_x;greenhouse_area_drag_velocity_x=0.0
	greenhouse_area_drag_last_ticks_msec=Time.get_ticks_msec()

func _update_greenhouse_area_drag(screen_position:Vector2)->void:
	if not greenhouse_area_drag_tracking:return
	var total_delta:=screen_position-greenhouse_area_drag_start_position
	if not greenhouse_area_drag_started:
		if absf(total_delta.y)>GREENHOUSE_AREA_DRAG_DEAD_ZONE and absf(total_delta.y)>absf(total_delta.x)*GREENHOUSE_AREA_DRAG_HORIZONTAL_BIAS:
			_cancel_greenhouse_area_drag()
			return
		if absf(total_delta.x)<GREENHOUSE_AREA_DRAG_DEAD_ZONE or absf(total_delta.x)<=absf(total_delta.y)*GREENHOUSE_AREA_DRAG_HORIZONTAL_BIAS:return
		greenhouse_area_drag_started=true;arrangement_transitioning=true
		if not greenhouse_area_drag_from_arrangement:
			saved_greenhouse_pan_x=greenhouse_pan_x;greenhouse_pan_target_x=greenhouse_pan_x
		if arrangement_ui:arrangement_ui.visible=false
		_update_play_ui()
	var arrangement_target:=_arrangement_focus_transition_for_pan(saved_greenhouse_pan_x)
	var lower:=minf(0.0,arrangement_target);var upper:=maxf(0.0,arrangement_target)
	_set_arrangement_transition_x(clampf(greenhouse_area_drag_start_transition_x+total_delta.x,lower,upper))
	var ticks:=Time.get_ticks_msec();var elapsed:=maxf(float(ticks-greenhouse_area_drag_last_ticks_msec)/1000.0,.001)
	var instant_velocity:=(screen_position.x-greenhouse_area_drag_last_position.x)/elapsed
	greenhouse_area_drag_velocity_x=lerpf(greenhouse_area_drag_velocity_x,instant_velocity,.45)
	greenhouse_area_drag_last_position=screen_position;greenhouse_area_drag_last_ticks_msec=ticks

func _finish_greenhouse_area_drag(screen_position:Vector2)->void:
	if not greenhouse_area_drag_tracking:return
	if not greenhouse_area_drag_last_position.is_equal_approx(screen_position):_update_greenhouse_area_drag(screen_position)
	var was_started:=greenhouse_area_drag_started
	greenhouse_area_drag_tracking=false
	if not was_started:
		greenhouse_area_drag_started=false
		return
	var arrangement_target:=_arrangement_focus_transition_for_pan(saved_greenhouse_pan_x)
	var progress:=clampf(arrangement_transition_x/maxf(arrangement_target,.001),0.0,1.0)
	var to_arrangement:=progress>=.5
	if greenhouse_area_drag_velocity_x>=GREENHOUSE_AREA_FLICK_THRESHOLD:to_arrangement=true
	elif greenhouse_area_drag_velocity_x<=-GREENHOUSE_AREA_FLICK_THRESHOLD:to_arrangement=false
	_snap_greenhouse_area(to_arrangement)

func _cancel_greenhouse_area_drag(update_ui:=true)->void:
	greenhouse_area_drag_tracking=false;greenhouse_area_drag_started=false;greenhouse_area_drag_velocity_x=0.0
	if update_ui:_update_play_ui()

func _input(event:InputEvent)->void:
	if audio_manager and (event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey):audio_manager.notify_user_gesture()
	if habitat_lookaround_active or jurejure_intro_camera_active:return
	if habitat_restoration_ui and habitat_restoration_ui.is_modal_visible():return
	if arrangement_scene_active or arrangement_transitioning:return
	if (opening_story_overlay and opening_story_overlay.visible) or (habitat_awakening_overlay and habitat_awakening_overlay.visible) or (seed_pod_story_overlay and seed_pod_story_overlay.visible) or (habitat_second_awakening_overlay and habitat_second_awakening_overlay.visible) or (jurejure_first_encounter_overlay and jurejure_first_encounter_overlay.visible) or (puku_puku_battle and puku_puku_battle.visible) or (tutorial_guide_overlay and tutorial_guide_overlay.visible and not first_play_harvest_guide_active and not old_seed_harvest_guide_active) or (intro_overlay and intro_overlay.visible) or (settings_overlay and settings_overlay.visible) or (jelly_dev_overlay and jelly_dev_overlay.visible) or (habitat_plant_panel and habitat_plant_panel.visible) or (habitat_dev_panel and habitat_dev_panel.visible) or (story_dev_panel and story_dev_panel.visible) or (forest_gacha_ui and forest_gacha_ui.visible) or (fusion_lab_ui and fusion_lab_ui.visible) or (species_get_overlay and species_get_overlay.visible) or (catalog_series_unlock_overlay and catalog_series_unlock_overlay.visible) or (catalog_preview_ui and catalog_preview_ui.is_overlay_open()) or (encyclopedia_overlay and encyclopedia_overlay.visible) or (shop_overlay and shop_overlay.visible) or (result_overlay and result_overlay.visible) or (play_overlay and play_overlay.visible):return
	if current_mode=="greenhouse" and not play_active and not catalog_preview_mode_active:return
	if event is InputEventScreenTouch:
		if event.pressed:
			_begin_pointer(event.position)
		else:
			_end_pointer(event.position)
	elif event is InputEventScreenDrag and pointer_down:
		_drag_pointer(event.position, event.relative)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_pointer(event.position)
		else:
			_end_pointer(event.position)
	elif event is InputEventMouseMotion and pointer_down and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_drag_pointer(event.position, event.relative)

func _begin_pointer(screen_pos:Vector2)->void:
	if _old_seed_story_active() and old_seed_harvest_guide_active and is_instance_valid(tutorial_harvest_plant) and str(tutorial_harvest_plant.data.get("species_id",""))==FIRST_STORY_SPECIES_ID:
		_begin_old_colorata_profile(Time.get_ticks_msec())
	pointer_down=true;pointer_start=screen_pos;pointer_last=screen_pos;pointer_travel=0.0
	greenhouse_drag_accumulator=0.0;greenhouse_drag_started=false;greenhouse_pan_target_x=greenhouse_pan_x
	habitat_target_yaw=view_yaw;habitat_target_pitch=view_pitch

func _drag_pointer(screen_pos:Vector2,relative:Vector2)->void:
	pointer_travel+=relative.length();pointer_last=screen_pos
	if current_mode=="greenhouse":
		if not greenhouse_drag_started:
			greenhouse_drag_accumulator+=relative.x
			if absf(greenhouse_drag_accumulator)<=GREENHOUSE_DRAG_DEAD_ZONE:return
			greenhouse_drag_started=true
			var excess:=greenhouse_drag_accumulator-signf(greenhouse_drag_accumulator)*GREENHOUSE_DRAG_DEAD_ZONE
			greenhouse_pan_target_x=clampf(greenhouse_pan_target_x+excess*GREENHOUSE_DRAG_SCALE,-greenhouse_pan_limit,greenhouse_pan_limit)
		else:
			greenhouse_pan_target_x=clampf(greenhouse_pan_target_x+relative.x*GREENHOUSE_DRAG_SCALE,-greenhouse_pan_limit,greenhouse_pan_limit)
		return
	if current_mode!="habitat":return
	if not greenhouse_drag_started:
		greenhouse_drag_accumulator+=relative.x
		if absf(greenhouse_drag_accumulator)<=GREENHOUSE_DRAG_DEAD_ZONE:return
		greenhouse_drag_started=true
		var excess:=greenhouse_drag_accumulator-signf(greenhouse_drag_accumulator)*GREENHOUSE_DRAG_DEAD_ZONE
		habitat_target_yaw=fmod(habitat_target_yaw+excess*HABITAT_DRAG_SCALE,360.0)
	else:habitat_target_yaw=fmod(habitat_target_yaw+relative.x*HABITAT_DRAG_SCALE,360.0)
	habitat_target_pitch=clampf(habitat_target_pitch+relative.y*.025,-13.0,9.0)

func _end_pointer(screen_pos:Vector2)->void:
	if not pointer_down:return
	pointer_down=false
	if old_colorata_profile_active:_old_colorata_profile_mark("tap_end")
	if pointer_travel<13.0 and pointer_start.distance_to(screen_pos)<16.0:
		if current_mode=="greenhouse":_try_harvest(screen_pos)
		elif current_mode=="habitat":_try_habitat_pick(screen_pos)

func _apply_view_rotation()->void:
	if camera:camera.rotation_degrees=Vector3(view_pitch,view_yaw,0.0)

func _try_harvest(screen_pos:Vector2)->void:
	# Each plant reconstructs its rendered Sprite3D quad in screen space. Unlike a
	# capped radius around the root, this remains aligned with huge visible leaves.
	if play_active and active_seed_type=="old" and not old_seed_harvest_guide_active:return
	if first_play_tutorial_active and not first_play_tutorial_sequence_complete:return
	if first_play_tutorial_active and not first_play_has_harvested and not first_play_harvest_guide_active:return
	var candidates:Array=[]
	for p in plants:
		if not is_instance_valid(p) or p.state!="growing" or camera.is_position_behind(p.global_position):continue
		if (first_play_harvest_guide_active or old_seed_harvest_guide_active) and p!=tutorial_harvest_plant:continue
		var hit:Dictionary=p.screen_hit_test(camera,screen_pos)
		if bool(hit.get("hit",false)):candidates.append({"p":p,"score":float(hit.get("score",INF))})
	if candidates.size()>0:
		candidates.sort_custom(func(a,b):return a.score<b.score)
		var selected_plant=candidates[0].p
		if old_colorata_profile_active and selected_plant==tutorial_harvest_plant:
			_old_colorata_profile_mark("harvest_target_decided");selected_plant.set_meta("old_colorata_profile",true)
		selected_plant.set_meta("harvest_input_msec",Time.get_ticks_msec())
		selected_plant.harvest()

func _habitat_sprite_screen_hit_used_rect(sprite:Sprite3D)->Rect2:
	if sprite==null or sprite.texture==null:return Rect2()
	if sprite.has_meta("habitat_screen_hit_used_rect"):
		var cached:Variant=sprite.get_meta("habitat_screen_hit_used_rect")
		if cached is Rect2:return cached
	var texture_size:=sprite.texture.get_size();var result:=Rect2(Vector2.ZERO,texture_size);var image:=sprite.texture.get_image()
	if image!=null and not image.is_empty():
		var used:=image.get_used_rect()
		if used.size.x>0 and used.size.y>0:result=Rect2(used)
	sprite.set_meta("habitat_screen_hit_used_rect",result)
	return result

func _habitat_sprite_screen_hit_test(sprite:Sprite3D,screen_point:Vector2)->Dictionary:
	# Restoration plants are much larger than their root position. Reconstruct the
	# rendered billboard quad so visible leaves, rather than a small center radius,
	# own the tap even when a normal habitat plant is rooted immediately beside it.
	if camera==null or sprite==null or sprite.texture==null:return {"hit":false}
	if camera.is_position_behind(sprite.global_position):return {"hit":false}
	var texture_size:=sprite.texture.get_size()
	if texture_size.x<=0.0 or texture_size.y<=0.0:return {"hit":false}
	var used:=_habitat_sprite_screen_hit_used_rect(sprite)
	if used.size.x<=0.0 or used.size.y<=0.0:used=Rect2(Vector2.ZERO,texture_size)
	var basis:=camera.global_transform.basis;var angle:=sprite.rotation.z
	var plane_right:Vector3=basis.x*cos(angle)+basis.y*sin(angle);var plane_up:Vector3=-basis.x*sin(angle)+basis.y*cos(angle)
	var global_scale:=sprite.global_transform.basis.get_scale();var origin:=sprite.global_position;var points:=PackedVector2Array()
	for pixel_point in [used.position,Vector2(used.end.x,used.position.y),used.end,Vector2(used.position.x,used.end.y)]:
		var local_pixels:=Vector2(pixel_point.x-texture_size.x*.5+sprite.offset.x,-(pixel_point.y-texture_size.y*.5+sprite.offset.y))
		var world_point:=origin+plane_right*local_pixels.x*sprite.pixel_size*global_scale.x+plane_up*local_pixels.y*sprite.pixel_size*global_scale.y
		points.append(camera.unproject_position(world_point))
	var visible_rect:=Rect2(points[0],Vector2.ZERO)
	for point in points:visible_rect=visible_rect.expand(point)
	var padding:=clampf(minf(visible_rect.size.x,visible_rect.size.y)*.08,14.0,36.0);var inside_artwork_bounds:=Geometry2D.is_point_in_polygon(screen_point,points)
	if not inside_artwork_bounds and not visible_rect.grow(padding).has_point(screen_point):return {"hit":false,"rect":visible_rect,"polygon":points}
	var half_size:=Vector2(maxf(visible_rect.size.x*.5,1.0),maxf(visible_rect.size.y*.5,1.0));var normalized_delta:=(screen_point-visible_rect.get_center())/half_size
	return {"hit":true,"score":normalized_delta.length()+(0.0 if inside_artwork_bounds else .85),"rect":visible_rect,"polygon":points,"center":visible_rect.get_center(),"inside_artwork_bounds":inside_artwork_bounds}

func _habitat_pickup_at(screen_pos:Vector2)->Dictionary:
	var restoration_candidates:Array=[]
	for item in habitat_pickups:
		if str(item.get("kind",""))!="restoration_plant":continue
		var sprite:=item.get("node") as Sprite3D
		if not is_instance_valid(sprite):continue
		var hit:=_habitat_sprite_screen_hit_test(sprite,screen_pos)
		if bool(hit.get("hit",false)):restoration_candidates.append({"item":item,"score":float(hit.get("score",INF))})
	if not restoration_candidates.is_empty():
		restoration_candidates.sort_custom(func(a,b):return a.score<b.score)
		return restoration_candidates[0].item
	var candidates:Array=[]
	for item in habitat_pickups:
		if str(item.get("kind",""))=="restoration_plant":continue
		var node=item.get("node")
		if not is_instance_valid(node) or camera.is_position_behind(node.global_position):continue
		var projected:=camera.unproject_position(node.global_position);var distance:=projected.distance_to(screen_pos)
		var kind:=str(item.get("kind",""));var hit_radius:=142.0 if kind=="jurejure_group" else (78.0 if kind=="wild_plant" else 42.0)
		if distance<hit_radius:candidates.append({"item":item,"distance":distance})
	if candidates.is_empty():return {}
	candidates.sort_custom(func(a,b):return a.distance<b.distance)
	return candidates[0].item

func _try_habitat_pick(screen_pos:Vector2)->void:
	var selected:=_habitat_pickup_at(screen_pos)
	if selected.is_empty():return
	if str(selected.kind)=="seed":_collect_habitat_seed(selected)
	elif str(selected.kind)=="old_catalog_page":_collect_habitat_old_catalog_page(selected)
	elif str(selected.kind)=="wild_plant":_collect_habitat_wild_plant(selected)
	elif str(selected.kind)=="restoration_plant":_open_restoration_plant_panel(selected)
	elif str(selected.kind)=="jurejure_group":_on_jurejure_group_pressed()

func _collect_habitat_wild_plant(item:Dictionary)->void:
	var selected_id:=str(item.get("individual_id",""));var habitat_result:=_ensure_habitat_wild_state(Time.get_unix_time_from_system(),true)
	if bool(habitat_result.get("population_changed",false)) and current_mode=="habitat":
		_build_habitat_items(true);item=_habitat_wild_item_by_id(selected_id)
	var plant:=_habitat_wild_plant_by_id(selected_id)
	if plant.is_empty():return
	if bool(plant.get("jellied",false)):
		if str(active_jurejure_event.get("individual_id",""))==selected_id:_clear_active_jurejure_event(false,false)
		HabitatWildSystemClass.remove_individual(habitat_wild_plants,selected_id);_save();_build_habitat_items();return
	audio_manager.play_se("squish",.26)
	_open_habitat_plant_panel(plant)

func _collect_habitat_seed(item:Dictionary)->void:
	if habitat_mystery_seeds_pending<=0:return
	habitat_mystery_seeds_pending-=1;mystery_seed_count+=1;habitat_pickups.erase(item);var node=item.node;_show_habitat_message(node.global_position,Localizer.text(language_code,"mystery_seed_get"),Color("#ffe4a0"));node.queue_free();_save();_update_habitat_ui()

func _collect_habitat_old_catalog_page(item:Dictionary)->void:
	if not habitat_old_catalog_page_pending:return
	var series_id:=str(item.get("series_id",habitat_old_catalog_page_series_id));habitat_old_catalog_page_pending=false;habitat_old_catalog_page_series_id="";_grant_old_catalog_page(1,true,series_id);habitat_pickups.erase(item);var node:Node3D=item.node;_show_habitat_message(node.global_position,Localizer.text(language_code,"old_catalog_page_get"),Color("#f5dfad"));node.queue_free();_save();_update_habitat_ui();audio_manager.play_se("new_species",.45)

func _show_habitat_message(world_position:Vector3,message:String,color:Color)->void:
	var label:=Label.new();label.text=message;label.size=Vector2(300,80);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",25);label.add_theme_color_override("font_color",color);label.add_theme_color_override("font_outline_color",UI_BROWN);label.add_theme_constant_override("outline_size",8);label.position=camera.unproject_position(world_position)-Vector2(150,40);effects_layer.add_child(label)
	var tween:=create_tween().bind_node(label).set_parallel();tween.tween_property(label,"position:y",label.position.y-70,.7);tween.tween_property(label,"modulate:a",0.0,.7).set_delay(.25);tween.chain().tween_callback(label.queue_free)

func _on_harvested(p)->void:
	if bool(p.get_meta("catalog_preview",false)):_on_catalog_preview_harvested(p);return
	if dev_jelly_test_active:
		plants.erase(p);var tween:=create_tween().bind_node(p);tween.tween_property(p,"scale",Vector3.ONE*.01,.2);_cleanup_later(p,.25);return
	last_harvest_input_msec=int(p.get_meta("harvest_input_msec",Time.get_ticks_msec()))
	var harvested_data:Dictionary=p.data.duplicate(true)
	var harvested_species_id:=str(harvested_data.get("species_id",""))
	var profiled_old_colorata:=bool(p.get_meta("old_colorata_profile",false)) and harvested_species_id==FIRST_STORY_SPECIES_ID
	var harvested_diameter_cm:=float(p.diameter_cm)
	var harvested_visual_scale:=float(p.visual_scale)
	var harvested_screen_position:=camera.unproject_position(p.global_position)
	var story_dev_101:=bool(p.get_meta("story_dev_101",false))
	var terminal_first_tutorial_harvest:=_is_terminal_first_tutorial_plant(p)
	if first_play_tutorial_active:first_play_has_harvested=true
	var completed_first_harvest_guide:=first_play_harvest_guide_active
	if old_seed_harvest_guide_active:
		old_seed_harvest_guide_active=false;tutorial_harvest_plant=null;_hide_first_play_tutorial_overlay()
	if completed_first_harvest_guide:
		if bool(p.get_meta("first_tutorial_reserved_new",false)):tutorial_steps["first_normal_tutorial_species_id"]=str(p.data.get("species_id",""))
		first_play_harvest_guide_active=false;tutorial_steps["first_harvest_guide"]=true;normal_play_tutorial_complete=true;tutorial_harvest_plant=null;_hide_first_play_tutorial_overlay()
		for remaining_plant in plants:
			if is_instance_valid(remaining_plant) and remaining_plant!=p and remaining_plant.state=="growing":remaining_plant.jelly_checks_enabled=true
		if _is_endless_normal_play():_end_first_play_tutorial_context()
	var story_old_seed:=_old_seed_story_active()
	var deferred_tovar:=tovar_event_active and harvested_species_id==HIDDEN_TOVAR_ID
	var endless_forced_new:=bool(p.get_meta("endless_forced_new",false))
	var old:=float(bests.get(harvested_species_id,0.0));var is_record:bool=not deferred_tovar and not story_old_seed and harvested_diameter_cm>old
	var already_pending_round_new:=harvested_species_id in pending_round_new_species_ids
	var is_first_get_for_puku:=_species_get_count(harvested_species_id)<=0 and not already_pending_round_new
	var first_discovery:=not deferred_tovar and is_first_get_for_puku
	var defer_round_new:=not deferred_tovar and _is_endless_normal_play() and first_discovery
	# Reserve the NEW immediately so a second input can never duplicate it. Full
	# discovery/story work still waits until the first feedback frame is visible.
	if defer_round_new:pending_round_new_species_ids.append(harvested_species_id)
	if profiled_old_colorata:_old_colorata_profile_mark("harvest_animation_start")
	audio_manager.play_se("harvest",.55)
	var harvest_tween:=create_tween().bind_node(p).set_parallel();harvest_tween.tween_property(p,"position:y",p.position.y+2.0,.42).set_trans(Tween.TRANS_BACK);harvest_tween.tween_property(p,"scale",p.scale*1.2,.22);harvest_tween.chain().tween_property(p,"scale",Vector3.ONE*0.01,.24)
	p.set_meta("harvest_feedback_started",true)
	last_harvest_feedback_msec=Time.get_ticks_msec();last_harvest_feedback_latency_msec=maxi(0,last_harvest_feedback_msec-last_harvest_input_msec)
	# Let the spotlight removal, sound trigger and first animation frame render
	# before save serialization and story/unlock evaluation run on the main thread.
	if DisplayServer.get_name()=="headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw
		# Web's frame_post_draw signal precedes browser composition. Give the
		# immediate sound/spotlight/Tween response a browser-driven frame before
		# synchronous progression and persistence can block the main thread.
		if OS.has_feature("web") and not story_old_seed:
			await get_tree().create_timer(0.12).timeout
	last_harvest_presented_msec=Time.get_ticks_msec();last_harvest_presented_latency_msec=maxi(0,last_harvest_presented_msec-last_harvest_input_msec)
	if profiled_old_colorata:_old_colorata_profile_mark("first_visual_response")
	if not completed_first_harvest_guide:_maybe_activate_first_play_harvest_guide()
	if deferred_tovar:tovar_harvested_this_play=true
	var restoration_snapshot:Dictionary={}
	if not deferred_tovar and HabitatRestorationClass.can_offer_return(_restoration_state(),harvested_diameter_cm):
		restoration_snapshot={
			"species_id":harvested_species_id,
			"display_name":Localizer.species_name(language_code,harvested_data),
			"diameter_cm":harvested_diameter_cm,
			"visual_scale":harvested_visual_scale,
			"rarity":str(harvested_data.get("rarity","")),
			"gold_star_count":int(harvested_data.get("gold_star_count",0)),
		}
	if not deferred_tovar:
		_record_endless_discovery_settlement(true,harvested_diameter_cm)
		if defer_round_new:
			# Formal GET, catalog progress, and story thresholds intentionally wait
			# until the round result is closed. Only the active forced slot is cleared;
			# a newly rolled reservation (including on the twelfth plant) survives.
			if endless_forced_new:endless_greenhouse.complete_forced_new()
		elif first_discovery:
			if profiled_old_colorata:_old_colorata_profile_mark("registration_start")
			_register_species_discovery(harvested_species_id,true,not story_old_seed)
			result_new_species_queue.append(harvested_species_id)
			if profiled_old_colorata:_old_colorata_profile_mark("registration_end")
		elif not already_pending_round_new:
			_register_species_discovery(harvested_species_id,true)
		elif endless_forced_new:
			endless_greenhouse.fail_forced_new(harvested_species_id)
	if is_record:
		bests[harvested_species_id]=harvested_diameter_cm
		if play_active and (play_share_record.is_empty() or harvested_diameter_cm>float(play_share_record.get("size",0.0))):play_share_record={"species_id":harvested_species_id,"size":harvested_diameter_cm}
		_evaluate_best_spawn_unlocks()
	var harvest_reward_units:=0
	if play_active and active_seed_type!="old":
		if not _is_endless_greenhouse_enabled():add_seed_pod_gauge_cm(harvested_diameter_cm,false,true)
		elif _is_endless_normal_play() and puku_gauge_intro_complete and not story_dev_101:
			harvest_reward_units=_harvest_puku_reward_units(harvested_diameter_cm,is_first_get_for_puku)
			_change_puku_balance(harvest_reward_units,"endless_harvest",false,true,harvested_screen_position)
			endless_economy_harvest_count+=1;endless_economy_max_harvest_cm=maxf(endless_economy_max_harvest_cm,harvested_diameter_cm)
	if play_active:StoryProgressionClass.record_greenhouse_harvest(story_progression_state,harvested_diameter_cm)
	_evaluate_unlock_rules("harvest_size",harvested_diameter_cm);_update_main_story_progress(false)
	if play_active:
		play_harvest_cm_total+=harvested_diameter_cm;play_puku_reward_units_total+=harvest_reward_units;play_harvest_count+=1;play_max_size=maxf(play_max_size,harvested_diameter_cm)
		if not story_old_seed and harvested_diameter_cm>play_previous_global_best:play_updated_global_best=true
		var notable=play_notable_species.get(harvested_species_id,{})
		if notable.is_empty() or harvested_diameter_cm>float(notable.get("size",0.0)):play_notable_species[harvested_species_id]={"name":Localizer.species_name(language_code,_catalog_entry(harvested_species_id)),"size":harvested_diameter_cm}
	if is_instance_valid(p) and active_seed_type!="old" and not terminal_first_tutorial_harvest:_show_harvest_result(p,harvest_reward_units)
	if is_instance_valid(p) and is_record:_show_record(p)
	if play_active and active_seed_type=="normal" and normal_play_tutorial_complete and not terminal_first_tutorial_harvest and not puku_buyback_tutorial_complete and not puku_buyback_tutorial_active:call_deferred("_start_puku_buyback_tutorial")
	if not restoration_snapshot.is_empty():
		var restoration:=_restoration_state()
		if HabitatRestorationClass.queue_pending_return_snapshot(restoration,restoration_snapshot):
			story_progression_state["restoration"]=restoration;_update_play_ui()
	if not story_old_seed:_save()
	_update_best_ui();_update_currency_ui();harvest_commit_count+=1
	if is_instance_valid(p):p.set_meta("harvest_state_committed",true);_cleanup_later(p,.68)

func _is_terminal_first_tutorial_plant(plant)->bool:
	if _is_endless_normal_play():return false
	return first_play_tutorial_active and not seed_pod_first_reward_seen and play_active and active_seed_type=="normal" and play_seeds_remaining==0 and play_spawn_queue==0 and play_seed_animations_pending==0 and plants.size()==1 and plants[0]==plant

func _on_jellied(p)->void:
	if bool(p.get_meta("catalog_preview",false)):_on_catalog_preview_jellied(p);return
	if _is_endless_normal_play():
		endless_economy_jelly_count+=1
		if bool(p.get_meta("endless_forced_new",false)):endless_greenhouse.fail_forced_new(str(p.data.get("species_id","")))
		_record_endless_discovery_settlement(false,0.0)
		_save()
	_maybe_activate_first_play_harvest_guide()
	_show_float(p,Localizer.text(language_code,"jelly_float"),Color("#e7c9f0"))
	audio_manager.play_se("jelly",.38)
	var tw:=create_tween();tw.tween_property(p,"scale",Vector3(p.scale.x*1.05,p.scale.y*.46,p.scale.z*1.05),.28).set_trans(Tween.TRANS_BOUNCE);tw.tween_interval(.25);tw.tween_property(p,"scale",Vector3.ONE*0.01,.38)
	_cleanup_later(p,1.0)

func _on_catalog_preview_harvested(p)->void:
	_show_float(p,Localizer.text(language_code,"preview_finished"),Color("#d9c9f0"))
	var tween:=create_tween().bind_node(p);tween.tween_property(p,"scale",Vector3.ONE*.01,.22)
	_cleanup_later(p,.25,false)

func _on_catalog_preview_jellied(p)->void:
	_show_float(p,Localizer.text(language_code,"preview_jelly"),Color("#e7c9f0"))
	var tween:=create_tween();tween.tween_property(p,"scale",Vector3(p.scale.x*1.05,p.scale.y*.46,p.scale.z*1.05),.28).set_trans(Tween.TRANS_BOUNCE);tween.tween_interval(.25);tween.tween_property(p,"scale",Vector3.ONE*.01,.38)
	_cleanup_later(p,1.0,false)

func _cleanup_later(p,delay:float,track_vacated:=true)->void:
	if track_vacated:
		recent_vacated_slots.append(p.original_pos)
		while recent_vacated_slots.size()>12:recent_vacated_slots.pop_front()
	plants.erase(p)
	if play_active and not dev_jelly_test_active:
		_queue_greenhouse_replacements();_update_play_ui()
		if play_seeds_remaining==0 and play_spawn_queue==0 and play_seed_animations_pending==0 and plants.is_empty():
			if not _queue_first_seed_pod_max_event():call_deferred("_finish_greenhouse_play")
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(p):p.label.queue_free();p.queue_free()

func _show_float(p,text:String,color:Color)->void:
	var l:=Label.new();l.text=text;l.size=Vector2(230,90);l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;l.add_theme_font_size_override("font_size",24);l.add_theme_color_override("font_color",color);l.add_theme_color_override("font_outline_color",UI_BROWN);l.add_theme_constant_override("outline_size",7);l.position=camera.unproject_position(p.global_position)-Vector2(115,40);effects_layer.add_child(l)
	var tw:=create_tween().bind_node(l).set_parallel();tw.tween_property(l,"position:y",l.position.y-85,.62).set_trans(Tween.TRANS_BACK);tw.tween_property(l,"modulate:a",0.0,.62).set_delay(.18);tw.chain().tween_callback(l.queue_free)

func _show_harvest_result(plant,reward_units:int)->void:
	var panel:=PanelContainer.new();panel.name="HarvestResult";panel.size=Vector2(220,142);panel.position=camera.unproject_position(plant.global_position)-Vector2(110,87);panel.pivot_offset=panel.size*.5;panel.scale=Vector2(.78,.78);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_theme_stylebox_override("panel",_box(Color(0.22,0.12,0.07,.92),Color("#f0cc82"),17,2));effects_layer.add_child(panel)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",0);content.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(content)
	var name_label:=Label.new();name_label.text=Localizer.species_name(language_code,plant.data);name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name_label.add_theme_font_size_override("font_size",20);name_label.add_theme_color_override("font_color",Color.WHITE);content.add_child(name_label)
	var size_label:=Label.new();size_label.name="HarvestSize";size_label.text=Localizer.text(language_code,"harvest_size",[_format_cm(plant.diameter_cm)]);size_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;size_label.add_theme_font_size_override("font_size",18);size_label.add_theme_color_override("font_color",Color.WHITE);content.add_child(size_label)
	var gauge_label:=Label.new();gauge_label.name="PukuRewardGain";gauge_label.text=Localizer.text(language_code,"harvest_puku_reward",[_format_puku_units(reward_units)]);gauge_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;gauge_label.add_theme_font_size_override("font_size",18);gauge_label.add_theme_color_override("font_color",UI_CREAM);gauge_label.visible=reward_units>0;content.add_child(gauge_label)
	var tween:=create_tween().bind_node(panel);tween.tween_property(panel,"scale",Vector2.ONE,.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);tween.tween_interval(1.12);tween.set_parallel(true);tween.tween_property(panel,"position:y",panel.position.y-34,.5).set_trans(Tween.TRANS_QUAD);tween.tween_property(panel,"modulate:a",0.0,.5);tween.set_parallel(false);tween.tween_callback(panel.queue_free)

func _show_record(p)->void:
	audio_manager.play_se("result_new_best",.5)
	record_text.text=Localizer.text(language_code,"endless_record_update" if _is_endless_normal_play() else "record_update",[p.diameter_cm]);record_card.visible=true;record_card.scale=Vector2(.72,.72);record_card.pivot_offset=record_card.size/2
	var tw:=create_tween();tw.tween_property(record_card,"scale",Vector2.ONE,.24).set_trans(Tween.TRANS_BACK);tw.tween_interval(2.2);tw.tween_property(record_card,"modulate:a",0.0,.25);tw.tween_callback(func():record_card.visible=false;record_card.modulate.a=1.0)

func _update_best_ui()->void:
	best_label.text=Localizer.text(language_code,"best_record",[_global_best_size()])

func _global_best_size()->float:
	var top:=0.0
	for value in bests.values():top=maxf(top,float(value))
	return top
