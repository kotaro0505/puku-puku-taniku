extends Node

signal rescue_reward_ad_requested(reward_context:String)

const SucculentClass = preload("res://scripts/succulent.gd")
const AudioManagerClass = preload("res://scripts/audio_manager.gd")
const PROGRESSION_VERSION := 3
const NORMAL_GERMINATION_COUNT := 24
const PREMIUM_GERMINATION_COUNT := 24
const OLD_SEED_GERMINATION_COUNT := 7
const PLAY_INITIAL_MIN_PLANTS := 9
const PLAY_INITIAL_MAX_PLANTS := 12
const SOIL_SOURCE_CENTER := Vector2(426.5,700.0)
const SOIL_SOURCE_RADII := Vector2(360.0,190.0)
const SPAWN_SPRITE_MARGIN_SOURCE_PX := 40.0
const GREENHOUSE_DRAG_SCALE := 0.30
const GREENHOUSE_DRAG_DEAD_ZONE := 3.0
const GREENHOUSE_PAN_FOLLOW_SECONDS := 0.075
const HABITAT_DRAG_SCALE := 0.055
const HABITAT_ITEM_RADIUS := 9.0
const HABITAT_BEST_LINK_EVENT_CM := 30.0
const RAIN_BONUS_DURATION_SECONDS := 60.0
const RAIN_INITIAL_PLANT_COUNT := 12
const RAIN_MAX_ACTIVE_PLANTS := 22
const RAIN_TRIGGER_CHANCES := [0.05,0.07,0.10,0.15,0.25,0.40,0.98]
const NORMAL_SEED_BAG_PRICE_YEN := 500
const PREMIUM_SEED_BAG_PRICE_YEN := 800
const RESCUE_REWARD_SEED_TYPE := "normal"
const RESCUE_REWARD_SEED_BAGS := 1
const REWARDED_AD_DEVELOPMENT_STUB_ENABLED := true
const SHOP_CHATTER_LINES := [
	"多肉を触ってみて柔らかくなっていたら水やりのタイミングだよ",
	"いらっしゃい！",
	"知ってる？食べられる多肉もあるんだって。",
	"今日はどんな多肉に出会えるかなあ。",
	"多肉を育ててると、よけいに季節を感じられるって思うんだ。",
	"多肉植物は水をあげすぎるとジュレるから気をつけてね！",
	"多肉植物栽培、慣れてきた？",
	"世界には数万種類の多肉植物があるらしいよ。すごいなあ。",
	"多肉の葉っぱを土に挿しておくと、根が出て増えるんだ。葉挿しって言うんだよ。",
	"アフィニスの花って真っ赤なんだって。見てみたいね！",
	"やあ！ゆっくり見てってよ。"
]
const HABITAT_SAFE_PLANT_POINTS := [Vector2(70,400),Vector2(155,410),Vector2(245,400),Vector2(335,420),Vector2(430,405),Vector2(535,415),Vector2(705,430),Vector2(820,410),Vector2(920,395),Vector2(1025,420),Vector2(1130,400),Vector2(1220,415)]
const RAIN_GROUND_REGIONS := [Rect2(12,350,225,220),Rect2(245,382,255,188),Rect2(505,405,140,165),Rect2(650,462,165,108),Rect2(820,405,225,165),Rect2(1050,350,218,220)]
const HABITAT_NEW_SPECIES_POINTS := [Vector2(640,385),Vector2(735,392),Vector2(545,388),Vector2(815,395),Vector2(465,392)]
const HABITAT_SAFE_SEED_POINTS := [Vector2(45,430),Vector2(115,445),Vector2(190,430),Vector2(275,445),Vector2(360,440),Vector2(455,435),Vector2(545,445),Vector2(625,455),Vector2(715,450),Vector2(805,440),Vector2(895,430),Vector2(980,445),Vector2(1060,435),Vector2(1140,445),Vector2(1210,435),Vector2(1260,455)]
const UI_CREAM := Color("#fff1d2")
const UI_BROWN := Color("#4a2618")
const UI_GOLD := Color("#e8aa35")

var rng := RandomNumberGenerator.new()
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
var habitat_env: WorldEnvironment
var habitat_environment: Environment
var habitat_items_root: Node3D
var habitat_pickups: Array = []
var habitat_new_species_id := ""
var pending_habitat_species: Array = []
var completed_unlock_conditions: Dictionary = {}
var unlock_rules: Array = []
var total_play_count := 0
var intro_story_complete := false
var encyclopedia_unlocked := false
var habitat_unlocked := false
var tutorial_steps: Dictionary = {}
var mode_button: Button
var shop_button: Button
var current_mode := "greenhouse"
var labels_layer: Control
var effects_layer: Control
var best_label: Label
var coin_label: Label
var record_card: PanelContainer
var record_text: Label
var encyclopedia_overlay: Control
var encyclopedia_list_page: Control
var encyclopedia_detail_page: Control
var encyclopedia_grid: GridContainer
var habitat_status_label: Label
var seed_bag_panel: PanelContainer
var play_timer_label: Label
var play_open_button: Button
var play_overlay: Control
var play_bag_summary: Label
var normal_play_button: Button
var premium_play_button: Button
var old_seed_play_button: Button
var shop_overlay: Control
var shop_wallet_label: Label
var shop_bag_label: Label
var shop_message: Label
var shop_premium_buy_button: Button
var shop_purchase_controls: Array[Control] = []
var shop_chatter_bubble: PanelContainer
var shop_chatter_label: Label
var shop_chatter_action_button: Button
var shop_chatter_tail: Polygon2D
var shop_chatter_tail_outline: Line2D
var last_shop_chatter := ""
var rescue_reward_in_progress := false
var intro_overlay: Control
var intro_dialog_panel: PanelContainer
var intro_dialogue_label: Label
var intro_continue_button: Button
var intro_speaker_label: Label
var intro_panda_portrait: TextureRect
var intro_story_step := 0
var intro_is_daily_gift := false
var tutorial_dialog_kind := ""
var tutorial_guide_overlay: Control
var tutorial_guide_button: Button
var tutorial_guide_finger: Label
var tutorial_guide_message: Label
var tutorial_panda_portrait: TextureRect
var tutorial_dialog_panel: PanelContainer
var tutorial_habitat_item: Dictionary = {}
var tutorial_harvest_plant: Node
var habitat_scroll_tutorial_active := false
var buyback_unlocked := false
var habitat_best_link_dialog_step := 0
var settings_overlay: Control
var audio_manager: Node
var audio_settings: Dictionary = {"bgm_enabled":true,"se_enabled":true,"bgm_volume":0.65,"se_volume":0.62}
var habitat_glow_tween: Tween
var habitat_sparkle: Label
var rain_visual: Control
var rain_drops: Array = []
var result_overlay: Control
var result_card: PanelContainer
var result_total_label: Label
var result_count_label: Label
var result_max_label: Label
var result_notable_label: Label
var result_confetti_layer: Control
var result_record_pulse_tween: Tween
var encyclopedia_icon_button: Button
var external_navigation_controls: Array[Control] = []
var encyclopedia_navigation_controls: Array[Control] = []
var coins := 1000
var bests: Dictionary = {}
var discovered: Dictionary = {}
var unlocked_species: Dictionary = {}
var greenhouse_available: Dictionary = {"colorata":true}
var habitat_seed_date := ""
var habitat_seeds_collected := 0
var normal_seed_bags := 0
var premium_seed_bags := 0
var old_seed_bags := 0
var login_bonus_date := ""
var play_active := false
var play_time_remaining := 0.0
var active_seed_type := "normal"
var play_modal_open := false
var play_earnings_total := 0
var play_harvest_count := 0
var play_max_size := 0.0
var play_previous_global_best := 0.0
var play_updated_global_best := false
var play_notable_species: Dictionary = {}
var current_target_count := NORMAL_GERMINATION_COUNT
var play_seeds_remaining := 0
var play_spawn_queue := 0
var play_seed_animations_pending := 0
var play_spawn_timer := 0.0
var play_concurrent_target := PLAY_INITIAL_MAX_PLANTS
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
var forced_golden_done := false
var view_yaw := 0.0
var view_pitch := -3.0
var habitat_target_yaw := 0.0
var habitat_target_pitch := -3.0
var pointer_down := false
var pointer_start := Vector2.ZERO
var pointer_last := Vector2.ZERO
var pointer_travel := 0.0
var greenhouse_drag_accumulator := 0.0
var greenhouse_drag_started := false

func _ready() -> void:
	rng.randomize()
	_load_species()
	_load_save()
	_apply_saved_unlocks()
	audio_manager=AudioManagerClass.new();add_child(audio_manager);audio_manager.apply_settings(audio_settings)
	_build_world()
	_build_ui()
	_build_habitat_items()
	get_viewport().size_changed.connect(_layout)
	_layout()
	_wire_ui_sounds(self)
	if not intro_story_complete:call_deferred("_start_intro_story")
	elif _daily_seed_gift_due():call_deferred("_start_daily_seed_gift")
	else:
		audio_manager.play_bgm("greenhouse")
		if total_play_count==0 and not bool(tutorial_steps.get("play_open_guide",false)):call_deferred("_show_tutorial_guide","play_open")

func _load_species() -> void:
	var raw := FileAccess.get_file_as_string("res://data/species-v2.json")
	var all_species: Array = JSON.parse_string(raw)
	catalog_species=all_species.duplicate(true)
	unlock_rules=JSON.parse_string(FileAccess.get_file_as_string("res://data/unlock-rules.json"))
	unlocked_species={"colorata":true}

func _load_save() -> void:
	if FileAccess.file_exists("user://records.json"):
		var value = JSON.parse_string(FileAccess.get_file_as_string("user://records.json"))
		if value is Dictionary:
			bests = value.get("bests",{}); coins = int(value.get("yen",value.get("coins",1000))); discovered=value.get("discovered",{"colorata":true});habitat_seed_date=str(value.get("habitat_seed_date",""));habitat_seeds_collected=int(value.get("habitat_seeds_collected",0))
			intro_story_complete=bool(value.get("intro_story_complete",false));total_play_count=int(value.get("total_play_count",0));completed_unlock_conditions=value.get("completed_unlock_conditions",{});pending_habitat_species=value.get("pending_habitat_species",[]);audio_settings=value.get("audio_settings",audio_settings)
			encyclopedia_unlocked=bool(value.get("encyclopedia_unlocked",intro_story_complete and (total_play_count>=1 or bool(discovered.get("colorata",false)))));habitat_unlocked=bool(value.get("habitat_unlocked",intro_story_complete and total_play_count>=3));tutorial_steps=value.get("tutorial_steps",{});old_seed_bags=int(value.get("old_seed_bags",0));buyback_unlocked=bool(value.get("buyback_unlocked",total_play_count>=4))
			rain_bag_count=maxi(0,int(value.get("rain_bag_count",0)));rain_event_pending=bool(value.get("rain_event_pending",false));rain_bonus_in_progress=bool(value.get("rain_bonus_in_progress",false));rain_time_remaining=clampf(float(value.get("rain_time_remaining",RAIN_BONUS_DURATION_SECONDS)),0.0,RAIN_BONUS_DURATION_SECONDS)
			rain_intro_normal_bags=maxi(0,int(value.get("rain_intro_normal_bags",0)));rain_draws_unlocked=bool(value.get("rain_draws_unlocked",total_play_count>3))
			if not rain_event_pending:rain_bonus_in_progress=false;rain_time_remaining=0.0
			if value.has("normal_seed_bags"):
				normal_seed_bags=int(value.get("normal_seed_bags",0));premium_seed_bags=int(value.get("premium_seed_bags",0));login_bonus_date=str(value.get("login_bonus_date",""))
			else:
				normal_seed_bags=0;premium_seed_bags=0;login_bonus_date=""
			# Legacy saves used unlocked_species for several meanings and could
			# contain the full catalog. Only the dedicated greenhouse list is
			# allowed to become a spawn source. Old saves safely restart from colorata.
			var saved_greenhouse=value.get("greenhouse_available",{"colorata":true})
			greenhouse_available={"colorata":true}
			if saved_greenhouse is Dictionary:
				for species_id in saved_greenhouse:
					if bool(saved_greenhouse[species_id]):greenhouse_available[str(species_id)]=true
			unlocked_species=greenhouse_available.duplicate(true)
			# Saves created before the encyclopedia already contain valid best sizes.
			for species_id in bests:
				if float(bests[species_id])>0.0:discovered[species_id]=true

func _save() -> void:
	var f := FileAccess.open("user://records.json",FileAccess.WRITE)
	if audio_manager:audio_settings=audio_manager.settings_dictionary()
	f.store_string(JSON.stringify({"progression_version":PROGRESSION_VERSION,"bests":bests,"discovered":discovered,"unlocked_species":unlocked_species,"greenhouse_available":greenhouse_available,"completed_unlock_conditions":completed_unlock_conditions,"pending_habitat_species":pending_habitat_species,"total_play_count":total_play_count,"intro_story_complete":intro_story_complete,"encyclopedia_unlocked":encyclopedia_unlocked,"habitat_unlocked":habitat_unlocked,"tutorial_steps":tutorial_steps,"old_seed_bags":old_seed_bags,"buyback_unlocked":buyback_unlocked,"habitat_seed_date":habitat_seed_date,"habitat_seeds_collected":habitat_seeds_collected,"normal_seed_bags":normal_seed_bags,"premium_seed_bags":premium_seed_bags,"login_bonus_date":login_bonus_date,"audio_settings":audio_settings,"rain_bag_count":rain_bag_count,"rain_event_pending":rain_event_pending,"rain_bonus_in_progress":rain_bonus_in_progress,"rain_time_remaining":rain_time_remaining,"rain_intro_normal_bags":rain_intro_normal_bags,"rain_draws_unlocked":rain_draws_unlocked,"yen":coins}))

func _daily_seed_gift_due()->bool:
	if not intro_story_complete:return false
	var today:=Time.get_date_string_from_system()
	if login_bonus_date.is_empty():login_bonus_date=today;_save();return false
	return login_bonus_date!=today

func _apply_saved_unlocks()->void:
	species.clear()
	for entry in catalog_species:
		var species_id:=str(entry.species_id)
		if bool(greenhouse_available.get(species_id,false)):species.append(entry)
	if species.is_empty():
		greenhouse_available={"colorata":true};unlocked_species=greenhouse_available.duplicate(true)
		for entry in catalog_species:
			if str(entry.species_id)=="colorata":species.append(entry);break

func _build_world() -> void:
	greenhouse_layer=CanvasLayer.new();greenhouse_layer.layer=-10;add_child(greenhouse_layer)
	greenhouse_backdrop=TextureRect.new();greenhouse_backdrop.texture=load("res://assets/greenhouse-main.jpg");greenhouse_backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;greenhouse_backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT;greenhouse_backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;greenhouse_layer.add_child(greenhouse_backdrop)
	world_root = Node3D.new(); add_child(world_root)
	habitat_env=WorldEnvironment.new(); var env:=Environment.new()
	var sky := Sky.new(); var panorama := PanoramaSkyMaterial.new()
	# The default 256px sky radiance map noticeably softens this 1280x640
	# panorama. 1024 keeps the source detail while remaining Web/mobile-safe.
	sky.radiance_size = Sky.RADIANCE_SIZE_1024
	panorama.panorama = load("res://assets/highland-panorama.jpg")
	sky.sky_material = panorama
	env.background_mode=Environment.BG_SKY; env.sky=sky; env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color=Color("#d6b98b"); env.ambient_light_energy=0.32
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	habitat_environment=env;habitat_env.environment=env; world_root.add_child(habitat_env)
	habitat_items_root=Node3D.new();habitat_items_root.visible=false;world_root.add_child(habitat_items_root)
	var sun:=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-18,72,0); sun.light_color=Color("#ffd9a0"); sun.light_energy=0.28; sun.shadow_enabled=false; world_root.add_child(sun)
	camera=Camera3D.new(); camera.fov=54.0; camera.current=true; world_root.add_child(camera)
	_build_greenhouse_pot()
	_apply_mode()

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
	effects_layer=Control.new(); effects_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); effects_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE; ui.add_child(effects_layer)
	var game_theme:=Theme.new();game_theme.default_font=load("res://assets/fonts/ZenMaruGothic-Bold.ttf") as Font;game_theme.default_font_size=16
	labels_layer.theme=game_theme;hud.theme=game_theme;effects_layer.theme=game_theme
	# logo
	var logo:=Label.new(); logo.text="ぷくぷく\n多 肉"; logo.position=Vector2(26,34); logo.size=Vector2(190,105); logo.add_theme_font_size_override("font_size",31); logo.add_theme_color_override("font_color",Color("#fff2d3")); logo.add_theme_color_override("font_outline_color",UI_BROWN); logo.add_theme_constant_override("outline_size",8); logo.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hud.add_child(logo)
	var ribbon:=Label.new(); ribbon.text=" PUKU PUKU TANIKU "; ribbon.position=Vector2(56,126); ribbon.add_theme_font_size_override("font_size",11); ribbon.add_theme_color_override("font_color",Color.WHITE); ribbon.add_theme_stylebox_override("normal",_box(Color("#d99a3c"),Color("#7b4a25"),12,2)); hud.add_child(ribbon)
	var best_panel:=PanelContainer.new(); best_panel.position=Vector2(204,54); best_panel.size=Vector2(168,66); best_panel.add_theme_stylebox_override("panel",_box(Color("#47261b"),Color("#f5c985"),16,2)); hud.add_child(best_panel)
	best_label=Label.new(); best_label.text="最高記録\n0.0 cm"; best_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; best_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; best_label.add_theme_font_size_override("font_size",17); best_label.add_theme_color_override("font_color",Color.WHITE); best_panel.add_child(best_label)
	var coin_panel:=PanelContainer.new(); coin_panel.position=Vector2(398,54); coin_panel.size=Vector2(153,53); coin_panel.add_theme_stylebox_override("panel",_box(Color("#55301d"),Color("#f1d19c"),22,2)); hud.add_child(coin_panel)
	coin_label=Label.new(); coin_label.text=" ¥%s" % _comma(coins); coin_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; coin_label.add_theme_font_size_override("font_size",20); coin_label.add_theme_color_override("font_color",Color("#ffd85b")); coin_panel.add_child(coin_label)
	for entry in [{"x":398,"t":"図鑑"},{"x":483,"t":"設定"}]:
		var b:=Button.new(); b.text=entry.t; b.position=Vector2(entry.x,116); b.size=Vector2(68,73); _skin_button(b,Color("#fff0cf"),17); hud.add_child(b)
		external_navigation_controls.append(b)
		if entry.t=="図鑑":encyclopedia_icon_button=b;encyclopedia_navigation_controls.append(b);b.mouse_filter=Control.MOUSE_FILTER_STOP;b.pressed.connect(_open_encyclopedia)
		else:b.pressed.connect(_open_settings)
	mode_button=Button.new();mode_button.text="原生地";mode_button.position=Vector2(398,198);mode_button.size=Vector2(153,55);_skin_button(mode_button,Color("#fff0cf"),16);mode_button.mouse_filter=Control.MOUSE_FILTER_STOP;mode_button.pressed.connect(_toggle_mode);hud.add_child(mode_button)
	external_navigation_controls.append(mode_button)
	shop_button=Button.new();shop_button.text="おみせ";shop_button.position=Vector2(398,262);shop_button.size=Vector2(153,55);_skin_button(shop_button,Color("#fff0cf"),16);shop_button.mouse_filter=Control.MOUSE_FILTER_STOP;shop_button.pressed.connect(_open_shop);hud.add_child(shop_button)
	external_navigation_controls.append(shop_button)
	habitat_status_label=Label.new();habitat_status_label.position=Vector2(163,42);habitat_status_label.size=Vector2(250,56);habitat_status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;habitat_status_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;habitat_status_label.add_theme_font_size_override("font_size",18);habitat_status_label.add_theme_color_override("font_color",UI_CREAM);habitat_status_label.add_theme_stylebox_override("normal",_box(Color("#4b2d20"),Color("#d8ad68"),18,2));habitat_status_label.visible=false;hud.add_child(habitat_status_label)
	seed_bag_panel=PanelContainer.new();seed_bag_panel.position=Vector2(210,125);seed_bag_panel.size=Vector2(156,92);seed_bag_panel.add_theme_stylebox_override("panel",_box(Color("#cda66a"),Color("#6f4325"),28,3));seed_bag_panel.visible=false;hud.add_child(seed_bag_panel)
	play_timer_label=Label.new();play_timer_label.text="● たね袋 ●\n残り 24粒";play_timer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;play_timer_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;play_timer_label.add_theme_font_size_override("font_size",20);play_timer_label.add_theme_color_override("font_color",Color("#4f2e1d"));play_timer_label.add_theme_color_override("font_outline_color",Color("#f4dbac"));play_timer_label.add_theme_constant_override("outline_size",2);seed_bag_panel.add_child(play_timer_label)
	play_open_button=Button.new();play_open_button.text="▶  たねをまく";play_open_button.position=Vector2(198,499);play_open_button.size=Vector2(180,58);_skin_button(play_open_button,Color("#8b5a35"),21);play_open_button.mouse_filter=Control.MOUSE_FILTER_STOP;play_open_button.pressed.connect(_open_play_modal);hud.add_child(play_open_button)
	record_card=PanelContainer.new(); record_card.position=Vector2(394,816); record_card.size=Vector2(164,134); record_card.add_theme_stylebox_override("panel",_box(Color("#674135"),Color("#f4d36e"),18,3)); record_card.visible=false; hud.add_child(record_card)
	record_text=Label.new(); record_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; record_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; record_text.add_theme_font_size_override("font_size",19); record_text.add_theme_color_override("font_color",Color.WHITE); record_card.add_child(record_text)
	_build_encyclopedia(hud)
	_build_play_overlay(hud)
	_build_shop(hud)
	_build_result_overlay(hud)
	_build_settings(hud)
	_build_intro_story(hud)
	_build_tutorial_guide(hud)
	_update_best_ui()
	_update_play_ui()

func _build_play_overlay(hud:Control)->void:
	play_overlay=Control.new();play_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);play_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;hud.add_child(play_overlay)
	var shade:=ColorRect.new();shade.color=Color(0.12,0.07,0.04,.42);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;play_overlay.add_child(shade)
	var panel:=PanelContainer.new();panel.position=Vector2(68,250);panel.size=Vector2(440,500);panel.mouse_filter=Control.MOUSE_FILTER_STOP;panel.add_theme_stylebox_override("panel",_box(Color("#f7e8c7"),Color("#9b642f"),26,4));play_overlay.add_child(panel)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",13);panel.add_child(content)
	var title:=Label.new();title.text="どのたねをまく？";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",24);title.add_theme_color_override("font_color",UI_BROWN);content.add_child(title)
	play_bag_summary=Label.new();play_bag_summary.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;play_bag_summary.add_theme_font_size_override("font_size",18);play_bag_summary.add_theme_color_override("font_color",Color("#70472d"));content.add_child(play_bag_summary)
	old_seed_play_button=Button.new();old_seed_play_button.custom_minimum_size=Vector2(350,68);_skin_button(old_seed_play_button,Color("#bba67d"),19);old_seed_play_button.pressed.connect(_start_greenhouse_play.bind("old"));content.add_child(old_seed_play_button)
	normal_play_button=Button.new();normal_play_button.custom_minimum_size=Vector2(350,76);_skin_button(normal_play_button,Color("#d9b56a"),20);normal_play_button.pressed.connect(_start_greenhouse_play.bind("normal"));content.add_child(normal_play_button)
	premium_play_button=Button.new();premium_play_button.custom_minimum_size=Vector2(350,76);_skin_button(premium_play_button,Color("#d18a55"),20);premium_play_button.pressed.connect(_start_greenhouse_play.bind("premium"));content.add_child(premium_play_button)
	var close:=Button.new();close.text="閉じる";close.custom_minimum_size=Vector2(250,44);_skin_button(close,Color("#ead8b1"),16);close.pressed.connect(_close_play_modal);content.add_child(close)

func _build_shop(hud:Control)->void:
	shop_overlay=Control.new();shop_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shop_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;shop_overlay.visible=false;hud.add_child(shop_overlay)
	var shop_texture:=load("res://assets/shop-background-final.jpg") as Texture2D
	var background:=TextureRect.new();background.texture=shop_texture;background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;background.stretch_mode=TextureRect.STRETCH_SCALE;background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.mouse_filter=Control.MOUSE_FILTER_STOP;background.gui_input.connect(_on_shop_background_gui_input);shop_overlay.add_child(background)
	var panda_tap:=Button.new();panda_tap.position=Vector2(190,405);panda_tap.size=Vector2(196,315);panda_tap.flat=true;panda_tap.focus_mode=Control.FOCUS_NONE;panda_tap.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND;panda_tap.pressed.connect(_on_shop_panda_tapped);shop_overlay.add_child(panda_tap)
	var close:=Button.new();close.text="もどる";close.position=Vector2(446,24);close.size=Vector2(106,55);_skin_button(close,Color("#fff0cf"),17);close.pressed.connect(_close_shop);shop_overlay.add_child(close)
	var purchase_panel:=PanelContainer.new();purchase_panel.position=Vector2(28,704);purchase_panel.size=Vector2(520,296);purchase_panel.add_theme_stylebox_override("panel",_box(Color(0.22,0.12,0.07,.93),Color("#d7aa64"),22,3));shop_overlay.add_child(purchase_panel)
	shop_wallet_label=Label.new();shop_wallet_label.position=Vector2(50,714);shop_wallet_label.size=Vector2(476,40);shop_wallet_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop_wallet_label.add_theme_font_size_override("font_size",21);shop_wallet_label.add_theme_color_override("font_color",Color("#ffd778"));shop_overlay.add_child(shop_wallet_label)
	shop_bag_label=Label.new();shop_bag_label.position=Vector2(50,752);shop_bag_label.size=Vector2(476,34);shop_bag_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop_bag_label.add_theme_font_size_override("font_size",16);shop_bag_label.add_theme_color_override("font_color",UI_CREAM);shop_overlay.add_child(shop_bag_label)
	var normal_buy:=Button.new();normal_buy.text="たね  1袋  500円";normal_buy.position=Vector2(62,797);normal_buy.size=Vector2(452,64);_skin_button(normal_buy,Color("#d8b56b"),20);normal_buy.pressed.connect(_buy_seed_bag.bind("normal"));shop_overlay.add_child(normal_buy)
	shop_premium_buy_button=Button.new();shop_premium_buy_button.position=Vector2(62,872);shop_premium_buy_button.size=Vector2(452,64);_skin_button(shop_premium_buy_button,Color("#d18a55"),20);shop_premium_buy_button.pressed.connect(_buy_seed_bag.bind("premium"));shop_overlay.add_child(shop_premium_buy_button)
	shop_message=Label.new();shop_message.position=Vector2(48,944);shop_message.size=Vector2(480,45);shop_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop_message.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;shop_message.add_theme_font_size_override("font_size",15);shop_message.add_theme_color_override("font_color",UI_CREAM);shop_overlay.add_child(shop_message)
	shop_purchase_controls=[purchase_panel,shop_wallet_label,shop_bag_label,normal_buy,shop_premium_buy_button,shop_message]
	shop_chatter_tail=Polygon2D.new();shop_chatter_tail.color=Color(1.0,.95,.82,.97);shop_chatter_tail.visible=false;shop_overlay.add_child(shop_chatter_tail)
	shop_chatter_tail_outline=Line2D.new();shop_chatter_tail_outline.default_color=Color("#9b6739");shop_chatter_tail_outline.width=3.0;shop_chatter_tail_outline.antialiased=true;shop_chatter_tail_outline.visible=false;shop_overlay.add_child(shop_chatter_tail_outline)
	shop_chatter_bubble=PanelContainer.new();shop_chatter_bubble.position=Vector2(88,110);shop_chatter_bubble.size=Vector2(400,108);shop_chatter_bubble.mouse_filter=Control.MOUSE_FILTER_STOP;shop_chatter_bubble.gui_input.connect(_on_shop_chatter_gui_input);shop_chatter_bubble.add_theme_stylebox_override("panel",_box(Color(1.0,.95,.82,.97),Color("#9b6739"),24,3));shop_chatter_bubble.visible=false;shop_overlay.add_child(shop_chatter_bubble)
	var chatter_content:=VBoxContainer.new();chatter_content.alignment=BoxContainer.ALIGNMENT_CENTER;chatter_content.add_theme_constant_override("separation",9);chatter_content.mouse_filter=Control.MOUSE_FILTER_PASS;shop_chatter_bubble.add_child(chatter_content)
	shop_chatter_label=Label.new();shop_chatter_label.custom_minimum_size=Vector2(220,64);shop_chatter_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shop_chatter_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;shop_chatter_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;shop_chatter_label.add_theme_font_size_override("font_size",18);shop_chatter_label.add_theme_color_override("font_color",UI_BROWN);shop_chatter_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;chatter_content.add_child(shop_chatter_label)
	shop_chatter_action_button=Button.new();shop_chatter_action_button.text="広告を見て種をもらう";shop_chatter_action_button.custom_minimum_size=Vector2(310,48);_skin_button(shop_chatter_action_button,Color("#d8b56b"),17);shop_chatter_action_button.pressed.connect(_request_rescue_reward_ad);shop_chatter_action_button.visible=false;chatter_content.add_child(shop_chatter_action_button)

func _set_shop_purchase_visible(is_visible:bool)->void:
	for control in shop_purchase_controls:
		if is_instance_valid(control):control.visible=is_visible

func _on_shop_panda_tapped()->void:
	if _shop_rescue_needed():
		_show_shop_chatter("種が買えなくて困ってる？\nちょっと待ってて。余ってるのがあるから、1袋持っていきなよ。",true)
		return
	_show_shop_chatter(_pick_shop_chatter(),false)

func _show_shop_chatter(message:String,is_rescue:bool)->void:
	shop_chatter_bubble.modulate=Color.WHITE;shop_chatter_bubble.visible=true;shop_chatter_label.text=message
	if is_rescue:
		shop_chatter_bubble.position=Vector2(22,86);shop_chatter_bubble.size=Vector2(420,250);shop_chatter_tail.visible=false;shop_chatter_tail_outline.visible=false
	else:
		var bubble_width:=clampf(210.0+message.length()*4.8,280.0,440.0);var bubble_height:=118.0 if message.length()>38 else 108.0
		shop_chatter_bubble.size=Vector2(bubble_width,bubble_height);shop_chatter_bubble.position=Vector2((576.0-bubble_width)*.5,110);_update_shop_chatter_tail()
	shop_chatter_action_button.visible=is_rescue;shop_chatter_action_button.disabled=rescue_reward_in_progress;shop_chatter_action_button.text="広告を準備中…" if rescue_reward_in_progress else "広告を見て種をもらう"

func _update_shop_chatter_tail()->void:
	var right:=shop_chatter_bubble.position.x+shop_chatter_bubble.size.x;var top:=shop_chatter_bubble.position.y;var height:=shop_chatter_bubble.size.y
	var base_top:=Vector2(right-5.0,top+height*.57);var base_bottom:=Vector2(right-5.0,top+height*.79);var tip:=Vector2(right-43.0,top+height+23.0)
	shop_chatter_tail.polygon=PackedVector2Array([base_top,tip,base_bottom]);shop_chatter_tail_outline.points=PackedVector2Array([base_top,tip,base_bottom]);shop_chatter_tail.visible=true;shop_chatter_tail_outline.visible=true

func _on_shop_background_gui_input(event:InputEvent)->void:
	if _shop_dismiss_pressed(event):_hide_shop_chatter()

func _on_shop_chatter_gui_input(event:InputEvent)->void:
	if _shop_dismiss_pressed(event):_hide_shop_chatter()

func _shop_dismiss_pressed(event:InputEvent)->bool:
	if event is InputEventMouseButton:return event.button_index==MOUSE_BUTTON_LEFT and event.pressed
	if event is InputEventScreenTouch:return event.pressed
	return false

func _hide_shop_chatter(force:=false)->void:
	if not shop_chatter_bubble.visible:return
	if shop_chatter_action_button.visible and not force:return
	shop_chatter_bubble.visible=false;shop_chatter_tail.visible=false;shop_chatter_tail_outline.visible=false;shop_chatter_bubble.modulate.a=1.0

func _pick_shop_chatter()->String:
	var date:=Time.get_date_dict_from_system();var month:=int(date.get("month",1));var day:=int(date.get("day",1));var japan:=_is_japan_region();var new_year:="あけましておめでとう！今年もよろしくね！"
	if japan and month==1 and day<=3 and last_shop_chatter!=new_year and rng.randf()<.68:
		last_shop_chatter=new_year
		return new_year
	var candidates:Array=SHOP_CHATTER_LINES.duplicate()
	if japan:
		if month==1 and day<=3:candidates.append(new_year)
		elif month==9:candidates.append("朝晩が涼しい日が増えてきたね。紅葉が楽しみだね！")
		elif month>=6 and month<=8:
			candidates.append("毎日暑いね。熱中症には気をつけてね！");candidates.append("夏の水やりは夕方から夜にやるといいよ！")
		elif month==12 or month<=2:candidates.append("毎日寒いけど多肉の色が賑やかな季節だね。")
		elif month>=3 and month<=5:candidates.append("だんだんと暖かい日が増えてきたね。多肉もどんどん育つね！")
	candidates.erase(last_shop_chatter)
	var chosen:=str(candidates[rng.randi_range(0,candidates.size()-1)]);last_shop_chatter=chosen;return chosen

func _is_japan_region()->bool:
	var locale:=TranslationServer.get_locale().replace("-","_").to_lower()
	return locale=="ja" or locale.begins_with("ja_") or locale.ends_with("_jp")

func _shop_rescue_needed()->bool:
	return old_seed_bags+normal_seed_bags+premium_seed_bags==0 and coins<NORMAL_SEED_BAG_PRICE_YEN

func _request_rescue_reward_ad()->void:
	if rescue_reward_in_progress or not _shop_rescue_needed():return
	rescue_reward_in_progress=true;shop_chatter_action_button.disabled=true;shop_chatter_action_button.text="広告を準備中…"
	if REWARDED_AD_DEVELOPMENT_STUB_ENABLED:
		await get_tree().create_timer(.65).timeout
		_on_rescue_reward_ad_completed(true)
	else:
		rescue_reward_ad_requested.emit("shop_seed_rescue")

func _on_rescue_reward_ad_completed(reward_earned:bool)->void:
	if not rescue_reward_in_progress:return
	rescue_reward_in_progress=false
	if not reward_earned:
		shop_chatter_action_button.disabled=false;shop_chatter_action_button.text="広告を見て種をもらう"
		return
	_grant_rescue_seed_bags();_save();_update_shop_ui();_update_play_ui();audio_manager.play_se("daily",.48)
	_show_shop_chatter("はい、どうぞ！大事にまいてみてね。",false)

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
	intro_panda_portrait=TextureRect.new();intro_panda_portrait.texture=_panda_portrait_texture();intro_panda_portrait.custom_minimum_size=Vector2(132,205);intro_panda_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;intro_panda_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;intro_panda_portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE;intro_panda_portrait.visible=false;dialog_row.add_child(intro_panda_portrait)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",12);content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;dialog_row.add_child(content)
	intro_speaker_label=Label.new();intro_speaker_label.text="パンダのたねや";intro_speaker_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;intro_speaker_label.add_theme_font_size_override("font_size",20);intro_speaker_label.add_theme_color_override("font_color",Color("#8b5528"));content.add_child(intro_speaker_label)
	intro_dialogue_label=Label.new();intro_dialogue_label.custom_minimum_size=Vector2(300,90);intro_dialogue_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;intro_dialogue_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;intro_dialogue_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;intro_dialogue_label.add_theme_font_size_override("font_size",20);intro_dialogue_label.add_theme_color_override("font_color",UI_BROWN);intro_dialogue_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_child(intro_dialogue_label)
	intro_continue_button=Button.new();intro_continue_button.text="つぎへ";intro_continue_button.custom_minimum_size=Vector2(250,55);_skin_button(intro_continue_button,Color("#d8b56b"),19);intro_continue_button.pressed.connect(_advance_intro_story);content.add_child(intro_continue_button)

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
	intro_is_daily_gift=false;tutorial_dialog_kind="";intro_story_step=0;current_mode="greenhouse";_apply_mode();_set_shop_purchase_visible(false);shop_overlay.visible=true;intro_overlay.visible=true;intro_panda_portrait.visible=false;_position_intro_dialog();intro_speaker_label.visible=true;play_overlay.visible=false;play_open_button.visible=false;audio_manager.play_bgm("shop");_advance_intro_story()

func _start_daily_seed_gift()->void:
	intro_is_daily_gift=true;current_mode="greenhouse";_apply_mode();_set_shop_purchase_visible(false);shop_overlay.visible=true;intro_overlay.visible=true;intro_panda_portrait.visible=false;_position_intro_dialog();intro_speaker_label.visible=true;play_overlay.visible=false;play_open_button.visible=false;audio_manager.play_bgm("shop")
	intro_dialogue_label.text="今日も来てくれてありがとう。\nたね袋 ×1 GET"
	intro_dialogue_label.add_theme_font_size_override("font_size",25);intro_dialogue_label.add_theme_color_override("font_color",Color("#b66d20"));intro_continue_button.text="温室へ"
	normal_seed_bags+=1;login_bonus_date=Time.get_date_string_from_system();_save();_show_intro_gift_effect();_update_play_ui()
	audio_manager.play_se("daily",.58)

func _advance_intro_story()->void:
	if tutorial_dialog_kind=="habitat_best_link" and habitat_best_link_dialog_step==0:
		habitat_best_link_dialog_step=1
		intro_dialogue_label.text="つまり、君が大きく育てれば育てるほど、ここにいる同じ品種も大きくなるってことだね。"
		intro_continue_button.text="わかった"
		return
	if not tutorial_dialog_kind.is_empty():
		var finished_kind:=tutorial_dialog_kind;tutorial_dialog_kind="";tutorial_steps[finished_kind+"_dialog"]=true;intro_overlay.visible=false;shop_overlay.visible=false;intro_speaker_label.visible=true;intro_dialogue_label.add_theme_font_size_override("font_size",20);intro_dialogue_label.add_theme_color_override("font_color",UI_BROWN);intro_continue_button.text="つぎへ";_save();_update_play_ui();audio_manager.play_bgm("habitat" if current_mode=="habitat" else "greenhouse")
		if finished_kind=="play1":_show_tutorial_guide("encyclopedia")
		elif finished_kind=="play3":_show_tutorial_guide("habitat")
		elif finished_kind=="habitat_scroll":habitat_scroll_tutorial_active=true
		elif finished_kind=="buyback":buyback_unlocked=true;tutorial_steps["buyback_unlocked"]=true;_save();_update_currency_ui()
		return
	if intro_is_daily_gift:
		intro_is_daily_gift=false;intro_overlay.visible=false;shop_overlay.visible=false;intro_speaker_label.visible=true;intro_dialogue_label.add_theme_font_size_override("font_size",20);intro_dialogue_label.add_theme_color_override("font_color",UI_BROWN);intro_continue_button.text="つぎへ";_update_play_ui();audio_manager.play_bgm("greenhouse");return
	intro_story_step+=1
	match intro_story_step:
		1:
			intro_speaker_label.visible=true
			intro_dialogue_label.text="こんにちは。売れ残った古いたねなんだけど…何のたねだったかな…。あげるからまいてみてよ！"
		2:
			intro_speaker_label.visible=false
			intro_dialogue_label.text="古いたね 3袋 GET"
			intro_dialogue_label.add_theme_font_size_override("font_size",29);intro_dialogue_label.add_theme_color_override("font_color",Color("#b66d20"));intro_continue_button.text="温室へ"
			_show_intro_gift_effect()
		_:
			intro_story_complete=true;old_seed_bags=3;login_bonus_date=Time.get_date_string_from_system();intro_overlay.visible=false;shop_overlay.visible=false;intro_speaker_label.visible=true;intro_dialogue_label.add_theme_font_size_override("font_size",20);intro_dialogue_label.add_theme_color_override("font_color",UI_BROWN);intro_continue_button.text="つぎへ";_save();_update_play_ui();audio_manager.play_bgm("greenhouse");_show_tutorial_guide("play_open")

func _start_post_play_dialog(kind:String)->void:
	tutorial_dialog_kind=kind;_set_shop_purchase_visible(false);shop_overlay.visible=true;intro_overlay.visible=true;intro_panda_portrait.visible=false;_position_intro_dialog();intro_speaker_label.visible=true;play_overlay.visible=false;play_open_button.visible=false;audio_manager.play_bgm("shop")
	if kind=="play1":intro_dialogue_label.text="育ったのはコロラータだったんだね！\n図鑑に登録しておいたよ。見てみよう。";intro_continue_button.text="図鑑を見る"
	elif kind=="play2":intro_dialogue_label.text="センスいいね！そうだ、今度一緒に多肉の原生地へ行こうよ。\n準備してくるからもう少し待ってね。";intro_continue_button.text="温室へ"
	else:intro_dialogue_label.text="準備できたよ！多肉の原生地へ行けるようになったよ。\n原生地を見に行ってみよう。";intro_continue_button.text="原生地へ"

func _start_habitat_scroll_tutorial()->void:
	tutorial_dialog_kind="habitat_scroll";intro_overlay.visible=true;intro_panda_portrait.visible=true;_position_intro_dialog();intro_speaker_label.visible=true;shop_overlay.visible=false;play_overlay.visible=false;play_open_button.visible=false
	intro_dialogue_label.text="指で画面をゆっくり左右に動かすと、原生地を見回せるよ。\n野生の多肉を探してみよう。";intro_continue_button.text="探してみる"

func _start_habitat_get_explanation()->void:
	tutorial_dialog_kind="habitat_get";intro_overlay.visible=true;intro_panda_portrait.visible=true;_position_intro_dialog();intro_speaker_label.visible=true;shop_overlay.visible=false;play_overlay.visible=false;play_open_button.visible=false
	intro_dialogue_label.text="見つけた多肉は図鑑に登録されたよ。\nこれからは、たねからもこの品種が育つようになるよ。";intro_continue_button.text="わかった"

func _start_habitat_best_link_dialog()->void:
	if bool(tutorial_steps.get("habitat_best_link_dialog",false)):return
	tutorial_dialog_kind="habitat_best_link";habitat_best_link_dialog_step=0;intro_overlay.visible=true;intro_panda_portrait.visible=true;_position_intro_dialog();intro_speaker_label.visible=true;shop_overlay.visible=false;play_overlay.visible=false;play_open_button.visible=false
	intro_dialogue_label.text="驚いたな。やっぱり間違いないよ。君が温室で育てた多肉の記録が、この原生地にも映ってるんだ。";intro_continue_button.text="つぎへ"

func _habitat_best_link_event_ready()->bool:
	if bool(tutorial_steps.get("habitat_best_link_dialog",false)) or not pending_habitat_species.is_empty():return false
	if not bool(tutorial_steps.get("habitat_scroll_dialog",false)):return false
	for best in bests.values():
		if float(best)>=HABITAT_BEST_LINK_EVENT_CM:return true
	return false

func _start_buyback_dialog()->void:
	if buyback_unlocked or bool(tutorial_steps.get("buyback_dialog",false)):return
	tutorial_dialog_kind="buyback";_set_shop_purchase_visible(false);shop_overlay.visible=true;intro_overlay.visible=true;intro_panda_portrait.visible=false;_position_intro_dialog();intro_speaker_label.visible=true;play_overlay.visible=false;play_open_button.visible=false;audio_manager.play_bgm("shop")
	intro_dialogue_label.text="育てた多肉、これからはうちで買い取るよ！\n大きく育てた株ほど高く買い取るからね。";intro_continue_button.text="わかった"

func _start_buyback_after_greenhouse_frame()->void:
	await get_tree().process_frame
	_start_buyback_dialog()

func _build_tutorial_guide(hud:Control)->void:
	tutorial_guide_overlay=Control.new();tutorial_guide_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);tutorial_guide_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;tutorial_guide_overlay.visible=false;hud.add_child(tutorial_guide_overlay)
	var shade:=ColorRect.new();shade.color=Color(0.05,0.035,0.025,.72);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;tutorial_guide_overlay.add_child(shade)
	tutorial_guide_button=Button.new();tutorial_guide_button.pivot_offset=Vector2(50,35);tutorial_guide_overlay.add_child(tutorial_guide_button)
	tutorial_guide_finger=Label.new();tutorial_guide_finger.text="☝";tutorial_guide_finger.add_theme_font_size_override("font_size",44);tutorial_guide_finger.add_theme_color_override("font_color",Color("#fff1b0"));tutorial_guide_finger.add_theme_color_override("font_outline_color",UI_BROWN);tutorial_guide_finger.add_theme_constant_override("outline_size",6);tutorial_guide_finger.mouse_filter=Control.MOUSE_FILTER_IGNORE;tutorial_guide_overlay.add_child(tutorial_guide_finger)
	tutorial_dialog_panel=PanelContainer.new();tutorial_dialog_panel.position=Vector2(40,790);tutorial_dialog_panel.size=Vector2(496,190);tutorial_dialog_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;tutorial_dialog_panel.add_theme_stylebox_override("panel",_box(Color(0.97,0.90,0.75,.97),Color("#a86f36"),24,4));tutorial_dialog_panel.visible=false;tutorial_guide_overlay.add_child(tutorial_dialog_panel)
	var tutorial_row:=HBoxContainer.new();tutorial_row.alignment=BoxContainer.ALIGNMENT_CENTER;tutorial_row.add_theme_constant_override("separation",12);tutorial_row.mouse_filter=Control.MOUSE_FILTER_IGNORE;tutorial_dialog_panel.add_child(tutorial_row)
	tutorial_panda_portrait=TextureRect.new();tutorial_panda_portrait.texture=_panda_portrait_texture();tutorial_panda_portrait.custom_minimum_size=Vector2(126,164);tutorial_panda_portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;tutorial_panda_portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;tutorial_panda_portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE;tutorial_row.add_child(tutorial_panda_portrait)
	tutorial_guide_message=Label.new();tutorial_guide_message.custom_minimum_size=Vector2(330,150);tutorial_guide_message.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tutorial_guide_message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;tutorial_guide_message.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;tutorial_guide_message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;tutorial_guide_message.add_theme_font_size_override("font_size",22);tutorial_guide_message.add_theme_color_override("font_color",UI_BROWN);tutorial_guide_message.mouse_filter=Control.MOUSE_FILTER_IGNORE;tutorial_row.add_child(tutorial_guide_message)

func _show_tutorial_guide(target:String)->void:
	var source:Button
	if target=="encyclopedia":source=encyclopedia_icon_button
	elif target=="habitat":source=mode_button
	elif target=="play_open":source=play_open_button
	elif target=="old_seed":source=old_seed_play_button
	else:return
	tutorial_guide_button.icon=null;tutorial_guide_button.expand_icon=false;tutorial_dialog_panel.visible=false
	tutorial_guide_button.position=source.global_position;tutorial_guide_button.size=source.size;tutorial_guide_button.text=source.text;tutorial_guide_button.set_meta("target",target);_skin_button(tutorial_guide_button,Color("#fff0cf"),17 if target=="encyclopedia" else 15)
	for connection in tutorial_guide_button.pressed.get_connections():tutorial_guide_button.pressed.disconnect(connection.callable)
	tutorial_guide_button.pressed.connect(_complete_tutorial_guide)
	tutorial_guide_finger.position=tutorial_guide_button.position+Vector2(-34,38);tutorial_guide_overlay.visible=true
	var tween:=create_tween().set_loops();tween.tween_property(tutorial_guide_button,"self_modulate",Color(1.25,1.18,.7,1),.55).set_trans(Tween.TRANS_SINE);tween.parallel().tween_property(tutorial_guide_finger,"position:y",tutorial_guide_finger.position.y-14,.55).set_trans(Tween.TRANS_SINE);tween.tween_property(tutorial_guide_button,"self_modulate",Color.WHITE,.55);tween.parallel().tween_property(tutorial_guide_finger,"position:y",tutorial_guide_finger.position.y,.55)

func _complete_tutorial_guide()->void:
	var target:=str(tutorial_guide_button.get_meta("target",""));tutorial_guide_overlay.visible=false;tutorial_steps[target+"_guide"]=true;_save()
	if target=="encyclopedia":_open_encyclopedia()
	elif target=="habitat":_toggle_mode()
	elif target=="play_open":_open_play_modal();call_deferred("_show_tutorial_guide","old_seed")
	elif target=="old_seed":_start_greenhouse_play("old")
	elif target=="first_harvest" and is_instance_valid(tutorial_harvest_plant):tutorial_harvest_plant.harvest()
	elif target=="habitat_species" and not tutorial_habitat_item.is_empty():_collect_habitat_species(tutorial_habitat_item)

func _show_first_harvest_guide_when_ready()->void:
	if bool(tutorial_steps.get("first_harvest_guide",false)):return
	for frame in range(120):
		await get_tree().process_frame
		if not play_active:return
		for plant in plants:
			if is_instance_valid(plant) and plant.state=="growing":
				_show_first_harvest_guide(plant)
				return

func _show_first_harvest_guide(plant)->void:
	tutorial_harvest_plant=plant
	var screen:=camera.unproject_position(plant.global_position)
	tutorial_guide_button.position=screen-Vector2(66,66);tutorial_guide_button.size=Vector2(132,132);tutorial_guide_button.text="";tutorial_guide_button.icon=plant.plant_sprite.texture;tutorial_guide_button.expand_icon=true;tutorial_guide_button.set_meta("target","first_harvest");_skin_button(tutorial_guide_button,Color(0.25,0.18,0.08,.35),16)
	for connection in tutorial_guide_button.pressed.get_connections():tutorial_guide_button.pressed.disconnect(connection.callable)
	tutorial_guide_button.pressed.connect(_complete_tutorial_guide);tutorial_guide_message.text="育った多肉をタップして収穫しよう";tutorial_dialog_panel.visible=true;_position_tutorial_dialog(Rect2(tutorial_guide_button.position,tutorial_guide_button.size));tutorial_guide_finger.position=tutorial_guide_button.position+Vector2(-35,70);tutorial_guide_overlay.visible=true
	var tween:=create_tween().set_loops();tween.tween_property(tutorial_guide_button,"self_modulate",Color(1.3,1.18,.72,1),.55).set_trans(Tween.TRANS_SINE);tween.parallel().tween_property(tutorial_guide_finger,"position:y",tutorial_guide_finger.position.y-14,.55);tween.tween_property(tutorial_guide_button,"self_modulate",Color.WHITE,.55);tween.parallel().tween_property(tutorial_guide_finger,"position:y",tutorial_guide_finger.position.y,.55)

func _show_habitat_species_guide(item:Dictionary,species_name:String)->void:
	tutorial_habitat_item=item;var node:Node3D=item.node;var screen:=camera.unproject_position(node.global_position)
	tutorial_guide_button.position=screen-Vector2(66,66);tutorial_guide_button.size=Vector2(132,132);tutorial_guide_button.text="";tutorial_guide_button.icon=node.texture;tutorial_guide_button.expand_icon=true;tutorial_guide_button.set_meta("target","habitat_species");_skin_button(tutorial_guide_button,Color(0.25,0.18,0.08,.35),16)
	for connection in tutorial_guide_button.pressed.get_connections():tutorial_guide_button.pressed.disconnect(connection.callable)
	tutorial_guide_button.pressed.connect(_complete_tutorial_guide);tutorial_guide_message.text="あ、あそこに野生の%sが生えているよ！"%species_name;tutorial_dialog_panel.visible=true;_position_tutorial_dialog(Rect2(tutorial_guide_button.position,tutorial_guide_button.size));tutorial_guide_finger.position=tutorial_guide_button.position+Vector2(-35,70);tutorial_guide_overlay.visible=true
	var tween:=create_tween().set_loops();tween.tween_property(tutorial_guide_button,"self_modulate",Color(1.35,1.22,.65,1),.55).set_trans(Tween.TRANS_SINE);tween.parallel().tween_property(tutorial_guide_finger,"position:y",tutorial_guide_finger.position.y-14,.55);tween.tween_property(tutorial_guide_button,"self_modulate",Color.WHITE,.55);tween.parallel().tween_property(tutorial_guide_finger,"position:y",tutorial_guide_finger.position.y,.55)

func _show_intro_gift_effect()->void:
	for i in range(7):
		var mote:=Label.new();mote.text="❧" if i%2==0 else "✦";mote.position=Vector2(245+rng.randf_range(-55,55),730+rng.randf_range(-15,25));mote.add_theme_font_size_override("font_size",18+rng.randi_range(0,7));mote.add_theme_color_override("font_color",Color("#f4ca58") if i%2 else Color("#8dad64"));effects_layer.add_child(mote)
		var tween:=create_tween().set_parallel();tween.tween_property(mote,"position",mote.position+Vector2(rng.randf_range(-80,80),rng.randf_range(-150,-90)),.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);tween.tween_property(mote,"modulate:a",0.0,.75).set_delay(.2);tween.chain().tween_callback(mote.queue_free)

func _build_settings(hud:Control)->void:
	settings_overlay=Control.new();settings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);settings_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;settings_overlay.visible=false;hud.add_child(settings_overlay)
	var shade:=ColorRect.new();shade.color=Color(0.12,0.07,0.04,.68);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;settings_overlay.add_child(shade)
	var panel:=PanelContainer.new();panel.position=Vector2(58,180);panel.size=Vector2(460,650);panel.add_theme_stylebox_override("panel",_box(Color("#f7e8c7"),Color("#9b642f"),26,4));settings_overlay.add_child(panel)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",18);panel.add_child(content)
	var title:=Label.new();title.text="設定";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",30);title.add_theme_color_override("font_color",UI_BROWN);content.add_child(title)
	_add_audio_setting_controls(content,"BGM",true)
	_add_audio_setting_controls(content,"効果音",false)
	var note:=Label.new();note.text="音源はモード・効果ごとに後から差し替えできます";note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;note.add_theme_font_size_override("font_size",14);note.add_theme_color_override("font_color",Color("#76513b"));content.add_child(note)
	var reset:=Button.new();reset.text="開発用：進行を初期状態へ戻す";reset.custom_minimum_size=Vector2(370,58);_skin_button(reset,Color("#d9c49d"),16);reset.pressed.connect(_reset_progression_for_development.bind(reset));content.add_child(reset)
	var close:=Button.new();close.text="閉じる";close.custom_minimum_size=Vector2(280,55);_skin_button(close,Color("#ead8b1"),18);close.pressed.connect(_close_settings);content.add_child(close)

func _add_audio_setting_controls(parent:VBoxContainer,label_text:String,is_bgm:bool)->void:
	var row:=HBoxContainer.new();row.alignment=BoxContainer.ALIGNMENT_CENTER;row.add_theme_constant_override("separation",12);parent.add_child(row)
	var toggle:=CheckButton.new();toggle.text=label_text+" ON";toggle.button_pressed=bool(audio_settings.get("bgm_enabled" if is_bgm else "se_enabled",true));toggle.custom_minimum_size=Vector2(145,48);row.add_child(toggle)
	var slider:=HSlider.new();slider.min_value=0;slider.max_value=100;slider.step=1;slider.value=float(audio_settings.get("bgm_volume" if is_bgm else "se_volume",.65)) * 100.0;slider.custom_minimum_size=Vector2(210,48);row.add_child(slider)
	toggle.toggled.connect(_change_audio_enabled.bind(is_bgm));slider.value_changed.connect(_change_audio_volume.bind(is_bgm))

func _open_settings()->void:
	settings_overlay.visible=true;_update_play_ui()

func _close_settings()->void:
	settings_overlay.visible=false;_save();_update_play_ui()

func _change_audio_enabled(enabled:bool,is_bgm:bool)->void:
	audio_settings["bgm_enabled" if is_bgm else "se_enabled"]=enabled;audio_manager.apply_settings(audio_settings);_save()

func _change_audio_volume(value:float,is_bgm:bool)->void:
	audio_settings["bgm_volume" if is_bgm else "se_volume"]=value/100.0;audio_manager.apply_settings(audio_settings);_save()

func _reset_progression_state()->void:
	coins=1000;bests.clear();discovered.clear();greenhouse_available={"colorata":true};unlocked_species=greenhouse_available.duplicate(true);completed_unlock_conditions.clear();pending_habitat_species.clear();total_play_count=0;intro_story_complete=false;encyclopedia_unlocked=false;habitat_unlocked=false;buyback_unlocked=false;tutorial_steps.clear();normal_seed_bags=0;premium_seed_bags=0;old_seed_bags=0;login_bonus_date="";habitat_seed_date="";habitat_seeds_collected=0;opening_species.clear();play_active=false;play_time_remaining=0.0;current_target_count=NORMAL_GERMINATION_COUNT;play_seeds_remaining=0;play_spawn_queue=0;play_seed_animations_pending=0;play_spawn_timer=0.0;play_concurrent_target=PLAY_INITIAL_MAX_PLANTS;rain_bag_count=0;rain_event_pending=false;rain_bonus_in_progress=false;rain_bonus_active=false;rain_time_remaining=0.0;rain_spawn_queue=0;rain_spawn_timer=0.0;rain_last_saved_second=-1;rain_intro_normal_bags=0;rain_draws_unlocked=false;habitat_scroll_tutorial_active=false;habitat_best_link_dialog_step=0;tutorial_habitat_item.clear();_stop_rain_visual();_apply_saved_unlocks();_clear_greenhouse_plants();_build_habitat_items();_save();_update_currency_ui();_update_play_ui()

func _reset_progression_for_development(button:Button)->void:
	_reset_progression_state();button.text="リセットしました（再読み込みしてください）"

func _build_result_overlay(hud:Control)->void:
	result_overlay=Control.new();result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);result_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;result_overlay.visible=false;hud.add_child(result_overlay)
	var shade:=ColorRect.new();shade.color=Color(0.08,0.05,0.035,.68);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;result_overlay.add_child(shade)
	result_card=PanelContainer.new();result_card.position=Vector2(54,205);result_card.size=Vector2(468,610);result_card.clip_contents=true;result_card.add_theme_stylebox_override("panel",_box(Color("#f7e8c7"),Color("#c8944f"),28,4));result_overlay.add_child(result_card)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",15);result_card.add_child(content)
	var title:=Label.new();title.text="今回の収穫";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_font_size_override("font_size",30);title.add_theme_color_override("font_color",UI_BROWN);content.add_child(title)
	result_total_label=Label.new();result_total_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;result_total_label.add_theme_font_size_override("font_size",34);result_total_label.add_theme_color_override("font_color",Color("#b06c24"));content.add_child(result_total_label)
	result_count_label=_result_line_label();content.add_child(result_count_label)
	result_max_label=_result_line_label();content.add_child(result_max_label)
	var divider:=HSeparator.new();divider.custom_minimum_size=Vector2(380,10);content.add_child(divider)
	var notable_title:=Label.new();notable_title.text="目立った収穫株";notable_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;notable_title.add_theme_font_size_override("font_size",19);notable_title.add_theme_color_override("font_color",Color("#725039"));content.add_child(notable_title)
	result_notable_label=Label.new();result_notable_label.custom_minimum_size=Vector2(390,112);result_notable_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;result_notable_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;result_notable_label.add_theme_font_size_override("font_size",18);result_notable_label.add_theme_color_override("font_color",UI_BROWN);content.add_child(result_notable_label)
	var close:=Button.new();close.text="閉じる / 戻る";close.custom_minimum_size=Vector2(350,54);_skin_button(close,Color("#ead8b1"),17);close.pressed.connect(_close_result);content.add_child(close)
	result_confetti_layer=Control.new();result_confetti_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);result_confetti_layer.mouse_filter=Control.MOUSE_FILTER_IGNORE;result_overlay.add_child(result_confetti_layer)

func _result_line_label()->Label:
	var label:=Label.new();label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",21);label.add_theme_color_override("font_color",Color("#65432e"));return label

func _clear_result_confetti()->void:
	if result_record_pulse_tween and result_record_pulse_tween.is_valid():result_record_pulse_tween.kill()
	result_record_pulse_tween=null
	if result_max_label:result_max_label.scale=Vector2.ONE
	if not result_confetti_layer:return
	for piece in result_confetti_layer.get_children():piece.queue_free()

func _play_result_confetti()->void:
	_clear_result_confetti()
	var colors:=[Color("#c98758"),Color("#d8b66a"),Color("#91a982"),Color("#c98b83"),Color("#e5d3a1")]
	for i in range(40):
		var piece:=ColorRect.new();piece.color=colors[rng.randi_range(0,colors.size()-1)];piece.color.a=.88;piece.size=Vector2(rng.randf_range(4.0,7.0),rng.randf_range(8.0,13.0));piece.position=Vector2(rng.randf_range(64.0,512.0),rng.randf_range(-65.0,115.0));piece.rotation=rng.randf_range(-1.0,1.0);piece.mouse_filter=Control.MOUSE_FILTER_IGNORE;result_confetti_layer.add_child(piece)
		var destination:=piece.position+Vector2(rng.randf_range(-34.0,34.0),rng.randf_range(500.0,710.0));var duration:=rng.randf_range(2.8,4.0)
		var tween:=create_tween().set_parallel();tween.tween_property(piece,"position",destination,duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN);tween.tween_property(piece,"rotation",piece.rotation+rng.randf_range(2.0,5.0),duration);tween.tween_property(piece,"modulate:a",0.0,.7).set_delay(duration-.7);tween.chain().tween_callback(piece.queue_free)

func _start_result_record_pulse()->void:
	result_max_label.pivot_offset=result_max_label.size*.5;result_max_label.scale=Vector2.ONE
	result_record_pulse_tween=create_tween().set_loops();result_record_pulse_tween.tween_property(result_max_label,"scale",Vector2(1.10,1.10),.52).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT);result_record_pulse_tween.tween_property(result_max_label,"scale",Vector2.ONE,.52).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _open_play_modal()->void:
	if play_active or current_mode!="greenhouse":return
	play_modal_open=true;_update_play_ui()

func _close_play_modal()->void:
	play_modal_open=false;_update_play_ui()

func _start_greenhouse_play(seed_type:String)->void:
	if play_active:return
	if seed_type=="old":
		if old_seed_bags<1:return
		old_seed_bags-=1;current_target_count=OLD_SEED_GERMINATION_COUNT
	elif seed_type=="premium":
		if not _premium_seed_unlocked():return
		if premium_seed_bags<1:return
		premium_seed_bags-=1;current_target_count=PREMIUM_GERMINATION_COUNT
	else:
		if normal_seed_bags<1:return
		normal_seed_bags-=1;current_target_count=NORMAL_GERMINATION_COUNT
	active_seed_type=seed_type;play_time_remaining=0.0;play_active=true;play_modal_open=false;play_earnings_total=0;play_harvest_count=0;play_max_size=0.0;play_previous_global_best=_global_best_size();play_updated_global_best=false;play_notable_species.clear();opening_species.clear();play_seeds_remaining=current_target_count;play_spawn_queue=0;play_seed_animations_pending=0;play_spawn_timer=0.0;play_concurrent_target=OLD_SEED_GERMINATION_COUNT if seed_type=="old" else rng.randi_range(PLAY_INITIAL_MIN_PLANTS,PLAY_INITIAL_MAX_PLANTS);_clear_greenhouse_plants()
	if result_overlay:result_overlay.visible=false
	for i in range(play_concurrent_target):_spawn_greenhouse_seed()
	if total_play_count==0 and not bool(tutorial_steps.get("first_harvest_guide",false)):call_deferred("_show_first_harvest_guide_when_ready")
	audio_manager.play_se("rare_seed" if seed_type=="premium" else "seed_bag",.72)
	_save();_update_play_ui()

func _finish_greenhouse_play()->void:
	if not play_active or rain_bonus_active or play_seeds_remaining>0 or play_spawn_queue>0 or play_seed_animations_pending>0 or not plants.is_empty():return
	play_active=false;play_time_remaining=0.0;play_spawn_timer=0.0;total_play_count+=1
	if total_play_count==1:discovered["colorata"]=true;encyclopedia_unlocked=true
	if total_play_count>=3:habitat_unlocked=true
	if total_play_count==3 and not bool(tutorial_steps.get("habitat_species_queued",false)):
		if pending_habitat_species.is_empty():_queue_random_species("通常")
		tutorial_steps["habitat_species_queued"]=true
	_evaluate_unlock_rules("play_count",float(total_play_count));_roll_rain_event();_clear_greenhouse_plants();_save();_update_play_ui();_show_play_result();audio_manager.play_se("result",.7)

func _clear_greenhouse_plants()->void:
	for plant in plants.duplicate():
		if is_instance_valid(plant):
			if plant.label and is_instance_valid(plant.label):plant.label.free()
			plant.free()
	plants.clear();recent_vacated_slots.clear();pending_seed_positions.clear()

func _update_play_ui()->void:
	if not play_overlay:return
	play_overlay.visible=current_mode=="greenhouse" and not play_active and play_modal_open
	play_open_button.visible=current_mode=="greenhouse" and intro_story_complete and not play_active and not play_modal_open and (not result_overlay or not result_overlay.visible) and (not shop_overlay or not shop_overlay.visible) and (not encyclopedia_overlay or not encyclopedia_overlay.visible) and (not settings_overlay or not settings_overlay.visible)
	seed_bag_panel.visible=current_mode=="greenhouse" and play_active and not rain_bonus_active and active_seed_type!="old"
	play_timer_label.visible=seed_bag_panel.visible
	for control in external_navigation_controls:control.visible=not play_active
	for control in encyclopedia_navigation_controls:control.visible=not play_active and encyclopedia_unlocked
	if mode_button:mode_button.visible=not play_active and habitat_unlocked
	if shop_button:shop_button.visible=not play_active and current_mode=="greenhouse"
	play_timer_label.text="● たね袋 ●\n残り %d粒"%play_seeds_remaining if play_timer_label.visible else ""
	var held:Array[String]=[]
	if old_seed_bags>0:held.append("古いたね %d袋"%old_seed_bags)
	if normal_seed_bags>0:held.append("たね %d袋"%normal_seed_bags)
	if premium_seed_bags>0 and _premium_seed_unlocked():held.append("プレミアムたね %d袋"%premium_seed_bags)
	play_bag_summary.text="　".join(held)
	old_seed_play_button.visible=old_seed_bags>0;old_seed_play_button.text="古いたねをまく　7粒　残り%d袋"%old_seed_bags
	normal_play_button.visible=normal_seed_bags>0;normal_play_button.text="たねをまく　24粒　残り%d袋"%normal_seed_bags;normal_play_button.disabled=normal_seed_bags<1
	premium_play_button.visible=premium_seed_bags>0 and _premium_seed_unlocked();premium_play_button.text="プレミアムたねをまく　24粒　残り%d袋"%premium_seed_bags;premium_play_button.disabled=not _premium_seed_unlocked() or premium_seed_bags<1

func _open_shop()->void:
	play_modal_open=false;_set_shop_purchase_visible(true);_update_shop_ui();shop_message.text="たね袋を1袋ずつ購入できます";play_overlay.visible=false;shop_chatter_bubble.visible=false;shop_chatter_tail.visible=false;shop_chatter_tail_outline.visible=false;shop_overlay.visible=true;audio_manager.play_bgm("shop");_update_play_ui()

func _close_shop()->void:
	_hide_shop_chatter(true);shop_overlay.visible=false;audio_manager.play_bgm("greenhouse" if current_mode=="greenhouse" else "habitat");_update_play_ui()

func _buy_seed_bag(seed_type:String)->void:
	if seed_type=="premium" and not _premium_seed_unlocked():shop_message.text="レア種を1種発見すると解放";return
	var price:=PREMIUM_SEED_BAG_PRICE_YEN if seed_type=="premium" else NORMAL_SEED_BAG_PRICE_YEN
	if coins<price:shop_message.text="所持金が足りません";return
	coins-=price
	if seed_type=="premium":premium_seed_bags+=1;shop_message.text="プレミアムたねを1袋購入しました"
	else:normal_seed_bags+=1;shop_message.text="たねを1袋購入しました"
	audio_manager.play_se("purchase",.48);_save();_update_currency_ui();_update_shop_ui();_update_play_ui()

func _update_shop_ui()->void:
	if not shop_wallet_label:return
	shop_wallet_label.text="所持金　¥%s"%_comma(coins);shop_bag_label.text="たね %d袋　｜　プレミアムたね %d袋"%[normal_seed_bags,premium_seed_bags]
	var premium_ok:=_premium_seed_unlocked();shop_premium_buy_button.text="プレミアムたね  1袋  800円" if premium_ok else "レア種を1種発見すると解放";shop_premium_buy_button.disabled=not premium_ok

func _premium_seed_unlocked()->bool:
	for entry in catalog_species:
		if not bool(discovered.get(str(entry.species_id),false)):continue
		if str(entry.get("rarity","通常")) in ["レア","スーパーレア"]:return true
	return false

func _update_currency_ui()->void:
	if coin_label:coin_label.text=" ¥%s"%_comma(coins)

func _show_play_result()->void:
	result_total_label.visible=buyback_unlocked
	result_total_label.text="合計  ＋¥%s"%_comma(play_earnings_total);result_count_label.text="収穫株数　%d株"%play_harvest_count
	result_max_label.remove_theme_color_override("font_outline_color");result_max_label.remove_theme_constant_override("outline_size")
	if play_updated_global_best:
		result_max_label.text="最大サイズ更新！\n%.1fcm"%play_max_size;result_max_label.add_theme_font_size_override("font_size",30);result_max_label.add_theme_color_override("font_color",Color("#b83b32"));result_max_label.add_theme_color_override("font_outline_color",Color("#f8e8c8"));result_max_label.add_theme_constant_override("outline_size",3);_play_result_confetti();call_deferred("_start_result_record_pulse");audio_manager.play_se("result_new_best",.48)
	else:
		result_max_label.text="最大サイズ　%.1fcm"%play_max_size;result_max_label.add_theme_font_size_override("font_size",21);result_max_label.add_theme_color_override("font_color",Color("#65432e"));_clear_result_confetti()
	var notable:Array=play_notable_species.values();notable.sort_custom(func(a,b):return float(a.get("size",0.0))>float(b.get("size",0.0)));var lines:Array[String]=[]
	for i in range(mini(3,notable.size())):lines.append("%s　%.1fcm"%[str(notable[i].get("name","")),float(notable[i].get("size",0.0))])
	result_notable_label.text="\n".join(lines) if not lines.is_empty() else "今回はまだありません"
	if rain_event_pending:result_notable_label.text+="\n\n☂ 原生地に恵みの雨が降っています"
	result_overlay.visible=true;result_overlay.modulate.a=0.0;result_card.position.y=225.0;play_open_button.visible=false
	var tween:=create_tween().set_parallel();tween.tween_property(result_overlay,"modulate:a",1.0,.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);tween.tween_property(result_card,"position:y",205.0,.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _close_result()->void:
	result_overlay.visible=false;result_overlay.modulate.a=1.0;_clear_result_confetti();_update_play_ui()
	if total_play_count==1 and not bool(tutorial_steps.get("play1_dialog",false)):_start_post_play_dialog("play1")
	elif total_play_count==2 and not bool(tutorial_steps.get("play2_dialog",false)):_start_post_play_dialog("play2")
	elif total_play_count==3 and not bool(tutorial_steps.get("play3_dialog",false)):_start_post_play_dialog("play3")

func _build_encyclopedia(hud:Control)->void:
	encyclopedia_overlay=Control.new();encyclopedia_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);encyclopedia_overlay.mouse_filter=Control.MOUSE_FILTER_STOP;encyclopedia_overlay.visible=false;hud.add_child(encyclopedia_overlay)
	var background:=ColorRect.new();background.color=Color("#3d2419");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.mouse_filter=Control.MOUSE_FILTER_STOP;encyclopedia_overlay.add_child(background)
	encyclopedia_list_page=Control.new();encyclopedia_list_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);encyclopedia_overlay.add_child(encyclopedia_list_page)
	var title:=Label.new();title.text="ぷくぷく図鑑";title.position=Vector2(28,28);title.size=Vector2(390,65);title.add_theme_font_size_override("font_size",31);title.add_theme_color_override("font_color",UI_CREAM);encyclopedia_list_page.add_child(title)
	var close:=Button.new();close.text="もどる";close.position=Vector2(447,27);close.size=Vector2(105,55);_skin_button(close,Color("#fff0cf"),17);close.pressed.connect(_close_encyclopedia);encyclopedia_list_page.add_child(close)
	var scroll:=ScrollContainer.new();scroll.position=Vector2(20,105);scroll.size=Vector2(536,890);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;encyclopedia_list_page.add_child(scroll)
	encyclopedia_grid=GridContainer.new();encyclopedia_grid.columns=2;encyclopedia_grid.custom_minimum_size=Vector2(516,0);encyclopedia_grid.add_theme_constant_override("h_separation",12);encyclopedia_grid.add_theme_constant_override("v_separation",14);scroll.add_child(encyclopedia_grid)
	encyclopedia_detail_page=Control.new();encyclopedia_detail_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);encyclopedia_detail_page.visible=false;encyclopedia_overlay.add_child(encyclopedia_detail_page)

func _open_encyclopedia()->void:
	if not encyclopedia_unlocked:return
	play_modal_open=false;_refresh_encyclopedia_cards();encyclopedia_detail_page.visible=false;encyclopedia_list_page.visible=true;play_overlay.visible=false;encyclopedia_overlay.visible=true;_update_play_ui()

func _close_encyclopedia()->void:
	encyclopedia_overlay.visible=false;_update_play_ui()

func _refresh_encyclopedia_cards()->void:
	for child in encyclopedia_grid.get_children():child.free()
	for entry in catalog_species:
		var species_id:=str(entry.get("species_id",""));var found:=bool(discovered.get(species_id,false))
		var card:=Button.new();card.custom_minimum_size=Vector2(252,218);_skin_button(card,Color("#f6e7c5"),16);card.disabled=not found;encyclopedia_grid.add_child(card)
		var content:=VBoxContainer.new();content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);content.offset_left=10;content.offset_top=8;content.offset_right=-10;content.offset_bottom=-8;content.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.alignment=BoxContainer.ALIGNMENT_CENTER;card.add_child(content)
		var image:=TextureRect.new();image.custom_minimum_size=Vector2(210,137);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.texture=_species_texture(entry);image.mouse_filter=Control.MOUSE_FILTER_IGNORE
		if not found:image.modulate=Color(0.12,0.09,0.08,0.82)
		content.add_child(image)
		var name_label:=Label.new();name_label.text=str(entry.get("name_ja","？？？")) if found else "？？？";name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name_label.add_theme_font_size_override("font_size",18);name_label.add_theme_color_override("font_color",UI_BROWN);content.add_child(name_label)
		var best_label_card:=Label.new();best_label_card.text=("自己ベスト  %.1f cm"%float(bests.get(species_id,0.0))) if found else "未発見";best_label_card.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;best_label_card.add_theme_font_size_override("font_size",14);best_label_card.add_theme_color_override("font_color",Color("#79543a"));content.add_child(best_label_card)
		if found:card.pressed.connect(_open_species_detail.bind(entry))

func _species_texture(entry:Dictionary)->Texture2D:
	var variant:=str(entry.get("visual_variant","laui"));var path:=str(SucculentClass.SPRITES.get(variant,SucculentClass.SPRITES.laui));return load(path) as Texture2D

func _build_habitat_items()->void:
	for child in habitat_items_root.get_children():child.free()
	habitat_pickups.clear();habitat_new_species_id=""
	var plant_points:Array=HABITAT_SAFE_PLANT_POINTS.duplicate()
	var point_index:=0
	for entry in catalog_species:
		var species_id:=str(entry.species_id)
		if bool(discovered.get(species_id,false)) and point_index<plant_points.size():
			_add_habitat_plant(entry,plant_points[point_index],false);point_index+=1
	var pending_spawn_index:=0
	for pending_id in pending_habitat_species:
		for entry in catalog_species:
			if str(entry.species_id)==str(pending_id):
				var is_first_tutorial_species:=pending_spawn_index==0 and not bool(tutorial_steps.get("habitat_wild_get",false))
				var new_point:Vector2=Vector2(810,385) if is_first_tutorial_species else HABITAT_NEW_SPECIES_POINTS[pending_spawn_index%HABITAT_NEW_SPECIES_POINTS.size()]
				habitat_new_species_id=str(pending_id);_add_habitat_plant(entry,new_point,true);pending_spawn_index+=1;break
	_reset_daily_seeds_if_needed()
	var seed_points:Array=HABITAT_SAFE_SEED_POINTS.duplicate();var daily_rng:=RandomNumberGenerator.new();daily_rng.seed=habitat_seed_date.hash()
	for i in range(seed_points.size()-1,0,-1):
		var swap_index:=daily_rng.randi_range(0,i);var held=seed_points[i];seed_points[i]=seed_points[swap_index];seed_points[swap_index]=held
	for i in range(maxi(0,10-habitat_seeds_collected)):_add_habitat_seed(seed_points[i])
	_update_habitat_ui()

func _add_habitat_plant(entry:Dictionary,panorama_point:Vector2,is_new:bool)->void:
	var sprite:=Sprite3D.new();sprite.texture=_species_texture(entry);sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED;sprite.no_depth_test=true;sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS;sprite.pixel_size=1.15/maxf(1.0,float(sprite.texture.get_width()));sprite.offset.y=-float(sprite.texture.get_height())*.18;sprite.position=_panorama_point_to_world(panorama_point,HABITAT_ITEM_RADIUS);habitat_items_root.add_child(sprite)
	if not is_new:sprite.scale=Vector3.ONE*_habitat_best_visual_scale(str(entry.species_id))
	var item={"node":sprite,"kind":"new_species" if is_new else "found_species","species_id":str(entry.species_id)};habitat_pickups.append(item)
	if is_new:
		sprite.modulate=Color(1.18,1.12,.78,1.0)
		var badge:=Label3D.new();badge.text="NEW!";badge.position.y=.72;badge.font_size=42;badge.outline_size=9;badge.modulate=Color("#ffe26f");sprite.add_child(badge)

func _habitat_best_visual_scale(species_id:String)->float:
	var best_cm:=float(bests.get(species_id,0.0))
	if best_cm<=0.0:return 1.0
	var greenhouse_equivalent:=.18+(best_cm-1.6)*.058
	return clampf(greenhouse_equivalent,.55,3.25)

func _add_habitat_seed(panorama_point:Vector2)->void:
	var seed:=MeshInstance3D.new();var mesh:=SphereMesh.new();mesh.radius=.105;mesh.height=.24;mesh.radial_segments=12;mesh.rings=6;seed.mesh=mesh
	var material:=StandardMaterial3D.new();material.albedo_color=Color("#b87932");material.roughness=.72;material.emission_enabled=true;material.emission=Color("#5c3514");material.emission_energy_multiplier=.35;seed.material_override=material;seed.position=_panorama_point_to_world(panorama_point,HABITAT_ITEM_RADIUS);habitat_items_root.add_child(seed);habitat_pickups.append({"node":seed,"kind":"seed"})

func _panorama_point_to_world(point:Vector2,radius:float)->Vector3:
	var longitude:float=(point.x/1280.0-.5)*TAU;var latitude:float=(.5-point.y/640.0)*PI;var horizontal:=cos(latitude)
	return Vector3(sin(longitude)*horizontal,sin(latitude),-cos(longitude)*horizontal)*radius

func _reset_daily_seeds_if_needed()->void:
	var today:=Time.get_date_string_from_system()
	if habitat_seed_date!=today:habitat_seed_date=today;habitat_seeds_collected=0;_save()

func _update_habitat_ui()->void:
	if habitat_status_label:
		habitat_status_label.visible=current_mode=="habitat" and rain_bonus_active
		habitat_status_label.text="恵みの雨  残り %d秒"%ceili(rain_time_remaining) if rain_bonus_active else ""
	if mode_button and current_mode=="greenhouse":mode_button.text="☂\n原生地" if rain_event_pending else "原生地"
	_update_habitat_button_glow()

func _roll_rain_event()->void:
	if rain_event_pending or active_seed_type=="old":return
	if not rain_draws_unlocked:
		rain_intro_normal_bags+=1
		if rain_intro_normal_bags<2:return
		rain_draws_unlocked=true
	rain_bag_count+=1
	var chance:float=float(RAIN_TRIGGER_CHANCES[mini(rain_bag_count-1,RAIN_TRIGGER_CHANCES.size()-1)])
	if rng.randf()>=chance:return
	rain_event_pending=true;rain_bonus_in_progress=false;rain_time_remaining=RAIN_BONUS_DURATION_SECONDS
	_show_rain_notice("原生地に恵みの雨が降っています")

func _show_rain_notice(message:String)->void:
	if effects_layer==null:return
	var notice:=Label.new();notice.text=message;notice.position=Vector2(68,215);notice.size=Vector2(440,72);notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;notice.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;notice.add_theme_font_size_override("font_size",22);notice.add_theme_color_override("font_color",Color("#eef8ff"));notice.add_theme_color_override("font_outline_color",Color("#28465d"));notice.add_theme_constant_override("outline_size",7);notice.add_theme_stylebox_override("normal",_box(Color(0.16,0.28,0.34,.9),Color("#b9deec"),18,2));effects_layer.add_child(notice)
	var tween:=create_tween();tween.tween_property(notice,"position:y",notice.position.y-12,.25).set_trans(Tween.TRANS_QUAD);tween.tween_interval(2.2);tween.tween_property(notice,"modulate:a",0.0,.45);tween.tween_callback(notice.queue_free)

func _evaluate_unlock_rules(trigger:String,current_value:float)->void:
	for rule in unlock_rules:
		if str(rule.get("trigger",""))!=trigger:continue
		var rule_id:=str(rule.get("id",""))
		if bool(completed_unlock_conditions.get(rule_id,false)) or current_value<float(rule.get("value",0.0)):continue
		completed_unlock_conditions[rule_id]=true
		var pending_before:=pending_habitat_species.size();_queue_random_species(str(rule.get("rarity","通常")))
		if pending_habitat_species.size()>pending_before:audio_manager.play_se("level_up",.52)
	_build_habitat_items();_save()

func _queue_random_species(rarity:String)->void:
	var candidates:Array=[]
	for entry in catalog_species:
		var species_id:=str(entry.species_id)
		if str(entry.get("rarity","通常"))!=rarity:continue
		if bool(discovered.get(species_id,false)) or bool(greenhouse_available.get(species_id,false)) or species_id in pending_habitat_species:continue
		candidates.append(entry)
	if candidates.is_empty():return
	var chosen:Dictionary=candidates[rng.randi_range(0,candidates.size()-1)];pending_habitat_species.append(str(chosen.species_id))

func _update_habitat_button_glow()->void:
	if not mode_button:return
	var has_pending:=not pending_habitat_species.is_empty() or rain_event_pending
	if habitat_glow_tween and habitat_glow_tween.is_valid():habitat_glow_tween.kill()
	mode_button.self_modulate=Color.WHITE
	if habitat_sparkle and is_instance_valid(habitat_sparkle):habitat_sparkle.queue_free()
	if not has_pending:return
	habitat_sparkle=Label.new();habitat_sparkle.text="☂" if rain_event_pending else "✦";habitat_sparkle.position=Vector2(5,-9);habitat_sparkle.add_theme_font_size_override("font_size",22);habitat_sparkle.add_theme_color_override("font_color",Color("#bceaff") if rain_event_pending else Color("#fff2a1"));habitat_sparkle.mouse_filter=Control.MOUSE_FILTER_IGNORE;mode_button.add_child(habitat_sparkle)
	var glow_color:=Color(0.72,1.05,1.22,1) if rain_event_pending else Color(1.2,1.12,.72,1)
	habitat_glow_tween=create_tween().set_loops();habitat_glow_tween.tween_property(mode_button,"self_modulate",glow_color,.75).set_trans(Tween.TRANS_SINE);habitat_glow_tween.parallel().tween_property(habitat_sparkle,"position:x",72.0,.75).set_trans(Tween.TRANS_SINE);habitat_glow_tween.parallel().tween_property(habitat_sparkle,"modulate:a",.25,.75);habitat_glow_tween.tween_property(mode_button,"self_modulate",Color.WHITE,.75);habitat_glow_tween.parallel().tween_property(habitat_sparkle,"position:x",5.0,.01);habitat_glow_tween.parallel().tween_property(habitat_sparkle,"modulate:a",1.0,.01);habitat_glow_tween.tween_interval(1.25)

func _open_species_detail(entry:Dictionary)->void:
	for child in encyclopedia_detail_page.get_children():child.free()
	encyclopedia_list_page.visible=false;encyclopedia_detail_page.visible=true
	var back:=Button.new();back.text="一覧へ";back.position=Vector2(24,28);back.size=Vector2(105,55);_skin_button(back,Color("#fff0cf"),17);back.pressed.connect(func():encyclopedia_detail_page.visible=false;encyclopedia_list_page.visible=true);encyclopedia_detail_page.add_child(back)
	var panel:=PanelContainer.new();panel.position=Vector2(28,115);panel.size=Vector2(520,760);panel.add_theme_stylebox_override("panel",_box(Color("#f6e7c5"),Color("#d3a75f"),24,4));encyclopedia_detail_page.add_child(panel)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",18);panel.add_child(content)
	var image:=TextureRect.new();image.custom_minimum_size=Vector2(450,470);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.texture=_species_texture(entry);content.add_child(image)
	var name_label:=Label.new();name_label.text=str(entry.get("name_ja",""));name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name_label.add_theme_font_size_override("font_size",31);name_label.add_theme_color_override("font_color",UI_BROWN);content.add_child(name_label)
	var species_id:=str(entry.get("species_id",""));var best_detail:=Label.new();best_detail.text="自己ベスト  %.1f cm"%float(bests.get(species_id,0.0));best_detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;best_detail.add_theme_font_size_override("font_size",23);best_detail.add_theme_color_override("font_color",Color("#98602e"));content.add_child(best_detail)

func _box(bg: Color, border: Color, radius: int, width: int) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new(); s.bg_color=bg; s.border_color=border
	s.set_border_width_all(width); s.set_corner_radius_all(radius); s.shadow_color=Color(0.18,0.08,0.02,0.34); s.shadow_size=6; s.shadow_offset=Vector2(0,3); s.content_margin_left=10; s.content_margin_right=10; s.content_margin_top=6; s.content_margin_bottom=6; return s

func _panda_portrait_texture()->Texture2D:
	var source:=load("res://assets/panda-clerk.png") as Texture2D
	var portrait:=AtlasTexture.new();portrait.atlas=source;portrait.region=Rect2(0.0,0.0,source.get_width(),source.get_height()*.70)
	return portrait

func _skin_button(b:Button,bg:Color,font_size:int)->void:
	b.add_theme_font_size_override("font_size",font_size); b.add_theme_color_override("font_color",UI_BROWN if bg.get_luminance()>.55 else Color.WHITE); b.add_theme_color_override("font_hover_color",UI_BROWN); b.add_theme_stylebox_override("normal",_box(bg,bg.lightened(.22),20,3)); b.add_theme_stylebox_override("hover",_box(bg.lightened(.08),Color.WHITE,20,3)); b.add_theme_stylebox_override("pressed",_box(bg.darkened(.08),bg.lightened(.2),20,3))
	if audio_manager and not b.pressed.is_connected(_play_ui_tap):b.pressed.connect(_play_ui_tap)

func _wire_ui_sounds(node:Node)->void:
	if node is Button and not node.pressed.is_connected(_play_ui_tap):node.pressed.connect(_play_ui_tap)
	for child in node.get_children():_wire_ui_sounds(child)

func _play_ui_tap()->void:
	if audio_manager:audio_manager.notify_user_gesture();audio_manager.play_se("ui_tap",.22)

func _layout() -> void:
	_update_greenhouse_pan()

func _update_greenhouse_pan()->void:
	if greenhouse_backdrop==null or greenhouse_backdrop.texture==null:return
	var viewport_size:=get_viewport().get_visible_rect().size
	var texture_size:=greenhouse_backdrop.texture.get_size()
	var cover_scale:=maxf(viewport_size.x/texture_size.x,viewport_size.y/texture_size.y)
	var display_size:=texture_size*cover_scale
	greenhouse_pan_limit=maxf(0.0,(display_size.x-viewport_size.x)*.5)
	greenhouse_pan_x=clampf(greenhouse_pan_x,-greenhouse_pan_limit,greenhouse_pan_limit)
	greenhouse_pan_target_x=clampf(greenhouse_pan_target_x,-greenhouse_pan_limit,greenhouse_pan_limit)
	greenhouse_backdrop.size=display_size
	greenhouse_backdrop.position=Vector2((viewport_size.x-display_size.x)*.5+greenhouse_pan_x,(viewport_size.y-display_size.y)*.5)
	if play_open_button:play_open_button.position=Vector2(198.0+greenhouse_pan_x,499.0)
	greenhouse_world_pan_x=0.0
	if camera:
		var soil_center:=camera.unproject_position(Vector3(0,.12,0))
		var soil_right:=camera.unproject_position(Vector3(1,.12,0))
		var pixels_per_world:=soil_right.x-soil_center.x
		if absf(pixels_per_world)>.001:greenhouse_world_pan_x=greenhouse_pan_x/pixels_per_world

func spawn_plant(force_golden := false,spawn_position:Variant=null) -> void:
	if rain_bonus_active:
		_spawn_rain_plant()
		return
	var chosen:Dictionary
	if active_seed_type=="old":
		for entry in catalog_species:
			if str(entry.species_id)=="colorata":chosen=entry;break
	elif force_golden:
		for entry in species:
			if str(entry.visual_variant) == "gold_laui": chosen = entry
		if chosen.is_empty(): chosen = species[0]
		forced_golden_done=true
	elif not opening_species.is_empty():chosen=opening_species.pop_front()
	else:chosen=_weighted_species()
	var pos:Vector3=_find_spawn_position() if spawn_position==null else spawn_position
	var label:=_plant_label(); labels_layer.add_child(label)
	var p = SucculentClass.new()
	p.original_pos=pos; p.position=pos; world_root.add_child(p); p.setup(chosen,rng.randi(),label,null)
	p.harvested.connect(_on_harvested); p.jellied.connect(_on_jellied)
	plants.append(p)
	if audio_manager:audio_manager.play_se("sprout",.28)

func _spawn_greenhouse_seed()->void:
	if not play_active or rain_bonus_active or play_seeds_remaining<=0:return
	var spawn_position:=_find_spawn_position();pending_seed_positions.append(spawn_position);play_seeds_remaining-=1;play_seed_animations_pending+=1;_update_play_ui();_animate_and_spawn_greenhouse_seed(spawn_position)

func _animate_and_spawn_greenhouse_seed(spawn_position:Vector3)->void:
	var seed:=Label.new();seed.text="●";seed.size=Vector2(22,22);seed.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;seed.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;seed.add_theme_font_size_override("font_size",17);seed.add_theme_color_override("font_color",Color("#6b3f20"));seed.add_theme_color_override("font_outline_color",Color("#e7c989"));seed.add_theme_constant_override("outline_size",2);seed.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var origin:=seed_bag_panel.global_position+Vector2(seed_bag_panel.size.x*.5,seed_bag_panel.size.y*.84)-Vector2(11,11);var displayed_spawn_position:=spawn_position+Vector3(greenhouse_world_pan_x,0,0);var destination:=camera.unproject_position(displayed_spawn_position)-Vector2(11,11);seed.position=origin;effects_layer.add_child(seed)
	var midpoint:=Vector2(lerpf(origin.x,destination.x,.55),minf(origin.y,destination.y)-34.0)
	var tween:=create_tween();tween.tween_property(seed,"position",midpoint,.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);tween.tween_property(seed,"position",destination,.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	if is_instance_valid(seed):seed.queue_free()
	pending_seed_positions.erase(spawn_position)
	play_seed_animations_pending=maxi(0,play_seed_animations_pending-1)
	if play_active and not rain_bonus_active:spawn_plant(false,spawn_position)
	if play_active and play_seeds_remaining==0 and play_spawn_queue==0 and play_seed_animations_pending==0 and plants.is_empty():call_deferred("_finish_greenhouse_play")

func _queue_greenhouse_replacements()->void:
	if not play_active or rain_bonus_active or active_seed_type=="old" or play_seeds_remaining<=play_spawn_queue:return
	var open_slots:=maxi(0,play_concurrent_target-(plants.size()+play_spawn_queue+play_seed_animations_pending))
	var add_count:=mini(open_slots,play_seeds_remaining-play_spawn_queue)
	if add_count<=0:return
	var was_empty:=play_spawn_queue==0;play_spawn_queue+=add_count
	if was_empty:play_spawn_timer=_next_greenhouse_spawn_interval()

func _next_greenhouse_spawn_interval()->float:
	if plants.size()<=3:return rng.randf_range(.04,.18)
	if rng.randf()<.20:return rng.randf_range(.04,.16)
	return rng.randf_range(.28,.92)

func _spawn_rain_plant()->void:
	var pool:=_rain_species_pool()
	if pool.is_empty():return
	var chosen:Dictionary=pool[rng.randi_range(0,pool.size()-1)]
	var pos:=_find_rain_spawn_position()
	var label:=_plant_label();labels_layer.add_child(label)
	var p=SucculentClass.new();p.original_pos=pos;p.position=pos;world_root.add_child(p);p.setup(chosen,rng.randi(),label,null);p.harvested.connect(_on_harvested);p.jellied.connect(_on_jellied);plants.append(p)
	if audio_manager:audio_manager.play_se("sprout",.22)

func _rain_species_pool()->Array:
	var pool:Array=[]
	for entry in catalog_species:
		var species_id:=str(entry.species_id)
		if bool(discovered.get(species_id,false)) and bool(greenhouse_available.get(species_id,false)):pool.append(entry)
	if pool.is_empty():
		for entry in catalog_species:
			if str(entry.species_id)=="colorata":pool.append(entry);break
	return pool

func _find_rain_spawn_position()->Vector3:
	var best:=_panorama_point_to_world(_random_rain_ground_point(),HABITAT_ITEM_RADIUS-.35)
	var best_clearance:=-1.0
	for attempt in range(96):
		var candidate:=_panorama_point_to_world(_random_rain_ground_point(),HABITAT_ITEM_RADIUS-.35)
		var clearance:=99.0
		for plant in plants:
			if is_instance_valid(plant):clearance=minf(clearance,candidate.distance_to(plant.original_pos))
		if clearance>best_clearance:best=candidate;best_clearance=clearance
		if clearance>=1.15:return candidate
	return best

func _random_rain_ground_point()->Vector2:
	var region:Rect2=RAIN_GROUND_REGIONS[rng.randi_range(0,RAIN_GROUND_REGIONS.size()-1)]
	return Vector2(rng.randf_range(region.position.x,region.end.x),rng.randf_range(region.position.y,region.end.y))

func _weighted_species()->Dictionary:
	var total:=0.0
	for s in species:total+=float(s.spawn_weight)
	var roll:=rng.randf()*total
	for s in species:
		roll-=float(s.spawn_weight)
		if roll<=0:return s
	return species[0]

func _find_spawn_position()->Vector3:
	# Sample world positions, but accept them only after projecting into the
	# scrolling background image's source-pixel coordinates.
	var best := Vector3.ZERO
	var best_clearance := -1.0
	for attempt in range(192):
		var angle := rng.randf_range(0.0, TAU)
		var radius := sqrt(rng.randf())
		var candidate := Vector3(cos(angle)*3.55*radius,.12,sin(angle)*3.15*radius)
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
		if clearance >= .82: return candidate
	return best

func _spawn_center_inside_soil(candidate:Vector3)->bool:
	if camera==null or greenhouse_backdrop==null or greenhouse_backdrop.texture==null:return false
	var displayed_world:=candidate+Vector3(greenhouse_world_pan_x,0,0)
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

func _start_rain_bonus()->void:
	if not rain_event_pending or rain_bonus_active:return
	rain_bonus_active=true;rain_bonus_in_progress=true;play_active=true;active_seed_type="rain";play_time_remaining=0.0
	if rain_time_remaining<=0.0:rain_time_remaining=RAIN_BONUS_DURATION_SECONDS
	rain_spawn_queue=0;rain_spawn_timer=0.0;rain_last_saved_second=ceili(rain_time_remaining)
	play_earnings_total=0;play_harvest_count=0;play_max_size=0.0;play_notable_species.clear();_clear_greenhouse_plants()
	for child in habitat_items_root.get_children():child.free()
	habitat_pickups.clear();habitat_items_root.visible=false
	for i in range(RAIN_INITIAL_PLANT_COUNT):spawn_plant()
	_start_rain_visual();_save();_update_play_ui();_update_habitat_ui();_show_rain_notice("恵みの雨が降り始めました")

func _finish_rain_bonus()->void:
	if not rain_bonus_active:return
	rain_bonus_active=false;rain_bonus_in_progress=false;rain_event_pending=false;rain_time_remaining=0.0;rain_bag_count=0;rain_spawn_queue=0;rain_spawn_timer=0.0;rain_last_saved_second=-1;play_active=false
	_clear_greenhouse_plants();_stop_rain_visual();_build_habitat_items();habitat_items_root.visible=current_mode=="habitat";_save();_update_play_ui();_update_habitat_ui();_show_rain_notice("恵みの雨が上がりました")

func _start_rain_visual()->void:
	_stop_rain_visual();rain_visual=Control.new();rain_visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);rain_visual.mouse_filter=Control.MOUSE_FILTER_IGNORE;effects_layer.add_child(rain_visual)
	var tint:=ColorRect.new();tint.color=Color(0.18,0.34,0.46,.13);tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);tint.mouse_filter=Control.MOUSE_FILTER_IGNORE;rain_visual.add_child(tint)
	rain_drops.clear()
	var viewport_size:=get_viewport().get_visible_rect().size
	for i in range(30):
		var drop:=ColorRect.new();drop.color=Color(0.75,0.91,1.0,rng.randf_range(.25,.58));drop.size=Vector2(rng.randf_range(1.0,2.2),rng.randf_range(32.0,68.0));drop.rotation=-.16;drop.position=Vector2(rng.randf_range(0.0,viewport_size.x),rng.randf_range(-viewport_size.y,viewport_size.y));drop.mouse_filter=Control.MOUSE_FILTER_IGNORE;drop.set_meta("speed",rng.randf_range(520.0,850.0));rain_visual.add_child(drop);rain_drops.append(drop)

func _stop_rain_visual()->void:
	if rain_visual and is_instance_valid(rain_visual):rain_visual.queue_free()
	rain_visual=null;rain_drops.clear()

func _update_rain_visual(delta:float)->void:
	if not rain_bonus_active:return
	var viewport_size:=get_viewport().get_visible_rect().size
	for drop in rain_drops:
		if not is_instance_valid(drop):continue
		drop.position+=Vector2(-70.0,float(drop.get_meta("speed",650.0)))*delta
		if drop.position.y>viewport_size.y+80.0:drop.position=Vector2(rng.randf_range(0.0,viewport_size.x+100.0),rng.randf_range(-240.0,-40.0))

func _process(delta:float)->void:
	_update_greenhouse_pan_follow(delta)
	_update_habitat_view_follow(delta)
	_update_habitat_scroll_tutorial()
	_update_rain_visual(delta)
	if rain_bonus_active:
		rain_time_remaining=maxf(0.0,rain_time_remaining-delta)
		var remaining_second:=ceili(rain_time_remaining)
		if remaining_second!=rain_last_saved_second:rain_last_saved_second=remaining_second;_save();_update_habitat_ui()
		if rain_time_remaining<=0.0:
			_finish_rain_bonus()
			return
		for p in plants:
			if is_instance_valid(p):p.simulate(delta)
		if rain_spawn_queue>0 and plants.size()<RAIN_MAX_ACTIVE_PLANTS:
			rain_spawn_timer-=delta
			if rain_spawn_timer<=0.0:rain_spawn_queue-=1;spawn_plant();rain_spawn_timer=rng.randf_range(.14,.32)
	elif current_mode=="greenhouse" and play_active:
		for p in plants:
			if is_instance_valid(p):p.simulate(delta)
		if play_spawn_queue>0:
			play_spawn_timer-=delta
			if play_spawn_timer<=0.0:
				play_spawn_queue-=1;_spawn_greenhouse_seed()
				if play_spawn_queue>0:play_spawn_timer=_next_greenhouse_spawn_interval()
	if not rain_bonus_active:_resolve_crowding(delta)
	_update_labels()

func _update_greenhouse_pan_follow(delta:float)->void:
	if current_mode!="greenhouse" or is_equal_approx(greenhouse_pan_x,greenhouse_pan_target_x):return
	var follow:=1.0-exp(-delta/GREENHOUSE_PAN_FOLLOW_SECONDS)
	greenhouse_pan_x=lerpf(greenhouse_pan_x,greenhouse_pan_target_x,follow)
	if absf(greenhouse_pan_target_x-greenhouse_pan_x)<0.05:greenhouse_pan_x=greenhouse_pan_target_x
	_update_greenhouse_pan()

func _update_habitat_view_follow(delta:float)->void:
	if current_mode!="habitat":return
	var follow:=1.0-exp(-delta/GREENHOUSE_PAN_FOLLOW_SECONDS)
	view_yaw=rad_to_deg(lerp_angle(deg_to_rad(view_yaw),deg_to_rad(habitat_target_yaw),follow));view_pitch=lerpf(view_pitch,habitat_target_pitch,follow)
	if absf(wrapf(habitat_target_yaw-view_yaw,-180.0,180.0))<.02:view_yaw=habitat_target_yaw
	if absf(habitat_target_pitch-view_pitch)<.02:view_pitch=habitat_target_pitch
	_apply_view_rotation()

func _toggle_mode()->void:
	if rain_bonus_active:return
	if current_mode=="greenhouse" and not habitat_unlocked:return
	var leaving_habitat:=current_mode=="habitat"
	current_mode="habitat" if current_mode=="greenhouse" else "greenhouse"
	_apply_mode()
	if current_mode=="habitat" and rain_event_pending:
		call_deferred("_start_rain_bonus")
	elif current_mode=="habitat" and not bool(tutorial_steps.get("habitat_scroll_dialog",false)):
		call_deferred("_start_habitat_scroll_tutorial")
	elif current_mode=="habitat" and _habitat_best_link_event_ready():
		call_deferred("_start_habitat_best_link_dialog")
	elif leaving_habitat and bool(tutorial_steps.get("habitat_get_dialog",false)) and not buyback_unlocked:
		call_deferred("_start_buyback_after_greenhouse_frame")

func _update_habitat_scroll_tutorial()->void:
	if not habitat_scroll_tutorial_active or current_mode!="habitat" or (tutorial_guide_overlay and tutorial_guide_overlay.visible):return
	var viewport_size:=get_viewport().get_visible_rect().size
	var visible_area:=Rect2(Vector2(55,105),viewport_size-Vector2(110,185))
	for item in habitat_pickups:
		if str(item.get("kind",""))!="new_species":continue
		var node:Node3D=item.get("node")
		if not is_instance_valid(node) or camera.is_position_behind(node.global_position):continue
		var screen:=camera.unproject_position(node.global_position)
		if not visible_area.has_point(screen):continue
		habitat_scroll_tutorial_active=false;tutorial_steps["habitat_species_spotted"]=true;_save()
		var species_name:="新品種"
		for entry in catalog_species:
			if str(entry.species_id)==str(item.get("species_id","")):species_name=str(entry.name_ja);break
		_show_habitat_species_guide(item,species_name)
		return

func _apply_mode()->void:
	if camera==null:return
	var greenhouse_mode:=current_mode=="greenhouse"
	if not greenhouse_mode:_build_habitat_items()
	greenhouse_layer.visible=greenhouse_mode
	habitat_items_root.visible=not greenhouse_mode
	if habitat_status_label:habitat_status_label.visible=not greenhouse_mode and rain_bonus_active
	# The official greenhouse artwork already contains the finished pot and soil.
	# Keep the old geometry disabled so no duplicate rim covers the sprites.
	pot_root.visible=false
	habitat_environment.background_mode=Environment.BG_CANVAS if greenhouse_mode else Environment.BG_SKY
	for p in plants:
		if is_instance_valid(p):p.visible=greenhouse_mode or rain_bonus_active;p.label.visible=false
	if greenhouse_mode:
		camera.position=Vector3(0,7.3,8.6);camera.look_at_from_position(camera.position,Vector3(0,1.05,0),Vector3.UP)
		_update_greenhouse_pan()
	else:
		camera.position=Vector3.ZERO;habitat_target_yaw=view_yaw;habitat_target_pitch=view_pitch;_apply_view_rotation()
	if mode_button:
		mode_button.text=("☂\n原生地" if rain_event_pending else "原生地") if greenhouse_mode else "温室"
	if audio_manager:audio_manager.play_bgm("greenhouse" if greenhouse_mode else "habitat")
	_update_play_ui()

func _resolve_crowding(_delta:float)->void:
	# Sprite plants remain rooted at their spawn point. Natural overlap is less
	# distracting than sliding a planted rosette around as it grows.
	for p in plants:
		if is_instance_valid(p):
			p.target_offset = Vector3.ZERO
			p.position.x = p.original_pos.x + (greenhouse_world_pan_x if current_mode=="greenhouse" else 0.0)
			p.position.z = p.original_pos.z

func _update_labels()->void:
	if current_mode!="greenhouse" and not rain_bonus_active:
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
		var r:=Rect2(screen-Vector2(46,62),Vector2(92,34))
		for other in occupied:
			if r.intersects(other):r.position.y=other.position.y-37
		occupied.append(r)
		p.label.position=r.position; p.label.text="%.1f cm"%p.diameter_cm; p.label.visible=p.state=="growing" and Rect2(Vector2.ZERO,get_viewport().get_visible_rect().size).grow(80).has_point(screen)

func _input(event:InputEvent)->void:
	if audio_manager and (event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey):audio_manager.notify_user_gesture()
	if (tutorial_guide_overlay and tutorial_guide_overlay.visible) or (intro_overlay and intro_overlay.visible) or (settings_overlay and settings_overlay.visible) or (encyclopedia_overlay and encyclopedia_overlay.visible) or (shop_overlay and shop_overlay.visible) or (result_overlay and result_overlay.visible) or (play_overlay and play_overlay.visible):return
	if current_mode=="greenhouse" and not play_active:return
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
	if pointer_travel<13.0 and pointer_start.distance_to(screen_pos)<16.0:
		if current_mode=="greenhouse" or rain_bonus_active:_try_harvest(screen_pos)
		elif current_mode=="habitat":_try_habitat_pick(screen_pos)

func _apply_view_rotation()->void:
	if camera:camera.rotation_degrees=Vector3(view_pitch,view_yaw,0.0)

func _try_harvest(screen_pos:Vector2)->void:
	# label-aware screen selection favors small visible plants when overlap occurs
	var candidates:Array=[]
	for p in plants:
		if not is_instance_valid(p) or p.state!="growing" or camera.is_position_behind(p.global_position):continue
		var center: Vector2 = camera.unproject_position(p.global_position+Vector3(0,p.visual_scale*.48,0))
		var top: Vector2 = camera.unproject_position(p.global_position+Vector3(0,p.visual_scale*1.25,0))
		var radius: float=clamp(center.distance_to(top)*1.15,30.0,180.0)
		var dist: float=center.distance_to(screen_pos)
		if dist<radius:candidates.append({"p":p,"score":dist/max(radius,1.0)+p.visual_scale*.08})
	if candidates.size()>0:
		candidates.sort_custom(func(a,b):return a.score<b.score);candidates[0].p.harvest()

func _try_habitat_pick(screen_pos:Vector2)->void:
	var candidates:Array=[]
	for item in habitat_pickups:
		var node=item.get("node")
		if not is_instance_valid(node) or camera.is_position_behind(node.global_position):continue
		var projected:=camera.unproject_position(node.global_position);var distance:=projected.distance_to(screen_pos)
		if distance<42.0:candidates.append({"item":item,"distance":distance})
	if candidates.is_empty():return
	candidates.sort_custom(func(a,b):return a.distance<b.distance);var selected:Dictionary=candidates[0].item
	if str(selected.kind)=="seed":_collect_habitat_seed(selected)
	elif str(selected.kind)=="new_species":_collect_habitat_species(selected)
	elif str(selected.kind)=="found_species":_squish_habitat_plant(selected)

func _collect_habitat_seed(item:Dictionary)->void:
	if habitat_seeds_collected>=10:return
	habitat_seeds_collected+=1;habitat_pickups.erase(item);var node=item.node;_show_habitat_message(node.global_position,"謎の種 GET!",Color("#ffe4a0"));node.queue_free();_save();_update_habitat_ui()

func _collect_habitat_species(item:Dictionary)->void:
	var node:Sprite3D=item.node;habitat_pickups.erase(item);node.visible=false
	var flying:=TextureRect.new();flying.texture=node.texture;flying.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;flying.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;flying.mouse_filter=Control.MOUSE_FILTER_IGNORE;flying.size=Vector2(112,112);flying.position=camera.unproject_position(node.global_position)-flying.size*.5;flying.pivot_offset=flying.size*.5;effects_layer.add_child(flying)
	var target:=Vector2(500,150)
	if encyclopedia_icon_button:target=encyclopedia_icon_button.global_position+encyclopedia_icon_button.size*.5
	var tween:=create_tween().set_parallel();tween.tween_property(flying,"position",target-flying.size*.5,.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN);tween.tween_property(flying,"scale",Vector2(.08,.08),.62).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN);tween.tween_property(flying,"rotation",.18,.62);tween.chain().tween_callback(_complete_habitat_species_get.bind(item,flying))

func _complete_habitat_species_get(item:Dictionary,flying:TextureRect)->void:
	var species_id:=str(item.species_id);greenhouse_available[species_id]=true;unlocked_species[species_id]=true;discovered[species_id]=true;pending_habitat_species.erase(species_id);habitat_new_species_id=""
	for entry in catalog_species:
		if str(entry.species_id)==species_id:
			var already_present:=false
			for active_entry in species:
				if str(active_entry.species_id)==species_id:already_present=true;break
			if not already_present:species.append(entry);opening_species.append(entry)
			_show_habitat_message(item.node.global_position,"%s GET!"%str(entry.name_ja),Color("#fff18a"));break
	if is_instance_valid(item.node):item.node.queue_free()
	if is_instance_valid(flying):flying.queue_free()
	if bool(tutorial_steps.get("habitat_species_spotted",false)) and not bool(tutorial_steps.get("habitat_get_dialog",false)):
		tutorial_steps["habitat_wild_get"]=true;call_deferred("_start_habitat_get_explanation")
	audio_manager.play_se("new_species",.72);_save();_update_habitat_ui()

func _squish_habitat_plant(item:Dictionary)->void:
	var node:Sprite3D=item.node;var original_scale:=node.scale;var tween:=create_tween();tween.tween_property(node,"scale",Vector3(original_scale.x*1.04,original_scale.y*.84,original_scale.z),.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT);tween.tween_property(node,"scale",original_scale,.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	audio_manager.play_se("squish",.42)

func _show_habitat_message(world_position:Vector3,message:String,color:Color)->void:
	var label:=Label.new();label.text=message;label.size=Vector2(300,80);label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",25);label.add_theme_color_override("font_color",color);label.add_theme_color_override("font_outline_color",UI_BROWN);label.add_theme_constant_override("outline_size",8);label.position=camera.unproject_position(world_position)-Vector2(150,40);effects_layer.add_child(label)
	var tween:=create_tween().set_parallel();tween.tween_property(label,"position:y",label.position.y-70,.7);tween.tween_property(label,"modulate:a",0.0,.7).set_delay(.25);tween.chain().tween_callback(label.queue_free)

func _on_harvested(p)->void:
	var old:=float(bests.get(p.data.species_id,0.0));var is_record:bool=p.diameter_cm>old
	discovered[p.data.species_id]=true
	if is_record:bests[p.data.species_id]=p.diameter_cm
	var reward:=harvest_reward_yen(p.diameter_cm) if buyback_unlocked else 0;coins+=reward;_evaluate_unlock_rules("harvest_size",p.diameter_cm);_save();_update_best_ui();_update_currency_ui();audio_manager.play_se("harvest",.55)
	if reward>0:audio_manager.play_se("payment",.25)
	if play_active:
		play_earnings_total+=reward;play_harvest_count+=1;play_max_size=maxf(play_max_size,p.diameter_cm)
		if not rain_bonus_active and p.diameter_cm>play_previous_global_best:play_updated_global_best=true
		var species_id:=str(p.data.species_id);var notable=play_notable_species.get(species_id,{})
		if notable.is_empty() or p.diameter_cm>float(notable.get("size",0.0)):play_notable_species[species_id]={"name":str(p.data.name_ja),"size":p.diameter_cm}
	_show_harvest_result(p,reward,buyback_unlocked)
	if is_record:_show_record(p,reward)
	var tween:=create_tween().set_parallel();tween.tween_property(p,"position:y",p.position.y+2.0,.42).set_trans(Tween.TRANS_BACK);tween.tween_property(p,"scale",p.scale*1.2,.22);tween.chain().tween_property(p,"scale",Vector3.ONE*0.01,.24)
	_cleanup_later(p,.68)

func _on_jellied(p)->void:
	_show_float(p,"ぷるん…\nジュレ",Color("#e7c9f0"))
	audio_manager.play_se("jelly",.38)
	var tw:=create_tween();tw.tween_property(p,"scale",Vector3(p.scale.x*1.05,p.scale.y*.46,p.scale.z*1.05),.28).set_trans(Tween.TRANS_BOUNCE);tw.tween_interval(.25);tw.tween_property(p,"scale",Vector3.ONE*0.01,.38)
	_cleanup_later(p,1.0)

func _cleanup_later(p,delay:float)->void:
	recent_vacated_slots.append(p.original_pos)
	while recent_vacated_slots.size()>12:recent_vacated_slots.pop_front()
	plants.erase(p)
	if rain_bonus_active and rain_time_remaining>0.0:
		rain_spawn_queue=mini(RAIN_MAX_ACTIVE_PLANTS,rain_spawn_queue+2)
		if rain_spawn_queue<=2:rain_spawn_timer=rng.randf_range(.14,.32)
	elif play_active:
		_queue_greenhouse_replacements();_update_play_ui()
		if play_seeds_remaining==0 and play_spawn_queue==0 and play_seed_animations_pending==0 and plants.is_empty():call_deferred("_finish_greenhouse_play")
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(p):p.label.queue_free();p.queue_free()

func _show_float(p,text:String,color:Color)->void:
	var l:=Label.new();l.text=text;l.size=Vector2(230,90);l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;l.add_theme_font_size_override("font_size",24);l.add_theme_color_override("font_color",color);l.add_theme_color_override("font_outline_color",UI_BROWN);l.add_theme_constant_override("outline_size",7);l.position=camera.unproject_position(p.global_position)-Vector2(115,40);effects_layer.add_child(l)
	var tw:=create_tween().set_parallel();tw.tween_property(l,"position:y",l.position.y-85,.62).set_trans(Tween.TRANS_BACK);tw.tween_property(l,"modulate:a",0.0,.62).set_delay(.18);tw.chain().tween_callback(l.queue_free)

func _show_harvest_result(plant,reward:int,show_money:bool)->void:
	var panel:=PanelContainer.new();panel.size=Vector2(220,132);panel.position=camera.unproject_position(plant.global_position)-Vector2(110,82);panel.pivot_offset=panel.size*.5;panel.scale=Vector2(.78,.78);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_theme_stylebox_override("panel",_box(Color(0.22,0.12,0.07,.92),Color("#f0cc82"),17,2));effects_layer.add_child(panel)
	var content:=VBoxContainer.new();content.alignment=BoxContainer.ALIGNMENT_CENTER;content.add_theme_constant_override("separation",0);content.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(content)
	var name_label:=Label.new();name_label.text=str(plant.data.name_ja);name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;name_label.add_theme_font_size_override("font_size",20);name_label.add_theme_color_override("font_color",Color.WHITE);content.add_child(name_label)
	var size_label:=Label.new();size_label.text="%.1fcm"%plant.diameter_cm;size_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;size_label.add_theme_font_size_override("font_size",19);size_label.add_theme_color_override("font_color",UI_CREAM);content.add_child(size_label)
	if show_money:
		var yen_label:=Label.new();yen_label.text="＋¥%d"%reward;yen_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;yen_label.add_theme_font_size_override("font_size",27);yen_label.add_theme_color_override("font_color",Color("#ffe06f"));yen_label.add_theme_color_override("font_outline_color",Color("#6b3518"));yen_label.add_theme_constant_override("outline_size",4);content.add_child(yen_label)
	var tween:=create_tween();tween.tween_property(panel,"scale",Vector2.ONE,.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);tween.tween_interval(1.12);tween.set_parallel(true);tween.tween_property(panel,"position:y",panel.position.y-34,.5).set_trans(Tween.TRANS_QUAD);tween.tween_property(panel,"modulate:a",0.0,.5);tween.set_parallel(false);tween.tween_callback(panel.queue_free)

func _show_record(p,reward:int)->void:
	audio_manager.play_se("result_new_best",.5)
	record_text.text=("収穫記録更新！\nNEW RECORD\n%.1f cm\n+%d円"%[p.diameter_cm,reward]) if buyback_unlocked else ("収穫記録更新！\nNEW RECORD\n%.1f cm"%p.diameter_cm);record_card.visible=true;record_card.scale=Vector2(.72,.72);record_card.pivot_offset=record_card.size/2
	var tw:=create_tween();tw.tween_property(record_card,"scale",Vector2.ONE,.24).set_trans(Tween.TRANS_BACK);tw.tween_interval(2.2);tw.tween_property(record_card,"modulate:a",0.0,.25);tw.tween_callback(func():record_card.visible=false;record_card.modulate.a=1.0)

func _update_best_ui()->void:
	best_label.text="最高記録\n%.1f cm"%_global_best_size()

func _global_best_size()->float:
	var top:=0.0
	for value in bests.values():top=maxf(top,float(value))
	return top

static func harvest_reward_yen(size_cm:float)->int:
	if size_cm<10.0:return 0
	if size_cm<20.0:return 10
	if size_cm<30.0:return 50
	if size_cm<40.0:return 100
	if size_cm<50.0:return 200
	if size_cm<60.0:return 300
	if size_cm<70.0:return 400
	if size_cm<80.0:return 500
	if size_cm<90.0:return 600
	if size_cm<100.0:return 1000
	if size_cm<110.0:return 1500
	if size_cm<120.0:return 2000
	if size_cm<130.0:return 2500
	if size_cm<140.0:return 3000
	return 3500+maxi(0,int(floor((size_cm-140.0)/10.0)))*500

func _comma(value:int)->String:
	var s:=str(value);var out:="";var count:=0
	for i in range(s.length()-1,-1,-1):
		if count>0 and count%3==0:out=","+out
		out=s[i]+out;count+=1
	return out
